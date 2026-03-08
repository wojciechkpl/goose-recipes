#!/bin/bash
# data_explorer.sh - Execute data exploration scripts in Docker and capture results
# Runs data processing code inside a container and writes results to markdown
#
# 🚫 DOCKER-ONLY EXECUTION: This tool is the ONLY permitted way to execute
#    data exploration code. NEVER run Python scripts directly on the host.
#    All execution happens inside Docker containers.

set -e

SCRIPT_NAME="data_explorer.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Usage Information ---
show_usage() {
    cat << 'EOF'
# data_explorer.sh - Data Exploration Executor

## PURPOSE
Executes data exploration Python scripts inside a Docker container and captures
the results. Designed to work with the docker_manager.sh tool for environment
setup. Ensures all analysis outputs are written to the designated output directory
as reproducible markdown files.

## USAGE
```bash
./coding_agent_context/tools/data_explorer.sh --action <action> --exploration-name <name> [options]
./coding_agent_context/tools/data_explorer.sh --help
```

## ACTIONS

| Action | Description |
|--------|-------------|
| `run` | Execute `run_exploration.py` in Docker, write outputs to --output dir |
| `run-script` | Execute a specific Python script (via --script) in the container |
| `verify` | Check that all expected output files from memory.md exist |
| `list-outputs` | List all generated output files with sizes |

## REQUIRED PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--action` | Action to perform (see table above) |
| `--exploration-name` | Name of the exploration session |

## OPTIONAL PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--output`, `-o` | Output directory for markdown results (default: `data_exploration_output/<name>/`) |
| `--script` | Specific Python script to run (for `run-script` action) |
| `--script-args` | Arguments to pass to the script (quoted string) |
| `--timeout` | Max execution time in seconds (default: 3600 = 1 hour) |
| `--help`, `-h` | Show this usage information |

## EXAMPLES
```bash
# Run the main exploration pipeline
./coding_agent_context/tools/data_explorer.sh \
    --action run \
    --exploration-name my_analysis

# Run with custom output directory
./coding_agent_context/tools/data_explorer.sh \
    --action run \
    --exploration-name my_analysis \
    --output data_exploration_output/my_analysis/

# Run a specific analysis script
./coding_agent_context/tools/data_explorer.sh \
    --action run-script \
    --exploration-name my_analysis \
    --script src/data_exploration/my_analysis/correlation_analysis.py

# Verify all outputs exist
./coding_agent_context/tools/data_explorer.sh \
    --action verify \
    --exploration-name my_analysis

# List all output files
./coding_agent_context/tools/data_explorer.sh \
    --action list-outputs \
    --exploration-name my_analysis
```

## OUTPUT
- Data processing results are written as markdown files into the output directory
- Execution logs (stdout/stderr) are captured to a session log file
- Exit code from the Python process is propagated
- A completion summary is printed to stdout
EOF
}

# --- Argument Parsing ---
ACTION=""
EXPLORATION_NAME=""
OUTPUT_DIR=""
SCRIPT_PATH=""
SCRIPT_ARGS=""
TIMEOUT=3600

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --action)
            ACTION="$2"
            shift 2
            ;;
        --exploration-name)
            EXPLORATION_NAME="$2"
            shift 2
            ;;
        --output|-o)
            OUTPUT_DIR="$2"
            shift 2
            ;;
        --script)
            SCRIPT_PATH="$2"
            shift 2
            ;;
        --script-args)
            SCRIPT_ARGS="$2"
            shift 2
            ;;
        --timeout)
            TIMEOUT="$2"
            shift 2
            ;;
        *)
            echo "ERROR: Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# --- Validation ---
if [[ -z "$ACTION" ]]; then
    echo "ERROR: --action parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ -z "$EXPLORATION_NAME" ]]; then
    echo "ERROR: --exploration-name parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

