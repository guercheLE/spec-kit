#!/usr/bin/env bash
# Enhanced Task splitting utility for large features (>12 tasks)
# Keeps level 3 sections together while respecting task limits
# Only splits when explicitly enabled via SPLIT_TASKS parameter
set -e

TASKS_FILE="$1"
FORCE_SPLIT="$2"

if [ -z "$TASKS_FILE" ] || [ ! -f "$TASKS_FILE" ]; then
    echo "Usage: $0 <task-breakdown.md> [--force]" >&2
    echo "Splits task-breakdown.md into multiple files if >12 tasks detected AND splitting is enabled" >&2
    echo "Keeps level 3 sections (###) together for logical grouping" >&2
    echo "Options:" >&2
    echo "  --force  : Force splitting even if SPLIT_TASKS=false" >&2
    exit 1
fi

# Count tasks in the file
TASK_COUNT=$(grep -c "^- \[\] T[0-9]" "$TASKS_FILE" 2>/dev/null || echo "0")

echo "📊 Tasks detected: $TASK_COUNT" >&2

# Check SPLIT_TASKS parameter in the file
SPLIT_TASKS=$(grep "^**Allow Task Splitting**:" "$TASKS_FILE" 2>/dev/null | sed 's/.*[\([^]]*\)].*/\1/' || echo "false")
echo "🔧 SPLIT_TASKS parameter: $SPLIT_TASKS" >&2

if [ "$TASK_COUNT" -le 12 ]; then
    echo "✅ Task count within limits ($TASK_COUNT <= 12), no splitting required" >&2
    exit 0
fi

# Check if splitting is enabled
if [ "$SPLIT_TASKS" != "true" ] && [ "$FORCE_SPLIT" != "--force" ]; then
    echo "⚠️  Task count exceeds limit ($TASK_COUNT > 12) but splitting is DISABLED" >&2
    echo "💡 To enable splitting:" >&2
    echo "   1. Set 'Allow Task Splitting: [true]' in the task-breakdown.md header, OR" >&2
    echo "   2. Use --force flag: $0 \"$TASKS_FILE\" --force" >&2
    echo "📝 Currently keeping all tasks in single file as requested" >&2
    exit 0
fi

echo "⚠️  Task count exceeds limit ($TASK_COUNT > 12) and splitting is ENABLED, proceeding..." >&2

FEATURE_DIR=$(dirname "$TASKS_FILE")

# Create temp files for analysis
TEMP_DIR="/tmp/task_split_$$"
mkdir -p "$TEMP_DIR"

# Extract header content (everything before first Phase or Task)
HEADER_END=$(grep -n "^## Phase\|^### \|^- \[ \] T[0-9][0-9][0-9]" "$TASKS_FILE" | head -1 | cut -d: -f1)
if [ -z "$HEADER_END" ]; then
    HEADER_END=1
else
    HEADER_END=$((HEADER_END - 1))
fi

sed -n "1,${HEADER_END}p" "$TASKS_FILE" > "$TEMP_DIR/header.txt"

# Find section boundaries using the enhanced regex pattern
# Pattern matches: level 3 headers (###) OR task items (- [ ] T###)
grep -n "^### \|^- \[ \] T[0-9][0-9][0-9]" "$TASKS_FILE" > "$TEMP_DIR/boundaries.txt" 2>/dev/null || true

if [ ! -s "$TEMP_DIR/boundaries.txt" ]; then
    echo "❌ No valid sections or tasks found for splitting" >&2
    rm -rf "$TEMP_DIR"
    exit 1
fi

# Analyze sections and their task counts
declare -a SECTIONS
declare -a SECTION_STARTS
declare -a SECTION_TASK_COUNTS
SECTION_INDEX=0

