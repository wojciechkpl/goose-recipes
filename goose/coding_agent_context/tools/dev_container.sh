#!/bin/bash
# dev_container.sh - Development container manager for code execution & testing
#
# 🚫 ALL code execution (tests, scripts, linting) MUST happen inside Docker.
#    This tool manages the development container lifecycle.
#    It is project-agnostic: it auto-detects or creates a Docker environment.

set -e

SCRIPT_NAME="dev_container.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

# ── Naming Convention ─────────────────────────────────────────────────────────
# The dev container uses a fixed, deterministic name derived from the project
# directory so that every tool (run_tests.sh, etc.) can find it without config.
PROJECT_DIR_NAME="$(basename "$PROJECT_ROOT")"
CONTAINER_NAME="dev-container-${PROJECT_DIR_NAME}"
IMAGE_TAG="dev-env-${PROJECT_DIR_NAME}:latest"
WORKSPACE_MOUNT="/app/workspace"

# ── Usage Information ─────────────────────────────────────────────────────────
show_usage() {
    cat << 'USAGE_EOF'
# dev_container.sh - Development Container Manager

## PURPOSE
Manages a persistent Docker development container for the current project.
ALL code execution (tests, linting, scripts) MUST happen inside this container.
This tool auto-detects the project's Docker setup or creates one if missing.

## USAGE
```bash
./coding_agent_context/tools/dev_container.sh --action <action> [options]
./coding_agent_context/tools/dev_container.sh --help
```

## ACTIONS

| Action | Description |
|--------|-------------|
| `ensure` | **Start here.** Ensure a dev container is running. Creates Docker env if needed, builds image, starts daemon. Idempotent — safe to call repeatedly. |
| `status` | Check if the dev container is running and healthy |
| `exec` | Execute a command inside the running dev container |
| `stop` | Stop and remove the dev container |
| `rebuild` | Force rebuild the image and restart the container |
| `shell` | Open an interactive shell in the dev container |

## REQUIRED PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--action` | Action to perform (see table above) |

## OPTIONAL PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--cmd` | Command to execute inside the container (for `exec` action) |
| `--help`, `-h` | Show this usage information |

## HOW IT DETECTS THE DOCKER ENVIRONMENT

The tool searches for a Docker setup in this priority order:
1. `docker/Dockerfile` — existing project Docker environment (preferred)
2. `Dockerfile` — root-level Dockerfile
3. **None found** — auto-generates a minimal `docker/Dockerfile` + `docker/requirements.txt`

When auto-generating, it:
- Uses `nvidia/cuda:12.1.1-runtime-ubuntu22.04` as the base image (GPU-enabled)
- Installs Python 3 and common build tools
- Scans for `requirements.txt`, `setup.py`, `setup.cfg`, `pyproject.toml` to install deps
- Installs `pytest` and `ruff` for testing and linting
- Creates `docker/build-docker.sh` and `docker/run-dev.sh` helper scripts

## EXAMPLES
```bash
# Ensure dev container is running (first thing in any workflow)
./coding_agent_context/tools/dev_container.sh --action ensure

# Check container status
./coding_agent_context/tools/dev_container.sh --action status

# Run a command inside the container
./coding_agent_context/tools/dev_container.sh --action exec --cmd "pytest tests/ -v"

# Run Python inside the container
./coding_agent_context/tools/dev_container.sh --action exec --cmd "python -c 'import sys; print(sys.version)'"

# Open interactive shell
./coding_agent_context/tools/dev_container.sh --action shell

# Force rebuild after Dockerfile changes
./coding_agent_context/tools/dev_container.sh --action rebuild

# Stop the container
./coding_agent_context/tools/dev_container.sh --action stop
```

## NAMING
- **Container name:** `dev-container-<project_dir_name>`
- **Image tag:** `dev-env-<project_dir_name>:latest`
- **Workspace mount:** Project root → `/app/workspace` inside container

These names are deterministic — every tool can find the container without configuration.
USAGE_EOF
}

# ── Argument Parsing ──────────────────────────────────────────────────────────
ACTION=""
CMD=""

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
        --cmd)
            CMD="$2"
            shift 2
            ;;
        *)
            echo "ERROR: Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

if [[ -z "$ACTION" ]]; then
    echo "ERROR: --action parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

# ── Helper Functions ──────────────────────────────────────────────────────────

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

# ── Check if container is running ─────────────────────────────────────────────
container_is_running() {
    docker ps -q --filter "name=^${CONTAINER_NAME}$" 2>/dev/null | grep -q .
}