# --- Derived Variables ---
IMAGE_TAG="data-exploration-${EXPLORATION_NAME}:latest"
CONTAINER_NAME="data-exploration-${EXPLORATION_NAME}"
DAEMON_CONTAINER_NAME="data-exploration-${EXPLORATION_NAME}"
WORKSPACE_MOUNT="/workspace"
DEFAULT_OUTPUT_DIR="data_exploration_output/${EXPLORATION_NAME}"
OUTPUT_DIR="${OUTPUT_DIR:-$DEFAULT_OUTPUT_DIR}"
EXPLORATION_CODE_DIR="src/data_exploration/${EXPLORATION_NAME}"
MEMORY_FILE="coding_agent_context/specs/data_exploration_${EXPLORATION_NAME}/memory.md"
DOCKER_SCRIPTS_DIR="${PROJECT_ROOT}/docker/data_exploration_${EXPLORATION_NAME}"
SESSION_LOG="${OUTPUT_DIR}/.execution_log_$(date -u +%Y%m%dT%H%M%SZ).txt"

# --- Helper Functions ---

log_step() {
    echo ""
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  $1"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
}

log_info() {
    echo "  ℹ️  $1"
}

log_ok() {
    echo "  ✅ $1"
}

log_error() {
    echo "  ❌ $1" >&2
}

# Check if image exists
check_image() {
    if ! docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
        log_error "Docker image not found: ${IMAGE_TAG}"
        echo ""
        echo "  🚫 REMINDER: ALL data exploration code MUST run inside Docker."
        echo "     You cannot bypass Docker by running Python directly on the host."
        echo ""
        echo "  To set up the Docker environment, run:"
        echo "  ./coding_agent_context/tools/docker_manager.sh --action setup --exploration-name ${EXPLORATION_NAME}"
        echo ""
        echo "  Or to just rebuild the image (if Dockerfile exists):"
        echo "  ./coding_agent_context/tools/docker_manager.sh --action build --exploration-name ${EXPLORATION_NAME}"
        exit 1
    fi
}

# Check if daemon container is running, use it; otherwise run ephemeral
run_in_docker() {
    local cmd="$1"
    local use_timeout="${2:-true}"

    # Ensure output dir exists on host
    mkdir -p "${PROJECT_ROOT}/${OUTPUT_DIR}"

    # Build common mount options
    local common_opts=(-v "${PROJECT_ROOT}:${WORKSPACE_MOUNT}")

    # Mount AWS credentials if they exist
    if [[ -d "$HOME/.aws" ]]; then
        common_opts+=(-v "$HOME/.aws:/root/.aws:ro")
    fi

    # Pass through AWS environment variables
    for var in AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION; do
        if [[ -n "${!var:-}" ]]; then
            common_opts+=(-e "$var=${!var}")
        fi
    done

    # Check if daemon container is already running
    if docker ps -q --filter "name=^${DAEMON_CONTAINER_NAME}$" 2>/dev/null | grep -q .; then
        log_info "Using running daemon container: ${DAEMON_CONTAINER_NAME}"
        if [[ "$use_timeout" == "true" ]]; then
            timeout "${TIMEOUT}" docker exec -i "${DAEMON_CONTAINER_NAME}" /bin/bash -c "cd ${WORKSPACE_MOUNT} && ${cmd}"
        else
            docker exec -i "${DAEMON_CONTAINER_NAME}" /bin/bash -c "cd ${WORKSPACE_MOUNT} && ${cmd}"
        fi
    else
        log_info "Running in ephemeral container from image: ${IMAGE_TAG}"
        if [[ "$use_timeout" == "true" ]]; then
            timeout "${TIMEOUT}" docker run --rm \
                --name "${CONTAINER_NAME}-run-$$" \
                "${common_opts[@]}" \
                "${IMAGE_TAG}" \
                /bin/bash -c "cd ${WORKSPACE_MOUNT} && ${cmd}"
        else
            docker run --rm \
                --name "${CONTAINER_NAME}-run-$$" \
                "${common_opts[@]}" \
                "${IMAGE_TAG}" \
                /bin/bash -c "cd ${WORKSPACE_MOUNT} && ${cmd}"
        fi
    fi
}

