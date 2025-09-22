#!/usr/bin/env bash
# Resolve folder naming conflicts AFTER checkout (Phase 2)
# This handles existing spec folders with same feature name but different numbers
set -e

CURRENT_BRANCH="$1"
if [ -z "$CURRENT_BRANCH" ]; then
    CURRENT_BRANCH=$(git rev-parse --abbrev-ref HEAD)
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Not in a git repository" >&2
    exit 1
fi

SPECS_DIR="$REPO_ROOT/specs"

# Validate we're on a feature branch
if [[ ! "$CURRENT_BRANCH" =~ ^feature/[0-9]{3}- ]]; then
    echo "ERROR: Must be on a feature branch. Current: $CURRENT_BRANCH" >&2
    exit 1
fi

# Extract expected folder name from current branch
EXPECTED_FOLDER_NAME=$(echo "$CURRENT_BRANCH" | sed 's/^feature\///')

echo "🔍 Phase 2: Checking for folder naming conflicts..." >&2
echo "   Current branch: $CURRENT_BRANCH" >&2
echo "   Expected folder: $EXPECTED_FOLDER_NAME" >&2

# Extract the feature base name (without number prefix)
FEATURE_BASE=$(echo "$EXPECTED_FOLDER_NAME" | sed 's/^[0-9]{3}-//')

# Find conflicting folders (same feature name, different numbers)
CONFLICT_FOLDERS=()
if [ -d "$SPECS_DIR" ]; then
    for spec_dir in "$SPECS_DIR"/*; do
        if [ -d "$spec_dir" ]; then
            folder_name=$(basename "$spec_dir")
            # Check if it matches pattern: number-feature_base
            if [[ "$folder_name" =~ ^[0-9]{3}-${FEATURE_BASE}$ ]] && [ "$folder_name" != "$EXPECTED_FOLDER_NAME" ]; then
                CONFLICT_FOLDERS+=("$folder_name")
            fi
        fi
    done
fi

# Handle folder conflicts
RESOLVED_FOLDERS=0
for conflict_folder in "${CONFLICT_FOLDERS[@]}"; do
    echo "" >&2
    echo "🔄 Resolving folder conflict: $conflict_folder" >&2
    
    OLD_SPEC_PATH="$SPECS_DIR/$conflict_folder"
    NEW_SPEC_PATH="$SPECS_DIR/$EXPECTED_FOLDER_NAME"
    
    if [ -d "$OLD_SPEC_PATH" ]; then
        echo "   📁 Renaming spec folder: $conflict_folder → $EXPECTED_FOLDER_NAME" >&2
        
        # Create new directory if it doesn't exist
        mkdir -p "$NEW_SPEC_PATH"
        
        # Check if new directory already has content
        if [ "$(ls -A "$NEW_SPEC_PATH" 2>/dev/null)" ]; then
            echo "   ⚠️  Target folder already exists with content. Merging..." >&2
            
            # Merge files, prioritizing newer files
            for old_file in "$OLD_SPEC_PATH"/*; do
                if [ -f "$old_file" ]; then
                    filename=$(basename "$old_file")
                    new_file="$NEW_SPEC_PATH/$filename"
                    
                    if [ -f "$new_file" ]; then
                        # File exists in both locations
                        if [ "$old_file" -nt "$new_file" ]; then
                            echo "     📄 Updating $filename (older → newer)" >&2
                            cp "$old_file" "$new_file"
                        else
                            echo "     📄 Keeping existing $filename (already newer)" >&2
                        fi
                    else
                        # File only exists in old location
                        echo "     📄 Moving $filename" >&2
                        mv "$old_file" "$new_file"
                    fi
                fi
            done
        else
            # New directory is empty, simple move
            echo "   📦 Moving all files to new location" >&2
            if [ "$(ls -A "$OLD_SPEC_PATH" 2>/dev/null)" ]; then
                mv "$OLD_SPEC_PATH"/* "$NEW_SPEC_PATH"/ 2>/dev/null || {
                    echo "   ⚠️  Some files may not have been moved" >&2
                }
            fi
        fi
        
        # Update file references within the spec files
        for spec_file in "$NEW_SPEC_PATH"/*.md; do
            if [ -f "$spec_file" ]; then
                echo "   🔗 Updating references in $(basename "$spec_file")" >&2
                
                # Update folder references
                sed -i.bak "s|specs/$conflict_folder|specs/$EXPECTED_FOLDER_NAME|g" "$spec_file" 2>/dev/null || true
                sed -i.bak "s|/$conflict_folder/|/$EXPECTED_FOLDER_NAME/|g" "$spec_file" 2>/dev/null || true
                
                # Update branch references if they exist
                OLD_BRANCH_NAME="feature/$conflict_folder"
                NEW_BRANCH_NAME="$CURRENT_BRANCH"
                sed -i.bak "s|$OLD_BRANCH_NAME|$NEW_BRANCH_NAME|g" "$spec_file" 2>/dev/null || true
                
                # Clean up backup file
                rm -f "$spec_file.bak" 2>/dev/null || true
            fi
        done
        
        # Remove old directory if it's empty
        if rmdir "$OLD_SPEC_PATH" 2>/dev/null; then
            echo "   🗑️  Removed empty old folder: $conflict_folder" >&2
        else
            echo "   ⚠️  Old folder not empty after move: $OLD_SPEC_PATH" >&2
            echo "       Manual cleanup may be needed" >&2
        fi
        
        RESOLVED_FOLDERS=$((RESOLVED_FOLDERS + 1))
        echo "   ✅ Folder renamed: $conflict_folder → $EXPECTED_FOLDER_NAME" >&2
    else
        echo "   ❓ Folder path doesn't exist: $OLD_SPEC_PATH" >&2
    fi
done

# Ensure the target folder exists
mkdir -p "$SPECS_DIR/$EXPECTED_FOLDER_NAME"

# Summary
if [ ${#CONFLICT_FOLDERS[@]} -eq 0 ]; then
    echo "" >&2
    echo "✅ Phase 2: No folder conflicts detected for: $EXPECTED_FOLDER_NAME" >&2
else
    echo "" >&2
    echo "🎯 Phase 2 Complete: Folder conflict resolution" >&2
    echo "   Conflicts found: ${#CONFLICT_FOLDERS[@]}" >&2
    echo "   Successfully resolved: $RESOLVED_FOLDERS" >&2
    echo "   Target folder ready: $EXPECTED_FOLDER_NAME" >&2
fi

# Output the resolved folder path for use by other scripts
echo "$SPECS_DIR/$EXPECTED_FOLDER_NAME"
