#!/bin/bash
# Install Kiro agent recipes globally
# Usage: ./kiro/setup-kiro.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
KIRO_DIR="${HOME}/.kiro/agents"

mkdir -p "$KIRO_DIR"

echo "Installing Kiro agent recipes to $KIRO_DIR..."

# Copy all agent JSON files
count=0
for f in "$SCRIPT_DIR"/agents/*.json "$SCRIPT_DIR"/agents/languages/*.json "$SCRIPT_DIR"/agents/specialized/*.json "$SCRIPT_DIR"/agents/subrecipes/*.json; do
    [ -f "$f" ] || continue
    cp "$f" "$KIRO_DIR/"
    count=$((count + 1))
done

echo "Installed $count agents to $KIRO_DIR"

# List installed agents with their models
echo ""
echo "Agent model assignments:"
for f in "$KIRO_DIR"/*.json; do
    [ -f "$f" ] || continue
    name=$(python3 -c "import json; print(json.load(open('$f'))['name'])" 2>/dev/null || basename "$f" .json)
    model=$(python3 -c "import json; print(json.load(open('$f')).get('model','default'))" 2>/dev/null || echo "?")
    printf "  %-30s %s\n" "$name" "$model"
done
