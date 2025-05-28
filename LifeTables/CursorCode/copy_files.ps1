# Script to copy and organize project files
param(
    [string]$SourceDir = "G:\My Drive\Kaparra Software\Rates Analysis\Resources",
    [string]$ProjectRoot = $PSScriptRoot,
    [switch]$DryRun
)

# Function to display status
function Write-Status {
    param([string]$Message)
    Write-Host "➡️ $Message" -ForegroundColor Cyan
}

# Function to copy files with confirmation
function Copy-FileWithConfirmation {
    param(
        [string]$Source,
        [string]$Destination,
        [string]$Description
    )
    
    if (Test-Path $Source) {
        Write-Status "Copying $Description..."
        if ($DryRun) {
            Write-Host "📋 Would copy: $Source -> $Destination" -ForegroundColor Yellow
        } else {
            Copy-Item -Path $Source -Destination $Destination -Force
            Write-Host "✅ Copied: $Description" -ForegroundColor Green
        }
    } else {
        Write-Host "⚠️ Warning: Source file not found - $Source" -ForegroundColor Yellow
    }
}

# Create necessary directories if they don't exist
$Directories = @(
    "lifeandothercontingencyclasses",
    "+utilities",
    "LifeTables",
    ".github/ISSUE_TEMPLATE"
)

foreach ($Dir in $Directories) {
    $TargetDir = Join-Path $ProjectRoot $Dir
    if (-not (Test-Path $TargetDir)) {
        if ($DryRun) {
            Write-Host "📋 Would create directory: $TargetDir" -ForegroundColor Yellow
        } else {
            New-Item -ItemType Directory -Path $TargetDir -Force | Out-Null
            Write-Status "Created directory: $Dir"
        }
    }
}

# Copy core class files
Write-Status "Copying core class files..."
$CoreFiles = @{
    "MortalityTable.m" = "Base mortality table class"
    "BasicMortalityTable.m" = "Basic mortality table implementation"
    "MortalityTableFactory.m" = "Mortality table factory class"
    "testMortalityTableSystem.m" = "System test script"
    "testMortalityTableReading.m" = "Reading test script"
}

foreach ($File in $CoreFiles.Keys) {
    $Source = Join-Path $SourceDir "lifeandothercontingencyclasses" $File
    $Destination = Join-Path $ProjectRoot "lifeandothercontingencyclasses" $File
    Copy-FileWithConfirmation -Source $Source -Destination $Destination -Description $CoreFiles[$File]
}

# Copy utilities
Write-Status "Copying utility files..."
$UtilsSource = Join-Path $SourceDir "+utilities" "LifeTableUtilities.m"
$UtilsDestination = Join-Path $ProjectRoot "+utilities" "LifeTableUtilities.m"
Copy-FileWithConfirmation -Source $UtilsSource -Destination $UtilsDestination -Description "Life table utilities"

# Copy documentation files
Write-Status "Copying documentation files..."
$DocFiles = @{
    "README.md" = "Project README"
    "CONTRIBUTING.md" = "Contributing guidelines"
    "LICENSE.md" = "License file"
    "PROJECT_PLAN.md" = "Project plan"
}

foreach ($File in $DocFiles.Keys) {
    $Source = Join-Path $ProjectRoot $File
    Copy-FileWithConfirmation -Source $Source -Destination (Join-Path $ProjectRoot $File) -Description $DocFiles[$File]
}

# Copy issue templates
Write-Status "Copying issue templates..."
$TemplateFiles = @{
    "bug_report.md" = "Bug report template"
    "feature_request.md" = "Feature request template"
    "documentation.md" = "Documentation issue template"
}

foreach ($File in $TemplateFiles.Keys) {
    $Source = Join-Path $ProjectRoot ".github" "ISSUE_TEMPLATE" $File
    $Destination = Join-Path $ProjectRoot ".github" "ISSUE_TEMPLATE" $File
    Copy-FileWithConfirmation -Source $Source -Destination $Destination -Description $TemplateFiles[$File]
}

# Copy life tables (if they exist)
Write-Status "Copying life tables..."
$LifeTableFiles = @(
    "Australian_Life_Tables_2015-17_Males.xlsx",
    "Australian_Life_Tables_2015-17_Females.xlsx",
    "Australian_Life_Tables_2015-17.mat",
    "Improvement_factors_2015-17.xlsx"
)

foreach ($File in $LifeTableFiles) {
    $Source = Join-Path $SourceDir "LifeTables" $File
    $Destination = Join-Path $ProjectRoot "LifeTables" $File
    Copy-FileWithConfirmation -Source $Source -Destination $Destination -Description "Life table data: $File"
}

Write-Status "File organization complete!"
Write-Host @"

🎉 Files have been organized successfully!

Project structure:
$ProjectRoot
├── lifeandothercontingencyclasses/
│   ├── MortalityTable.m
│   ├── BasicMortalityTable.m
│   ├── MortalityTableFactory.m
│   ├── testMortalityTableSystem.m
│   └── testMortalityTableReading.m
├── +utilities/
│   └── LifeTableUtilities.m
├── LifeTables/
│   ├── Australian_Life_Tables_2015-17_Males.xlsx
│   ├── Australian_Life_Tables_2015-17_Females.xlsx
│   └── Improvement_factors_2015-17.xlsx
└── .github/
    └── ISSUE_TEMPLATE/
        ├── bug_report.md
        ├── feature_request.md
        └── documentation.md

Next steps:
1. Review the copied files
2. Run the test scripts to verify functionality
3. Commit the changes to your repository

"@ -ForegroundColor Green

if ($DryRun) {
    Write-Host "`n🔍 This was a dry run - no files were actually copied" -ForegroundColor Yellow
    Write-Host "To perform the actual copy, run the script without the -DryRun parameter" -ForegroundColor Yellow
} 