# Repository initialization script
param(
    [string]$RepoName = "mortality-table-analysis",
    [string]$GitHubUsername = "",
    [string]$ProjectRoot = $PSScriptRoot
)

# Function to create directory if it doesn't exist
function EnsureDirectory {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -ItemType Directory -Path $Path -Force | Out-Null
    }
}

# Function to display status
function Write-Status {
    param([string]$Message)
    Write-Host "➡️ $Message" -ForegroundColor Cyan
}

# Validate GitHub username
if (-not $GitHubUsername) {
    $GitHubUsername = Read-Host "Enter your GitHub username"
}

Write-Status "Initializing repository structure..."

# Create directory structure
$Directories = @(
    "lifeandothercontingencyclasses",
    "+utilities",
    "LifeTables",
    "docs/examples",
    ".github/ISSUE_TEMPLATE"
)

foreach ($Dir in $Directories) {
    EnsureDirectory (Join-Path $ProjectRoot $Dir)
}

Write-Status "Initializing Git repository..."

# Initialize Git repository if not already initialized
if (-not (Test-Path (Join-Path $ProjectRoot ".git"))) {
    git init
}

# Update README with correct username
$ReadmePath = Join-Path $ProjectRoot "README.md"
if (Test-Path $ReadmePath) {
    (Get-Content $ReadmePath) -replace "yourusername", $GitHubUsername | Set-Content $ReadmePath
}

# Update CONTRIBUTING with correct username
$ContributingPath = Join-Path $ProjectRoot "CONTRIBUTING.md"
if (Test-Path $ContributingPath) {
    (Get-Content $ContributingPath) -replace "yourusername", $GitHubUsername | Set-Content $ContributingPath
}

Write-Status "Creating .gitignore..."

# Create .gitignore for MATLAB
@"
# MATLAB specific
*.asv
*.m~
*.mat
*.mex*
slprj/
sccprj/
codegen/
*.slxc

# Editor specific
*.swp
*~

# OS specific
.DS_Store
Thumbs.db

# Custom
/LifeTables/*.xlsx
"@ | Set-Content (Join-Path $ProjectRoot ".gitignore")

Write-Status "Setting up Git configuration..."

# Configure Git
git config core.autocrlf true
git config core.safecrlf warn

Write-Status "Adding files to Git..."

# Add all files
git add .

Write-Status "Creating initial commit..."

# Create initial commit
git commit -m "Initial commit: Project setup with core functionality"

Write-Status "Setting up remote repository..."

# Add remote repository
$RemoteUrl = "https://github.com/$GitHubUsername/$RepoName.git"
git remote add origin $RemoteUrl

Write-Status "Repository initialization complete!"
Write-Host @"

🎉 Repository initialized successfully!

Next steps:
1. Create a new repository on GitHub: https://github.com/new
2. Push your code:
   git push -u origin main

Your repository URL will be: $RemoteUrl

"@ -ForegroundColor Green 