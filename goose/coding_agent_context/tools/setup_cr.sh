#!/bin/bash
# =============================================================================
# SETUP CODE REVIEW TOOL
# =============================================================================
# Sets up a code review workspace for vim DirDiff comparison.
#
# Creates structure:
#   /local/home/tobmenne/users/tobmenne001/work/codeReviews/<datetime>_CR_<crID>/
#   ├── target/       # Target branch of source package
#   └── codeChange/   # From-scratch clone with coding_agent_context copied
#
# Usage: ./setup_cr.sh --cr-id <ID> --clone-cmd "<cmd>" --target-branch <branch>
# =============================================================================

set -euo pipefail

# --- Constants ---
CR_BASE_DIR="/local/home/tobmenne/users/tobmenne001/work/codeReviews"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"
SUB_PROJECT_REL_PATH="prototype/evaluation"
CODING_AGENT_CONTEXT_REL_PATH="${SUB_PROJECT_REL_PATH}/coding_agent_context"

# --- Functions ---
show_usage() {
    cat << 'EOF'
SETUP CODE REVIEW TOOL
======================

Sets up a code review workspace for vim DirDiff comparison between a target
branch and a code change (from-scratch clone).

USAGE:
    ./setup_cr.sh --cr-id <ID> --clone-cmd "<cmd>" --target-branch <branch>
    ./setup_cr.sh --help

REQUIRED PARAMETERS:
    --cr-id|-c <ID>           Code Review ID (e.g., "249366242")
    --clone-cmd|-k "<cmd>"    From-scratch clone command (quoted)
                              Example: "git clone ssh://git.amazon.com/pkg/MapleModel/snapshot/dhyanidd/2026-01-24T00-22-10 -b head"
    --target-branch|-b <name> Target branch name (e.g., "science_mainline")

OPTIONAL PARAMETERS:
    --help|-h                 Show this help message

WORKFLOW:
    1. Creates workdir: /local/home/tobmenne/users/tobmenne001/work/codeReviews/<datetime>_CR_<crID>
    2. Clones source package (origin) into "target/" subfolder
    3. Checks out the target branch in "target/"
    4. Runs the from-scratch clone command in "codeChange/" subfolder
    5. Copies coding_agent_context folder to codeChange at same relative position

OUTPUT:
    - Prints the created workspace path on success
    - Use vim DirDiff to compare target/ and codeChange/ directories

EXAMPLES:
    # Setup CR 249366242 comparing against science_mainline
    ./setup_cr.sh \
        --cr-id 249366242 \
        --clone-cmd "git clone ssh://git.amazon.com/pkg/MapleModel/snapshot/dhyanidd/2026-01-24T00-22-10 -b head" \
        --target-branch science_mainline

    # Using short flags
    ./setup_cr.sh \
        -c 249366242 \
        -k "git clone ssh://git.amazon.com/pkg/MapleModel/snapshot/dhyanidd/2026-01-24T00-22-10 -b head" \
        -b science_mainline
EOF
}

log_info() {
    echo "[INFO] $1"
}

log_error() {
    echo "[ERROR] $1" >&2
}

log_step() {
    echo ""
    echo "=== STEP: $1 ==="
}

# --- Parse Arguments ---
CR_ID=""
CLONE_CMD=""
TARGET_BRANCH=""

while [[ $# -gt 0 ]]; do
    case $1 in
        --help|-h)
            show_usage
            exit 0
            ;;
        --cr-id|-c)
            CR_ID="$2"
            shift 2
            ;;
        --clone-cmd|-k)
            CLONE_CMD="$2"
            shift 2
            ;;
        --target-branch|-b)
            TARGET_BRANCH="$2"
            shift 2
            ;;
        *)
            log_error "Unknown parameter: $1"
            echo "Use --help for usage information"
            exit 1
            ;;
    esac
done

# --- Validation ---
if [[ -z "$CR_ID" ]]; then
    log_error "--cr-id parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ -z "$CLONE_CMD" ]]; then
    log_error "--clone-cmd parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ -z "$TARGET_BRANCH" ]]; then
    log_error "--target-branch parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

# --- Determine Source Package URI from origin remote ---
log_step "Detecting source package URI"
cd "$PROJECT_ROOT"
SOURCE_PACKAGE_URI=$(git remote get-url origin)
if [[ -z "$SOURCE_PACKAGE_URI" ]]; then
    log_error "Could not determine origin remote URL from project root: $PROJECT_ROOT"
    exit 1
