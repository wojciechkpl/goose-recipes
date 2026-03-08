#!/bin/bash
# docker_manager.sh - Docker environment management for data exploration
# Sets up, builds, and manages Docker containers for data processing

set -e

SCRIPT_NAME="docker_manager.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# --- Usage Information ---
show_usage() {
    cat << 'EOF'
# docker_manager.sh - Docker Environment Manager for Data Exploration

## PURPOSE
Manages Docker environments for data exploration sessions. Handles creation
of Dockerfiles, build/run scripts, image building, and container lifecycle.
Supports both dedicated exploration Dockerfiles and extending existing project Dockerfiles.

## USAGE
```bash
./coding_agent_context/tools/docker_manager.sh --action <action> --exploration-name <name> [options]
./coding_agent_context/tools/docker_manager.sh --help
```

## ACTIONS

| Action | Description |
|--------|-------------|
| `setup` | Create Dockerfile + build/run scripts, build image, verify container |
| `build` | Build (or rebuild) the Docker image only |
| `start` | Start a container in daemon mode (for repeated executions) |
| `stop` | Stop and remove a running daemon container |
| `status` | Check if the container/image exists and is running |
| `shell` | Open an interactive shell in the container |

## REQUIRED PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--action` | Action to perform (see table above) |
| `--exploration-name` | Name of the exploration session (used for image tags, paths) |

## OPTIONAL PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--data-sources` | Comma-separated data source paths (used during `setup` to detect dependencies) |
| `--help`, `-h` | Show this usage information |

## ENVIRONMENT VARIABLES
| Variable | Default | Description |
|----------|---------|-------------|
| `USE_PACKAGE_DOCKER` | `false` | If `true`, extend existing project Dockerfile instead of creating dedicated one |

## EXAMPLES
```bash
# Full setup (creates Dockerfile, builds image, verifies)
./coding_agent_context/tools/docker_manager.sh \
    --action setup \
    --exploration-name my_analysis \
    --data-sources "data/file.csv,s3://bucket/data.parquet"

# Rebuild image after Dockerfile changes
./coding_agent_context/tools/docker_manager.sh --action build --exploration-name my_analysis

# Start daemon container for repeated script executions
./coding_agent_context/tools/docker_manager.sh --action start --exploration-name my_analysis

# Check container status
./coding_agent_context/tools/docker_manager.sh --action status --exploration-name my_analysis

# Open interactive shell
./coding_agent_context/tools/docker_manager.sh --action shell --exploration-name my_analysis

# Stop daemon container
./coding_agent_context/tools/docker_manager.sh --action stop --exploration-name my_analysis
```

## OUTPUT
- Dockerfile and helper scripts created in `docker/data_exploration_<name>/`
- Docker image tagged as `data-exploration-<name>:latest`
- Status and progress messages printed to stdout
EOF
}

# --- Argument Parsing ---
ACTION=""
EXPLORATION_NAME=""
DATA_SOURCES=""

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
        --data-sources)
            DATA_SOURCES="$2"
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
USE_PACKAGE_DOCKER="${USE_PACKAGE_DOCKER:-false}"
IMAGE_TAG="data-exploration-${EXPLORATION_NAME}:latest"
CONTAINER_NAME="data-exploration-${EXPLORATION_NAME}"
DEDICATED_DOCKER_DIR="${PROJECT_ROOT}/docker/data_exploration_${EXPLORATION_NAME}"
EXISTING_DOCKER_DIR="${PROJECT_ROOT}/docker"
WORKSPACE_MOUNT="/workspace"

# Decide which docker directory to use
if [[ "$USE_PACKAGE_DOCKER" == "true" && -f "${EXISTING_DOCKER_DIR}/Dockerfile" ]]; then
    DOCKER_DIR="${EXISTING_DOCKER_DIR}"
    DOCKER_MODE="extended"
else
    DOCKER_DIR="${DEDICATED_DOCKER_DIR}"
    DOCKER_MODE="dedicated"
fi

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

# --- Detect required Python packages from data sources ---
detect_extra_requirements() {
    local sources="$1"
    local extras=""

    # Check for S3 paths
    if echo "$sources" | grep -qi "s3://"; then
        extras="${extras} boto3>=1.28.0 s3fs awscli"
    fi

    # Check for parquet files
    if echo "$sources" | grep -qi "\.parquet"; then
        extras="${extras} pyarrow"
    fi

    # Check for JSON files
    if echo "$sources" | grep -qi "\.json"; then
        extras="${extras} orjson"
    fi

    # Check for Excel files
    if echo "$sources" | grep -qi "\.xlsx\|\.xls"; then
        extras="${extras} openpyxl"
    fi

    echo "$extras"
}

