#!/bin/bash
# validate-schemas.sh
# Validates JSON files against their schemas

set -e

REPO_ROOT="/workspace"
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

echo -e "${CYAN}=== JSON Schema Validator ===${NC}"
echo ""

# Check if jq is available
if ! command -v jq &> /dev/null; then
    echo -e "${YELLOW}Warning: jq not found, using basic validation${NC}"
    USE_JQ=false
else
    USE_JQ=true
fi

ERROR_COUNT=0

# Function to validate version pattern
validate_version() {
    local file=$1
    local version=$2

    if [[ ! $version =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
        echo -e "  ${RED}[ERROR] Invalid version format: $version${NC}"
        return 1
    fi
    return 0
}

# Validate INVENTORY.json
echo -e "${CYAN}Validating INVENTORY.json...${NC}"
INVENTORY="$REPO_ROOT/docs/repo-keeper/INVENTORY.json"

if [ -f "$INVENTORY" ]; then
    if [ "$USE_JQ" = true ]; then
        # Validate JSON syntax
        if ! jq empty "$INVENTORY" 2>/dev/null; then
            echo -e "  ${RED}[ERROR] Invalid JSON syntax${NC}"
            ((ERROR_COUNT++))
        else
            # Check required fields
            VERSION=$(jq -r '.version // empty' "$INVENTORY")
            LAST_UPDATED=$(jq -r '.last_updated // empty' "$INVENTORY")
            REPO=$(jq -r '.repository // empty' "$INVENTORY")

            if [ -z "$VERSION" ]; then
                echo -e "  ${RED}[ERROR] Missing required field: version${NC}"
                ((ERROR_COUNT++))
            elif ! validate_version "$INVENTORY" "$VERSION"; then
                ((ERROR_COUNT++))
            else
                echo -e "  ${GREEN}[OK] version: $VERSION${NC}"
            fi

            if [ -z "$LAST_UPDATED" ]; then
                echo -e "  ${RED}[ERROR] Missing required field: last_updated${NC}"
                ((ERROR_COUNT++))
            elif [[ ! $LAST_UPDATED =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
                echo -e "  ${RED}[ERROR] Invalid date format: $LAST_UPDATED (expected YYYY-MM-DD)${NC}"
                ((ERROR_COUNT++))
            else
                echo -e "  ${GREEN}[OK] last_updated: $LAST_UPDATED${NC}"
            fi

            if [ -z "$REPO" ]; then
                echo -e "  ${RED}[ERROR] Missing required field: repository${NC}"
                ((ERROR_COUNT++))
            else
                echo -e "  ${GREEN}[OK] repository: $REPO${NC}"
            fi

            # Check skills array
            SKILLS_COUNT=$(jq '.skills | length' "$INVENTORY")
            if [ "$SKILLS_COUNT" -eq 0 ]; then
                echo -e "  ${YELLOW}[WARNING] No skills defined${NC}"
            else
                echo -e "  ${GREEN}[OK] skills: $SKILLS_COUNT entries${NC}"
            fi

            # Check commands array
            COMMANDS_COUNT=$(jq '.commands | length' "$INVENTORY")
            if [ "$COMMANDS_COUNT" -eq 0 ]; then
                echo -e "  ${YELLOW}[WARNING] No commands defined${NC}"
            else
                echo -e "  ${GREEN}[OK] commands: $COMMANDS_COUNT entries${NC}"
            fi
        fi
    else
        # Basic validation without jq
        if grep -q '"version"' "$INVENTORY" && grep -q '"skills"' "$INVENTORY"; then
            echo -e "  ${GREEN}[OK] Basic structure valid${NC}"
        else
            echo -e "  ${RED}[ERROR] Missing required fields${NC}"
            ((ERROR_COUNT++))
        fi
    fi
else
    echo -e "  ${RED}[ERROR] INVENTORY.json not found${NC}"
    ((ERROR_COUNT++))
fi

# Validate data files
echo ""
echo -e "${CYAN}Validating data files...${NC}"

for data_file in "$REPO_ROOT/data"/*.json; do
    [ -e "$data_file" ] || continue

    filename=$(basename "$data_file")

    if [ "$USE_JQ" = true ]; then
        if ! jq empty "$data_file" 2>/dev/null; then
            echo -e "  ${RED}[ERROR] $filename: Invalid JSON syntax${NC}"
            ((ERROR_COUNT++))
        else
            # Check for version field if present
            VERSION=$(jq -r '.version // empty' "$data_file")
            if [ -n "$VERSION" ]; then
                if validate_version "$data_file" "$VERSION"; then
                    echo -e "  ${GREEN}[OK] $filename: version $VERSION${NC}"
                else
                    ((ERROR_COUNT++))
                fi
            else
                if [ "$VERBOSE" = true ]; then
                    echo -e "  ${GRAY}[INFO] $filename: no version field${NC}"
                fi
            fi
        fi
    else
        echo -e "  ${GRAY}[SKIP] $filename (jq not available)${NC}"
    fi
done

# Summary
echo ""
echo -e "${CYAN}=== Summary ===${NC}"
if [ $ERROR_COUNT -eq 0 ]; then
    echo -e "${GREEN}✓ All schemas valid!${NC}"
    echo -e "${GREEN}Total errors: $ERROR_COUNT${NC}"
    exit 0
else
    echo -e "${RED}✗ Schema validation failed!${NC}"
    echo -e "${RED}Total errors: $ERROR_COUNT${NC}"
    exit 1
fi
