#!/usr/bin/env bash
# Constitutional compliance validator
set -e

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Not in a git repository" >&2
    exit 1
fi

CONSTITUTION_FILE="$REPO_ROOT/.specify/memory/constitution.md"
PHASE="$1"  # specify, plan, tasks, or implement
FEATURE_DIR="$2"

JSON_MODE=false
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;;
    esac
done

VIOLATIONS=()
WARNINGS=()
COMPLIANCE_STATUS="COMPLIANT"

# Check if constitution exists
if [ ! -f "$CONSTITUTION_FILE" ]; then
    VIOLATIONS+=("CRITICAL: Constitution file not found at $CONSTITUTION_FILE")
    COMPLIANCE_STATUS="NON_COMPLIANT"
fi

# Phase-specific compliance checks
case "$PHASE" in
    "specify")
        # Check specification compliance
        if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/spec.md" ]; then
            # Check for implementation details in spec (should not exist)
            if grep -q -i "api\|endpoint\|database\|framework\|library" "$FEATURE_DIR/spec.md"; then
                WARNINGS+=("Specification contains potential implementation details")
            fi
            
            # Check for [NEEDS CLARIFICATION] markers
            CLARIFICATION_COUNT=$(grep -c "\[NEEDS CLARIFICATION" "$FEATURE_DIR/spec.md" 2>/dev/null || echo "0")
            if [ "$CLARIFICATION_COUNT" -gt 0 ]; then
                VIOLATIONS+=("Specification has $CLARIFICATION_COUNT unresolved clarification items")
                COMPLIANCE_STATUS="NON_COMPLIANT"
            fi
        fi
        ;;
        
    "plan")
        # Check planning compliance
        if [ -f "$CONSTITUTION_FILE" ]; then
            # Check Test-First requirement
            if grep -q -i "test.*first\|tdd\|NON-NEGOTIABLE" "$CONSTITUTION_FILE"; then
                if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/feature-planning.md" ]; then
                    if ! grep -q -i "test.*first\|tdd\|Phase 2.*Tests" "$FEATURE_DIR/feature-planning.md"; then
                        VIOLATIONS+=("Constitution requires Test-First, but feature-planning.md doesn't emphasize testing")
                        COMPLIANCE_STATUS="NON_COMPLIANT"
                    fi
                fi
            fi
            
            # Check for required architecture patterns
            if grep -q "Library-First" "$CONSTITUTION_FILE"; then
                if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/feature-planning.md" ]; then
                    if ! grep -q -i "library\|lib/" "$FEATURE_DIR/feature-planning.md"; then
                        WARNINGS+=("Constitution emphasizes Library-First but plan may not reflect this")
                    fi
                fi
            fi
        fi
        ;;
        
    "tasks")
        # Check task compliance
        if [ -f "$CONSTITUTION_FILE" ]; then
            # Verify TDD approach in tasks
            if grep -q -i "test.*first\|tdd" "$CONSTITUTION_FILE"; then
                if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/task-breakdown.md" ]; then
                    # Check if tests come before implementation
                    TEST_PHASE_LINE=$(grep -n "Phase.*Test\|Tests First" "$FEATURE_DIR/task-breakdown.md" | head -1 | cut -d: -f1)
                    IMPL_PHASE_LINE=$(grep -n "Phase.*Core\|Phase.*Implementation" "$FEATURE_DIR/task-breakdown.md" | head -1 | cut -d: -f1)
                    
                    if [ -n "$TEST_PHASE_LINE" ] && [ -n "$IMPL_PHASE_LINE" ]; then
                        if [ "$TEST_PHASE_LINE" -gt "$IMPL_PHASE_LINE" ]; then
                            VIOLATIONS+=("Tasks violate Test-First: implementation phase comes before test phase")
                            COMPLIANCE_STATUS="NON_COMPLIANT"
                        fi
                    fi
                fi
            fi
        fi
        
        # Check task count limits
        if [ -n "$FEATURE_DIR" ] && [ -f "$FEATURE_DIR/task-breakdown.md" ]; then
            TASK_COUNT=$(grep -c "^- \[\* \] T[0-9]" "$FEATURE_DIR/task-breakdown.md" 2>/dev/null || echo "0")
            if [ "$TASK_COUNT" -gt 12 ]; then
                if [ ! -f "$FEATURE_DIR/tasks1.md" ]; then
                    VIOLATIONS+=("Task count ($TASK_COUNT) exceeds limit (12) but not split")
                    COMPLIANCE_STATUS="NON_COMPLIANT"
                fi
            fi
        fi
        ;;
        
    "implement")
        # Check implementation compliance
        if [ -f "$CONSTITUTION_FILE" ]; then
            # Verify tests exist before implementation
            if grep -q -i "test.*first\|tdd" "$CONSTITUTION_FILE"; then
                if [ -d "$REPO_ROOT/src" ] && [ ! -d "$REPO_ROOT/tests" ]; then
                    VIOLATIONS+=("Implementation exists but no tests directory found (violates Test-First)")
                    COMPLIANCE_STATUS="NON_COMPLIANT"
                fi
            fi
        fi
        ;;
        
    *)
        VIOLATIONS+=("Unknown phase: $PHASE")
        COMPLIANCE_STATUS="NON_COMPLIANT"
        ;;