# --- Create Dedicated Dockerfile ---
create_dedicated_dockerfile() {
    log_step "Creating dedicated Dockerfile for data exploration"
    mkdir -p "$DEDICATED_DOCKER_DIR"

    # Detect extra requirements
    local extra_pkgs
    extra_pkgs=$(detect_extra_requirements "$DATA_SOURCES")

    # Check if project has a requirements.txt to inherit from
    local project_requirements=""
    if [[ -f "${EXISTING_DOCKER_DIR}/requirements.txt" ]]; then
        project_requirements="COPY docker/requirements.txt /tmp/project_requirements.txt
RUN pip install --no-cache-dir -r /tmp/project_requirements.txt"
        log_info "Found project requirements.txt — will install project dependencies"
    fi

    cat > "${DEDICATED_DOCKER_DIR}/Dockerfile" << DOCKERFILE_END
# ==============================================================================
# Data Exploration Environment: ${EXPLORATION_NAME}
# Generated by docker_manager.sh on $(date -Iseconds)
# ==============================================================================
FROM python:3.12-slim

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# System dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \\
    build-essential \\
    curl \\
    git \\
    && rm -rf /var/lib/apt/lists/*

# Core data science dependencies
RUN pip install --no-cache-dir \\
    pandas \\
    numpy \\
    matplotlib \\
    seaborn \\
    scipy \\
    pyarrow \\
    tabulate \\
    ${extra_pkgs}

${project_requirements}

# Working directory
WORKDIR ${WORKSPACE_MOUNT}

# Default: interactive shell
CMD ["/bin/bash"]
DOCKERFILE_END

    log_ok "Dockerfile created: ${DEDICATED_DOCKER_DIR}/Dockerfile"
}

# --- Create Extended Dockerfile (from existing project Dockerfile) ---
create_extended_dockerfile() {
    log_step "Extending existing project Dockerfile for data exploration"
    mkdir -p "$DEDICATED_DOCKER_DIR"

    # Detect extra requirements beyond what project already has
    local extra_pkgs
    extra_pkgs=$(detect_extra_requirements "$DATA_SOURCES")

    # Read existing Dockerfile to understand base image
    local base_image
    base_image=$(grep "^FROM" "${EXISTING_DOCKER_DIR}/Dockerfile" | head -1 | awk '{print $2}')
    log_info "Existing Dockerfile base image: $base_image"

    cat > "${DEDICATED_DOCKER_DIR}/Dockerfile" << DOCKERFILE_END
# ==============================================================================
# Data Exploration Environment: ${EXPLORATION_NAME}
# Extended from project Dockerfile
# Generated by docker_manager.sh on $(date -Iseconds)
# ==============================================================================

# --- Stage 1: Use existing project image as base ---
FROM ${base_image}

ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1

# Install project requirements first (same as project Dockerfile)
COPY docker/requirements.txt /tmp/project_requirements.txt
RUN pip install --no-cache-dir -r /tmp/project_requirements.txt

# Additional data exploration dependencies
RUN pip install --no-cache-dir \\
    seaborn \\
    scipy \\
    tabulate \\
    ${extra_pkgs}

WORKDIR ${WORKSPACE_MOUNT}

CMD ["/bin/bash"]
DOCKERFILE_END

    log_ok "Extended Dockerfile created: ${DEDICATED_DOCKER_DIR}/Dockerfile"
}

# --- Generate build.sh ---
generate_build_script() {
    cat > "${DEDICATED_DOCKER_DIR}/build.sh" << BUILD_END
#!/bin/bash
# ==============================================================================
# Build the data exploration Docker image: ${EXPLORATION_NAME}
# Generated by docker_manager.sh
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\${SCRIPT_DIR}/../.." && pwd)"
IMAGE_TAG="${IMAGE_TAG}"

echo "Building data exploration image: \${IMAGE_TAG}"
echo "Context: \${PROJECT_ROOT}"
echo "Dockerfile: \${SCRIPT_DIR}/Dockerfile"

docker build \\
    -t "\${IMAGE_TAG}" \\
    -f "\${SCRIPT_DIR}/Dockerfile" \\
    "\${PROJECT_ROOT}"

echo ""
echo "✅ Build complete. Image: \${IMAGE_TAG}"
BUILD_END

    chmod +x "${DEDICATED_DOCKER_DIR}/build.sh"
    log_ok "build.sh created: ${DEDICATED_DOCKER_DIR}/build.sh"
}

# --- Generate run.sh ---
generate_run_script() {
    cat > "${DEDICATED_DOCKER_DIR}/run.sh" << 'RUN_HEADER'
#!/bin/bash
# ==============================================================================
RUN_HEADER

    cat >> "${DEDICATED_DOCKER_DIR}/run.sh" << RUN_END
# Run data exploration container: ${EXPLORATION_NAME}
# Generated by docker_manager.sh
#
# Usage:
#   ./run.sh              # Interactive shell (default)
#   ./run.sh shell        # Interactive shell
#   ./run.sh process      # Run run_exploration.py and exit
#   ./run.sh daemon       # Start in background (use: docker exec -it ${CONTAINER_NAME} bash)
# ==============================================================================

set -euo pipefail

SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\${SCRIPT_DIR}/../.." && pwd)"
IMAGE_TAG="${IMAGE_TAG}"
CONTAINER_NAME="${CONTAINER_NAME}"
AWS_CREDS_DIR="\$HOME/.aws"

MODE="\${1:-shell}"

COMMON_OPTS=(
    -v "\${PROJECT_ROOT}:${WORKSPACE_MOUNT}"
)

# Mount AWS credentials if they exist
if [[ -d "\$AWS_CREDS_DIR" ]]; then
    COMMON_OPTS+=(-v "\${AWS_CREDS_DIR}:/root/.aws:ro")
fi

# Pass through AWS environment variables if set
for var in AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION; do
    if [[ -n "\${!var:-}" ]]; then
        COMMON_OPTS+=(-e "\$var=\${!var}")
    fi
done

case "\$MODE" in
    shell)
        echo "Starting interactive shell..."
        docker run -it --rm --name "\${CONTAINER_NAME}" \\
            "\${COMMON_OPTS[@]}" \\
            "\${IMAGE_TAG}" \\
            /bin/bash
        ;;
    process)
        echo "Running data exploration..."
        docker run --rm --name "\${CONTAINER_NAME}-run" \\
            "\${COMMON_OPTS[@]}" \\
            "\${IMAGE_TAG}" \\
            python src/data_exploration/${EXPLORATION_NAME}/run_exploration.py
        ;;
    daemon)
        echo "Starting in background (use: docker exec -it \${CONTAINER_NAME} bash)..."
        docker run -d --name "\${CONTAINER_NAME}" \\
            "\${COMMON_OPTS[@]}" \\
            "\${IMAGE_TAG}" \\
            tail -f /dev/null
        echo "Container started: \${CONTAINER_NAME}"
        echo "  Shell:  docker exec -it \${CONTAINER_NAME} bash"
        echo "  Stop:   docker stop \${CONTAINER_NAME} && docker rm \${CONTAINER_NAME}"
        ;;
    *)
        echo "Usage: \$0 [shell|process|daemon]"
        exit 1
        ;;
esac
RUN_END

    chmod +x "${DEDICATED_DOCKER_DIR}/run.sh"
    log_ok "run.sh created: ${DEDICATED_DOCKER_DIR}/run.sh"
}

# --- Action: setup ---
action_setup() {
    log_step "Setting up Docker environment for: ${EXPLORATION_NAME}"
    log_info "Mode: ${DOCKER_MODE} (USE_PACKAGE_DOCKER=${USE_PACKAGE_DOCKER})"

    # Step 1: Create Dockerfile
    if [[ -f "${DEDICATED_DOCKER_DIR}/Dockerfile" ]]; then
        log_info "Dockerfile already exists at ${DEDICATED_DOCKER_DIR}/Dockerfile — skipping creation"
    else
        if [[ "$DOCKER_MODE" == "extended" ]]; then
            create_extended_dockerfile
        else
            create_dedicated_dockerfile
        fi
    fi

    # Step 2: Generate helper scripts
    generate_build_script
    generate_run_script

    # Step 3: Build image
    log_step "Building Docker image: ${IMAGE_TAG}"
    bash "${DEDICATED_DOCKER_DIR}/build.sh"

    # Step 4: Verify container starts
    log_step "Verifying container"
    local verify_output
    verify_output=$(docker run --rm "${IMAGE_TAG}" python -c "
import sys
print(f'Python {sys.version}')
try:
    import pandas; print(f'pandas {pandas.__version__}')
except: print('pandas NOT FOUND')
try:
    import numpy; print(f'numpy {numpy.__version__}')
except: print('numpy NOT FOUND')
try:
    import matplotlib; print(f'matplotlib {matplotlib.__version__}')
except: print('matplotlib NOT FOUND')
print('Container verification OK')
" 2>&1)

    echo "$verify_output"

    if echo "$verify_output" | grep -q "Container verification OK"; then
        log_ok "Container verified successfully"
    else
        log_error "Container verification failed"
        exit 1
    fi

    # Summary
    log_step "Setup Complete"
    echo ""
    echo "  Docker mode:    ${DOCKER_MODE}"
    echo "  Dockerfile:     ${DEDICATED_DOCKER_DIR}/Dockerfile"
    echo "  Image:          ${IMAGE_TAG}"
    echo "  Build script:   ${DEDICATED_DOCKER_DIR}/build.sh"
    echo "  Run script:     ${DEDICATED_DOCKER_DIR}/run.sh"
    echo ""
    echo "  Quick start:"
    echo "    Interactive:  ${DEDICATED_DOCKER_DIR}/run.sh shell"
    echo "    Process:      ${DEDICATED_DOCKER_DIR}/run.sh process"
    echo "    Daemon:       ${DEDICATED_DOCKER_DIR}/run.sh daemon"
}

# --- Action: build ---
action_build() {
    log_step "Building Docker image: ${IMAGE_TAG}"

    if [[ ! -f "${DEDICATED_DOCKER_DIR}/build.sh" ]]; then
        log_error "build.sh not found. Run --action setup first."
        exit 1
    fi

    bash "${DEDICATED_DOCKER_DIR}/build.sh"
    log_ok "Image built: ${IMAGE_TAG}"
}

# --- Action: start ---
action_start() {
    log_step "Starting daemon container: ${CONTAINER_NAME}"

    # Stop existing if running
    if docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q .; then
        log_info "Stopping existing container..."
        docker stop "${CONTAINER_NAME}" >/dev/null 2>&1 || true
        docker rm "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi

    bash "${DEDICATED_DOCKER_DIR}/run.sh" daemon
    log_ok "Container started: ${CONTAINER_NAME}"
}

# --- Action: stop ---
action_stop() {
    log_step "Stopping container: ${CONTAINER_NAME}"

    if docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q .; then
        docker stop "${CONTAINER_NAME}" >/dev/null 2>&1
        docker rm "${CONTAINER_NAME}" >/dev/null 2>&1
        log_ok "Container stopped and removed"
    else
        log_info "Container not running"
    fi
}

# --- Action: status ---
action_status() {
    log_step "Docker Status: ${EXPLORATION_NAME}"

    echo ""
    echo "  Image:"
    if docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1; then
        local image_size
        image_size=$(docker image inspect "${IMAGE_TAG}" --format '{{.Size}}' | awk '{printf "%.0f MB", $1/1024/1024}')
        echo "    ✅ ${IMAGE_TAG} (${image_size})"
    else
        echo "    ❌ ${IMAGE_TAG} not found"
    fi

    echo ""
    echo "  Container:"
    if docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q .; then
        echo "    ✅ ${CONTAINER_NAME} is RUNNING"
        docker ps --filter "name=${CONTAINER_NAME}" --format "    ID: {{.ID}}  Up: {{.Status}}"
    elif docker ps -aq --filter "name=${CONTAINER_NAME}" | grep -q .; then
        echo "    ⏸️  ${CONTAINER_NAME} exists but is STOPPED"
    else
        echo "    ⚪ ${CONTAINER_NAME} does not exist"
    fi

    echo ""
    echo "  Files:"
    for f in Dockerfile build.sh run.sh; do
        if [[ -f "${DEDICATED_DOCKER_DIR}/$f" ]]; then
            echo "    ✅ ${DEDICATED_DOCKER_DIR}/$f"
        else
            echo "    ❌ ${DEDICATED_DOCKER_DIR}/$f (missing)"
        fi
    done
}

# --- Action: shell ---
action_shell() {
    log_info "Opening interactive shell in: ${CONTAINER_NAME}"

    # If daemon container is running, exec into it
    if docker ps -q --filter "name=${CONTAINER_NAME}" | grep -q .; then
        docker exec -it "${CONTAINER_NAME}" /bin/bash
    else
        # Start a fresh interactive container
        bash "${DEDICATED_DOCKER_DIR}/run.sh" shell
    fi
}

# --- Dispatch ---
case "$ACTION" in
    setup)  action_setup ;;
    build)  action_build ;;
    start)  action_start ;;
    stop)   action_stop ;;
    status) action_status ;;
    shell)  action_shell ;;
    *)
        echo "ERROR: Unknown action: $ACTION"
        echo "Valid actions: setup, build, start, stop, status, shell"
        exit 1
        ;;
esac
