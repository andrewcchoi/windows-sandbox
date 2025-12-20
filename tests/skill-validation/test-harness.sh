#!/bin/bash
# Test harness for continuous skill validation
set -e

# Configuration
TEST_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GENERATED_DIR="$TEST_DIR/generated"
REPORTS_DIR="$TEST_DIR/reports"
ACCURACY_THRESHOLD=95
DRY_RUN="${DRY_RUN:-false}"
LOG_FILE="${LOG_FILE:-$REPORTS_DIR/test-harness.log}"

# Load Python fallbacks for jq and bc if not available
if ! command -v jq >/dev/null 2>&1 || ! command -v bc >/dev/null 2>&1; then
    source "$TEST_DIR/lib/python-fallbacks.sh"
fi

# Load comparison engine
source "$TEST_DIR/compare-containers.sh"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Enhanced logging with timestamps and file output
log_info() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [INFO] $1"
    echo -e "${GREEN}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_warn() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [WARN] $1"
    echo -e "${YELLOW}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_error() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [ERROR] $1"
    echo -e "${RED}${msg}${NC}"
    echo "$msg" >> "$LOG_FILE"
}

log_debug() {
    local msg="[$(date '+%Y-%m-%d %H:%M:%S')] [DEBUG] $1"
    if [ "${DEBUG:-false}" = "true" ]; then
        echo -e "${BLUE}${msg}${NC}"
    fi
    echo "$msg" >> "$LOG_FILE"
}

# Pre-flight validation checks
validate_yaml() {
    local yaml_file="$1"

    if [ ! -f "$yaml_file" ]; then
        return 1
    fi

    # Try to parse YAML using Python (most reliable)
    if command -v python3 >/dev/null 2>&1; then
        python3 -c "import yaml; yaml.safe_load(open('$yaml_file'))" 2>/dev/null
        return $?
    fi

    # Fallback: Basic syntax check
    # Check for balanced colons and valid structure
    if grep -q "^\s*-\s*prompt_pattern:" "$yaml_file" && \
       grep -q "^\s*-\s*response:" "$yaml_file"; then
        return 0
    fi

    return 1
}

validate_config_file() {
    local config_file="$1"
    local mode="$2"

    log_debug "Validating config file: $config_file"

    if [ ! -f "$config_file" ]; then
        log_error "Config file not found: $config_file"
        return 1
    fi

    if ! validate_yaml "$config_file"; then
        log_error "Invalid YAML in config file: $config_file"
        return 1
    fi

    # Check for required sections
    if ! grep -q "^responses:" "$config_file"; then
        log_error "Config file missing 'responses:' section: $config_file"
        return 1
    fi

    # Check response count is reasonable (1-10 responses)
    local response_count=$(grep -c "^\s*-\s*prompt_pattern:" "$config_file" || echo "0")
    if [ "$response_count" -lt 1 ]; then
        log_error "Config file has no responses: $config_file"
        return 1
    fi

    if [ "$response_count" -gt 10 ]; then
        log_warn "Config file has unusually high response count ($response_count): $config_file"
    fi

    log_debug "Config file validation passed: $response_count responses found"
    return 0
}

validate_example_directory() {
    local example_dir="$1"
    local mode="$2"

    log_debug "Validating example directory: $example_dir"

    if [ ! -d "$example_dir" ]; then
        log_error "Example directory not found: $example_dir"
        return 1
    fi

    # Check for expected files
    local expected_files=(
        ".devcontainer/devcontainer.json"
        "docker-compose.yml"
    )

    for file in "${expected_files[@]}"; do
        if [ ! -f "$example_dir/$file" ]; then
            log_error "Missing expected file in example directory: $file"
            return 1
        fi
    done

    log_debug "Example directory validation passed"
    return 0
}

preflight_checks() {
    local mode="$1"
    local example_dir="/workspace/examples/demo-app-sandbox-$mode"
    local config_file="$example_dir/test-config.yml"

    log_info "Running pre-flight checks for $mode mode..."

    # Create reports directory if it doesn't exist
    mkdir -p "$REPORTS_DIR"

    # Validate example directory exists
    if ! validate_example_directory "$example_dir" "$mode"; then
        log_error "Pre-flight check failed: Invalid example directory"
        return 1
    fi

    # Validate config file if it exists
    if [ -f "$config_file" ]; then
        if ! validate_config_file "$config_file" "$mode"; then
            log_error "Pre-flight check failed: Invalid config file"
            return 1
        fi
    else
        log_warn "No test config found for $mode mode, will use defaults"
    fi

    # Check test project exists
    if [ ! -d "$TEST_DIR/test-project" ]; then
        log_error "Test project directory not found: $TEST_DIR/test-project"
        return 1
    fi

    log_info "Pre-flight checks passed for $mode mode"
    return 0
}

