# Resolve folder naming conflicts AFTER checkout (Phase 2) - PowerShell version
param(
    [Parameter(Mandatory=$true)]
    [string]$Words,
    
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

$SpecifyDir = Join-Path $RepoRoot ".specify"
if (-not (Test-Path $SpecifyDir)) {
    Write-Host "Creating .specify directory..." -ForegroundColor Yellow
    New-Item -ItemType Directory -Path $SpecifyDir -Force | Out-Null
}

$NewFeatureNumber = "{0:D3}" -f $NewBranchNumber
$NewFeatureDirName = "$NewFeatureNumber-$Words"
$NewFeatureDir = Join-Path $SpecifyDir $NewFeatureDirName

Write-Host "🔍 Phase 2: Checking for folder naming conflicts..." -ForegroundColor Cyan
Write-Host "   Target folder: .specify/$NewFeatureDirName" -ForegroundColor Gray

# Find conflicting folders
$ConflictFolders = @()
try {
    $Pattern = "\d{3}-$Words"
    $AllDirs = Get-ChildItem -Path $SpecifyDir -Directory -ErrorAction SilentlyContinue
    foreach ($Dir in $AllDirs) {
        if ($Dir.Name -match "^$Pattern$" -and $Dir.Name -ne $NewFeatureDirName) {
            $ConflictFolders += $Dir.FullName
        }
    }
} catch {}

# Handle folder conflicts
$ResolvedFolders = 0
foreach ($ConflictFolder in $ConflictFolders) {
    $ConflictName = Split-Path $ConflictFolder -Leaf
    Write-Host ""
    Write-Host "🔄 Resolving folder conflict: .specify/$ConflictName" -ForegroundColor Yellow
    
    if (-not (Test-Path $NewFeatureDir)) {
        Write-Host "   📁 Creating target directory: .specify/$NewFeatureDirName" -ForegroundColor Cyan
        New-Item -ItemType Directory -Path $NewFeatureDir -Force | Out-Null
    }
    
    # Merge files from conflict folder to new folder
    try {
        $ConflictFiles = Get-ChildItem -Path $ConflictFolder -File -Recurse -ErrorAction SilentlyContinue
        $MergedFiles = 0
        
        foreach ($File in $ConflictFiles) {
            $RelativePath = $File.FullName.Substring($ConflictFolder.Length + 1)
            $TargetPath = Join-Path $NewFeatureDir $RelativePath
            $TargetDir = Split-Path $TargetPath -Parent
            
            if (-not (Test-Path $TargetDir)) {
                New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            }
            
            if (-not (Test-Path $TargetPath)) {
                Write-Host "   📄 Merging file: $RelativePath" -ForegroundColor Gray
                Copy-Item $File.FullName $TargetPath
                $MergedFiles++
            } else {
                Write-Host "   ⚠️  File exists, skipping: $RelativePath" -ForegroundColor Yellow
            }
        }
        
        Write-Host "   ✅ Merged $MergedFiles files from .specify/$ConflictName" -ForegroundColor Green
        
        # Update file references
        $SpecFiles = Get-ChildItem -Path $NewFeatureDir -Filter "*.md" -Recurse -ErrorAction SilentlyContinue
        $UpdatedReferences = 0
        
        foreach ($SpecFile in $SpecFiles) {
            try {
                $Content = Get-Content $SpecFile.FullName -Raw -ErrorAction SilentlyContinue
                if ($Content) {
                    $OriginalContent = $Content
                    $Content = $Content -replace [regex]::Escape($ConflictName), $NewFeatureDirName
                    
                    if ($Content -ne $OriginalContent) {
                        Set-Content -Path $SpecFile.FullName -Value $Content -NoNewline
                        $UpdatedReferences++
                    }
                }
            } catch {
                Write-Host "   ⚠️  Failed to update references in: $($SpecFile.Name)" -ForegroundColor Yellow
            }
        }
        
        if ($UpdatedReferences -gt 0) {
            Write-Host "   🔗 Updated references in $UpdatedReferences files" -ForegroundColor Cyan
        }
        
        # Remove old folder
        Write-Host "   🗑️  Removing old folder: .specify/$ConflictName" -ForegroundColor Red
        Remove-Item $ConflictFolder -Recurse -Force -ErrorAction SilentlyContinue
        
        $ResolvedFolders++
        Write-Host "   ✅ Folder resolved: .specify/$ConflictName → .specify/$NewFeatureDirName" -ForegroundColor Green
        
    } catch {
        Write-Host "   ❌ Failed to resolve folder conflict: .specify/$ConflictName" -ForegroundColor Red
        Write-Host "   Error: $($_.Exception.Message)" -ForegroundColor Red
    }
}

# Summary
if ($ConflictFolders.Count -eq 0) {
    Write-Host ""
    Write-Host "✅ Phase 2: No folder conflicts detected for: .specify/$NewFeatureDirName" -ForegroundColor Green
} else {
    Write-Host ""
    Write-Host "🎯 Phase 2 Complete: Folder conflict resolution" -ForegroundColor Magenta
    Write-Host "   Conflicts found: $($ConflictFolders.Count)" -ForegroundColor Gray
    Write-Host "   Successfully resolved: $ResolvedFolders" -ForegroundColor Gray
    Write-Host "   Target folder ready: .specify/$NewFeatureDirName" -ForegroundColor Gray
}

# Ensure target directory exists
if (-not (Test-Path $NewFeatureDir)) {
    Write-Host ""
    Write-Host "📁 Creating target directory: .specify/$NewFeatureDirName" -ForegroundColor Cyan
    New-Item -ItemType Directory -Path $NewFeatureDir -Force | Out-Null
}

# Output the resolved folder path
Write-Output $NewFeatureDir
