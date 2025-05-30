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
            availableTables = testCase.DataSource.getAvailableTables();
            if ~isempty(availableTables)
                fprintf('\n'); % For better console formatting during test runs
                for i = 1:length(availableTables)
                    tableEnum = availableTables(i);
                    try
                        % Get the data struct to pass to the new sampler method
                        dataStruct = testCase.DataSource.getMortalityTable(tableEnum);
                        % Call the new method on the DataSource instance
                        testCase.DataSource.logMortalityTableSample(dataStruct, ...
                            sprintf('---> Sampling cached data for: %s (after test)', char(tableEnum)));
                    catch ME
                        testCase.DataSource.log('Error during post-test sampling for %s: %s', char(tableEnum), ME.message);
                    end
                end
            end
            testCase.DataSource.clearCache();
        end
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
        
        function testCashflowStrategyMortalityTable(testCase)
            %#Test, #:Tags "Integration"
            strategy = CashflowStrategy('MortalityDataSource', testCase.DataSource, ...
                                        'TableName', TableNames.ALT_Table2020_22);

            testCase.verifyClass(strategy, 'CashflowStrategy', 'Strategy object should be created.');
            testCase.verifyNotEmpty(strategy.BaseLifeTable, 'BaseLifeTable should be populated.');
            testCase.verifyClass(strategy.BaseLifeTable, 'BasicMortalityTable', 'BaseLifeTable should be BasicMortalityTable.');

            mortalityData = strategy.BaseLifeTable.MortalityRates;
            testCase.verifyNotEmpty(mortalityData, 'MortalityRates within BaseLifeTable should not be empty.');

            % Use the new sampler method from the DataSource
            testCase.DataSource.logMortalityTableSample(mortalityData, ...
                sprintf('--- Sample data from CashflowStrategy BaseLifeTable: %s ---', char(strategy.TableName)));

            % Basic Sanity Checks (can be expanded)
            testCase.verifyTrue(all(mortalityData.Male.qx >= 0 & mortalityData.Male.qx <= 1), 'Male qx sanity check.');
            testCase.verifyTrue(all(diff(mortalityData.Female.lx) <= 0), 'Female lx sanity check (decreasing).');
        end

    end
end