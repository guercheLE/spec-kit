#!/usr/bin/env bash
# Resolve branch naming conflicts BEFORE checkout (Phase 1)
# This handles existing branches with same feature name but different numbers
set -e

FEATURE_DESCRIPTION="$1"
NEW_BRANCH_NUMBER="$2"

if [ -z "$FEATURE_DESCRIPTION" ] || [ -z "$NEW_BRANCH_NUMBER" ]; then
    echo "Usage: $0 <feature_description> <new_branch_number>" >&2
    exit 1
fi

REPO_ROOT=$(git rev-parse --show-toplevel 2>/dev/null)
if [ $? -ne 0 ]; then
    echo "ERROR: Not in a git repository" >&2
    exit 1
fi

# Generate the expected names
# Check if feature description already contains numbering (e.g., "001-feature-name")
if [[ "$FEATURE_DESCRIPTION" =~ ^[0-9]{3}- ]]; then
    # Use the provided numbering as-is
    NEW_FEATURE_DIR_NAME="$FEATURE_DESCRIPTION"
    NEW_BRANCH_NAME="feature/${NEW_FEATURE_DIR_NAME}"
    WORDS=$(echo "$FEATURE_DESCRIPTION" | sed 's/^[0-9]{3}-//')
else
    # Generate numbering for unnumbered features
    BRANCH_NAME=$(echo "$FEATURE_DESCRIPTION" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/-\{-/g' | sed 's/^-//' | sed 's/-$//')
    WORDS=$(echo "$BRANCH_NAME" | tr '-' '\n' | grep -v '^$' | head -3 | tr '\n' '-' | sed 's/-$//')
    NEW_FEATURE_NUMBER=$(printf "%03d" "$NEW_BRANCH_NUMBER")
    NEW_FEATURE_DIR_NAME="${NEW_FEATURE_NUMBER}-${WORDS}"
    NEW_BRANCH_NAME="feature/${NEW_FEATURE_DIR_NAME}"
fi

echo "🔍 Phase 1: Checking for branch naming conflicts..." >&2
echo "   Target branch: $NEW_BRANCH_NAME" >&2

# Find conflicting branches (same feature name, different numbers)
CONFLICT_BRANCHES=()

# Check local branches
while IFS= read -r branch; do
    if [ -n "$branch" ]; then
        branch=$(echo "$branch" | sed 's/^[ *]*//')
        if [[ "$branch" =~ ^feature/[0-9]{3}-${WORDS}$ ]] && [ "$branch" != "$NEW_BRANCH_NAME" ]; then
            CONFLICT_BRANCHES+=("$branch")
        fi
    fi
done < <(git branch 2>/dev/null | grep "feature/[0-9]{3}-${WORDS}" || true)

# Check remote branches
while IFS= read -r branch; do
    if [ -n "$branch" ]; then
        branch=$(echo "$branch" | sed 's/remotes\/origin\///')
        if [[ "$branch" =~ ^feature/[0-9]{3}-${WORDS}$ ]] && [ "$branch" != "$NEW_BRANCH_NAME" ]; then
            # Only add if not already in local conflicts
            if [[ ! " ${CONFLICT_BRANCHES[@]} " =~ " ${branch} " ]]; then
                CONFLICT_BRANCHES+=("$branch")
            fi
        fi
    fi
done < <(git branch -r 2>/dev/null | grep "origin\/feature/[0-9]{3}-${WORDS}" || true)

# Handle branch conflicts
RESOLVED_BRANCHES=0
for conflict_branch in "${CONFLICT_BRANCHES[@]}"; do
    echo "" >&2
    echo "🔄 Resolving branch conflict: $conflict_branch" >&2
    
    # Check if branch exists locally
    if git show-ref --verify --quiet "refs/heads/$conflict_branch"; then
        echo "   📍 Local branch exists: $conflict_branch" >&2
        
        # Get current branch before switching
        ORIGINAL_BRANCH=$(git rev-parse --abbrev-ref HEAD)
        
        # Checkout the conflict branch
        if git checkout "$conflict_branch" 2>/dev/null; then
            echo "   🏷️  Renaming local branch: $conflict_branch → $NEW_BRANCH_NAME" >&2
            git branch -m "$NEW_BRANCH_NAME"
            
            # Remove old remote tracking if it exists
            git config --unset "branch.$NEW_BRANCH_NAME.remote" 2>/dev/null || true
            git config --unset "branch.$NEW_BRANCH_NAME.merge" 2>/dev/null || true
            
            # Delete old remote branch if it exists
            if git ls-remote --heads origin "$conflict_branch" | grep -q "$conflict_branch"; then
                echo "   🗑️  Deleting remote branch: origin/$conflict_branch" >&2
                git push origin --delete "$conflict_branch" 2>/dev/null || {
                    echo "   ⚠️  Failed to delete remote branch (may not have permission)" >&2
                }
            fi
            
            # Set new upstream
            echo "   🔗 Setting new upstream: origin/$NEW_BRANCH_NAME" >&2
            git push -u origin "$NEW_BRANCH_NAME" 2>/dev/null || {
                echo "   ⚠️  Failed to set upstream (will be set on first push)" >&2
            }
            
            RESOLVED_BRANCHES=$((RESOLVED_BRANCHES + 1))
            echo "   ✅ Branch renamed: $conflict_branch → $NEW_BRANCH_NAME" >&2
            
            # Return to original branch
            git checkout "$ORIGINAL_BRANCH" 2>/dev/null || true
        else
            echo "   ❌ Failed to checkout $conflict_branch" >&2
        fi
    else
        # Remote-only branch
        echo "   🌐 Remote-only branch: $conflict_branch" >&2
        
        # Check out the remote branch and rename it
        if git checkout -b "$NEW_BRANCH_NAME" "origin/$conflict_branch" 2>/dev/null; then
            echo "   🏷️  Created local branch: $NEW_BRANCH_NAME from origin/$conflict_branch" >&2
            
            # Delete old remote branch
            if git ls-remote --heads origin "$conflict_branch" | grep -q "$conflict_branch"; then
                echo "   🗑️  Deleting old remote branch: origin/$conflict_branch" >&2
                git push origin --delete "$conflict_branch" 2>/dev/null || {
                    echo "   ⚠️  Failed to delete remote branch (may not have permission)" >&2
                }
            fi
            
            # Set new upstream
            git push -u origin "$NEW_BRANCH_NAME" 2>/dev/null || {
                echo "   ⚠️  Failed to set upstream (will be set on first push)" >&2
            }
            
            RESOLVED_BRANCHES=$((RESOLVED_BRANCHES + 1))
            echo "   ✅ Remote branch resolved: $conflict_branch → $NEW_BRANCH_NAME" >&2
        else
            echo "   ❌ Failed to checkout remote branch $conflict_branch" >&2
        fi
    fi
done

# Summary
if [ ${#CONFLICT_BRANCHES[@]} -eq 0 ]; then
    echo "" >&2
    echo "✅ Phase 1: No branch conflicts detected for: $NEW_BRANCH_NAME" >&2
else
    echo "" >&2
    echo "🎯 Phase 1 Complete: Branch conflict resolution" >&2
    echo "   Conflicts found: ${#CONFLICT_BRANCHES[@]}" >&2
    echo "   Successfully resolved: $RESOLVED_BRANCHES" >&2
    echo "   Target branch ready: $NEW_BRANCH_NAME" >&2
fi

# Output the resolved branch name for use by other scripts
echo "$NEW_BRANCH_NAME"
