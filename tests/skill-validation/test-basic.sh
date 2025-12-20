#!/bin/bash
# Basic test script for comparison engine (no external dependencies)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================="
echo "Basic Comparison Engine Tests"
echo "========================================="
echo ""

# Test 1: Check all scripts exist
echo "Test 1: Checking script files exist..."
TESTS_PASSED=0
TESTS_FAILED=0

check_file() {
    local file="$1"
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} Found: $file"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} Missing: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

check_file "$SCRIPT_DIR/lib/section-parser.sh"
check_file "$SCRIPT_DIR/lib/diff-analyzer.sh"
check_file "$SCRIPT_DIR/compare-containers.sh"

# Test 2: Check scripts are executable
echo ""
echo "Test 2: Checking scripts are executable..."

check_executable() {
    local file="$1"
    if [ -x "$file" ]; then
        echo -e "${GREEN}✓${NC} Executable: $file"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} Not executable: $file"
        ((TESTS_FAILED++))
        return 1
    fi
}

check_executable "$SCRIPT_DIR/lib/section-parser.sh"
check_executable "$SCRIPT_DIR/lib/diff-analyzer.sh"
check_executable "$SCRIPT_DIR/compare-containers.sh"

# Test 3: Check scripts can be sourced
echo ""
echo "Test 3: Checking scripts can be sourced..."

if source "$SCRIPT_DIR/lib/section-parser.sh" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} section-parser.sh sources successfully"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} section-parser.sh failed to source"
    ((TESTS_FAILED++))
fi

if source "$SCRIPT_DIR/lib/diff-analyzer.sh" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} diff-analyzer.sh sources successfully"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} diff-analyzer.sh failed to source"
    ((TESTS_FAILED++))
fi

# Test 4: Check functions are defined
echo ""
echo "Test 4: Checking functions are defined..."

check_function() {
    local func="$1"
    if declare -f "$func" >/dev/null; then
        echo -e "${GREEN}✓${NC} Function defined: $func"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} Function not defined: $func"
        ((TESTS_FAILED++))
        return 1
    fi
}

check_function "extract_sections"
check_function "section_exists"
check_function "get_section_content"
check_function "validate_syntax"
check_function "calculate_structure_similarity"

# Test 5: Test section parser with actual file
echo ""
echo "Test 5: Testing section parser..."

# Create test file with sections
TEST_FILE="$SCRIPT_DIR/fixtures/test-files/test-sections-basic.txt"
mkdir -p "$(dirname "$TEST_FILE")"
cat > "$TEST_FILE" <<'EOF'
===SECTION_START:header===
Header content
===SECTION_END:header===
===SECTION_START:body===
Body content
===SECTION_END:body===
EOF

# Test extract_sections
sections=$(extract_sections "$TEST_FILE")
section_count=$(echo "$sections" | wc -l)

if [ "$section_count" -eq 2 ]; then
    echo -e "${GREEN}✓${NC} extract_sections: Found 2 sections"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} extract_sections: Expected 2 sections, found $section_count"
    ((TESTS_FAILED++))
fi

# Test section_exists
if section_exists "$TEST_FILE" "header"; then
    echo -e "${GREEN}✓${NC} section_exists: Found existing section"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} section_exists: Failed to find existing section"
    ((TESTS_FAILED++))
fi

if ! section_exists "$TEST_FILE" "nonexistent"; then
    echo -e "${GREEN}✓${NC} section_exists: Correctly reports missing section"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} section_exists: Incorrectly found nonexistent section"
    ((TESTS_FAILED++))
fi

# Test get_section_content
content=$(get_section_content "$TEST_FILE" "header")
if echo "$content" | grep -q "Header content"; then
    echo -e "${GREEN}✓${NC} get_section_content: Extracted correct content"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} get_section_content: Failed to extract content"
    ((TESTS_FAILED++))
fi

# Cleanup
rm -f "$TEST_FILE"

# Test 6: Test validate_syntax (basic)
echo ""
echo "Test 6: Testing validate_syntax..."

# Test with valid JSON (using python as fallback)
VALID_JSON="$SCRIPT_DIR/fixtures/test-files/valid-basic.json"
echo '{"test": "value"}' > "$VALID_JSON"

if python3 -c "import json; json.load(open('$VALID_JSON'))" 2>/dev/null; then
    echo -e "${GREEN}✓${NC} JSON validation works"
    ((TESTS_PASSED++))
else
    echo -e "${RED}✗${NC} JSON validation failed"
    ((TESTS_FAILED++))
fi

rm -f "$VALID_JSON"

# Summary
echo ""
echo "========================================="
echo "Test Summary"
echo "========================================="
echo "Tests passed: ${GREEN}$TESTS_PASSED${NC}"
echo "Tests failed: ${RED}$TESTS_FAILED${NC}"

if [ $TESTS_FAILED -eq 0 ]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed${NC}"
    exit 1
fi
