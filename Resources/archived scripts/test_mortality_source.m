function test_mortality_source()
    %TEST_MORTALITY_SOURCE Run tests for mortality data source functionality
    
    try
        % Add required paths
        addpath(genpath('lifeandothercontingencyclasses'));
        addpath(genpath('cashflowgeneratorclasses'));
        
        % Ensure TableNames enum is loaded
        if ~exist('TableNames', 'class')
            error('TableNames enum not found. Please ensure it is in the MATLAB path.');
        end
        
        % Initialize test results
        results = struct();
        
        % Run tests
        results.agaSource = testAustralianGovernmentActuarySource();
        results.cacheManager = testMortalityCacheManager();
        
        % Print results to log file
        printResults(results);
        
        % Print results to console
        printResultsToConsole(results);
        
    catch e
        fprintf('Error in test execution: %s\n', e.message);
        fprintf('Stack trace:\n');
        for i = 1:length(e.stack)
            fprintf('  %s:%d\n', e.stack(i).name, e.stack(i).line);
        end
    end
end

function results = testAustralianGovernmentActuarySource()
    % Test AGA source implementation
    results = struct();
    
    try
        % Test initialization
        source = AustralianGovernmentActuarySource();
        results.init = true;
        
        % Test URL cache initialization
        results.urlCacheInit = ~isempty(source.UrlCache);
        
        % Test table URLs
        results.tableUrls = ~isempty(source.getTableUrls());
        
        % Test website availability
        results.websiteAvailable = source.isWebsiteAvailable();
        
        % Test table fetching
        [data, success] = source.fetchTable(TableNames.ALT_Table2020_22);
        results.tableFetch = success && ~isempty(data);
        
    catch e
        results.error = e.message;
        results.init = false;
        results.urlCacheInit = false;
        results.tableUrls = false;
        results.websiteAvailable = false;
        results.tableFetch = false;
    end
end

function results = testMortalityCacheManager()
    % Test cache manager functionality
    results = struct();
    
    try
        % Test initialization
        cache = MortalityCacheManager();
        results.init = true;
        
        % Test cache directory
        results.cacheDir = exist(cache.getCacheDir(), 'dir') == 7;
        
        % Test caching
        testKey = 'test_table';
        testData = rand(10);
        cache.cacheTable(testKey, testData);
        results.cacheWrite = true;
        
        % Test retrieval
        [data, wasCached] = cache.getTable(testKey);
        results.cacheRead = wasCached && isequal(data, testData);
        
        % Test cache stats
        stats = cache.getCacheStats();
        results.cacheStats = isstruct(stats) && isfield(stats, 'hits');
        
        % Test invalidation
        cache.invalidateTable(testKey);
        [~, wasCached] = cache.getTable(testKey);
        results.cacheInvalidate = ~wasCached;
        
        % Test clearing
        cache.clearCache();
        results.cacheClear = isempty(cache.getCache());
        
    catch e
        results.error = e.message;
        results.init = false;
        results.cacheDir = false;
        results.cacheWrite = false;
        results.cacheRead = false;
        results.cacheStats = false;
        results.cacheInvalidate = false;
        results.cacheClear = false;
    end
end

