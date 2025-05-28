# Setup script for repository initialization
param(
    [string]$GitHubUsername = "",
    [string]$RepoName = "mortality-table-analysis"
)

# Function to check if a command exists
function Test-Command {
    param([string]$Command)
    $null -ne (Get-Command -Name $Command -ErrorAction SilentlyContinue)
}

# Function to display error and exit
function Write-ErrorAndExit {
    param([string]$Message)
    Write-Host "❌ Error: $Message" -ForegroundColor Red
    exit 1
}

# Function to display success
function Write-Success {
    param([string]$Message)
    Write-Host "✅ $Message" -ForegroundColor Green
}

# Check prerequisites
Write-Host "Checking prerequisites..." -ForegroundColor Cyan

# Check Git installation
if (-not (Test-Command "git")) {
    Write-ErrorAndExit "Git is not installed. Please install Git from https://git-scm.com/"
}
Write-Success "Git is installed"

# Check MATLAB installation
$MatlabPath = Get-Command matlab -ErrorAction SilentlyContinue
if (-not $MatlabPath) {
    Write-Host "⚠️ Warning: MATLAB command not found in PATH. Make sure MATLAB is installed." -ForegroundColor Yellow
} else {
    Write-Success "MATLAB is installed"
}

# Validate GitHub username
if (-not $GitHubUsername) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

if (-not $GitHubUsername) {
    Write-ErrorAndExit "GitHub username is required"
}

# Run initialization script
$InitScript = Join-Path $PSScriptRoot "init_repo.ps1"
if (-not (Test-Path $InitScript)) {
    Write-ErrorAndExit "Initialization script not found at: $InitScript"
}

Write-Host "`nStarting repository initialization..." -ForegroundColor Cyan
& $InitScript -GitHubUsername $GitHubUsername -RepoName $RepoName

if ($LASTEXITCODE -eq 0) {
    Write-Success "`nRepository setup completed successfully!"
} else {
    Write-ErrorAndExit "Repository setup failed"
} 