esac

# General compliance checks (apply to all phases)
if [ -f "$CONSTITUTION_FILE" ]; then
    # Check version consistency
    if grep -q "VERSION" "$CONSTITUTION_FILE"; then
        CONSTITUTION_VERSION=$(grep "VERSION" "$CONSTITUTION_FILE" | head -1 | grep -o ".*" || echo "unknown")
        if [ "$CONSTITUTION_VERSION" = "unknown" ]; then
            WARNINGS+=("Constitution version not clearly specified")
        fi
    fi
fi

# Generate compliance report
TOTAL_VIOLATIONS=${#VIOLATIONS[@]}
TOTAL_WARNINGS=${#WARNINGS[@]}

if $JSON_MODE; then
    # Convert arrays to JSON
    violations_json=$(printf '"%s",' "${VIOLATIONS[@]}")
    violations_json="[${violations_json%,}]"
    
    warnings_json=$(printf '"%s",' "${WARNINGS[@]}")
    warnings_json="[${warnings_json%,}]"
    
    printf '{
  "phase": "%s",
  "compliance_status": "%s",
  "total_violations": %d,
  "total_warnings": %d,
  "violations": %s,
  "warnings": %s,
  "constitution_exists": %s,
  "timestamp": "%s"
}\n' "$PHASE" "$COMPLIANCE_STATUS" "$TOTAL_VIOLATIONS" "$TOTAL_WARNINGS" "$violations_json" "$warnings_json" "$([ -f "$CONSTITUTION_FILE" ] && echo 'true' || echo 'false')" "$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
else
    echo "=== CONSTITUTIONAL COMPLIANCE REPORT ==="
    echo "Phase: $PHASE"
    echo "Status: $COMPLIANCE_STATUS"
    echo "Violations: $TOTAL_VIOLATIONS"
    echo "Warnings: $TOTAL_WARNINGS"
    echo ""
    
    if [ "$TOTAL_VIOLATIONS" -gt 0 ]; then
        echo "🚨 VIOLATIONS:"
        printf '  - %s\n' "${VIOLATIONS[@]}"
        echo ""
    fi
    
    if [ "$TOTAL_WARNINGS" -gt 0 ]; then
        echo "⚠️  WARNINGS:"
        printf '  - %s\n' "${WARNINGS[@]}"
        echo ""
    fi
    
    if [ "$COMPLIANCE_STATUS" = "COMPLIANT" ]; then
        echo "✅ No constitutional violations detected"
    else
        echo "❌ Constitutional compliance issues found - must be resolved"
    fi
fi

# Exit with appropriate code
if [ "$COMPLIANCE_STATUS" = "NON_COMPLIANT" ]; then
    exit 1
else
    exit 0
fi