function printResults(results)
    % Print test results to log file
    
    % Create logs directory if it doesn't exist
    if ~exist('logs', 'dir')
        mkdir('logs');
    end
    
    % Open log file
    logFile = fullfile('logs', 'test_mortality_source.log');
    fid = fopen(logFile, 'w');
    
    % Check if file was opened successfully
    if fid == -1
        error('Could not open log file for writing: %s', logFile);
    end
    
    % Print header
    fprintf(fid, 'Mortality Data Source Test Results\n');
    fprintf(fid, '==================================\n\n');
    
    % Print AGA source results
    fprintf(fid, 'AGA Source Tests:\n');
    fprintf(fid, '----------------\n');
    printTestResult(fid, 'Initialization', results.agaSource.init);
    printTestResult(fid, 'URL Cache Initialization', results.agaSource.urlCacheInit);
    printTestResult(fid, 'Table URLs', results.agaSource.tableUrls);
    printTestResult(fid, 'Website Availability', results.agaSource.websiteAvailable);
    printTestResult(fid, 'Table Fetch', results.agaSource.tableFetch);
    if isfield(results.agaSource, 'error')
        fprintf(fid, 'Error: %s\n', results.agaSource.error);
    end
    fprintf(fid, '\n');
    
    % Print cache manager results
    fprintf(fid, 'Cache Manager Tests:\n');
    fprintf(fid, '-------------------\n');
    printTestResult(fid, 'Initialization', results.cacheManager.init);
    printTestResult(fid, 'Cache Directory', results.cacheManager.cacheDir);
    printTestResult(fid, 'Cache Write', results.cacheManager.cacheWrite);
    printTestResult(fid, 'Cache Read', results.cacheManager.cacheRead);
    printTestResult(fid, 'Cache Stats', results.cacheManager.cacheStats);
    printTestResult(fid, 'Cache Invalidate', results.cacheManager.cacheInvalidate);
    printTestResult(fid, 'Cache Clear', results.cacheManager.cacheClear);
    if isfield(results.cacheManager, 'error')
        fprintf(fid, 'Error: %s\n', results.cacheManager.error);
    end
    fprintf(fid, '\n');
    
    % Print summary
    totalTests = 0;
    passedTests = 0;
    fields = fieldnames(results);
    for i = 1:length(fields)
        testResults = results.(fields{i});
        resultFields = fieldnames(testResults);
        for j = 1:length(resultFields)
            if ~strcmp(resultFields{j}, 'error')
                totalTests = totalTests + 1;
                if testResults.(resultFields{j})
                    passedTests = passedTests + 1;
                end
            end
        end
    end
    
    fprintf(fid, 'Summary:\n');
    fprintf(fid, '--------\n');
    fprintf(fid, 'Total Tests: %d\n', totalTests);
    fprintf(fid, 'Passed: %d\n', passedTests);
    fprintf(fid, 'Failed: %d\n', totalTests - passedTests);
    
    % Close log file
    fclose(fid);
    
    % Print message to console
    fprintf('Test results written to: %s\n', logFile);
end

function printResultsToConsole(results)
    % Print test results to the MATLAB console
    fprintf('\nMortality Data Source Test Results\n');
    fprintf('==================================\n\n');
    
    % Print AGA source results
    fprintf('AGA Source Tests:\n');
    fprintf('----------------\n');
    printTestResult(1, 'Initialization', results.agaSource.init);
    printTestResult(1, 'URL Cache Initialization', results.agaSource.urlCacheInit);
    printTestResult(1, 'Table URLs', results.agaSource.tableUrls);
    printTestResult(1, 'Website Availability', results.agaSource.websiteAvailable);
    printTestResult(1, 'Table Fetch', results.agaSource.tableFetch);
    if isfield(results.agaSource, 'error')
        fprintf('Error: %s\n', results.agaSource.error);
    end
    fprintf('\n');
    
    % Print cache manager results
    fprintf('Cache Manager Tests:\n');
    fprintf('-------------------\n');
    printTestResult(1, 'Initialization', results.cacheManager.init);
    printTestResult(1, 'Cache Directory', results.cacheManager.cacheDir);
    printTestResult(1, 'Cache Write', results.cacheManager.cacheWrite);
    printTestResult(1, 'Cache Read', results.cacheManager.cacheRead);
    printTestResult(1, 'Cache Stats', results.cacheManager.cacheStats);
    printTestResult(1, 'Cache Invalidate', results.cacheManager.cacheInvalidate);
    printTestResult(1, 'Cache Clear', results.cacheManager.cacheClear);
    if isfield(results.cacheManager, 'error')
        fprintf('Error: %s\n', results.cacheManager.error);
    end
    fprintf('\n');
    
    % Print summary
    totalTests = 0;
    passedTests = 0;
    fields = fieldnames(results);
    for i = 1:length(fields)
        testResults = results.(fields{i});
        resultFields = fieldnames(testResults);
        for j = 1:length(resultFields)
            if ~strcmp(resultFields{j}, 'error')
                totalTests = totalTests + 1;
                if testResults.(resultFields{j})
                    passedTests = passedTests + 1;
                end
            end
        end
    end
    
    fprintf('Summary:\n');
    fprintf('--------\n');
    fprintf('Total Tests: %d\n', totalTests);
    fprintf('Passed: %d\n', passedTests);
    fprintf('Failed: %d\n', totalTests - passedTests);
    fprintf('\n');
end

function printTestResult(fidOrConsole, testName, result)
    % Print individual test result
    if isnumeric(fidOrConsole) && fidOrConsole == 1
        % Print to console
        fprintf('%s: %s\n', testName, ifelse(result, 'PASS', 'FAIL'));
    else
        % Print to file
        fprintf(fidOrConsole, '%s: %s\n', testName, ifelse(result, 'PASS', 'FAIL'));
    end
end

function result = ifelse(condition, trueValue, falseValue)
    % Ternary-like operation
    if condition
        result = trueValue;
    else
        result = falseValue;
    end
end 