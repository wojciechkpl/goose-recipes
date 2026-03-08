#!/bin/bash
# run_tests.sh - Test execution tool
# Runs pytest INSIDE the dev Docker container managed by dev_container.sh.
# Writes test output to a markdown file for the calling agent to ingest.
#
# 🚫 DOCKER-ONLY EXECUTION: Tests are NEVER run on the host.
#    This tool delegates to the dev container. If the container is not
#    running, it calls dev_container.sh --action ensure to start it.

set -e

SCRIPT_NAME="run_tests.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Derive container name (must match dev_container.sh convention) ────────────
PROJECT_DIR_NAME="$(basename "$PROJECT_ROOT")"
CONTAINER_NAME="dev-container-${PROJECT_DIR_NAME}"
WORKSPACE_MOUNT="/app/workspace"
DEV_CONTAINER_TOOL="${SCRIPT_DIR}/dev_container.sh"

# --- Usage Information ---
show_usage() {
    cat << 'EOF'
# run_tests.sh - Test Execution Tool (Docker-Only)

## PURPOSE
Executes pytest tests **inside the dev Docker container** and captures results.
Writes test output to a markdown file for the calling agent to ingest.

🚫 Tests are NEVER executed on the host machine. If the dev container is not
   running, this tool will automatically start it via `dev_container.sh --action ensure`.

## USAGE
```bash
./coding_agent_context/tools/run_tests.sh --output <output_file.md> --target <test_file_or_dir>
./coding_agent_context/tools/run_tests.sh --help
```

## REQUIRED PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--output`, `-o` | Path to output markdown file for test results |
| `--target`, `-t` | Target test file or directory to run |

## OPTIONAL PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--pytest-args` | Additional arguments to pass to pytest (quoted string) |
| `--help`, `-h` | Show this usage information |

## EXAMPLES
```bash
# Run specific test file
./coding_agent_context/tools/run_tests.sh -o results.md -t tests/test_auth.py

# Run all tests in directory
./coding_agent_context/tools/run_tests.sh --output results.md --target tests/

# Run with extra pytest flags
./coding_agent_context/tools/run_tests.sh -o results.md -t tests/ --pytest-args "-x --tb=long"

# Get usage information
./coding_agent_context/tools/run_tests.sh --help
```

## HOW IT WORKS
1. Checks if the dev container (managed by `dev_container.sh`) is running
2. If not running, calls `dev_container.sh --action ensure` to start it
3. Translates the host test path to a container path
4. Runs `pytest` inside the container via `docker exec`
5. Captures output to the specified markdown file

## OUTPUT
- Test results are written to the output markdown file
- Exit code indicates PASS (0) or FAIL (non-zero)
- Only a completion notification is printed to stdout
- The calling agent should read the output file for detailed results

## PREREQUISITES
- Docker must be installed and accessible
- The project should have a `docker/Dockerfile` (or one will be auto-generated)
- `dev_container.sh` must be in the same `tools/` directory
EOF
}

# --- Argument Parsing ---
OUTPUT_FILE=""
TARGET_FILE=""
PYTEST_ARGS=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --output|-o)
            OUTPUT_FILE="$2"
            shift 2
            ;;
        --target|-t)
            TARGET_FILE="$2"
            shift 2
            ;;
        --pytest-args)
            PYTEST_ARGS="$2"
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
if [[ -z "$OUTPUT_FILE" ]]; then
    echo "ERROR: --output parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ -z "$TARGET_FILE" ]]; then
    echo "ERROR: --target parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

# --- Create output directory if needed ---
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ -n "$OUTPUT_DIR" && "$OUTPUT_DIR" != "." ]]; then
    mkdir -p "$OUTPUT_DIR"
fi

# --- Write header to output file ---
{
    echo "# Test Execution Results"
    echo ""
    echo "**Generated:** $(date -Iseconds)"
    echo "**Target:** $TARGET_FILE"
    echo "**Container:** ${CONTAINER_NAME}"
    echo "**Execution:** Docker (never host)"
    echo ""
    echo "---"
    echo ""
} > "$OUTPUT_FILE"

# --- Ensure dev container is running ---
if ! docker ps -q --filter "name=^${CONTAINER_NAME}$" 2>/dev/null | grep -q .; then
    {
        echo "## ⚙️ Starting Dev Container"
        echo ""
        echo "Dev container \`${CONTAINER_NAME}\` was not running. Starting it now..."
        echo ""
    } >> "$OUTPUT_FILE"

    echo "ℹ️  Dev container not running — starting via dev_container.sh..."

    # Call dev_container.sh to ensure container is up
    ENSURE_OUTPUT=$("${DEV_CONTAINER_TOOL}" --action ensure 2>&1) || {
        {
            echo "## ❌ ERROR: Failed to Start Dev Container"
            echo ""
            echo "Could not start the dev container. Output:"
            echo ""
            echo '```'
            echo "$ENSURE_OUTPUT"
            echo '```'
            echo ""
            echo "**Troubleshooting:**"
            echo "1. Check that Docker is installed and running"
            echo "2. Check that \`docker/Dockerfile\` exists (or will be auto-generated)"
            echo "3. Run manually: \`./coding_agent_context/tools/dev_container.sh --action ensure\`"
        } >> "$OUTPUT_FILE"
        echo "❌ RUN_TESTS: Failed to start dev container. See: $OUTPUT_FILE"
        exit 1
    }

    {
        echo '```'
        echo "$ENSURE_OUTPUT"
        echo '```'
        echo ""
        echo "---"
        echo ""
    } >> "$OUTPUT_FILE"

    echo "✅ Dev container started."
fi

# --- Path Translation ---
# Convert host path to container path. The project root maps to WORKSPACE_MOUNT.
REL_PATH=$(realpath --relative-to="$PROJECT_ROOT" "$(realpath -m "$TARGET_FILE")" 2>/dev/null || echo "$TARGET_FILE")
DOCKER_PATH="${WORKSPACE_MOUNT}/${REL_PATH}"

{
    echo "## Path Mapping"
    echo ""
    echo "- Host path: \`$REL_PATH\`"
    echo "- Docker path: \`$DOCKER_PATH\`"
    echo ""
    echo "---"
    echo ""
    echo "## Test Output"
    echo ""
    echo '```'
} >> "$OUTPUT_FILE"

# --- Execute Pytest in Dev Container ---
set +e  # Don't exit on test failure
docker exec -i "${CONTAINER_NAME}" /bin/bash -c \
    "cd ${WORKSPACE_MOUNT} && PYTHONPATH=${WORKSPACE_MOUNT}/src:${WORKSPACE_MOUNT} pytest '${DOCKER_PATH}' -v --tb=short ${PYTEST_ARGS}" \
    >> "$OUTPUT_FILE" 2>&1
TEST_EXIT_CODE=$?
set -e

{
    echo '```'
    echo ""
    echo "---"
    echo ""
    if [[ $TEST_EXIT_CODE -eq 0 ]]; then
        echo "## ✅ Result: PASSED"
    else
        echo "## ❌ Result: FAILED"
        echo ""
        echo "Exit code: $TEST_EXIT_CODE"
    fi
} >> "$OUTPUT_FILE"

# --- Completion Notification ---
if [[ $TEST_EXIT_CODE -eq 0 ]]; then
    echo "✅ RUN_TESTS: All tests PASSED. Results: $OUTPUT_FILE"
else
    echo "❌ RUN_TESTS: Tests FAILED. Results: $OUTPUT_FILE"
fi

exit $TEST_EXIT_CODE