# Cleanup on failure
cleanup_on_failure() {
    local mode="$1"
    local output_dir="$GENERATED_DIR/$mode"
    local timestamp=$(date '+%Y%m%d-%H%M%S')
    local failed_dir="$REPORTS_DIR/failed-$mode-$timestamp"

    log_warn "Cleaning up after failure for $mode mode"

    # Kill any background processes
    if [ -n "${skill_pid:-}" ]; then
        if kill -0 "$skill_pid" 2>/dev/null; then
            log_debug "Killing skill process: $skill_pid"
            kill "$skill_pid" 2>/dev/null || true
            wait "$skill_pid" 2>/dev/null || true
        fi
    fi

    # Preserve failed output for debugging
    if [ -d "$output_dir" ]; then
        log_info "Preserving failed output to: $failed_dir"
        mkdir -p "$failed_dir"
        cp -r "$output_dir" "$failed_dir/" 2>/dev/null || true

        # Also save any logs
        if [ -f "$LOG_FILE" ]; then
            cp "$LOG_FILE" "$failed_dir/test-harness.log" 2>/dev/null || true
        fi
    fi

    # Clean up temporary files
    rm -f /tmp/skill_*.fifo 2>/dev/null || true

    log_info "Cleanup complete"
}

# Generate skill output
generate_skill_output() {
    local mode="$1"
    local test_project="$TEST_DIR/test-project"
    local output_dir="$GENERATED_DIR/$mode"
    local example_dir="/workspace/examples/demo-app-sandbox-$mode"
    local config_file="$example_dir/test-config.yml"

    log_info "Generating output for $mode mode..."

    # Run pre-flight checks
    if ! preflight_checks "$mode"; then
        log_error "Pre-flight checks failed for $mode mode"
        return 1
    fi

    # Dry-run mode: Show what would happen without actually running
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would generate skill output for $mode mode"
        log_info "[DRY RUN] Test project: $test_project"
        log_info "[DRY RUN] Output directory: $output_dir"
        log_info "[DRY RUN] Config file: $config_file"
        log_info "[DRY RUN] Example directory: $example_dir"
        return 0
    fi

    # Set up trap for cleanup on failure
    trap 'cleanup_on_failure "$mode"' ERR

    # Create fresh test directory
    rm -rf "$output_dir"
    cp -r "$test_project" "$output_dir"
    cd "$output_dir"

    # Load response feeder
    source "$TEST_DIR/lib/response-feeder.sh"

    # Try interactive monitoring first if config exists
    local feed_result=0
    if [ -f "$config_file" ]; then
        log_info "Using test config with response feeder: $config_file"
        feed_responses_interactive "$mode" "$config_file" || feed_result=$?
    else
        # Fallback: Pre-pipe default responses
        log_warn "No test config found, using pre-piped defaults"
        feed_responses_prepipe "$mode" || feed_result=$?
    fi

    # Check if feeding responses failed
    if [ $feed_result -ne 0 ]; then
        log_error "Failed to feed responses for $mode mode"
        cd "$TEST_DIR"
        trap - ERR
        cleanup_on_failure "$mode"
        return 1
    fi

    # Return to test directory
    cd "$TEST_DIR"

    # Validate generated files exist
    if [ ! -f "$output_dir/.devcontainer/devcontainer.json" ]; then
        log_error "devcontainer.json not generated"
        trap - ERR
        cleanup_on_failure "$mode"
        return 1
    fi

    if [ ! -f "$output_dir/docker-compose.yml" ]; then
        log_error "docker-compose.yml not generated"
        trap - ERR
        cleanup_on_failure "$mode"
        return 1
    fi

    # Remove trap on success
    trap - ERR

    log_info "✓ Generated files successfully for $mode mode"
    return 0
}

# Cleanup test output
cleanup_test_output() {
    local mode="$1"
    local output_dir="$GENERATED_DIR/$mode"

    log_info "Cleaning up test output for $mode"
    rm -rf "$output_dir"
}

# Generate detailed report
generate_report() {
    local mode="$1"
    local iteration="$2"
    local accuracy="$3"
    local report_file="$REPORTS_DIR/${mode}-iteration-${iteration}.txt"

    cat > "$report_file" <<EOF
Skill Validation Report
=======================
Mode: $mode
Iteration: $iteration
Timestamp: $(date)
Accuracy: ${accuracy}%
Threshold: ${ACCURACY_THRESHOLD}%
Status: $([ $(echo "$accuracy >= $ACCURACY_THRESHOLD" | bc -l) -eq 1 ] && echo "PASS" || echo "FAIL")

Generated Files:
EOF

    find "$GENERATED_DIR/$mode" -type f >> "$report_file"

    log_info "Report saved to $report_file"
}

