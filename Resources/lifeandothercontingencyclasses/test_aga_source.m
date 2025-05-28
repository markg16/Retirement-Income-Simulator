% Test script for Australian Government Actuary data source
function test_aga_source(clearCache)
    % Test script for AustralianGovernmentActuarySource
    % clearCache: optional boolean to clear cache before testing
    
    if nargin < 1
        clearCache = false;
    end
    
    try
        % Create source object
        fprintf('Creating AGA source...\n');
        source = AustralianGovernmentActuarySource('OverwriteExisting', true);
        
        % Clear cache if requested
        if clearCache
            fprintf('Clearing cache...\n');
            source.clearCache();
        end
        
        % Test 1: Check source availability
        fprintf('\nTest 1: Checking source availability...\n');
        isAvailable = source.checkAvailability();
        assert(isAvailable, 'Source should be available');
        fprintf('Source is available\n');
        
        % Test 2: Get available tables
        fprintf('\nTest 2: Getting available tables...\n');
        tables = source.getAvailableTables();
        assert(~isempty(tables), 'Should return available tables');
        fprintf('Available tables:\n');
        for i = 1:length(tables)
            fprintf('  %s\n', char(tables(i)));
        end
        
        % Test 3: Fetch latest table
        fprintf('\nTest 3: Fetching latest table...\n');
        latestTable = TableNames.ALT_Table2020_22;
        data = source.getMortalityTable(latestTable);
        
        % Validate data structure
        assert(isfield(data, 'Male'), 'Data should have Male field');
        assert(isfield(data, 'Female'), 'Data should have Female field');
        assert(isfield(data.Male, 'Age'), 'Male data should have Age field');
        assert(isfield(data.Male, 'qx'), 'Male data should have qx field');
        assert(isfield(data.Male, 'lx'), 'Male data should have lx field');
        
        % Print sample data
        fprintf('\nSample of latest data (first 3 rows):\n');
        for i = 1:min(3, length(data.Male.Age))
            fprintf('  Age: %d, Male qx: %g, Male lx: %g\n', data.Male.Age(i), data.Male.qx(i), data.Male.lx(i));
            if isfield(data, 'Female') && isfield(data.Female, 'qx') && isfield(data.Female, 'lx') && ...
               length(data.Female.qx) >= i && length(data.Female.lx) >= i
                fprintf('  Female qx: %g, Female lx: %g\n', data.Female.qx(i), data.Female.lx(i));
            end
        end
        
        % Test 4: Test caching
        fprintf('\nTest 4: Testing caching...\n');
        % First call should download
        tic;
        data1 = source.getMortalityTable(latestTable);
        time1 = toc;
        
        % Second call should use cache
        tic;
        data2 = source.getMortalityTable(latestTable);
        time2 = toc;
        
        assert(time2 < time1, 'Second call should be faster (using cache)');
        assert(isequal(data1, data2), 'Cached data should match downloaded data');
        fprintf('Cache test passed\n');
        
        % Test 5: Test data validation
        fprintf('\nTest 5: Testing data validation...\n');
        assert(all(data.Male.Age >= 0), 'Ages should be non-negative');
        assert(all(data.Male.qx >= 0 & data.Male.qx <= 1), 'qx should be between 0 and 1');
        assert(all(data.Male.lx > 0), 'lx should be positive');
        fprintf('Data validation passed\n');
        
        % Test 6: Test error handling
        fprintf('\nTest 6: Testing error handling...\n');
        try
            % Try to get a non-existent table
            source.getMortalityTable('NonExistentTable');
            error('Should have thrown an error for non-existent table');
        catch e
            fprintf('Error handling test passed: %s\n', e.message);
        end
        
        fprintf('\nAll tests completed successfully!\n');
        
    catch e
        fprintf('\nTest failed with error:\n%s\n', e.message);
        fprintf('Stack trace:\n');
        for i = 1:length(e.stack)
            fprintf('  %s:%d\n', e.stack(i).name, e.stack(i).line);
        end
    end
end 