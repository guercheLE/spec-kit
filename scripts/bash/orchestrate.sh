#!/usr/bin/env bash
# Project Development Orchestrator
set -e

JSON_MODE=false
ARGS=()
for arg in "$@"; do
    case "$arg" in
        --json) JSON_MODE=true ;; 
        --help|-h) 
            echo "Usage: $0 [--json] <project_description>"
            echo "Orchestrates complete project development workflow"
            exit 0 ;; 
        *) ARGS+=("$arg") ;; 
    esac
done

PROJECT_DESCRIPTION="${ARGS[*]}"
if [ -z "$PROJECT_DESCRIPTION" ]; then
    echo "Usage: $0 [--json] <project_description>" >&2
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Not in a git repository. Run this script from within a git repository." >&2
    exit 1
fi
SPECS_DIR="$REPO_ROOT/specs"
mkdir -p "$SPECS_DIR"

# Analyze project state (brownfield vs greenfield)
echo "🔍 Analyzing project state..." >&2
PROJECT_STATE_RESULT=$("$REPO_ROOT/.specify/scripts/bash/analyze-project-state.sh" --json)
PROJECT_TYPE=$(echo "$PROJECT_STATE_RESULT" | jq -r '.project_type')
NEXT_BRANCH_NUMBER=$(echo "$PROJECT_STATE_RESULT" | jq -r '.next_branch_number')
echo "📊 Project type detected: $PROJECT_TYPE" >&2
echo "🔢 Next branch number: $NEXT_BRANCH_NUMBER" >&2

# Create orchestration plan file if it doesn't exist
ORCHESTRATION_PLAN_FILE="$REPO_ROOT/orchestration-plan.md"
if [ ! -f "$ORCHESTRATION_PLAN_FILE" ]; then
    if [ -f "$REPO_ROOT/.specify/templates/orchestration-plan-template.md" ]; then
        cp "$REPO_ROOT/.specify/templates/orchestration-plan-template.md" "$ORCHESTRATION_PLAN_FILE"
    else
        cat > "$ORCHESTRATION_PLAN_FILE" << 'EOF'
# Project Orchestration Plan

**Project**: [PROJECT_NAME]
**Description**: $PROJECT_DESCRIPTION

## Product Features (Priority 1)
- [ ] Core Feature 1
- [ ] Core Feature 2
- [ ] Basic Auth

## Enhanced Product Features (Priority 2)
- [ ] Advanced Feature 1
- [ ] Analytics
- [ ] Advanced Auth

## Enhanced Product Features (Priority 3)  
- [ ] Premium Features
- [ ] Integrations
- [ ] Admin Panel

## Dependencies
```
Product Features -> Enhanced Product P2 -> Enhanced Product P3
```

## Execution Plan
1. Analyze and identify specific features from project description
2. Create dependency graph
3. Execute workflow for each feature in order
EOF
    fi
fi

# Generate execution plan with project state awareness
EXECUTION_PLAN="$REPO_ROOT/execution-plan.json"
cat > "$EXECUTION_PLAN" << EOF
{
  "project_description": "$PROJECT_DESCRIPTION",
  "project_type": "$PROJECT_TYPE", 
  "next_branch_number": $NEXT_BRANCH_NUMBER,
  "project_state": $PROJECT_STATE_RESULT,
  "orchestration_plan_file": "$ORCHESTRATION_PLAN_FILE",
  "specs_directory": "$SPECS_DIR",
  "features": [],
  "dependencies": {},
  "execution_order": [],
  "branch_tracking": {
    "last_used_number": $((NEXT_BRANCH_NUMBER - 1)),
    "next_available": $NEXT_BRANCH_NUMBER,
    "format": "feature/{number:03d}-{name}"
  },
  "workflow_rules": {
    "global_files_branch": "main",
    "spec_files_branch": "feature/*",
    "commit_pattern": "Complete {phase} for {feature_name}",
    "no_implementation": true,
    "complete_spec_before_next": true
  },
  "status": "initialized"
}
EOF

if $JSON_MODE; then
    printf '{"ORCHESTRATION_PLAN_FILE":"%s","EXECUTION_PLAN":"%s","SPECS_DIR":"%s","PROJECT_TYPE":"%s","NEXT_BRANCH_NUMBER":%d,"PROJECT_STATE":%s,"STATUS":"ready_for_analysis"}\n' "$ORCHESTRATION_PLAN_FILE" "$EXECUTION_PLAN" "$SPECS_DIR" "$PROJECT_TYPE" "$NEXT_BRANCH_NUMBER" "$PROJECT_STATE_RESULT"
else
    echo "ORCHESTRATION_PLAN_FILE: $ORCHESTRATION_PLAN_FILE"
    echo "EXECUTION_PLAN: $EXECUTION_PLAN"
    echo "SPECS_DIR: $SPECS_DIR"
    echo "PROJECT_TYPE: $PROJECT_TYPE"
    echo "NEXT_BRANCH_NUMBER: $NEXT_BRANCH_NUMBER"
    echo "STATUS: ready_for_analysis"
fi