# Test a single skill
test_skill() {
    local mode="$1"
    local iteration="$2"

    log_info "Testing skill: $mode (iteration $iteration)"

    # Dry-run mode: Just validate and show what would happen
    if [ "$DRY_RUN" = "true" ]; then
        log_info "[DRY RUN] Would test $mode skill (iteration $iteration)"
        if ! preflight_checks "$mode"; then
            log_error "[DRY RUN] Pre-flight checks would fail for $mode"
            return 1
        fi
        log_info "[DRY RUN] Would generate files for $mode mode"
        log_info "[DRY RUN] Would compare against examples"
        log_info "[DRY RUN] Would generate report"
        return 0
    fi

    # Generate files with error handling
    if ! generate_skill_output "$mode"; then
        log_error "Generation failed for $mode"
        return 1
    fi

    # Compare against examples (preferred) or templates (fallback)
    local accuracy
    accuracy=$(compare_with_examples "$mode")

    log_info "Accuracy: ${accuracy}%"

    # Generate report
    generate_report "$mode" "$iteration" "$accuracy"

    # Check threshold
    if (( $(echo "$accuracy >= $ACCURACY_THRESHOLD" | bc -l) )); then
        log_info "✓ PASS - $mode skill meets accuracy threshold"
        return 0
    else
        log_warn "✗ FAIL - $mode skill below threshold (${accuracy}% < ${ACCURACY_THRESHOLD}%)"
        return 1
    fi
}

# Print usage information
usage() {
    cat << EOF
Usage: $0 [OPTIONS]

Test harness for continuous skill validation with automated response feeding.

OPTIONS:
    -h, --help              Show this help message
    -d, --dry-run          Run in dry-run mode (validate without executing)
    -m, --mode MODE        Test specific mode only (basic|intermediate|advanced|yolo)
    -t, --threshold NUM    Set accuracy threshold (default: 95)
    --debug                Enable debug logging
    --log-file FILE        Specify log file location (default: reports/test-harness.log)

EXAMPLES:
    # Run all tests
    $0

    # Dry-run to validate configuration
    DRY_RUN=true $0

    # Test specific mode only
    $0 --mode basic

    # Enable debug logging
    DEBUG=true $0

ENVIRONMENT VARIABLES:
    DRY_RUN            Set to 'true' to run in dry-run mode
    DEBUG              Set to 'true' to enable debug logging
    LOG_FILE           Path to log file
    ACCURACY_THRESHOLD Override accuracy threshold

EOF
}

# Parse command-line arguments
parse_args() {
    local test_modes=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            -h|--help)
                usage
                exit 0
                ;;
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -m|--mode)
                test_modes+=("$2")
                shift 2
                ;;
            -t|--threshold)
                ACCURACY_THRESHOLD="$2"
                shift 2
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Return selected modes or all modes
    if [ ${#test_modes[@]} -eq 0 ]; then
        echo "basic intermediate advanced yolo"
    else
        echo "${test_modes[@]}"
    fi
}

# Main loop
main() {
    local test_modes=()

    # Check for help flag first
    if [[ "$*" =~ (--help|-h) ]]; then
        usage
        exit 0
    fi

    # Parse all arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -d|--dry-run)
                DRY_RUN=true
                shift
                ;;
            --debug)
                DEBUG=true
                shift
                ;;
            --log-file)
                LOG_FILE="$2"
                shift 2
                ;;
            -t|--threshold)
                ACCURACY_THRESHOLD="$2"
                shift 2
                ;;
            -m|--mode)
                test_modes+=("$2")
                shift 2
                ;;
            *)
                log_error "Unknown option: $1"
                usage
                exit 1
                ;;
        esac
    done

    # Set modes to test
    if [ ${#test_modes[@]} -eq 0 ]; then
        local modes=("basic" "intermediate" "advanced" "yolo")
    else
        local modes=("${test_modes[@]}")
    fi

    # Initialize log file
    mkdir -p "$REPORTS_DIR"
    echo "=== Test Harness Log - $(date) ===" > "$LOG_FILE"

    log_info "=== Skill Validation Test Harness ==="
    log_info "Modes to test: ${modes[*]}"
    log_info "Accuracy threshold: ${ACCURACY_THRESHOLD}%"
    log_info "Dry-run mode: $DRY_RUN"
    log_info "Log file: $LOG_FILE"
    log_info ""

    for mode in "${modes[@]}"; do
        log_info "Starting continuous test for: $mode"

        local iteration=1
        local max_iterations=5

        while [ $iteration -le $max_iterations ]; do
            if test_skill "$mode" "$iteration"; then
                log_info "✓ $mode skill PASSED - moving to next mode"
                break
            else
                log_warn "Iteration $iteration/$max_iterations failed - will retry after fix"

                # Skip prompt in dry-run mode
                if [ "$DRY_RUN" = "true" ]; then
                    log_info "[DRY RUN] Would prompt for retry"
                    break
                fi

                # Prompt for skill edits
                read -p "Edit skill and press Enter to retry (or 'skip' to move to next): " input
                if [ "$input" = "skip" ]; then
                    log_warn "Skipping $mode mode"
                    break
                fi

                ((iteration++))
            fi
        done

        # Cleanup (skip in dry-run)
        if [ "$DRY_RUN" != "true" ]; then
            cleanup_test_output "$mode"
        fi
    done

    log_info "All skill testing complete"
    log_info "Full log available at: $LOG_FILE"
}

# Only run main if not being sourced
if [ "${BASH_SOURCE[0]}" = "${0}" ]; then
    main "$@"
fi