fi
log_info "Source package URI: $SOURCE_PACKAGE_URI"

# --- Generate deterministic datetime string ---
# Using ISO 8601 format with dashes replaced by underscores for filesystem compatibility
DATETIME_STRING=$(date -u +"%Y-%m-%dT%H-%M-%SZ")
log_info "Datetime string (UTC): $DATETIME_STRING"

# --- Create workspace directory ---
log_step "Creating workspace directory"
WORKSPACE_DIR="${CR_BASE_DIR}/${DATETIME_STRING}_CR_${CR_ID}"

if [[ -d "$WORKSPACE_DIR" ]]; then
    log_error "Workspace directory already exists: $WORKSPACE_DIR"
    exit 1
fi

mkdir -p "$WORKSPACE_DIR"
log_info "Created workspace: $WORKSPACE_DIR"

# --- Clone target branch ---
log_step "Cloning target branch into 'target/' subfolder"
TARGET_DIR="${WORKSPACE_DIR}/target"
mkdir -p "$TARGET_DIR"

log_info "Cloning $SOURCE_PACKAGE_URI..."
git clone "$SOURCE_PACKAGE_URI" "$TARGET_DIR"

log_info "Checking out target branch: $TARGET_BRANCH"
cd "$TARGET_DIR"
git checkout "$TARGET_BRANCH"
git pull origin "$TARGET_BRANCH" || log_info "Pull skipped (branch may be detached or no upstream)"

log_info "Target branch setup complete"

# --- Run from-scratch clone command ---
log_step "Running from-scratch clone into 'codeChange/' subfolder"
CODE_CHANGE_DIR="${WORKSPACE_DIR}/codeChange"
mkdir -p "$CODE_CHANGE_DIR"

cd "$CODE_CHANGE_DIR"
log_info "Executing clone command: $CLONE_CMD"

# Execute the clone command - it will create a subdirectory
eval "$CLONE_CMD"

# Find the cloned directory (should be the only subdirectory)
CLONED_SUBDIR=$(find "$CODE_CHANGE_DIR" -mindepth 1 -maxdepth 1 -type d | head -n 1)
if [[ -z "$CLONED_SUBDIR" ]]; then
    log_error "Clone command did not create a subdirectory in $CODE_CHANGE_DIR"
    exit 1
fi
log_info "Cloned repository: $CLONED_SUBDIR"

# --- Copy coding_agent_context folder ---
log_step "Copying coding_agent_context folder to codeChange"
SOURCE_CONTEXT_DIR="${PROJECT_ROOT}/${CODING_AGENT_CONTEXT_REL_PATH}"
DEST_CONTEXT_DIR="${CLONED_SUBDIR}/${CODING_AGENT_CONTEXT_REL_PATH}"

if [[ ! -d "$SOURCE_CONTEXT_DIR" ]]; then
    log_error "Source coding_agent_context not found: $SOURCE_CONTEXT_DIR"
    exit 1
fi

# Create parent directories if they don't exist
mkdir -p "$(dirname "$DEST_CONTEXT_DIR")"

# Copy the entire folder preserving structure
cp -r "$SOURCE_CONTEXT_DIR" "$DEST_CONTEXT_DIR"
cp -r "${PROJECT_ROOT}/${SUB_PROJECT_REL_PATH}/.aider.conf.yml" "${CLONED_SUBDIR}/${SUB_PROJECT_REL_PATH}/.aider.conf.yml"
cp -r "${PROJECT_ROOT}/${SUB_PROJECT_REL_PATH}/.vimrc" "${CLONED_SUBDIR}/${SUB_PROJECT_REL_PATH}/.vimrc"

log_info "Copied coding_agent_context to: $DEST_CONTEXT_DIR"

# --- Summary ---
log_step "Setup Complete"
echo ""
echo "=============================================="
echo "CODE REVIEW WORKSPACE READY"
echo "=============================================="
echo ""
echo "Workspace:    $WORKSPACE_DIR"
echo "CR ID:        $CR_ID"
echo "Target:       $TARGET_DIR"
echo "              Branch: $TARGET_BRANCH"
echo "Code Change:  $CLONED_SUBDIR"
echo ""
echo "To compare with vim DirDiff:"
echo "  vim -c \"DirDiff $TARGET_DIR $CLONED_SUBDIR\""
echo ""
echo "=============================================="

exit 0
