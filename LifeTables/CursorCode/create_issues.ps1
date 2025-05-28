# Create issues for Mortality Table Analysis project

# USAGE:
# - Optionally add 'milestone' and 'assignees' fields to any issue in the $issues array.
#   - 'milestone' should be the milestone number (not title).
#   - 'assignees' should be an array of GitHub usernames.
#
# Example:
#   @{ title = "..."; body = "..."; labels = @("..."); milestone = 1; assignees = @("username1", "username2") }
#
# To get milestone numbers, use:
#   curl -H "Authorization: token <TOKEN>" https://api.github.com/repos/<owner>/<repo>/milestones

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

# Function to handle API calls with retries
function Invoke-GitHubAPI {
    param (
        [string]$Uri,
        [string]$Method = "Get",
        [object]$Body = $null,
        [int]$MaxRetries = 3,
        [int]$RetryDelaySeconds = 5
    )
    
    $attempt = 0
    while ($attempt -lt $MaxRetries) {
        try {
            $params = @{
                Uri = $Uri
                Method = $Method
                Headers = $headers
            }
            
            if ($Body) {
                $params.Body = $Body
                $params.ContentType = "application/json"
            }
            
            $response = Invoke-RestMethod @params
            
            # Check if response is HTML instead of JSON
            if ($response -is [string] -and $response.Contains("<!DOCTYPE html>")) {
                throw "Received HTML response instead of JSON. This might indicate an authentication issue."
            }
            
            return $response
        }
        catch {
            $attempt++
            
            # Check for rate limiting
            $errorDetails = $_.Exception.Response
            if ($errorDetails) {
                $rateLimitRemaining = $errorDetails.Headers["X-RateLimit-Remaining"]
                $rateLimitReset = $errorDetails.Headers["X-RateLimit-Reset"]
                
                if ($rateLimitRemaining -eq "0") {
                    $resetTime = [DateTimeOffset]::FromUnixTimeSeconds($rateLimitReset).DateTime
                    $waitTime = ($resetTime - (Get-Date)).TotalSeconds + 10
                    Write-Host "Rate limit exceeded. Waiting until $resetTime to retry..." -ForegroundColor Yellow
                    Start-Sleep -Seconds $waitTime
                    continue
                }
            }
            
            if ($attempt -eq $MaxRetries) {
                throw $_
            }
            
            if ($errorDetails -and $errorDetails.StatusCode -eq 504) {
                Write-Host "Gateway timeout, retrying in $RetryDelaySeconds seconds... (Attempt $attempt of $MaxRetries)" -ForegroundColor Yellow
                Start-Sleep -Seconds $RetryDelaySeconds
                continue
            }
            
            # If it's not a timeout or rate limit, rethrow the error
            throw $_
        }
    }
}

# Verify labels exist
Write-Host "Verifying labels..." -ForegroundColor Yellow
$requiredLabels = @("enhancement", "Q3-2025", "script", "documentation", "testing")
$existingLabels = @()

try {
    $existingLabels = Invoke-GitHubAPI -Uri "https://api.github.com/repos/$owner/$repo/labels"
    $existingLabelNames = $existingLabels | ForEach-Object { $_.name }
} catch {
    Write-Warning "Could not fetch existing labels: $_"
    $existingLabelNames = @()
}

foreach ($label in $requiredLabels) {
    if ($label -notin $existingLabelNames) {
        Write-Host "Creating label: $label" -ForegroundColor Yellow
        $labelData = @{
            name = $label
            color = switch ($label) {
                "enhancement" { "a2eeef" }
                "Q3-2025" { "0052cc" }
                "script" { "d73a4a" }
                "documentation" { "0075ca" }
                "testing" { "f9d0c4" }
                default { "ededed" }
            }
            description = switch ($label) {
                "enhancement" { "New feature or request" }
                "Q3-2025" { "Target completion in Q3 2025" }
                "script" { "Script-related tasks" }
                "documentation" { "Documentation updates" }
                "testing" { "Testing related tasks" }
                default { "" }
            }
        } | ConvertTo-Json

        try {
            Invoke-GitHubAPI -Uri "https://api.github.com/repos/$owner/$repo/labels" -Method Post -Body $labelData
            Write-Host "Successfully created label: $label" -ForegroundColor Green
        } catch {
            $errorDetails = $_.Exception.Response
            if ($errorDetails -and $errorDetails.StatusCode -eq 422) {
                $errorBody = $null
                try {
                    $reader = New-Object System.IO.StreamReader($errorDetails.GetResponseStream())
                    $errorBody = $reader.ReadToEnd() | ConvertFrom-Json
                    $reader.Close()
                    
                    if ($errorBody.errors[0].code -eq "already_exists") {
                        Write-Host "Label '$label' already exists, skipping creation" -ForegroundColor Yellow
                        continue
                    }
                } catch {
                    Write-Warning "Could not parse error response: $_"
                }
            }
            Write-Error "Failed to create label '$label': $_"
        }
    } else {
        Write-Host "Label '$label' already exists, skipping creation" -ForegroundColor Yellow
    }
}

