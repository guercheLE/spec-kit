#!/usr/bin/env bash
# (Moved to scripts/bash/) Common functions and variables for all scripts

get_repo_root() { git rev-parse --show-toplevel; }
get_current_branch() { git rev-parse --abbrev-ref HEAD; }

# Test if git MCP server is configured and working
test_git_mcp() {
    # Try a safe, read-only git MCP operation
    if mcp git status --porcelain >/dev/null 2>&1; then
        echo "mcp-git"
        return 0
    elif git-mcp status --porcelain >/dev/null 2>&1; then
        echo "git-mcp"
        return 0
    else
        echo "git"
        return 1
    fi
}

# Use git MCP if available, fallback to git
smart_git() {
    local git_cmd=$(test_git_mcp)
    case "$git_cmd" in
        "mcp-git")
            mcp git "$@"
            ;;
        "git-mcp")
            git-mcp "$@"
            ;;
        *)
            git "$@"
            ;;
    esac
}

check_feature_branch() {
    local branch="$1"
    if [[ ! "$branch" =~ ^feature/[0-9]{3}- ]]; then
        echo "ERROR: Not on a feature branch. Current branch: $branch" >&2
        echo "Feature branches should be named like: feature/001-feature-name" >&2
        return 1
    fi; return 0
}

# Enhanced branch verification with timing safety
verify_branch_with_retry() {
    local expected_branch="$1"
    local max_attempts="${2:-5}"
    local wait_time="${3:-0.3}"
    local attempt=1
    
    while [ $attempt -le $max_attempts ]; do
        local current_branch=$(get_current_branch)
        if [[ "$current_branch" == "$expected_branch" ]]; then
            # Additional filesystem stability wait
            sleep "$wait_time"
            echo "[common] Successfully verified branch: $expected_branch" >&2
            return 0
        fi
        
        echo "[common] Attempt $attempt: Expected '$expected_branch', got '$current_branch'. Retrying..." >&2
        sleep 0.5
        attempt=$((attempt + 1))
    done
    
    echo "ERROR: Failed to verify branch after $max_attempts attempts" >&2
    echo "Expected: '$expected_branch', Current: '$(get_current_branch)'" >&2
    return 1
}

# Safe branch operations with git MCP fallback
safe_checkout_branch() {
    local branch="$1"
    local create_new="${2:-false}"
    
    echo "[common] Checking out branch: $branch (create_new: $create_new)" >&2
    
    if [[ "$create_new" == "true" ]]; then
        smart_git checkout -b "$branch" || {
            echo "ERROR: Failed to create and checkout branch: $branch" >&2
            return 1
        }
    else
        smart_git checkout "$branch" || {
            echo "ERROR: Failed to checkout existing branch: $branch" >&2
            return 1
        }
    fi
    
    # Verify the checkout was successful
    verify_branch_with_retry "$branch" 5 0.3 || return 1
    
    return 0
}

get_feature_dir() { echo "$1/specs/$2"; }

get_feature_paths() {
    local repo_root=$(get_repo_root)
    local current_branch=$(get_current_branch)
    # Strip 'feature/' prefix to get just the feature name for directory path
    local feature_name=$(echo "$current_branch" | sed 's/^feature\///')
    local feature_dir=$(get_feature_dir "$repo_root" "$feature_name")
    cat <<EOF
REPO_ROOT='$repo_root'
CURRENT_BRANCH='$current_branch'
FEATURE_DIR='$feature_dir'
FEATURE_SPEC='$feature_dir/spec.md'
IMPL_PLAN='$feature_dir/feature-planning.md'
TASKS='$feature_dir/task-breakdown.md'
RESEARCH='$feature_dir/research.md'
DATA_MODEL='$feature_dir/data-model.md'
QUICKSTART='$feature_dir/quickstart.md'
CONTRACTS_DIR='$feature_dir/contracts'
EOF
}

check_file() { [[ -f "$1" ]] && echo "  ✓ $2" || echo "  ✗ $2"; }
check_dir() { [[ -d "$1" && -n $(ls -A "$1" 2>/dev/null) ]] && echo "  ✓ $2" || echo "  ✗ $2"; }

# Git timing safety functions (added to fix timing issues with file system)

# Safe checkout with Git status refresh (eliminates need for timing delays)
safe_checkout() {
    local branch_name="$1"
    local minimal_delay="${2:-50}"  # Reduced to 50ms minimum for filesystem consistency
    
    echo "[common] Switching to branch: $branch_name" >&2
    
    # Perform checkout
    if git checkout "$branch_name" 2>/dev/null; then
        # Minimal filesystem stability delay (reduced from 300ms)
        local sleep_time=$(echo "scale=3; $minimal_delay / 1000" | bc)
        sleep "$sleep_time"
        
        # CRITICAL: Force Git status refresh - this is the real fix, not timing
        echo "[common] Refreshing Git working directory status..." >&2
        local status_output
        status_output=$(git status --porcelain)
        
        if [[ -z "$status_output" ]]; then
            echo "[common] ✅ Branch checkout successful, working tree clean" >&2
            return 0
        else
            echo "[common] ⚠️ Warning: Working tree not clean after checkout" >&2
            echo "$status_output" >&2
            return 1
        fi
    else
        echo "[common] ❌ Failed to checkout branch: $branch_name" >&2
        return 1
    fi
}

# Verify current branch matches expected
verify_branch() {
    local expected_branch="$1"
    local current_branch
    current_branch=$(get_current_branch)
    
    if [[ "$current_branch" == "$expected_branch" ]]; then
        echo "[common] ✅ On correct branch: $current_branch" >&2
        return 0
    else
        echo "[common] ❌ Branch mismatch. Expected: $expected_branch, Current: $current_branch" >&2
        return 1
    fi
}

# Safe branch switching with verification
switch_to_branch() {
    local target_branch="$1"
    local timing_ms="${2:-300}"
    
    # Check if already on target branch
    if verify_branch "$target_branch"; then
        echo "[common] Already on target branch: $target_branch" >&2
        return 0
    fi
    
    # Perform safe checkout
    if safe_checkout "$target_branch" "$timing_ms"; then
        # Double-verify we're on the right branch
        return verify_branch "$target_branch"
    else
        return 1
    fi
}

# Safe commit with Git status refresh (primary fix for untracked file bug)
safe_commit() {
    local commit_message="$1"
    local git_command="${2:-git}"  # Allow override for MCP git
    
    echo "[common] Committing changes: $commit_message" >&2
    
    # Add all changes
    if $git_command add .; then
        echo "[common] Changes staged successfully" >&2
    else
        echo "[common] ❌ Failed to stage changes" >&2
        return 1
    fi
    
    # Commit changes
    if $git_command commit -m "$commit_message"; then
        echo "[common] ✅ Commit successful" >&2
    else
        echo "[common] ❌ Failed to commit changes" >&2
        return 1
    fi
    
    # CRITICAL: Git status refresh is the real fix - forces cache synchronization
    echo "[common] Refreshing Git working directory status after commit..." >&2
    local status_output
    status_output=$($git_command status --porcelain)
    
    if [[ -z "$status_output" ]]; then
        echo "[common] ✅ Working tree clean after commit" >&2
        return 0
    else
        echo "[common] ⚠️ Warning: Working tree not clean after commit" >&2
        echo "$status_output" >&2
        return 0  # Don't fail on warnings, just inform
    fi
}