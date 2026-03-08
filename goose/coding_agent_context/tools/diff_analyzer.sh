#!/bin/bash
# =============================================================================
# DIFF ANALYZER TOOL
# =============================================================================
# Analyzes code differences between two directory trees and generates a
# structured report suitable for code review.
#
# Usage: ./diff_analyzer.sh --output <file.md> --target-dir <path> --change-dir <path> --focus-subpath <path>
# =============================================================================

set -e

SCRIPT_NAME="diff_analyzer.sh"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# --- Usage Information ---
show_usage() {
    cat << 'EOF'
# diff_analyzer.sh - Code Difference Analyzer

## PURPOSE
Analyzes code differences between a target (baseline) directory and a change
directory, focusing on a specific subpath. Generates a structured diff report
for code review purposes.

## USAGE
```bash
./coding_agent_context/tools/diff_analyzer.sh \
    --output <output_file.md> \
    --target-dir <path_to_target> \
    --change-dir <path_to_change> \
    --focus-subpath <relative_path>
./coding_agent_context/tools/diff_analyzer.sh --help
```

## REQUIRED PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--output`, `-o` | Path to output markdown file (will be created/overwritten) |
| `--target-dir`, `-t` | Path to target (baseline) directory |
| `--change-dir`, `-c` | Path to change directory (code being reviewed) |
| `--focus-subpath`, `-f` | Relative subpath to focus analysis on (e.g., "prototype/evaluation") |

## OPTIONAL PARAMETERS
| Parameter | Description |
|-----------|-------------|
| `--help`, `-h` | Show this usage information |

## OUTPUT FORMAT
The output markdown file contains:
- Summary statistics (files added, modified, deleted)
- List of changed files with change type
- Unified diff for each changed file
- File-by-file breakdown for downstream analysis

## EXCLUDED PATHS
The following are automatically excluded from diff analysis:
- `coding_agent_context/` - Agent tooling (copied separately, not part of code change)
- `cr_review/` - Generated review artifacts
- `.git/`, `__pycache__/`, `.pytest_cache/`, `node_modules/`, `.idea/`, `.vscode/`
- Swap files (`*.swp`, `*.swo`), `.DS_Store`

## EXAMPLES
```bash
# Analyze differences in prototype/evaluation subfolder
./coding_agent_context/tools/diff_analyzer.sh \
    -o diff_report.md \
    -t ../../target \
    -c . \
    -f prototype/evaluation

# Full parameter names
./coding_agent_context/tools/diff_analyzer.sh \
    --output code_changes.md \
    --target-dir /path/to/target \
    --change-dir /path/to/change \
    --focus-subpath src/main
```
EOF
}

# --- Argument Parsing ---
OUTPUT_FILE=""
TARGET_DIR=""
CHANGE_DIR=""
FOCUS_SUBPATH=""

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
        --target-dir|-t)
            TARGET_DIR="$2"
            shift 2
            ;;
        --change-dir|-c)
            CHANGE_DIR="$2"
            shift 2
            ;;
        --focus-subpath|-f)
            FOCUS_SUBPATH="$2"
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

if [[ -z "$TARGET_DIR" ]]; then
    echo "ERROR: --target-dir parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ -z "$CHANGE_DIR" ]]; then
    echo "ERROR: --change-dir parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

if [[ -z "$FOCUS_SUBPATH" ]]; then
    echo "ERROR: --focus-subpath parameter is required"
    echo "Use --help for usage information"
    exit 1
fi

# Resolve to absolute paths
TARGET_DIR=$(cd "$TARGET_DIR" && pwd)
CHANGE_DIR=$(cd "$CHANGE_DIR" && pwd)

# Verify focus subpath exists in at least one directory
TARGET_FOCUS="${TARGET_DIR}/${FOCUS_SUBPATH}"
CHANGE_FOCUS="${CHANGE_DIR}/${FOCUS_SUBPATH}"

if [[ ! -d "$TARGET_FOCUS" && ! -d "$CHANGE_FOCUS" ]]; then
    echo "ERROR: Focus subpath '$FOCUS_SUBPATH' does not exist in either directory"
    exit 1
fi

# --- Create output directory if needed ---
OUTPUT_DIR=$(dirname "$OUTPUT_FILE")
if [[ -n "$OUTPUT_DIR" && "$OUTPUT_DIR" != "." ]]; then
    mkdir -p "$OUTPUT_DIR"
fi

# --- Write header to output file ---
{
    echo "# Code Difference Analysis Report"
    echo ""
    echo "**Generated:** $(date -Iseconds)"
    echo "**Target Directory:** $TARGET_DIR"
    echo "**Change Directory:** $CHANGE_DIR"
    echo "**Focus Subpath:** $FOCUS_SUBPATH"
    echo ""
    echo "---"
    echo ""
} > "$OUTPUT_FILE"

