#!/usr/bin/env pwsh
# Common PowerShell functions analogous to common.sh (moved to powershell/)

function Get-RepoRoot {
    git rev-parse --show-toplevel
}

function Get-CurrentBranch {
    git rev-parse --abbrev-ref HEAD
}

function Test-FeatureBranch {
    param([string]$Branch)
    if ($Branch -notmatch '^feature/[0-9]{3}-') {
        Write-Output "ERROR: Not on a feature branch. Current branch: $Branch"
        Write-Output "Feature branches should be named like: feature/001-feature-name"
        return $false
    }
    return $true
}

function Get-FeatureDir {
    param([string]$RepoRoot, [string]$Branch)
    # Extract feature directory name from branch (feature/001-name -> 001-name)
    if ($Branch -match '^feature/(.+)$') {
        $FeatureDirName = $matches[1]
        Join-Path $RepoRoot "specs/$FeatureDirName"
    } else {
        Join-Path $RepoRoot "specs/$Branch"
    }
}

function Get-FeaturePathsEnv {
    $repoRoot = Get-RepoRoot
    $currentBranch = Get-CurrentBranch
    $featureDir = Get-FeatureDir -RepoRoot $repoRoot -Branch $currentBranch
    [PSCustomObject]@{
        REPO_ROOT       = $repoRoot
        CURRENT_BRANCH  = $currentBranch
        FEATURE_DIR     = $featureDir
        FEATURE_SPEC    = Join-Path $featureDir 'spec.md'
        IMPL_PLAN       = Join-Path $featureDir 'feature-planning.md'
        TASKS           = Join-Path $featureDir 'task-breakdown.md'
        RESEARCH        = Join-Path $featureDir 'research.md'
        DATA_MODEL      = Join-Path $featureDir 'data-model.md'
        QUICKSTART      = Join-Path $featureDir 'quickstart.md'
        CONTRACTS_DIR   = Join-Path $featureDir 'contracts'
    }
}

function Test-FileExists {
    param([string]$Path, [string]$Description)
    if (Test-Path -Path $Path -PathType Leaf) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

function Test-DirHasFiles {
    param([string]$Path, [string]$Description)
    if ((Test-Path -Path $Path -PathType Container) -and (Get-ChildItem -Path $Path -ErrorAction SilentlyContinue | Where-Object { -not $_.PSIsContainer } | Select-Object -First 1)) {
        Write-Output "  ✓ $Description"
        return $true
    } else {
        Write-Output "  ✗ $Description"
        return $false
    }
}

# Git timing safety functions (added to fix timing issues with file system)

# Safe checkout with timing to prevent file system issues
function Safe-Checkout {
    param(
        [Parameter(Mandatory=$true)]
        [string]$BranchName,
        
        [Parameter(Mandatory=$false)]
        [int]$TimeoutMs = 300
    )
    
    Write-Host "[common] Switching to branch: $BranchName" -ForegroundColor Cyan
    
    try {
        # Perform checkout
        $checkoutResult = git checkout $BranchName 2>$null
        if ($LASTEXITCODE -eq 0) {
            # Wait for file system to stabilize
            $sleepTime = $TimeoutMs / 1000.0
            Start-Sleep -Seconds $sleepTime
            
            # CRITICAL: Force Git status refresh to prevent untracked file bug
            Write-Host "[common] Refreshing Git working directory status..." -ForegroundColor Cyan
            $statusOutput = git status --porcelain
        
        if ([string]::IsNullOrWhiteSpace($statusOutput)) {
            Write-Host "[common] ✅ Branch checkout successful, working tree clean" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[common] ⚠️ Warning: Working tree not clean after checkout" -ForegroundColor Yellow
            Write-Host $statusOutput
            return $false
        }
    } catch {
        Write-Host "[common] ❌ Exception during checkout: $_" -ForegroundColor Red
        return $false
    }

# Verify current branch matches expected
function Verify-Branch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$ExpectedBranch
    )
    
    try {
        $currentBranch = Get-CurrentBranch
        if ($currentBranch -eq $ExpectedBranch) {
            Write-Host "[common] ✅ On correct branch: $currentBranch" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[common] ❌ Branch mismatch. Expected: $ExpectedBranch, Current: $currentBranch" -ForegroundColor Red
            return $false
        }
    } catch {
        Write-Host "[common] ❌ Exception during branch verification: $_" -ForegroundColor Red
        return $false
    }
}

# Safe branch switching with verification
function Switch-ToBranch {
    param(
        [Parameter(Mandatory=$true)]
        [string]$TargetBranch,
        
        [Parameter(Mandatory=$false)]
        [int]$TimingMs = 300
    )
    
    # Check if already on target branch
    if (Verify-Branch -ExpectedBranch $TargetBranch) {
        Write-Host "[common] Already on target branch: $TargetBranch" -ForegroundColor Green
        return $true
    }
    
    # Perform safe checkout
    if (Safe-Checkout -BranchName $TargetBranch -TimeoutMs $TimingMs) {
        # Double-verify we're on the right branch
        return Verify-Branch -ExpectedBranch $TargetBranch
    } else {
        return $false
    }
}

# Safe commit with Git status refresh to prevent untracked file bug
function Safe-Commit {
    param(
        [Parameter(Mandatory=$true)]
        [string]$CommitMessage
    )
    
    Write-Host "[common] Committing changes: $CommitMessage" -ForegroundColor Cyan
    
    try {
        # Add all changes
        $addResult = git add .
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[common] Changes staged successfully" -ForegroundColor Green
        } else {
            Write-Host "[common] ❌ Failed to stage changes" -ForegroundColor Red
            return $false
        }
        
        # Commit changes
        $commitResult = git commit -m $CommitMessage
        if ($LASTEXITCODE -eq 0) {
            Write-Host "[common] ✅ Commit successful" -ForegroundColor Green
        } else {
            Write-Host "[common] ❌ Failed to commit changes" -ForegroundColor Red
            return $false
        }
        
        # CRITICAL: Force Git status refresh after commit to prevent untracked file bug
        Write-Host "[common] Refreshing Git working directory status after commit..." -ForegroundColor Cyan
        $statusOutput = git status --porcelain
        
        if ([string]::IsNullOrWhiteSpace($statusOutput)) {
            Write-Host "[common] ✅ Working tree clean after commit" -ForegroundColor Green
            return $true
        } else {
            Write-Host "[common] ⚠️ Warning: Working tree not clean after commit" -ForegroundColor Yellow
            Write-Host $statusOutput
            return $true  # Don't fail on warnings, just inform
        }
    } catch {
        Write-Host "[common] ❌ Exception during commit: $_" -ForegroundColor Red
        return $false
    }
}