# Create a new feature branch and spec directory (PowerShell version)
param(
    [Parameter(Mandatory=$true)]
    [string]$FeatureDescription,
    
    [Parameter(Mandatory=$false)]
    [string]$TemplateDir = ""
)

$ErrorActionPreference = "Stop"

# Script directory for includes
$ScriptDir = Split-Path $MyInvocation.MyCommand.Path -Parent

# Validate git repository
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

# Check if we're on main branch
$CurrentBranch = git rev-parse --abbrev-ref HEAD
if ($CurrentBranch -ne "main") {
    Write-Error "ERROR: Must be on main branch. Currently on: $CurrentBranch"
    exit 1
}

# Source common PowerShell functions (if exists)
$CommonScript = Join-Path $ScriptDir "common.ps1"
if (Test-Path $CommonScript) {
    . $CommonScript
}

# Generate branch name components
$BranchName = $FeatureDescription.ToLower() -replace '[^a-z0-9]', '-' -replace '-+', '-' -replace '^-', '' -replace '-', ''
$Words = ($BranchName -split '-' | Where-Object { $_ -ne '' } | Select-Object -First 3) -join '-'

# Find next available branch number
$NextNumber = 1
try {
    $AllBranches = git branch -a 2>$null | ForEach-Object { $_ -replace '^\s*[\*\s]*', '' -replace 'remotes/', '' } | Sort-Object -Unique
    $FeatureBranches = $AllBranches | Where-Object { $_ -match '^(origin/)?feature/\d{3}-' }
    
    if ($FeatureBranches) {
        $UsedNumbers = $FeatureBranches | ForEach-Object {
            if ($_ -match '^(origin/)?feature/(\d{3})-') {
                [int]$Matches[2]
            }
        } | Sort-Object -Unique
        
        $NextNumber = 1
        foreach ($Num in $UsedNumbers) {
            if ($Num -eq $NextNumber) {
                $NextNumber++
            } else {
                break
            }
        }
    }
} catch {
    Write-Host "⚠️  Warning: Could not determine branch numbers, using 001" -ForegroundColor Yellow
    $NextNumber = 1
}

$FeatureNumber = "{0:D3}" -f $NextNumber
$FeatureDirName = "$FeatureNumber-$Words"
$BranchName = "feature/$FeatureDirName"

Write-Host "🚀 Creating new feature: $FeatureDescription" -ForegroundColor Cyan
Write-Host "   Branch: $BranchName" -ForegroundColor Gray
Write-Host "   Directory: .specify/$FeatureDirName" -ForegroundColor Gray
Write-Host ""

# PHASE 1: Resolve branch naming conflicts BEFORE checkout
Write-Host "🔄 Phase 1: Resolving branch naming conflicts..." -ForegroundColor Magenta

$Phase1Script = Join-Path $ScriptDir "resolve-branch-conflicts.ps1"
if (Test-Path $Phase1Script) {
    try {
        $ResolvedBranchName = & $Phase1Script -FeatureDescription $FeatureDescription -NewBranchNumber $NextNumber
        if ($LASTEXITCODE -eq 0 -and $ResolvedBranchName) {
            $BranchName = $ResolvedBranchName.Trim()
            Write-Host "✅ Phase 1 completed successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Phase 1 script returned an error, continuing with original branch name" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Phase 1 script failed, continuing with original branch name" -ForegroundColor Yellow
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Phase 1 script not found, skipping branch conflict resolution" -ForegroundColor Yellow
}

Write-Host ""

# Create and checkout new branch
Write-Host "🌿 Creating and checking out branch: $BranchName" -ForegroundColor Cyan
try {
    git checkout -b $BranchName 2>$null
    if ($LASTEXITCODE -ne 0) {
        Write-Error "ERROR: Failed to create branch $BranchName"
        exit 1
    }
    Write-Host "✅ Successfully created and checked out: $BranchName" -ForegroundColor Green
} catch {
    Write-Error "ERROR: Failed to create branch $BranchName"
    exit 1
}

Write-Host ""

# PHASE 2: Resolve folder naming conflicts AFTER checkout
Write-Host "🔄 Phase 2: Resolving folder naming conflicts..." -ForegroundColor Magenta

$SpecifyDir = Join-Path $RepoRoot ".specify"
$FeatureDir = Join-Path $SpecifyDir $FeatureDirName

$Phase2Script = Join-Path $ScriptDir "resolve-folder-conflicts.ps1"
if (Test-Path $Phase2Script) {
    try {
        $ResolvedFeatureDir = & $Phase2Script -Words $Words -NewBranchNumber $NextNumber
        if ($LASTEXITCODE -eq 0 -and $ResolvedFeatureDir) {
            $FeatureDir = $ResolvedFeatureDir.Trim()
            Write-Host "✅ Phase 2 completed successfully" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Phase 2 script returned an error, continuing with original folder" -ForegroundColor Yellow
        }
    } catch {
        Write-Host "⚠️  Phase 2 script failed, continuing with original folder" -ForegroundColor Yellow
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
} else {
    Write-Host "⚠️  Phase 2 script not found, skipping folder conflict resolution" -ForegroundColor Yellow
}

# Ensure feature directory exists
if (-not (Test-Path $FeatureDir)) {
    Write-Host "📁 Creating feature directory: .specify/$FeatureDirName" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $FeatureDir -Force | Out-Null
}

Write-Host ""

# Copy template files if specified
if ($TemplateDir -and (Test-Path $TemplateDir)) {
    Write-Host "📋 Copying template files from: $TemplateDir" -ForegroundColor Cyan
    try {
        Copy-Item "$TemplateDir\*" $FeatureDir -Recurse -Force
        Write-Host "✅ Template files copied successfully" -ForegroundColor Green
    } catch {
        Write-Host "⚠️  Failed to copy template files: $($_.Exception.Message)" -ForegroundColor Yellow
    }
    Write-Host ""
}

# Create initial files
$SpecifyFile = Join-Path $FeatureDir "specify-request.md"
$InitialContent = @"
# Feature Request: $FeatureDescription

Branch: $BranchName
Feature Directory: .specify/$FeatureDirName
Feature Number: $FeatureNumber

## Description
[Describe the feature request here]

## Acceptance Criteria
- [ ] Criterion 1
- [ ] Criterion 2
- [ ] Criterion 3

## Technical Notes
[Add any technical considerations here]
"@

Set-Content -Path $SpecifyFile -Value $InitialContent
Write-Host "📝 Created initial specify-request.md" -ForegroundColor Green

# Output JSON for script chaining
$ResultJson = @{
    branch_name = $BranchName
    feature_dir = $FeatureDir
    feature_number = $FeatureNumber
    feature_dir_name = $FeatureDirName
    words = $Words
    description = $FeatureDescription
} | ConvertTo-Json -Compress

Write-Host ""
Write-Host "🎉 Feature setup complete!" -ForegroundColor Green
Write-Host "   Branch: $BranchName" -ForegroundColor Gray
Write-Host "   Directory: .specify/$FeatureDirName" -ForegroundColor Gray
Write-Host "   Ready for development!" -ForegroundColor Gray
Write-Host ""

# Output JSON result
Write-Output $ResultJson