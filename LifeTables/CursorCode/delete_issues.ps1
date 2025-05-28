# Delete issues with Q3-2025 label

# Check for GitHub token
$token = $env:GITHUB_TOKEN
if (-not $token) {
    Write-Error "Please set the GITHUB_TOKEN environment variable with your GitHub personal access token"
    Write-Error "You can create a token at: https://github.com/settings/tokens"
    exit 1
}

# Get repository information
$repoInfo = git config --get remote.origin.url
if (-not $repoInfo) {
    Write-Error "Not in a git repository. Please run this script from a git repository directory."
    exit 1
}

# Extract owner and repo name from git URL
$repoInfo = $repoInfo -replace ".*github.com[:/]", ""
$repoInfo = $repoInfo -replace "\.git$", ""
$owner, $repo = $repoInfo -split "/"

$headers = @{
    "Authorization" = "token $token"
    "Accept" = "application/vnd.github.v3+json"
}

# Get all issues with Q3-2025 label
$uri = "https://api.github.com/repos/$owner/$repo/issues?labels=Q3-2025&state=all"
Write-Host "Fetching issues with Q3-2025 label..." -ForegroundColor Yellow

try {
    $issues = Invoke-RestMethod -Uri $uri -Headers $headers
    $totalIssues = $issues.Count
    Write-Host "Found $totalIssues issues to delete" -ForegroundColor Yellow

    if ($totalIssues -eq 0) {
        Write-Host "No issues found with Q3-2025 label" -ForegroundColor Green
        exit 0
    }

    # Confirm deletion
    $confirmation = Read-Host "Are you sure you want to delete all $totalIssues issues? (y/N)"
    if ($confirmation -ne 'y') {
        Write-Host "Deletion cancelled" -ForegroundColor Yellow
        exit 0
    }

    # Delete each issue
    $successCount = 0
    $failureCount = 0
    $results = @()

    foreach ($issue in $issues) {
        try {
            Write-Host "Deleting issue: $($issue.title)" -ForegroundColor Yellow
            $deleteUri = "https://api.github.com/repos/$owner/$repo/issues/$($issue.number)"
            $response = Invoke-RestMethod -Uri $deleteUri -Method Patch -Headers $headers -Body '{"state":"closed"}' -ContentType "application/json"
            
            if ($response.state -eq 'closed') {
                Write-Host "Successfully closed issue: $($issue.title)" -ForegroundColor Green
                $results += [PSCustomObject]@{ Title = $issue.title; Status = 'Success'; Number = $issue.number }
                $successCount++
            }
        }
        catch {
            Write-Error "Error closing issue '$($issue.title)': $_"
            $results += [PSCustomObject]@{ Title = $issue.title; Status = 'Failed'; Number = $issue.number; Error = $_ }
            $failureCount++
        }
    }

    # Print summary
    Write-Host "`n==== Issue Deletion Summary ====" -ForegroundColor Yellow
    Write-Host "Total Issues: $totalIssues" -ForegroundColor White
    Write-Host "Successfully Closed: $successCount" -ForegroundColor Green
    Write-Host "Failed: $failureCount" -ForegroundColor Red
    Write-Host "`nDetailed Results:" -ForegroundColor Yellow
    foreach ($result in $results) {
        if ($result.Status -eq 'Success') {
            Write-Host "[SUCCESS] #$($result.Number) - $($result.Title)" -ForegroundColor Green
        } else {
            Write-Host "[FAILED]  #$($result.Number) - $($result.Title): $($result.Error)" -ForegroundColor Red
        }
    }
}
catch {
    Write-Error "Error fetching issues: $_"
    exit 1
} 