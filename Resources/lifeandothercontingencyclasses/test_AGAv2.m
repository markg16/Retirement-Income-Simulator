classdef test_AGAv2 < matlab.unittest.TestCase
    %TEST_AGA Test suite for AustralianGovernmentActuarySource using
    %cachemanager
    
    properties (ClassSetupParameter)
        % Creates a shared resource for all tests in this class, making it faster.
        SharedSource = {true}
    end
    
    properties (Constant)
        EXPECTED_TABLE_COUNT = 4;
    end
    
    properties (Access = private)
        % This property is populated by the [TestClassSetup] method.
        DataSource
    end
    methods (Access = private)
        function logSampleSummary(testCase, tableEnum)
            % Helper function to log a sample summary for a single table.
            source = testCase.DataSource;
            tableName = char(tableEnum);

            source.log('---> Sampling cached data for: %s', tableName);

            try
                data = source.getMortalityTable(tableEnum);

                if ~isfield(data, 'Male') || ~isfield(data, 'Female')
                    source.log('ERROR: Cached data for %s is incomplete.', tableName);
                    return;
                end

                sampleAges = [0, 21, 45, 65, 85, 100];
                results = table('Size', [length(sampleAges), 3], 'VariableTypes', {'double', 'double', 'double'}, 'VariableNames', {'Age', 'Male_qx', 'Female_qx'}, 'RowNames', string(sampleAges));
                for j = 1:length(sampleAges)
                    age = sampleAges(j);
                    results.Age(j) = age;
                    maleIdx = data.Male.Age == age;
                    femaleIdx = data.Female.Age == age;
                    if any(maleIdx), results.Male_qx(j) = data.Male.qx(maleIdx); else, results.Male_qx(j) = NaN; end
                    if any(femaleIdx), results.Female_qx(j) = data.Female.qx(femaleIdx); else, results.Female_qx(j) = NaN; end
                end

                disp(results); % Display to console
                logOutput = evalc('disp(results)'); % Capture for log file
                if ~isempty(source.LogFile) && source.LogFile ~= -1
                    fprintf(source.LogFile, '%s', logOutput);
                end
            catch ME
                source.log('Could not process summary for %s. Reason: %s', tableName, ME.message);
            end
        end
    end
    methods (TestClassSetup)
        function setupClass(testCase, SharedSource)
            % This runs ONCE before any test in the class.
            if SharedSource
                try
                    % Create a single, shared instance of the source for all tests.
                    % OverwriteExisting=true ensures a clean state for the test run.
                    testCase.DataSource = AustralianGovernmentActuarySource('OverwriteExisting', true);
                    testCase.assumeNotEmpty(testCase.DataSource, 'Fatal: Failed to initialize the shared DataSource.');
                catch ME
                    testCase.assumeFail(['Fatal: Test class setup failed: ' ME.message]);
                end
            end
        end
    end
    
    methods (TestMethodTeardown)
        function inspectAndClearCache(testCase)
            % This runs after EACH test.

            % Get all tables that were just placed in the cache by the preceding test.
            availableTables = testCase.DataSource.getAvailableTables();

            if ~isempty(availableTables)
                fprintf('\n'); % Add a newline for better formatting in the test runner
                % For each table found, run the summary.
                for i = 1:length(availableTables)
                    testCase.logSampleSummary(availableTables(i));
                end
            end

            % Now, clear the cache to isolate the next test.
            testCase.DataSource.clearCache();
        end
        % function clearTableCache(testCase)
        %     % After each test, clear the CACHED TABLES, but not the whole object.
        %     % This provides isolation for tests that check caching behavior.
        %     testCase.DataSource.clearCache();
        % end
    end
    
    methods (TestClassTeardown)

        % This block can be empty or removed if you have nothing else to run once at the very end.
        function finalCleanup(testCase)
            testCase.DataSource.log('--- Test Class Finished ---');
        end
        
        
    end
    
    methods (Test)
         %#Test, #:Tags "Integration"
        % Tagging tests that require internet as 'Integration'
        
        function testInitialization(testCase)
            testCase.verifyEqual(testCase.DataSource.SourceName, 'Australian Government Actuary', 'Source name should be correct');
            testCase.verifyEqual(testCase.DataSource.SourceURL, 'https://aga.gov.au/publications/life-tables', 'Source URL should be correct');
            % Avoid "magic numbers". Compare against the expected constant.
            testCase.verifyEqual(testCase.DataSource.UrlCache.Count, uint64(testCase.EXPECTED_TABLE_COUNT), 'UrlCache should have the expected number of tables.');
        end
        
        function testFetchLatestData(testCase)
            data = testCase.DataSource.fetchLatestData();
            testCase.verifyNotEmpty(data, 'Latest data should not be empty.');
            testCase.verifyTrue(isfield(data, 'Male') && isfield(data, 'Female'), 'Data should contain Male and Female fields.');
            % Add more specific assertions
            testCase.verifyEqual(data.Male.Age(1), 0, 'First age for males should be 0.');
            testCase.verifyEqual(data.Female.Age(1), 0, 'First age for females should be 0.');
        end
        
        function testFetchAllTables(testCase)
            testCase.DataSource.fetchAllTables();
            tables = testCase.DataSource.getAvailableTables();
            testCase.verifyGreaterThanOrEqual(length(tables), 1, 'At least one table should be fetched and available.');
        end
        
        function testTableValidation(testCase)
            data = testCase.DataSource.fetchLatestData();
            testCase.verifyTrue(testCase.DataSource.validateTableData(data.Male), 'Male table data should be valid.');
            testCase.verifyTrue(testCase.DataSource.validateTableData(data.Female), 'Female table data should be valid.');
        end
        
        function testErrorHandling(testCase)
            testCase.verifyError(@() testCase.DataSource.getMortalityTable('InvalidTable'), 'MATLAB:invalidType', 'Getting an invalid table should throw a specific error.');
        end
        
        function testCacheManagement(testCase)
            % This test relies on an isolated state, so the teardown's clearCache is important.
            testCase.verifyEmpty(testCase.DataSource.getAvailableTables(), 'Cache should be empty at the start of the test.');
            
            testCase.DataSource.fetchLatestData();
            testCase.verifyNotEmpty(testCase.DataSource.getAvailableTables(), 'Cache should contain tables after fetching.');
            
            testCase.DataSource.clearCache();
            testCase.verifyEmpty(testCase.DataSource.getAvailableTables(), 'Cache should be empty after clearing.');
        end
        
        function testDataConsistency(testCase)
            % Verifies that fetching from source and fetching from cache yield the same result.
            data1 = testCase.DataSource.fetchLatestData(); % Fetches from source
            data2 = testCase.DataSource.fetchLatestData(); % Should fetch from cache
            
            testCase.verifyEqual(data1.Male.qx, data2.Male.qx, 'Male qx values should be consistent between fetches.');
            testCase.verifyEqual(data1.Female.qx, data2.Female.qx, 'Female qx values should be consistent between fetches.');
        end
    end
end