$issues = @(
    @{
        title = "Mortality Data Cache Integration"
        body = @"
## Overview
Implement comprehensive mortality data cache integration for efficient data access and improved performance.

### Tasks
- [ ] Data Model Analysis and Documentation
  - Document current mortality table access patterns
  - Map data flow from cache to annuity calculations
  - Identify required changes to existing classes:
    - `MortalityDataSource` interface modifications
    - `AustralianGovernmentActuarySource` cache integration
    - `SingleLifeTimeAnnuity` mortality table access
    - `Person` class mortality data handling
  - Create data model diagrams showing:
    - Current architecture
    - Proposed cache integration
    - Data flow patterns
  - Document cache access patterns and interfaces

- [ ] Cache Integration with Annuity Classes
  - Implement cache access in SingleLifeTimeAnnuity initialization
  - Add cache validation and refresh mechanisms
  - Optimize cache usage for multiple annuity calculations

- [ ] Performance Optimization
  - Implement batch mortality table loading
  - Add cache preloading for common scenarios
  - Optimize memory usage for large annuity portfolios

- [ ] Error Handling and Recovery
  - Add cache miss handling
  - Implement fallback mechanisms
  - Add cache consistency checks

- [ ] Monitoring and Maintenance
  - Add cache usage metrics
  - Implement cache cleanup strategies
  - Add cache health monitoring

### Dependencies
- Requires completion of basic AGA data source integration
- Needs access to annuity class implementations

### Acceptance Criteria
1. Cache system successfully integrated with annuity calculations
2. Performance improvements demonstrated through benchmarks
3. Comprehensive error handling implemented
4. Monitoring system in place
5. Documentation completed

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    },
    @{
        title = "Data Source Layer Enhancement"
        body = @"
## Overview
Enhance the data source layer to support multiple data sources and improve data handling capabilities.

### Tasks
- [ ] Additional Data Source Implementations
  - Design and implement new data source classes
  - Add support for different data formats
  - Implement data validation for new sources

- [ ] Data Source Factory Pattern
  - Implement factory pattern for data source creation
  - Add configuration management
  - Implement source selection logic

### Dependencies
- Requires completion of basic AGA data source integration
- Needs data format specifications for new sources

### Acceptance Criteria
1. Multiple data sources successfully implemented
2. Factory pattern working correctly
3. Configuration system in place
4. Documentation completed

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    },
    @{
        title = "Data Processing Layer Enhancement"
        body = @"
## Overview
Enhance the data processing layer with advanced validation and transformation capabilities.

### Tasks
- [ ] Advanced Validation Rules
  - Implement comprehensive data validation
  - Add custom validation rules
  - Create validation reporting system

- [ ] Data Transformation Pipeline
  - Implement data transformation framework
  - Add support for multiple transformation types
  - Create transformation validation

- [ ] Performance Optimization
  - Optimize data processing algorithms
  - Implement parallel processing where applicable
  - Add performance monitoring

### Dependencies
- Requires completion of basic data validation
- Needs performance requirements specification

### Acceptance Criteria
1. Advanced validation system implemented
2. Transformation pipeline working correctly
3. Performance improvements demonstrated
4. Documentation completed

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    },
    @{
        title = "GitHub Issue Creation Script Enhancement"
        body = @"
## Overview
Enhance the GitHub issue creation script with additional features for better usability and maintainability.

### Tasks
- [ ] Milestone Support
  - Add milestone number validation
  - Implement milestone lookup functionality
  - Add milestone creation if not exists
  - Document milestone usage in script

- [ ] Assignee Management
  - Add assignee validation
  - Implement user lookup functionality
  - Add support for team assignments
  - Document assignee usage in script

- [ ] Project Integration
  - Add support for GitHub Projects
  - Implement column assignment
  - Add project creation if not exists
  - Document project integration in script

- [ ] Dry Run Mode
  - Add --dry-run flag
  - Implement issue preview functionality
  - Add validation without creation
  - Document dry run usage

- [ ] External Data Support
  - Add CSV input support
  - Add JSON input support
  - Implement data validation
  - Add template support
  - Document external data usage

- [ ] Rate Limit Handling
  - Add rate limit detection
  - Implement automatic retry with backoff
  - Add rate limit status reporting
  - Document rate limit handling

- [ ] Enhanced Error Reporting
  - Add detailed error messages
  - Implement error logging
  - Add error recovery options
  - Document error handling

### Dependencies
- Requires GitHub API access
- Needs PowerShell 5.1 or later

### Acceptance Criteria
1. All new features implemented and tested
2. Documentation completed
3. Error handling robust
4. Performance optimized
5. User feedback improved

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025", "script")
    },
    @{
        title = "Script Documentation and Testing"
        body = @"
## Overview
Create comprehensive documentation and testing suite for the GitHub issue creation script.

### Tasks
- [ ] Documentation
  - Create README.md
  - Add usage examples
  - Document all features
  - Add troubleshooting guide
  - Create contribution guidelines

- [ ] Testing
  - Create unit tests
  - Add integration tests
  - Implement CI/CD pipeline
  - Add test documentation
  - Create test data sets

- [ ] Examples
  - Create example configurations
  - Add sample issue templates
  - Create example workflows
  - Document best practices

### Dependencies
- Requires completion of script enhancements
- Needs testing framework setup

### Acceptance Criteria
1. Documentation complete and clear
2. Test coverage > 80%
3. Examples working and documented
4. CI/CD pipeline operational

### Timeline
Target completion: Q3 2025
"@
        labels = @("documentation", "testing", "Q3-2025")
    },
    @{
        title = "Data Validation Enhancement"
        body = @"
## Overview
Implement comprehensive data validation rules and reporting system.

### Tasks
- [ ] Implement comprehensive validation rules
  - Add validation for data types
  - Add range validation
  - Add consistency checks
  - Add format validation

- [ ] Add validation reporting
  - Create validation report format
  - Add detailed error messages
  - Implement report generation
  - Add report export options

- [ ] Create validation test suite
  - Add unit tests for validation rules
  - Add integration tests
  - Add performance tests
  - Document test cases

### Dependencies
- Requires completion of basic data validation
- Needs test framework setup

### Acceptance Criteria
1. All validation rules implemented and tested
2. Reporting system working correctly
3. Test suite complete and passing
4. Documentation updated

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025", "testing")
    },
    @{
        title = "Error Handling Enhancement"
        body = @"
## Overview
Enhance error handling and recovery mechanisms throughout the system.

### Tasks
- [ ] Enhance error recovery
  - Implement automatic retry mechanisms
  - Add fallback options
  - Create recovery procedures
  - Add error logging

- [ ] Improve error messages
  - Add detailed error descriptions
  - Include troubleshooting steps
  - Add error codes
  - Create error documentation

- [ ] Add error tracking
  - Implement error logging
  - Add error analytics
  - Create error dashboard
  - Add alert system

### Dependencies
- Requires completion of basic error handling
- Needs logging system setup

### Acceptance Criteria
1. Error recovery system implemented
2. Error messages clear and helpful
3. Error tracking system working
4. Documentation complete

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    },
    @{
        title = "Performance Optimization"
        body = @"
## Overview
Optimize system performance and add monitoring capabilities.

### Tasks
- [ ] Optimize data retrieval
  - Implement batch processing
  - Add parallel processing
  - Optimize queries
  - Add caching

- [ ] Improve caching
  - Implement cache strategies
  - Add cache invalidation
  - Optimize cache size
  - Add cache monitoring

- [ ] Add performance monitoring
  - Implement metrics collection
  - Add performance dashboard
  - Create alert system
  - Add reporting

### Dependencies
- Requires completion of basic caching
- Needs monitoring system setup

### Acceptance Criteria
1. Performance improvements demonstrated
2. Caching system optimized
3. Monitoring system working
4. Documentation complete

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    },
    @{
        title = "Analysis Tools Development"
        body = @"
## Overview
Develop advanced analysis tools for mortality data.

### Tasks
- [ ] Statistical analysis
  - Implement basic statistics
  - Add trend analysis
  - Add correlation analysis
  - Add regression analysis

- [ ] Trend analysis
  - Implement time series analysis
  - Add forecasting
  - Add seasonal analysis
  - Add trend visualization

- [ ] Comparison tools
  - Add table comparison
  - Add period comparison
  - Add source comparison
  - Add visualization

### Dependencies
- Requires completion of basic data processing
- Needs statistical libraries

### Acceptance Criteria
1. Analysis tools implemented
2. Trend analysis working
3. Comparison tools functional
4. Documentation complete

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    },
    @{
        title = "Visualization System"
        body = @"
## Overview
Implement comprehensive visualization capabilities for mortality data.

### Tasks
- [ ] Basic charts
  - Add line charts
  - Add bar charts
  - Add scatter plots
  - Add histograms

- [ ] Interactive plots
  - Add zoom capabilities
  - Add pan controls
  - Add data point selection
  - Add tooltips

- [ ] Export capabilities
  - Add image export
  - Add PDF export
  - Add data export
  - Add report generation

### Dependencies
- Requires completion of analysis tools
- Needs visualization libraries

### Acceptance Criteria
1. All chart types implemented
2. Interactive features working
3. Export system functional
4. Documentation complete

### Timeline
Target completion: Q3 2025
"@
        labels = @("enhancement", "Q3-2025")
    }
)

