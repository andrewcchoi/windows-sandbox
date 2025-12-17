# validate-schemas.ps1
# Validates JSON files against their schemas

param(
    [switch]$Verbose
)

$ErrorActionPreference = "Stop"
$repoRoot = "/workspace"

Write-Host "=== JSON Schema Validator ===" -ForegroundColor Cyan
Write-Host ""

$errorCount = 0

# Function to validate version pattern
function Test-VersionFormat {
    param([string]$Version)
    return $Version -match '^\d+\.\d+\.\d+$'
}

# Validate INVENTORY.json
Write-Host "Validating INVENTORY.json..." -ForegroundColor Cyan
$inventoryPath = Join-Path $repoRoot "docs/repo-keeper/INVENTORY.json"

if (Test-Path $inventoryPath) {
    try {
        $inventory = Get-Content $inventoryPath -Raw | ConvertFrom-Json

        # Check required fields
        if (-not $inventory.version) {
            Write-Host "  [ERROR] Missing required field: version" -ForegroundColor Red
            $errorCount++
        } elseif (-not (Test-VersionFormat $inventory.version)) {
            Write-Host "  [ERROR] Invalid version format: $($inventory.version)" -ForegroundColor Red
            $errorCount++
        } else {
            Write-Host "  [OK] version: $($inventory.version)" -ForegroundColor Green
        }

        if (-not $inventory.last_updated) {
            Write-Host "  [ERROR] Missing required field: last_updated" -ForegroundColor Red
            $errorCount++
        } elseif ($inventory.last_updated -notmatch '^\d{4}-\d{2}-\d{2}$') {
            Write-Host "  [ERROR] Invalid date format: $($inventory.last_updated) (expected YYYY-MM-DD)" -ForegroundColor Red
            $errorCount++
        } else {
            Write-Host "  [OK] last_updated: $($inventory.last_updated)" -ForegroundColor Green
        }

        if (-not $inventory.repository) {
            Write-Host "  [ERROR] Missing required field: repository" -ForegroundColor Red
            $errorCount++
        } else {
            Write-Host "  [OK] repository: $($inventory.repository)" -ForegroundColor Green
        }

        # Check arrays
        if ($inventory.skills) {
            Write-Host "  [OK] skills: $($inventory.skills.Count) entries" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] No skills defined" -ForegroundColor Yellow
        }

        if ($inventory.commands) {
            Write-Host "  [OK] commands: $($inventory.commands.Count) entries" -ForegroundColor Green
        } else {
            Write-Host "  [WARNING] No commands defined" -ForegroundColor Yellow
        }

    } catch {
        Write-Host "  [ERROR] Invalid JSON syntax: $_" -ForegroundColor Red
        $errorCount++
    }
} else {
    Write-Host "  [ERROR] INVENTORY.json not found" -ForegroundColor Red
    $errorCount++
}

# Validate data files
Write-Host ""
Write-Host "Validating data files..." -ForegroundColor Cyan

$dataPath = Join-Path $repoRoot "data"
$dataFiles = @()

if (Test-Path $dataPath) {
    $dataFiles = Get-ChildItem -Path $dataPath -Filter "*.json" -ErrorAction SilentlyContinue
}

foreach ($file in $dataFiles) {
    try {
        $data = Get-Content $file.FullName -Raw | ConvertFrom-Json

        if ($data.version) {
            if (Test-VersionFormat $data.version) {
                Write-Host "  [OK] $($file.Name): version $($data.version)" -ForegroundColor Green
            } else {
                Write-Host "  [ERROR] $($file.Name): Invalid version format: $($data.version)" -ForegroundColor Red
                $errorCount++
            }
        } else {
            if ($Verbose) {
                Write-Host "  [INFO] $($file.Name): no version field" -ForegroundColor Gray
            }
        }
    } catch {
        Write-Host "  [ERROR] $($file.Name): Invalid JSON syntax" -ForegroundColor Red
        $errorCount++
    }
}

# Summary
Write-Host ""
Write-Host "=== Summary ===" -ForegroundColor Cyan
if ($errorCount -eq 0) {
    Write-Host "✓ All schemas valid!" -ForegroundColor Green
    Write-Host "Total errors: $errorCount" -ForegroundColor Green
    exit 0
} else {
    Write-Host "✗ Schema validation failed!" -ForegroundColor Red
    Write-Host "Total errors: $errorCount" -ForegroundColor Red
    exit 1
}