# --- Collect file lists ---
# Get all files in focus subpath (excluding .git, coding_agent_context, and common binary/generated files)
get_files() {
    local base_dir="$1"
    local focus="$2"
    local full_path="${base_dir}/${focus}"
    
    if [[ -d "$full_path" ]]; then
        find "$full_path" -type f \
            ! -path "*/.git/*" \
            ! -path "*/coding_agent_context/*" \
            ! -path "*/.aider.conf.yml" \
            ! -path "*/.vimrc" \
            ! -path "*/__pycache__/*" \
            ! -path "*.pyc" \
            ! -path "*/.pytest_cache/*" \
            ! -path "*/node_modules/*" \
            ! -path "*/.idea/*" \
            ! -path "*/.vscode/*" \
            ! -path "*/cr_review/*" \
            ! -name "*.swp" \
            ! -name "*.swo" \
            ! -name ".DS_Store" \
            -print 2>/dev/null | sed "s|^${base_dir}/||" | sort
    fi
}

TARGET_FILES=$(get_files "$TARGET_DIR" "$FOCUS_SUBPATH")
CHANGE_FILES=$(get_files "$CHANGE_DIR" "$FOCUS_SUBPATH")

# --- Categorize changes ---
ADDED_FILES=()
MODIFIED_FILES=()
DELETED_FILES=()

# Find added and modified files
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if [[ ! -f "${TARGET_DIR}/${file}" ]]; then
        ADDED_FILES+=("$file")
    elif ! diff -q "${TARGET_DIR}/${file}" "${CHANGE_DIR}/${file}" > /dev/null 2>&1; then
        MODIFIED_FILES+=("$file")
    fi
done <<< "$CHANGE_FILES"

# Find deleted files
while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    if [[ ! -f "${CHANGE_DIR}/${file}" ]]; then
        DELETED_FILES+=("$file")
    fi
done <<< "$TARGET_FILES"

# --- Write Summary Statistics ---
{
    echo "## Summary Statistics"
    echo ""
    echo "| Change Type | Count |"
    echo "|-------------|-------|"
    echo "| Added | ${#ADDED_FILES[@]} |"
    echo "| Modified | ${#MODIFIED_FILES[@]} |"
    echo "| Deleted | ${#DELETED_FILES[@]} |"
    echo "| **Total** | **$((${#ADDED_FILES[@]} + ${#MODIFIED_FILES[@]} + ${#DELETED_FILES[@]}))** |"
    echo ""
    echo "---"
    echo ""
} >> "$OUTPUT_FILE"

# --- Write File Lists ---
{
    echo "## Changed Files"
    echo ""
    
    if [[ ${#ADDED_FILES[@]} -gt 0 ]]; then
        echo "### Added Files"
        echo ""
        for file in "${ADDED_FILES[@]}"; do
            echo "- \`$file\`"
        done
        echo ""
    fi
    
    if [[ ${#MODIFIED_FILES[@]} -gt 0 ]]; then
        echo "### Modified Files"
        echo ""
        for file in "${MODIFIED_FILES[@]}"; do
            echo "- \`$file\`"
        done
        echo ""
    fi
    
    if [[ ${#DELETED_FILES[@]} -gt 0 ]]; then
        echo "### Deleted Files"
        echo ""
        for file in "${DELETED_FILES[@]}"; do
            echo "- \`$file\`"
        done
        echo ""
    fi
    
    echo "---"
    echo ""
} >> "$OUTPUT_FILE"

# --- Write Detailed Diffs ---
{
    echo "## Detailed Diffs"
    echo ""
} >> "$OUTPUT_FILE"

# Function to write diff for a file
write_diff() {
    local file="$1"
    local change_type="$2"
    local target_file="${TARGET_DIR}/${file}"
    local change_file="${CHANGE_DIR}/${file}"
    
    {
        echo "### \`$file\` ($change_type)"
        echo ""
        
        case "$change_type" in
            "ADDED")
                echo "**New file added**"
                echo ""
                # Show file content (limited to first 200 lines for sanity)
                echo "\`\`\`"
                head -200 "$change_file"
                if [[ $(wc -l < "$change_file") -gt 200 ]]; then
                    echo ""
                    echo "... (truncated, file has $(wc -l < "$change_file") lines total)"
                fi
                echo "\`\`\`"
                ;;
            "MODIFIED")
                echo "\`\`\`diff"
                diff -u "$target_file" "$change_file" 2>/dev/null | head -500 || true
                echo "\`\`\`"
                ;;
            "DELETED")
                echo "**File deleted**"
                echo ""
                echo "Previous content (first 50 lines):"
                echo "\`\`\`"
                head -50 "$target_file"
                if [[ $(wc -l < "$target_file") -gt 50 ]]; then
                    echo ""
                    echo "... (truncated)"
                fi
                echo "\`\`\`"
                ;;
        esac
        
        echo ""
        echo "---"
        echo ""
    } >> "$OUTPUT_FILE"
}

# Write diffs for all changed files
for file in "${ADDED_FILES[@]}"; do
    write_diff "$file" "ADDED"
done

for file in "${MODIFIED_FILES[@]}"; do
    write_diff "$file" "MODIFIED"
done

for file in "${DELETED_FILES[@]}"; do
    write_diff "$file" "DELETED"
done

# --- Completion Notification ---
echo "✅ DIFF_ANALYZER: Analysis complete."
echo "   Output: $OUTPUT_FILE"
echo "   Added: ${#ADDED_FILES[@]}, Modified: ${#MODIFIED_FILES[@]}, Deleted: ${#DELETED_FILES[@]}"
