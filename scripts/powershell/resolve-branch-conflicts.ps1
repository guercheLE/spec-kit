# Resolve branch naming conflicts BEFORE checkout (Phase 1) - PowerShell version
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureDescription,
    
    [Parameter(Mandatory=$true)]
    [int]$NewBranchNumber
)

$ErrorActionPreference = "Stop"

try {
    $RepoRoot = git rev-parse --show-toplevel 2>$null
    if (-not $RepoRoot) {
        Write-Error "ERROR: Not in a git repository"
        exit 1
    }
} catch {
    Write-Error "ERROR: Not in a git repository"
    exit 1
}

# Generate the expected names
$BranchName = $FeatureDescription.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-|-$', ''
$Words = ($BranchName -split '-' | Where-Object { $_ -ne '' } | Select-Object -First 3) -join '-'

$NewFeatureNumber = "{0:D3}" -f $NewBranchNumber
$NewFeatureDirName = "$NewFeatureNumber-$Words"
$NewBranchName = "feature/$NewFeatureDirName"

Write-Host "🔍 Phase 1: Checking for branch naming conflicts..." -ForegroundColor Cyan
Write-Host "   Target branch: $NewBranchName" -ForegroundColor Gray

# Find conflicting branches
$ConflictBranches = @()

# Check local branches
try {
    $LocalBranches = git branch 2>$null | Where-Object { $_ -match "feature/\d{3}-$Words" }
    foreach ($Branch in $LocalBranches) {
        $CleanBranch = $Branch -replace '^\s*[\*\s]*', ''
        if ($CleanBranch -match "^feature/\d{3}-$Words$" -and $CleanBranch -ne $NewBranchName) {
            $ConflictBranches += $CleanBranch
        }
    }
} catch {}

# Check remote branches
try {
    $RemoteBranches = git branch -r 2>$null | Where-Object { $_ -match "origin/feature/\d{3}-$Words" }
    foreach ($Branch in $RemoteBranches) {
        $CleanBranch = ($Branch -replace 'remotes/origin/', '').Trim()
        if ($CleanBranch -match "^feature/\d{3}-$Words$" -and $CleanBranch -ne $NewBranchName -and $CleanBranch -notin $ConflictBranches) {
            $ConflictBranches += $CleanBranch
        }
    }
} catch {}

# Handle branch conflicts
$ResolvedBranches = 0
foreach ($ConflictBranch in $ConflictBranches) {
    Write-Host ""
    Write-Host "🔄 Resolving branch conflict: $ConflictBranch" -ForegroundColor Yellow
    
    # Check if branch exists locally
    $LocalBranchExists = $false
    try {
        git show-ref --verify --quiet "refs/heads/$ConflictBranch" 2>$null
        $LocalBranchExists = $LASTEXITCODE -eq 0
    } catch {}
    
    if ($LocalBranchExists) {
        Write-Host "   📍 Local branch exists: $ConflictBranch" -ForegroundColor Gray
        
        # Get current branch before switching
        $OriginalBranch = git rev-parse --abbrev-ref HEAD
        
        # Checkout the conflict branch
        try {
            git checkout $ConflictBranch 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   🏷️  Renaming local branch: $ConflictBranch → $NewBranchName" -ForegroundColor Green
                git branch -m $NewBranchName
                
                # Remove old remote tracking
                try {
                    git config --unset "branch.$NewBranchName.remote" 2>$null
                    git config --unset "branch.$NewBranchName.merge" 2>$null
                } catch {}
                
                # Delete old remote branch
                try {
                    $RemoteExists = git ls-remote --heads origin $ConflictBranch 2>$null
                    if ($RemoteExists -and $LASTEXITCODE -eq 0) {
                        Write-Host "   🗑️  Deleting remote branch: origin/$ConflictBranch" -ForegroundColor Red
                        git push origin --delete $ConflictBranch 2>$null
                        if ($LASTEXITCODE -ne 0) {
                            Write-Host "   ⚠️  Failed to delete remote branch (may not have permission)" -ForegroundColor Yellow
                        }
                    }
                } catch {}
                
                # Set new upstream
                Write-Host "   🔗 Setting new upstream: origin/$NewBranchName" -ForegroundColor Cyan
                git push -u origin $NewBranchName 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "   ⚠️  Failed to set upstream (will be set on first push)" -ForegroundColor Yellow
                }
                
                $ResolvedBranches++
                Write-Host "   ✅ Branch renamed: $ConflictBranch → $NewBranchName" -ForegroundColor Green
                
                # Return to original branch
                try {
                    git checkout $OriginalBranch 2>$null
                } catch {}
            } else {
                Write-Host "   ❌ Failed to checkout $ConflictBranch" -ForegroundColor Red
            }
        } catch {
            Write-Host "   ❌ Failed to checkout $ConflictBranch" -ForegroundColor Red
        }
    } else {
        # Remote-only branch
        Write-Host "   🌐 Remote-only branch: $ConflictBranch" -ForegroundColor Gray
        
        try {
            git checkout -b $NewBranchName "origin/$ConflictBranch" 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Host "   🏷️  Created local branch: $NewBranchName from origin/$ConflictBranch" -ForegroundColor Green
                
                # Delete old remote branch
                try {
                    $RemoteExists = git ls-remote --heads origin $ConflictBranch 2>$null
                    if ($RemoteExists -and $LASTEXITCODE -eq 0) {
                        Write-Host "   🗑️  Deleting old remote branch: origin/$ConflictBranch" -ForegroundColor Red
                        git push origin --delete $ConflictBranch 2>$null
                        if ($LASTEXITCODE -ne 0) {
                            Write-Host "   ⚠️  Failed to delete remote branch (may not have permission)" -ForegroundColor Yellow
                        }
                    }
                } catch {}
                
                # Set new upstream
                git push -u origin $NewBranchName 2>$null
                if ($LASTEXITCODE -ne 0) {
                    Write-Host "   ⚠️  Failed to set upstream (will be set on first push)" -ForegroundColor Yellow
                }
                
                $ResolvedBranches++
                Write-Host "   ✅ Remote branch resolved: $ConflictBranch → $NewBranchName" -ForegroundColor Green
            } else {
                Write-Host "   ❌ Failed to checkout remote branch $ConflictBranch" -ForegroundColor Red
            }
        } catch {
            Write-Host "   ❌ Failed to checkout remote branch $ConflictBranch" -ForegroundColor Red
        }
    }
}

# Summary
if ($ConflictBranches.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ Phase 1: No branch conflicts detected for: $NewBranchName" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "🎯 Phase 1 Complete: Branch conflict resolution" -ForegroundColor Magenta
    Write-Host "   Conflicts found: $($ConflictBranches.Count)" -ForegroundColor Gray
    Write-Host "   Successfully resolved: $ResolvedBranches" -ForegroundColor Gray
    Write-Host "   Target branch ready: $NewBranchName" -ForegroundColor Gray
}

# Output the resolved branch name
Write-Output $NewBranchName
