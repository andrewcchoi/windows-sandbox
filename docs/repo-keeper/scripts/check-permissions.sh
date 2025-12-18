#!/bin/bash
# check-permissions.sh
# Validates that shell scripts have execute permissions

set -e

# Auto-detect repo root from script location
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

# Allow override via environment variable
if [[ -n "${REPO_ROOT_OVERRIDE:-}" ]]; then
    REPO_ROOT="$REPO_ROOT_OVERRIDE"
fi

VERBOSE=false

# Parse arguments
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -v|--verbose) VERBOSE=true ;;
        *) echo "Unknown parameter: $1"; exit 1 ;;
    esac
    shift
done

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
GRAY='\033[0;90m'
NC='\033[0m'

echo -e "${CYAN}=== File Permissions Validator ===${NC}"
echo ""

WARNING_COUNT=0
TOTAL_SCRIPTS=0

# Check script permissions in scripts directory
echo -e "${CYAN}Checking script permissions...${NC}"

for script in "$SCRIPT_DIR"/*.sh; do
    [ -e "$script" ] || continue
    ((TOTAL_SCRIPTS++))

    script_name=$(basename "$script")

    if [ ! -x "$script" ]; then
        echo -e "  ${YELLOW}[WARNING] Not executable: $script_name${NC}"
        ((WARNING_COUNT++))
    elif [ "$VERBOSE" = true ]; then
        echo -e "  ${GRAY}[OK] $script_name is executable${NC}"
    fi
done

# Check scripts in lib directory
if [ -d "$SCRIPT_DIR/lib" ]; then
    for script in "$SCRIPT_DIR/lib"/*.sh; do
        [ -e "$script" ] || continue
        ((TOTAL_SCRIPTS++))

        script_name="lib/$(basename "$script")"

        if [ ! -x "$script" ]; then
            echo -e "  ${YELLOW}[WARNING] Not executable: $script_name${NC}"
            ((WARNING_COUNT++))
        elif [ "$VERBOSE" = true ]; then
            echo -e "  ${GRAY}[OK] $script_name is executable${NC}"
        fi
    done
fi

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
echo "Total shell scripts checked: $TOTAL_SCRIPTS"
if [ $WARNING_COUNT -eq 0 ]; then
    echo -e "${GREEN}All scripts are executable!${NC}"
    echo -e "${GREEN}Warnings: $WARNING_COUNT${NC}"
    exit 0
else
    echo -e "${YELLOW}Scripts with permission issues: $WARNING_COUNT${NC}"
    echo ""
    echo "To fix permission issues, run:"
    echo "  chmod +x \$SCRIPT_DIR/*.sh"
    echo "  chmod +x \$SCRIPT_DIR/lib/*.sh"
    exit 0  # Don't fail on warnings
fi