# Store results for summary
$results = @()
$totalIssues = $issues.Count
$successCount = 0
$failureCount = 0

Write-Host "Starting to create $totalIssues issues..." -ForegroundColor Yellow

# Create each issue
foreach ($issue in $issues) {
    try {
        $body = $issue.body
        $labels = $issue.labels
        $issueData = @{
            title = $issue.title
            body = $body
            labels = $labels
        }
        if ($issue.ContainsKey('milestone')) {
            $issueData.milestone = $issue.milestone
        }
        if ($issue.ContainsKey('assignees')) {
            $issueData.assignees = $issue.assignees
        }
        $jsonData = $issueData | ConvertTo-Json -Depth 5
        $uri = "https://api.github.com/repos/$owner/$repo/issues"
        Write-Host "Creating issue: $($issue.title)"
        
        try {
            $response = Invoke-GitHubAPI -Uri $uri -Method Post -Body $jsonData
            
            # Verify response is valid
            if ($response -and $response.html_url) {
                Write-Host "Successfully created issue: $($issue.title)" -ForegroundColor Green
                Write-Host "Issue URL: $($response.html_url)" -ForegroundColor Cyan
                $results += [PSCustomObject]@{ Title = $issue.title; Status = 'Success'; Url = $response.html_url; Error = $null }
                $successCount++
            } else {
                throw "Invalid response format from GitHub API"
            }
        } catch {
            $errorDetails = $_.Exception.Response
            $errorBody = $null
            if ($errorDetails -ne $null) {
                try {
                    $reader = New-Object System.IO.StreamReader($errorDetails.GetResponseStream())
                    $errorBody = $reader.ReadToEnd()
                    $reader.Close()
                } catch {
                    $errorBody = "Error reading response stream: $_"
                }
            }
            
            $errorMessage = if ($errorBody) {
                try {
                    $errorJson = $errorBody | ConvertFrom-Json
                    if ($errorJson.message) {
                        $errorJson.message
                    } else {
                        $errorBody
                    }
                } catch {
                    if ($errorBody.Contains("<!DOCTYPE html>")) {
                        "Received HTML response instead of JSON. This might indicate an authentication issue."
                    } else {
                        $errorBody
                    }
                }
            } else {
                $_.Exception.Message
            }
            
            Write-Error "Error creating issue '$($issue.title)': $errorMessage"
            $results += [PSCustomObject]@{ Title = $issue.title; Status = 'Failed'; Url = $null; Error = $errorMessage }
            $failureCount++
        }
    }
    catch {
        Write-Error "Unexpected error creating issue '$($issue.title)': $_"
        $results += [PSCustomObject]@{ Title = $issue.title; Status = 'Failed'; Url = $null; Error = $_ }
        $failureCount++
    }
}

# Print summary
Write-Host "`n==== Issue Creation Summary ====" -ForegroundColor Yellow
Write-Host "Total Issues: $totalIssues" -ForegroundColor White
Write-Host "Successful: $successCount" -ForegroundColor Green
Write-Host "Failed: $failureCount" -ForegroundColor Red
Write-Host "`nDetailed Results:" -ForegroundColor Yellow
foreach ($result in $results) {
    if ($result.Status -eq 'Success') {
        Write-Host "[SUCCESS] $($result.Title): $($result.Url)" -ForegroundColor Green
    } else {
        Write-Host "[FAILED]  $($result.Title): $($result.Error)" -ForegroundColor Red
    }
} 