while IFS= read -r line; do
    LINE_NUM=$(echo "$line" | cut -d: -f1)
    CONTENT=$(echo "$line" | cut -d: -f2-)
    
    if [[ "$CONTENT" =~ ^###[[:space:]] ]]; then
        # This is a section header
        SECTIONS[$SECTION_INDEX]="$CONTENT"
        SECTION_STARTS[$SECTION_INDEX]=$LINE_NUM
        SECTION_TASK_COUNTS[$SECTION_INDEX]=0
        SECTION_INDEX=$((SECTION_INDEX + 1))
    elif [[ "$CONTENT" =~ ^-[[:space:]]\[[[:space:]]\][[:space:]]T[0-9] ]]; then
        # This is a task, increment count for current section
        if [ $SECTION_INDEX -gt 0 ]; then
            CURRENT_SECTION=$((SECTION_INDEX - 1))
            SECTION_TASK_COUNTS[$CURRENT_SECTION]=$((SECTION_TASK_COUNTS[$CURRENT_SECTION] + 1))
        fi
    fi
done < "$TEMP_DIR/boundaries.txt"

echo "📋 Sections detected: $SECTION_INDEX" >&2
for i in $(seq 0 $((SECTION_INDEX - 1))); do
    echo "   ${SECTIONS[$i]}: ${SECTION_TASK_COUNTS[$i]} tasks" >&2
done

# Smart grouping: combine sections to stay close to 10-12 tasks per file
declare -a SPLIT_GROUPS
declare -a SPLIT_TASK_COUNTS
CURRENT_GROUP=0
CURRENT_GROUP_TASKS=0
MAX_TASKS_PER_SPLIT=12
IDEAL_TASKS_PER_SPLIT=10

SPLIT_GROUPS[$CURRENT_GROUP]=""
SPLIT_TASK_COUNTS[$CURRENT_GROUP]=0

for i in $(seq 0 $((SECTION_INDEX - 1))); do
    SECTION_TASKS=${SECTION_TASK_COUNTS[$i]}
    
    # If adding this section would exceed max tasks and we already have some tasks
    if [ $((CURRENT_GROUP_TASKS + SECTION_TASKS)) -gt $MAX_TASKS_PER_SPLIT ] && [ $CURRENT_GROUP_TASKS -gt 0 ]; then
        # Start a new group
        CURRENT_GROUP=$((CURRENT_GROUP + 1))
        CURRENT_GROUP_TASKS=0
        SPLIT_GROUPS[$CURRENT_GROUP]=""
        SPLIT_TASK_COUNTS[$CURRENT_GROUP]=0
    fi
    
    # Add section to current group
    if [ -z "${SPLIT_GROUPS[$CURRENT_GROUP]}" ]; then
        SPLIT_GROUPS[$CURRENT_GROUP]="$i"
    else
        SPLIT_GROUPS[$CURRENT_GROUP]="${SPLIT_GROUPS[$CURRENT_GROUP]},$i"
    fi
    
    CURRENT_GROUP_TASKS=$((CURRENT_GROUP_TASKS + SECTION_TASKS))
    SPLIT_TASK_COUNTS[$CURRENT_GROUP]=$CURRENT_GROUP_TASKS
done

TOTAL_SPLITS=$((CURRENT_GROUP + 1))

echo "🗂️  Smart grouping results:" >&2
for i in $(seq 0 $((TOTAL_SPLITS - 1))); do
    echo "   Split $((i + 1)): ${SPLIT_TASK_COUNTS[$i]} tasks (sections: ${SPLIT_GROUPS[$i]})" >&2
done

# Create split files
for SPLIT_INDEX in $(seq 0 $((TOTAL_SPLITS - 1))); do
    SPLIT_FILE="$FEATURE_DIR/tasks$((SPLIT_INDEX + 1)).md"
    
    # Copy header to split file
    cp "$TEMP_DIR/header.txt" "$SPLIT_FILE"
    
    # Add split-specific metadata
    cat >> "$SPLIT_FILE" << EOF

**TASK SPLIT $((SPLIT_INDEX + 1)) of $TOTAL_SPLITS** (Section-Aware Splitting)
**Tasks**: ${SPLIT_TASK_COUNTS[$SPLIT_INDEX]} tasks in this split
**Total Project**: $TASK_COUNT tasks across all splits
**Dependencies**: $([ $SPLIT_INDEX -eq 0 ] && echo "None (foundation)" || echo "tasks${SPLIT_INDEX}.md must complete before this split starts")

## Critical Rules
- **Complete Previous First**: $([ $SPLIT_INDEX -eq 0 ] && echo "This is the foundation split - start here" || echo "tasks${SPLIT_INDEX}.md must be 100% complete before starting this split")
- **Sequential Execution**: Do not run tasks from multiple split files in parallel
- **Section Integrity**: Related tasks within sections kept together for logical workflow
- **Test Dependencies**: Ensure all tests from previous splits pass before proceeding

EOF

    # Extract content for this split's sections
    IFS="," read -ra SECTION_INDICES <<< "${SPLIT_GROUPS[$SPLIT_INDEX]}"
    
    for SECTION_IDX in "${SECTION_INDICES[@]}"; do
        SECTION_START=${SECTION_STARTS[$SECTION_IDX]}
        
        # Find end of this section (start of next section or end of file)
        SECTION_END=$(wc -l < "$TASKS_FILE")
        if [ $((SECTION_IDX + 1)) -lt $SECTION_INDEX ]; then
            NEXT_SECTION_START=${SECTION_STARTS[$((SECTION_IDX + 1))]}
            SECTION_END=$((NEXT_SECTION_START - 1))
        fi
        
        # Extract section content
        sed -n "${SECTION_START},${SECTION_END}p" "$TASKS_FILE" >> "$SPLIT_FILE"
    done
    
    # Add completion tracking
    cat >> "$SPLIT_FILE" << EOF

## Split Completion Status
- [ ] All ${SPLIT_TASK_COUNTS[$SPLIT_INDEX]} tasks in this split completed
- [ ] All tests passing for implemented functionality
- [ ] Ready for next split$([ $((SPLIT_INDEX + 1)) -lt $TOTAL_SPLITS ] && echo " (tasks$((SPLIT_INDEX + 2)).md)" || echo " - ALL SPLITS COMPLETE!")

**Section Summary**: This split contains logical grouping of related functionality
$([ $((SPLIT_INDEX + 1)) -lt $TOTAL_SPLITS ] && echo "**Next Steps**: After completing all tasks above, proceed to tasks$((SPLIT_INDEX + 2)).md" || echo "**Project Complete**: This is the final split - project ready for deployment!")

EOF
    
    echo "✅ Created: $SPLIT_FILE (${SPLIT_TASK_COUNTS[$SPLIT_INDEX]} tasks)" >&2
done

# Backup original tasks.md
mv "$TASKS_FILE" "$TASKS_FILE.backup"

# Create a master tasks.md file that references the splits
cat > "$TASKS_FILE" << EOF
# Tasks: [FEATURE NAME] - SECTION-AWARE SPLIT EXECUTION

**Original Task Count**: $TASK_COUNT (exceeds 12-task limit)
**Split Strategy**: Section-aware splitting (keeps related tasks together)
**Split Files**: $TOTAL_SPLITS files with logical section grouping
**Execution Order**: Sequential - complete each file before moving to next
**Splitting Enabled**: SPLIT_TASKS=true $([ "$FORCE_SPLIT" = "--force" ] && echo "(forced)" || echo "(explicit)")

## Smart Splitting Summary

The original tasks were intelligently split to keep level 3 sections (###) together:

EOF

for i in $(seq 0 $((TOTAL_SPLITS - 1))); do
    cat >> "$TASKS_FILE" << EOF
### $((i + 1)). tasks$((i + 1)).md
- **Tasks**: ${SPLIT_TASK_COUNTS[$i]} tasks
- **Status**: ⏳ Pending
- **Theme**: $([ $i -eq 0 ] && echo "Foundation & Core Setup" || [ $i -eq $((TOTAL_SPLITS - 1)) ] && echo "Polish & Final Integration" || echo "Feature Extensions & Advanced Functionality")
- **Prerequisites**: $([ $i -eq 0 ] && echo "None (start here)" || echo "tasks${i}.md must be complete")

EOF
done

cat >> "$TASKS_FILE" << EOF

## Section-Aware Splitting Rules
1. **Logical Grouping**: Level 3 sections (###) kept together within splits
2. **Sequential Only**: Never run tasks from multiple split files in parallel
3. **Complete Before Next**: Finish all tasks in current split before moving to next
4. **Section Integrity**: Related functionality stays together for better workflow
5. **Dependency Chain**: Each split builds on previous splits

## Split Execution Workflow
- **Start**: Execute tasks1.md (foundation)
- **Progress**: Complete each split fully before next
- **Testing**: Run tests after each split completion
- **Completion**: All splits done = feature ready

## Recovery & Debugging
- Original tasks.md backed up as: tasks.md.backup
- To restore original: 
- Individual splits preserved for granular execution
- Section boundaries preserved for logical workflow

## Benefits of Section-Aware Splitting
- **Logical Flow**: Related tasks stay together
- **Better Context**: Easier to understand task relationships  
- **Reduced Context Switching**: Work on related functionality in batches
- **Cleaner Dependencies**: Section boundaries align with natural dependencies

---
**Generated by**: .specify/scripts/bash/split-tasks.sh (enhanced with parameter control)
**Split Date**: $(date +"%Y-%m-%d %H:%M:%S")
**Strategy**: Section-aware with $(grep -c "^### " "$TASKS_FILE.backup" 2>/dev/null || echo "N/A") sections across $TOTAL_SPLITS splits
EOF

# Cleanup temp files
rm -rf "$TEMP_DIR"

echo "" >&2
echo "🎯 Section-aware task splitting complete!" >&2
echo "📋 Master file: $TASKS_FILE" >&2
echo "📁 Split files: tasks1.md through tasks${TOTAL_SPLITS}.md" >&2
echo "💾 Backup: $TASKS_FILE.backup" >&2
echo "🧩 Sections kept together for logical workflow" >&2
echo "" >&2
echo "⚠️  IMPORTANT: Execute split files sequentially, never in parallel!" >&2
