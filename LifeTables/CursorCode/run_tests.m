function run_tests()
    %RUN_TESTS Run tests for mortality data source functionality
    %   Tests the MortalityDataSource base class and AGA source implementation
    
    % Initialize test results
    results = struct('name', {}, 'passed', {}, 'message', {});
    
    % Test MortalityDataSource base class
    results = [results; testMortalityDataSourceBase()];
    
    % Test AGA source
    results = [results; testAustralianGovernmentActuarySource()];
    
    % Test Cache Manager
    results = [results; testMortalityCacheManager()];
    
    % Print results
    printResults(results);
end

function results = testMortalityDataSourceBase()
    %TESTMORTALITYDATASOURCEBASE Test base MortalityDataSource class
    results = struct('name', {}, 'passed', {}, 'message', {});
    
    try
        % Test initialization
        source = MortalityDataSource();
        results(end+1) = struct('name', 'Base Class Initialization', ...
                              'passed', true, ...
                              'message', 'Successfully initialized base class');
        
        % Test cache initialization
        results(end+1) = struct('name', 'Cache Initialization', ...
                              'passed', ~isempty(source.DataCache), ...
                              'message', 'Cache initialized');
        
        % Test directory creation
        results(end+1) = struct('name', 'Directory Creation', ...
                              'passed', exist(source.CacheDir, 'dir') == 7, ...
                              'message', 'Cache directory created');
        
    catch e
        results(end+1) = struct('name', 'Base Class Tests', ...
                              'passed', false, ...
                              'message', sprintf('Error: %s', e.message));
    end
end

function results = testAustralianGovernmentActuarySource()
    %TESTAUSTRALIANGOVERNMENTACTUARYSOURCE Test AGA source implementation
    results = struct('name', {}, 'passed', {}, 'message', {});
    
    try
        % Test initialization
        source = AustralianGovernmentActuarySource();
        results(end+1) = struct('name', 'AGA Source Initialization', ...
                              'passed', true, ...
                              'message', 'Successfully initialized AGA source');
        
        % Test URL cache initialization
        results(end+1) = struct('name', 'URL Cache Initialization', ...
                              'passed', ~isempty(source.UrlCache), ...
                              'message', 'URL cache initialized');
        
        % Test table URLs
        results(end+1) = struct('name', 'Table URLs', ...
                              'passed', source.TableURLs.Count > 0, ...
                              'message', 'Table URLs initialized');
        
        % Test availability check
        isAvailable = source.checkAvailability();
        results(end+1) = struct('name', 'Website Availability', ...
                              'passed', islogical(isAvailable), ...
                              'message', 'Availability check completed');
        
        % Test table fetching (only if website is available)
        if isAvailable
            try
                table = source.fetchTable(TableNames.ALT_Table2015_17);
                results(end+1) = struct('name', 'Table Fetching', ...
                                      'passed', ~isempty(table), ...
                                      'message', 'Successfully fetched table');
            catch e
                results(end+1) = struct('name', 'Table Fetching', ...
                                      'passed', false, ...
                                      'message', sprintf('Error fetching table: %s', e.message));
            end
        end
        
    catch e
        results(end+1) = struct('name', 'AGA Source Tests', ...
                              'passed', false, ...
                              'message', sprintf('Error: %s', e.message));
    end
end

function results = testMortalityCacheManager()
    %TESTMORTALITYCACHEMANAGER Test cache manager functionality
    results = struct('name', {}, 'passed', {}, 'message', {});
    
    try
        % Test initialization
        cache = MortalityCacheManager();
        results(end+1) = struct('name', 'Cache Manager Initialization', ...
                              'passed', true, ...
                              'message', 'Successfully initialized cache manager');
        
        % Test cache directory
        results(end+1) = struct('name', 'Cache Directory', ...
                              'passed', exist(cache.CacheDir, 'dir') == 7, ...
                              'message', 'Cache directory exists');
        
        % Test cache operations
        testKey = 'test_table';
        testData = struct('data', [1 2 3]);
        
        % Test caching
        cache.cacheTable(testKey, testData);
        results(end+1) = struct('name', 'Cache Table', ...
                              'passed', true, ...
                              'message', 'Successfully cached table');
        
        % Test retrieval
        [data, isCached] = cache.getTable(testKey);
        results(end+1) = struct('name', 'Get Table', ...
                              'passed', isCached && isequal(data, testData), ...
                              'message', 'Successfully retrieved cached table');
        
        % Test cache stats
        stats = cache.getCacheStats();
        results(end+1) = struct('name', 'Cache Stats', ...
                              'passed', isstruct(stats) && isfield(stats, 'hits'), ...
                              'message', 'Cache statistics available');
        
        % Test cache invalidation
        cache.invalidateTable(testKey);
        [~, isCached] = cache.getTable(testKey);
        results(end+1) = struct('name', 'Cache Invalidation', ...
                              'passed', ~isCached, ...
                              'message', 'Successfully invalidated table');
        
        % Test cache clearing
        cache.clearCache();
        tables = cache.getCachedTables();
        results(end+1) = struct('name', 'Cache Clearing', ...
                              'passed', isempty(tables), ...
                              'message', 'Successfully cleared cache');
        
    catch e
        results(end+1) = struct('name', 'Cache Manager Tests', ...
                              'passed', false, ...
                              'message', sprintf('Error: %s', e.message));
    end
end

function printResults(results)
    %PRINTRESULTS Print test results
    fprintf('\n=== Test Results ===\n\n');
    
    totalTests = length(results);
    passedTests = sum([results.passed]);
    
    for i = 1:length(results)
        result = results(i);
        status = ifelse(result.passed, 'PASSED', 'FAILED');
        color = ifelse(result.passed, 'green', 'red');
        fprintf('[%s] %s: %s\n', status, result.name, result.message);
    end
    
    fprintf('\nSummary: %d/%d tests passed (%.1f%%)\n', ...
            passedTests, totalTests, 100 * passedTests / totalTests);
end

function result = ifelse(condition, trueValue, falseValue)
    %IFELSE Ternary operator for MATLAB
    if condition
        result = trueValue;
    else
        result = falseValue;
    end
end 