# ── Check if image exists ─────────────────────────────────────────────────────
image_exists() {
    docker image inspect "${IMAGE_TAG}" >/dev/null 2>&1
}

# ── Locate Dockerfile ─────────────────────────────────────────────────────────
# Returns the path to the Dockerfile directory relative to PROJECT_ROOT,
# or empty string if none found.
find_dockerfile_dir() {
    if [[ -f "${PROJECT_ROOT}/docker/Dockerfile" ]]; then
        echo "docker"
    elif [[ -f "${PROJECT_ROOT}/Dockerfile" ]]; then
        echo "."
    else
        echo ""
    fi
}

# ── Auto-generate Docker environment ──────────────────────────────────────────
generate_docker_env() {
    log_step "No Docker environment found — auto-generating one"

    local docker_dir="${PROJECT_ROOT}/docker"
    mkdir -p "$docker_dir"

    # ── Collect dependency files ──
    local pip_install_lines=""

    # Check for requirements.txt at various locations
    for req_file in "requirements.txt" "docker/requirements.txt" "requirements/base.txt" "requirements/dev.txt"; do
        if [[ -f "${PROJECT_ROOT}/${req_file}" ]]; then
            pip_install_lines="${pip_install_lines}
COPY ${req_file} /tmp/$(basename ${req_file})
RUN pip install --no-cache-dir -r /tmp/$(basename ${req_file}) && rm /tmp/$(basename ${req_file})"
        fi
    done

    # Check for pyproject.toml or setup.py
    if [[ -f "${PROJECT_ROOT}/pyproject.toml" ]]; then
        pip_install_lines="${pip_install_lines}
COPY pyproject.toml /tmp/pyproject.toml
RUN pip install --no-cache-dir /tmp/ || true"
    elif [[ -f "${PROJECT_ROOT}/setup.py" ]]; then
        pip_install_lines="${pip_install_lines}
COPY setup.py /tmp/setup.py
RUN cd /tmp && pip install --no-cache-dir -e . || true"
    fi

    # If we found nothing, add a minimal requirements install
    if [[ -z "$pip_install_lines" ]]; then
        pip_install_lines="
# No requirements file detected — install common defaults
RUN pip install --no-cache-dir pandas numpy"
    fi

    # ── Generate Dockerfile ──
    cat > "${docker_dir}/Dockerfile" << DOCKERFILE_EOF
# ==============================================================================
# Development Environment (auto-generated by coding_agent_context/tools/dev_container.sh)
# ==============================================================================
FROM nvidia/cuda:12.1.1-runtime-ubuntu22.04

ENV DEBIAN_FRONTEND=noninteractive
ENV PYTHONUNBUFFERED=1
ENV PYTHONDONTWRITEBYTECODE=1
ENV NVIDIA_VISIBLE_DEVICES=all
ENV NVIDIA_DRIVER_CAPABILITIES=compute,utility

# System dependencies (including Python since base image is Ubuntu, not Python)
RUN apt-get update && apt-get install -y --no-install-recommends \\
    build-essential \\
    curl \\
    git \\
    python3 \\
    python3-pip \\
    python3-dev \\
    && ln -sf /usr/bin/python3 /usr/bin/python \\
    && rm -rf /var/lib/apt/lists/*

# Always install testing & linting tools
RUN pip install --no-cache-dir pytest ruff

# Project dependencies
${pip_install_lines}

WORKDIR ${WORKSPACE_MOUNT}

CMD ["/bin/bash"]
DOCKERFILE_EOF

    log_ok "Generated: docker/Dockerfile"

    # ── Generate build script ──
    cat > "${docker_dir}/build-docker.sh" << BUILD_EOF
#!/bin/bash
# Build the development Docker image (auto-generated)
set -euo pipefail
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\${SCRIPT_DIR}/.." && pwd)"
IMAGE_TAG="\${1:-${IMAGE_TAG}}"
echo "Building dev image: \${IMAGE_TAG}"
docker build -t "\${IMAGE_TAG}" -f "\${SCRIPT_DIR}/Dockerfile" "\${PROJECT_ROOT}"
echo "✅ Done. Image: \${IMAGE_TAG}"
BUILD_EOF
    chmod +x "${docker_dir}/build-docker.sh"
    log_ok "Generated: docker/build-docker.sh"

    # ── Generate run script ──
    cat > "${docker_dir}/run-dev.sh" << RUN_EOF
#!/bin/bash
# Run the development container (auto-generated)
set -euo pipefail
SCRIPT_DIR="\$(cd "\$(dirname "\${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="\$(cd "\${SCRIPT_DIR}/.." && pwd)"
IMAGE_TAG="\${2:-${IMAGE_TAG}}"
CONTAINER_NAME="${CONTAINER_NAME}"
MODE="\${1:-shell}"

COMMON_OPTS=(-v "\${PROJECT_ROOT}:${WORKSPACE_MOUNT}")

# Mount AWS credentials if available
if [[ -d "\$HOME/.aws" ]]; then
    COMMON_OPTS+=(-v "\$HOME/.aws:/root/.aws:ro")
fi

# Pass through AWS env vars
for var in AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION; do
    if [[ -n "\${!var:-}" ]]; then
        COMMON_OPTS+=(-e "\$var=\${!var}")
    fi
done

case "\$MODE" in
    shell)
        docker run --gpus all -it --rm --name "\${CONTAINER_NAME}" "\${COMMON_OPTS[@]}" "\${IMAGE_TAG}" /bin/bash
        ;;
    daemon)
        docker run --gpus all -d --name "\${CONTAINER_NAME}" "\${COMMON_OPTS[@]}" "\${IMAGE_TAG}" tail -f /dev/null
        echo "Container started: \${CONTAINER_NAME}"
        ;;
    *)
        echo "Usage: \$0 [shell|daemon]"
        exit 1
        ;;
esac
RUN_EOF
    chmod +x "${docker_dir}/run-dev.sh"
    log_ok "Generated: docker/run-dev.sh"
}

# ── Build the Docker image ────────────────────────────────────────────────────
build_image() {
    local dockerfile_dir
    dockerfile_dir=$(find_dockerfile_dir)

    if [[ -z "$dockerfile_dir" ]]; then
        generate_docker_env
        dockerfile_dir="docker"
    fi

    log_step "Building Docker image: ${IMAGE_TAG}"
    log_info "Dockerfile: ${dockerfile_dir}/Dockerfile"
    log_info "Context:    ${PROJECT_ROOT}"

    docker build \
        -t "${IMAGE_TAG}" \
        -f "${PROJECT_ROOT}/${dockerfile_dir}/Dockerfile" \
        "${PROJECT_ROOT}"

    log_ok "Image built: ${IMAGE_TAG}"
}

# ── Start the daemon container ────────────────────────────────────────────────
start_container() {
    # Stop any existing container with the same name
    if docker ps -aq --filter "name=^${CONTAINER_NAME}$" 2>/dev/null | grep -q .; then
        log_info "Removing existing container: ${CONTAINER_NAME}"
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    fi

    log_step "Starting dev container: ${CONTAINER_NAME}"

    local run_opts=(-d --name "${CONTAINER_NAME}")
    run_opts+=(--gpus all)
    run_opts+=(--ipc=host)
    run_opts+=(-e NVIDIA_VISIBLE_DEVICES=all)
    run_opts+=(-e NVIDIA_DRIVER_CAPABILITIES=compute,utility)
    run_opts+=(-v "${PROJECT_ROOT}:${WORKSPACE_MOUNT}")

    # Mount AWS credentials if available
    if [[ -d "$HOME/.aws" ]]; then
        run_opts+=(-v "$HOME/.aws:/root/.aws:ro")
    fi

    # Pass through AWS env vars
    for var in AWS_PROFILE AWS_ACCESS_KEY_ID AWS_SECRET_ACCESS_KEY AWS_SESSION_TOKEN AWS_DEFAULT_REGION; do
        if [[ -n "${!var:-}" ]]; then
            run_opts+=(-e "$var=${!var}")
        fi
    done

    docker run "${run_opts[@]}" "${IMAGE_TAG}" tail -f /dev/null

    log_ok "Container started: ${CONTAINER_NAME}"
    log_info "Workspace: ${PROJECT_ROOT} → ${WORKSPACE_MOUNT}"
}

# ── Verify container health ───────────────────────────────────────────────────
verify_container() {
    log_info "Verifying container health..."

    local verify_output
    verify_output=$(docker exec -i "${CONTAINER_NAME}" python -c "
import sys
print(f'Python {sys.version}')
try:
    import pytest; print(f'pytest {pytest.__version__}')
except: print('pytest NOT FOUND — install it in your Dockerfile')
print('Container OK')
" 2>&1)

    echo "$verify_output" | sed 's/^/    /'

    if echo "$verify_output" | grep -q "Container OK"; then
        log_ok "Container is healthy"
        return 0
    else
        log_error "Container health check failed"
        return 1
    fi
}

# ══════════════════════════════════════════════════════════════════════════════
# ACTIONS
# ══════════════════════════════════════════════════════════════════════════════

# ── ensure ────────────────────────────────────────────────────────────────────
# Idempotent: if already running → verify; if not → build + start.
action_ensure() {
    log_step "Ensuring dev container is ready: ${CONTAINER_NAME}"

    # 1. Check if container is already running
    if container_is_running; then
        log_ok "Container already running: ${CONTAINER_NAME}"
        verify_container
        return $?
    fi

    # 2. Check if image exists — if not, build it
    if ! image_exists; then
        log_info "Image not found — building..."
        build_image
    else
        log_ok "Image exists: ${IMAGE_TAG}"
    fi

    # 3. Start the container
    start_container

    # 4. Verify
    verify_container
}

# ── status ────────────────────────────────────────────────────────────────────
action_status() {
    log_step "Dev Container Status: ${CONTAINER_NAME}"

    echo ""
    echo "  Image:"
    if image_exists; then
        local image_size
        image_size=$(docker image inspect "${IMAGE_TAG}" --format '{{.Size}}' | awk '{printf "%.0f MB", $1/1024/1024}')
        echo "    ✅ ${IMAGE_TAG} (${image_size})"
    else
        echo "    ❌ ${IMAGE_TAG} not found"
    fi

    echo ""
    echo "  Container:"
    if container_is_running; then
        echo "    ✅ ${CONTAINER_NAME} is RUNNING"
        docker ps --filter "name=^${CONTAINER_NAME}$" --format "    ID: {{.ID}}  Up: {{.Status}}"
    elif docker ps -aq --filter "name=^${CONTAINER_NAME}$" 2>/dev/null | grep -q .; then
        echo "    ⏸️  ${CONTAINER_NAME} exists but is STOPPED"
    else
        echo "    ⚪ ${CONTAINER_NAME} does not exist"
    fi

    echo ""
    echo "  Docker environment:"
    local dockerfile_dir
    dockerfile_dir=$(find_dockerfile_dir)
    if [[ -n "$dockerfile_dir" ]]; then
        echo "    ✅ Dockerfile: ${dockerfile_dir}/Dockerfile"
    else
        echo "    ⚪ No Dockerfile found (will be auto-generated on 'ensure')"
    fi
}

# ── exec ──────────────────────────────────────────────────────────────────────
action_exec() {
    if [[ -z "$CMD" ]]; then
        log_error "--cmd parameter is required for exec action"
        exit 1
    fi

    if ! container_is_running; then
        log_error "Dev container is not running: ${CONTAINER_NAME}"
        echo ""
        echo "  Run this first:"
        echo "    ./coding_agent_context/tools/dev_container.sh --action ensure"
        exit 1
    fi

    docker exec -i "${CONTAINER_NAME}" /bin/bash -c "cd ${WORKSPACE_MOUNT} && ${CMD}"
}

# ── stop ──────────────────────────────────────────────────────────────────────
action_stop() {
    log_step "Stopping dev container: ${CONTAINER_NAME}"

    if docker ps -aq --filter "name=^${CONTAINER_NAME}$" 2>/dev/null | grep -q .; then
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1
        log_ok "Container stopped and removed"
    else
        log_info "Container not running"
    fi
}

# ── rebuild ───────────────────────────────────────────────────────────────────
action_rebuild() {
    log_step "Rebuilding dev container: ${CONTAINER_NAME}"

    # Stop existing
    if docker ps -aq --filter "name=^${CONTAINER_NAME}$" 2>/dev/null | grep -q .; then
        docker rm -f "${CONTAINER_NAME}" >/dev/null 2>&1
    fi

    # Rebuild image
    build_image

    # Start fresh
    start_container
    verify_container
}

# ── shell ─────────────────────────────────────────────────────────────────────
action_shell() {
    if ! container_is_running; then
        log_error "Dev container is not running: ${CONTAINER_NAME}"
        echo "  Run: ./coding_agent_context/tools/dev_container.sh --action ensure"
        exit 1
    fi

    docker exec -it "${CONTAINER_NAME}" /bin/bash
}

# ══════════════════════════════════════════════════════════════════════════════
# DISPATCH
# ══════════════════════════════════════════════════════════════════════════════
case "$ACTION" in
    ensure)  action_ensure ;;
    status)  action_status ;;
    exec)    action_exec ;;
    stop)    action_stop ;;
    rebuild) action_rebuild ;;
    shell)   action_shell ;;
    *)
        echo "ERROR: Unknown action: $ACTION"
        echo "Valid actions: ensure, status, exec, stop, rebuild, shell"
        exit 1
        ;;
esac