# --- Action: run ---
action_run() {
    log_step "Running data exploration: ${EXPLORATION_NAME}"
    check_image

    # Verify exploration code exists
    if [[ ! -f "${PROJECT_ROOT}/${EXPLORATION_CODE_DIR}/run_exploration.py" ]]; then
        log_error "Exploration entry point not found: ${EXPLORATION_CODE_DIR}/run_exploration.py"
        echo ""
        echo "  Expected file: ${EXPLORATION_CODE_DIR}/run_exploration.py"
        echo "  Make sure the exploration code has been implemented first."
        exit 1
    fi

    # Create output directory
    mkdir -p "${PROJECT_ROOT}/${OUTPUT_DIR}"

    log_info "Entry point: ${EXPLORATION_CODE_DIR}/run_exploration.py"
    log_info "Output dir:  ${OUTPUT_DIR}/"
    log_info "Timeout:     ${TIMEOUT}s"
    echo ""

    # Capture start time
    local start_time
    start_time=$(date +%s)

    # Execute in Docker
    local exit_code=0

    {
        echo "# Data Exploration Execution Log"
        echo ""
        echo "**Exploration:** ${EXPLORATION_NAME}"
        echo "**Started:** $(date -Iseconds)"
        echo "**Entry Point:** ${EXPLORATION_CODE_DIR}/run_exploration.py"
        echo "**Image:** ${IMAGE_TAG}"
        echo ""
        echo "---"
        echo ""
        echo '```'
    } > "${PROJECT_ROOT}/${SESSION_LOG}"

    set +e
    run_in_docker \
        "PYTHONPATH=${WORKSPACE_MOUNT} EXPLORATION_OUTPUT_DIR=${OUTPUT_DIR} python ${EXPLORATION_CODE_DIR}/run_exploration.py" \
        true \
        >> "${PROJECT_ROOT}/${SESSION_LOG}" 2>&1
    exit_code=$?
    set -e

    {
        echo '```'
        echo ""
        echo "---"
        echo ""
        echo "**Finished:** $(date -Iseconds)"
        echo "**Exit Code:** ${exit_code}"
    } >> "${PROJECT_ROOT}/${SESSION_LOG}"

    # Calculate duration
    local end_time
    end_time=$(date +%s)
    local duration=$(( end_time - start_time ))

    # Report results
    echo ""
    if [[ $exit_code -eq 0 ]]; then
        log_ok "Execution completed successfully (${duration}s)"

        # List outputs
        echo ""
        echo "  Generated outputs:"
        if [[ -d "${PROJECT_ROOT}/${OUTPUT_DIR}" ]]; then
            find "${PROJECT_ROOT}/${OUTPUT_DIR}" -name "*.md" -not -name ".*" -type f | sort | while read -r f; do
                local rel_path="${f#${PROJECT_ROOT}/}"
                local size
                size=$(stat --format="%s" "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "?")
                echo "    📄 ${rel_path} (${size} bytes)"
            done
        fi
    elif [[ $exit_code -eq 124 ]]; then
        log_error "Execution TIMED OUT after ${TIMEOUT}s"
        echo "  Increase timeout with: --timeout <seconds>"
    else
        log_error "Execution FAILED with exit code: ${exit_code}"
        echo ""
        echo "  Check the execution log:"
        echo "    cat ${SESSION_LOG}"
        echo ""
        echo "  Last 20 lines of output:"
        tail -22 "${PROJECT_ROOT}/${SESSION_LOG}" | head -20 | sed 's/^/    /'
    fi

    echo ""
    echo "  Execution log: ${SESSION_LOG}"

    return $exit_code
}

# --- Action: run-script ---
action_run_script() {
    log_step "Running script: ${SCRIPT_PATH}"
    check_image

    if [[ -z "$SCRIPT_PATH" ]]; then
        log_error "--script parameter is required for run-script action"
        exit 1
    fi

    if [[ ! -f "${PROJECT_ROOT}/${SCRIPT_PATH}" ]]; then
        log_error "Script not found: ${SCRIPT_PATH}"
        exit 1
    fi

    # Create output directory
    mkdir -p "${PROJECT_ROOT}/${OUTPUT_DIR}"

    log_info "Script: ${SCRIPT_PATH}"
    log_info "Args:   ${SCRIPT_ARGS:-<none>}"
    echo ""

    local exit_code=0
    set +e
    run_in_docker \
        "PYTHONPATH=${WORKSPACE_MOUNT} EXPLORATION_OUTPUT_DIR=${OUTPUT_DIR} python ${SCRIPT_PATH} ${SCRIPT_ARGS}" \
        true
    exit_code=$?
    set -e

    if [[ $exit_code -eq 0 ]]; then
        log_ok "Script completed successfully"
    else
        log_error "Script failed with exit code: ${exit_code}"
    fi

    return $exit_code
}

# --- Action: verify ---
action_verify() {
    log_step "Verifying outputs: ${EXPLORATION_NAME}"

    local memory_path="${PROJECT_ROOT}/${MEMORY_FILE}"

    if [[ ! -f "$memory_path" ]]; then
        log_error "Memory file not found: ${MEMORY_FILE}"
        echo "  Cannot verify without exploration history."
        exit 1
    fi

    log_info "Checking outputs against memory file..."
    echo ""

    # Extract expected output files from memory
    # Look for file paths in backticks that point to the output directory
    local expected_files=()
    while IFS= read -r line; do
        expected_files+=("$line")
    done < <(grep -oP "(?<=\`)${OUTPUT_DIR}/[^\`]+\.md(?=\`)" "$memory_path" 2>/dev/null || true)

    # Also check for INDEX.md as a baseline
    expected_files+=("${OUTPUT_DIR}/INDEX.md")

    # Deduplicate
    local unique_files
    unique_files=$(printf '%s\n' "${expected_files[@]}" | sort -u)

    local total=0
    local found=0
    local missing=0

    while IFS= read -r expected; do
        [[ -z "$expected" ]] && continue
        total=$((total + 1))
        local full_path="${PROJECT_ROOT}/${expected}"
        if [[ -f "$full_path" ]]; then
            found=$((found + 1))
            echo "  ✅ ${expected}"
        else
            missing=$((missing + 1))
            echo "  ❌ ${expected} (MISSING)"
        fi
    done <<< "$unique_files"

    echo ""
    echo "  Results: ${found}/${total} files found, ${missing} missing"

    if [[ $missing -gt 0 ]]; then
        log_error "Backwards compatibility check FAILED — ${missing} output(s) missing"
        echo "  Re-run the exploration to regenerate missing outputs:"
        echo "  ./coding_agent_context/tools/data_explorer.sh --action run --exploration-name ${EXPLORATION_NAME}"
        return 1
    else
        log_ok "All expected outputs present — backwards compatibility OK"
        return 0
    fi
}

# --- Action: list-outputs ---
action_list_outputs() {
    log_step "Output files: ${EXPLORATION_NAME}"

    local output_path="${PROJECT_ROOT}/${OUTPUT_DIR}"

    if [[ ! -d "$output_path" ]]; then
        log_info "Output directory does not exist yet: ${OUTPUT_DIR}/"
        return 0
    fi

    echo ""
    local total_files=0
    local total_size=0

    # List markdown files
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        total_files=$((total_files + 1))
        local rel_path="${f#${PROJECT_ROOT}/}"
        local size
        size=$(stat --format="%s" "$f" 2>/dev/null || stat -f%z "$f" 2>/dev/null || echo "0")
        total_size=$((total_size + size))
        local size_human
        if [[ $size -gt 1048576 ]]; then
            size_human="$(awk "BEGIN{printf \"%.1f MB\", ${size}/1048576}")"
        elif [[ $size -gt 1024 ]]; then
            size_human="$(awk "BEGIN{printf \"%.1f KB\", ${size}/1024}")"
        else
            size_human="${size} B"
        fi
        echo "  📄 ${rel_path}  (${size_human})"
    done < <(find "$output_path" -name "*.md" -not -name ".*" -type f | sort)

    # List execution logs
    local log_count=0
    while IFS= read -r f; do
        [[ -z "$f" ]] && continue
        log_count=$((log_count + 1))
    done < <(find "$output_path" -name ".execution_log_*" -type f 2>/dev/null)

    echo ""
    echo "  Summary: ${total_files} output file(s), ${log_count} execution log(s)"
    if [[ $total_size -gt 1048576 ]]; then
        echo "  Total size: $(awk "BEGIN{printf \"%.1f MB\", ${total_size}/1048576}")"
    elif [[ $total_size -gt 1024 ]]; then
        echo "  Total size: $(awk "BEGIN{printf \"%.1f KB\", ${total_size}/1024}")"
    else
        echo "  Total size: ${total_size} B"
    fi
}

# --- Dispatch ---
case "$ACTION" in
    run)          action_run ;;
    run-script)   action_run_script ;;
    verify)       action_verify ;;
    list-outputs) action_list_outputs ;;
    *)
        echo "ERROR: Unknown action: $ACTION"
        echo "Valid actions: run, run-script, verify, list-outputs"
        exit 1
        ;;
esac
