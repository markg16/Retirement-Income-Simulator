classdef test_AGA_mortality_source < matlab.unittest.TestCase
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
            testCase.verifyTrue(isfield(data.MortalityRates, 'Male') && isfield(data.MortalityRates, 'Female'), 'Data should contain Male and Female fields.');
            % Add more specific assertions
            testCase.verifyEqual(data.MortalityRates.Male.Age(1), 0, 'First age for males should be 0.');
            testCase.verifyEqual(data.MortalityRates.Female.Age(1), 0, 'First age for females should be 0.');
        end
        
        function testFetchAllTables(testCase)
            testCase.DataSource.fetchAllTables();
            tables = testCase.DataSource.getAvailableTables();
            testCase.verifyGreaterThanOrEqual(length(tables), 1, 'At least one table should be fetched and available.');
        end
        
        function testTableValidation(testCase)
            data = testCase.DataSource.fetchLatestData();
            testCase.verifyTrue(testCase.DataSource.validateTableData(data.MortalityRates.Male), 'Male table data should be valid.');
            testCase.verifyTrue(testCase.DataSource.validateTableData(data.MortalityRates.Female), 'Female table data should be valid.');
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
            
            testCase.verifyEqual(data1.MortalityRates.Male.qx, data2.MortalityRates.Male.qx, 'Male qx values should be consistent between fetches.');
            testCase.verifyEqual(data1.MortalityRates.Female.qx, data2.MortalityRates.Female.qx, 'Female qx values should be consistent between fetches.');
        end
        
        function testCashflowStrategyMortalityTable(testCase)
            %#Test, #:Tags "Integration"
            strategy = CashflowStrategy(TableNames.ALT_Table2020_22,testCase.DataSource);

            testCase.verifyClass(strategy, 'CashflowStrategy', 'Strategy object should be created.');
            testCase.verifyNotEmpty(strategy.BaseLifeTable, 'BaseLifeTable should be populated.');
            testCase.verifyClass(strategy.BaseLifeTable, 'BasicMortalityTable', 'BaseLifeTable should be BasicMortalityTable.');

            mortalityData = strategy.BaseLifeTable.MortalityRates;
            testCase.verifyNotEmpty(mortalityData, 'MortalityRates within BaseLifeTable should not be empty.');

            % Use the new sampler method from the DataSource
            testCase.DataSource.logMortalityTableSample(mortalityData, ...
                sprintf('--- Sample data from CashflowStrategy BaseLifeTable: %s ---', char(strategy.MortalityIdentifier)));

            % Basic Sanity Checks (can be expanded)
            testCase.verifyTrue(all(mortalityData.Male.qx >= 0 & mortalityData.Male.qx <= 1), 'Male qx sanity check.');
            testCase.verifyTrue(all(diff(mortalityData.Female.lx) <= 0), 'Female lx sanity check (decreasing).');
        end
        function testBasicMortalityTableConstructor(testCase)
            %#Test, #:Tags "Unit"
            mockRates.Male.Age = (0:10)'; % Simplified for test
            mockRates.Male.qx = linspace(0.001, 0.01, 11)';
            mockRates.Male.lx = round(cumprod([100000; (1-mockRates.Male.qx(1:10))]));
            mockRates.Female.Age = (0:10)';
            mockRates.Female.qx = linspace(0.0008, 0.008, 11)';
            mockRates.Female.lx = round(cumprod([100000; (1-mockRates.Female.qx(1:10))]));

            tableFilePath = 'mock_basic_table.mat'; % Not actually saved, just a path placeholder
            
            % Assuming BasicMortalityTable constructor is: BasicMortalityTable(tableFilePath, mortalityRates)
            bmt = BasicMortalityTable(tableFilePath, mockRates);
            
            testCase.verifyClass(bmt, 'BasicMortalityTable');
            testCase.verifyEqual(bmt.TableName, '', 'Default TableName should be empty or as set by constructor if applicable'); % Adjust if constructor sets it
            testCase.verifyEqual(bmt.SourceType, 'File', 'SourceType should be File');
            testCase.verifyEqual(bmt.SourcePath, tableFilePath, 'SourcePath should be set.');
            testCase.verifyEqual(bmt.MortalityRates.Male.Age, mockRates.Male.Age, 'Male ages should match.');
            testCase.verifyEqual(bmt.MortalityRates.Female.qx, mockRates.Female.qx, 'Female qx rates should match.');
        end
        function testCachedImprovementFactorDecorator(testCase)
            %#Test, #:Tags "Unit"

            % --- ARRANGE ---
            % The setup phase where we create all the components needed for the test.

            % 1. Create a fully isolated Mock Data Source for this test.
            %    This provides controlled base data and its own isolated CacheManager.
            mockBaseRates.Male.Age = (40:70)';
            mockBaseRates.Male.qx = linspace(0.005, 0.05, 31)';
            mockBaseRates.Male.lx = round(100000 * cumprod([1; (1-mockBaseRates.Male.qx(1:30))]));
            mockBaseRates.Female.Age = (40:70)';
            mockBaseRates.Female.qx = linspace(0.004, 0.04, 31)';
            mockBaseRates.Female.lx = round(100000 * cumprod([1; (1-mockBaseRates.Female.qx(1:30))]));

            % We create the mock source, telling it to respond to a specific enum member
            % and to use the custom rates we just defined.
            mockBaseTableNameEnum = TableNames.ALT_Table2020_22; % Use any valid enum member
            mockLocalDataSource = MockMortalityDataSource(mockBaseTableNameEnum, mockBaseRates);

            % 2. Create the Base Mortality Table directly from the mock source.
            %    The getMortalityTable method now correctly returns a BasicMortalityTable object.
            baseTable = mockLocalDataSource.getMortalityTable(mockBaseTableNameEnum);
            testCase.verifyClass(baseTable, 'BasicMortalityTable', 'Base table for decorator must be a BasicMortalityTable object.');
            baseTable.TableName = 'MockBaseTableForDecorator'; % Give it a clear name for the test

            % 3. Set up the Improvement Strategy and its dependencies.
            %    We'll use a constant 1% improvement for this test. The strategy no longer
            %    needs a file, so we can remove the complex file mocking.
            improvementFactor = 0.01;
            mockIFStrategy = ConstantImprovementFactorStrategy(improvementFactor);
            improvementFactorsFile = 'dummy.txt'; % Path is ignored by Constant...Strategy but required by signature
            startAgeForImprovement = 50;

            % 4. Get the isolated CacheManager from the Mock Data Source.
            %    This ensures the decorator's caching doesn't interfere with other tests.
            decoratorCacheManager = mockLocalDataSource.getCacheManager();
            decoratorCacheManager.clearCache(); % Ensure it's clean before the main action

            % --- ACT ---
            % Here we create the object we are actually testing.

            % 5. Create the Decorator using all the components we arranged.
            decorator = CachedImprovementFactorDecorator(baseTable, improvementFactorsFile, ...
                mockIFStrategy, startAgeForImprovement, decoratorCacheManager);

            % --- ASSERT ---
            % Here we verify that the object behaved as expected.

            % 6. Verify Decorator Properties
            testCase.verifyClass(decorator, 'CachedImprovementFactorDecorator');
            testCase.verifyEqual(decorator.StartAgeForImprovement, startAgeForImprovement);
            testCase.verifyNotEmpty(decorator.MortalityRates, 'Decorator MortalityRates should be populated.');

            % 7. Verify Improvement Logic
            ageToTest = 60;
            genderToTest = 'Male';
            baseRate = baseTable.getRate(genderToTest, ageToTest);
            decoratedRate = decorator.getRate(genderToTest, ageToTest);

            testCase.verifyNotEqual(decoratedRate, baseRate, 'Decorated rate should differ from base rate.');

            duration = ageToTest - startAgeForImprovement;
            expectedDecoratedRate = baseRate * (1 - improvementFactor)^duration;
            testCase.verifyEqual(decoratedRate, expectedDecoratedRate, 'AbsTol', 1e-9, 'Decorated rate calculation is incorrect.');

            % 8. Verify Age Range and Caching
            %    The decorator's table should only contain ages from StartAgeForImprovement onwards.
            testCase.verifyError(@() decorator.getRate(genderToTest, 45), ...
                'CachedImprovementFactorDecorator:AgeNotFound', ...
                'Decorator should error for ages before its StartAgeForImprovement.');

            %    Check that the decorator cached its generated rates struct.
            [~, isCached] = decoratorCacheManager.getTable(decorator.getCacheKeyForImprovedTable());
            testCase.verifyTrue(isCached, 'Improved rates struct should now be in the cache.');
        end

        function testDataSourceManagerSharedCache(testCase)

            %#Test, #:Tags "Unit"
            % This test validates the core functionality of the DataSourceManager singleton.
            
            % --- Scenario 1: Default Behavior (No Shared Cache) ---
            testCase.log('--- Testing DataSourceManager: Default (Isolated) Caches ---');
            
            % ARRANGE
            manager = DataSourceManager.getInstance();
            manager.reset(); % Ensure a clean state for the test

            % ACT
            % Get two different types of data sources from the manager
            agaSource = manager.getDataSource(MortalityDataSourceNames.AustralianGovernmentActuarySource);
            mockSource = manager.getDataSource(MortalityDataSourceNames.MockMortalityDataSource);
            
            % Get the CacheManager handle from each data source
            agaCacheManager = agaSource.getCacheManager();
            mockCacheManager = mockSource.getCacheManager();
            
            % ASSERT
            testCase.verifyNotSameHandle(agaCacheManager, mockCacheManager, ...
                'By default, different data sources should get separate CacheManager instances.');
            testCase.log('Verified that default data sources have isolated caches.');

            
            % --- Scenario 2: Configured Behavior (With a Shared Cache) ---
            testCase.log('--- Testing DataSourceManager: Configured Shared Cache ---');
            
            % ARRANGE
            manager.reset(); % Reset the manager again for the second part of the test
            
            % Create a single CacheManager instance that we want to share
            sharedCache = utilities.MortalityCacheManager('cacheFile', 'TestSharedCache.mat');
            sharedCache.clearCache(); % Ensure it's empty
            
            % Configure the manager to use this shared cache for both data source types
            manager.registerCacheManager(MortalityDataSourceNames.AustralianGovernmentActuarySource, sharedCache);
            manager.registerCacheManager(MortalityDataSourceNames.MockMortalityDataSource, sharedCache);
            
            % ACT
            % Get the data sources again. The manager will now use the registered cache.
            agaSourceShared = manager.getDataSource(MortalityDataSourceNames.AustralianGovernmentActuarySource);
            mockSourceShared = manager.getDataSource(MortalityDataSourceNames.MockMortalityDataSource);
            
            % Get the CacheManager handle from each
            agaCacheManagerShared = agaSourceShared.getCacheManager();
            mockCacheManagerShared = mockSourceShared.getCacheManager();
            
            % ASSERT
            testCase.verifySameHandle(agaCacheManagerShared, mockCacheManagerShared, ...
                'When registered, different data sources should share the exact same CacheManager handle.');
            testCase.verifySameHandle(agaCacheManagerShared, sharedCache, ...
                'The data source cache manager should be the same one we registered.');
            testCase.log('Verified that data sources can be configured to use a shared cache.');
        end
        function testCashflowStrategyWithManager(testCase)
            %#Test, #:Tags "Integration"
            % This is an end-to-end integration test that verifies a CashflowStrategy
            % can be created using a data source provided by the DataSourceManager.

            % --- ARRANGE ---

            % 1. Get the singleton instance of the DataSourceManager.
            %    This is the central point of access for all data sources in a real application.
            manager = DataSourceManager.getInstance();

            % 2. Reset the manager to ensure a clean state for this specific test.
            manager.reset();

            % 3. Define which mortality table we want to use.
            tableNameIdentifier = TableNames.ALT_Table2020_22;

            % 4. Ask the manager to provide the correct data source for this table.
            %    The manager will handle creating the AustralianGovernmentActuarySource instance.
            %% 
            agaSource = manager.getDataSourceForTable(tableNameIdentifier);

            % --- ACT ---

            % 5. Create the CashflowStrategy, injecting the data source we just got from the manager.
            strategy = CashflowStrategy('MortalityDataSource', agaSource, ...
                'MortalityIdentifier', tableNameIdentifier);

            % --- ASSERT ---

            % 6. Verify that the strategy and its components were created correctly.
            testCase.verifyClass(strategy, 'CashflowStrategy', 'Strategy object should be created.');
            testCase.verifyNotEmpty(strategy.BaseLifeTable, 'BaseLifeTable should be populated by the strategy.');
            testCase.verifyClass(strategy.BaseLifeTable, 'BasicMortalityTable', 'BaseLifeTable should be a BasicMortalityTable object.');

            % 7. Verify the data within the table is valid.
            mortalityData = strategy.BaseLifeTable.MortalityRates;
            testCase.verifyNotEmpty(mortalityData, 'MortalityRates within BaseLifeTable should not be empty.');

            % Log a sample for visual confirmation
            agaSource.logMortalityTableSample(mortalityData, ...
                sprintf('--- Sample data from CashflowStrategy (via DataSourceManager): %s ---', char(strategy.BaseLifeTable.TableName)));

            % Perform basic data sanity checks
            testCase.verifyTrue(all(mortalityData.Male.qx >= 0 & mortalityData.Male.qx <= 1), 'Male qx values should be valid probabilities.');
            testCase.verifyTrue(all(diff(mortalityData.Female.lx) <= 0), 'Female lx values should be non-increasing.');
        end
    end
end


% This is at the end of your test_AGAv2.m file, AFTER the main class 'end'
% Helper function for cleanup, can be outside the class or as a local function
% if MATLAB version supports it in scripts/class files.
function cleanupMockUtility(testSpecificUtilDir, originalUtilPath)
    % originalUtilPath is not strictly used in this version but kept for signature consistency
    % if you later decide to restore the exact path. For now, rmpath is targeted.
    
    % Check if directory exists before trying to remove it from path to avoid warnings
    if exist(testSpecificUtilDir, 'dir')
        rmpath(testSpecificUtilDir);
    end
    
    % Check again if directory exists before trying to remove it physically
    if exist(testSpecificUtilDir, 'dir')
        % Attempt to remove the directory and its contents.
        % The 's' flag allows removal of non-empty directories.
        % Use with caution and ensure testSpecificUtilDir is correctly defined.
        status = rmdir(testSpecificUtilDir, 's');
        if ~status
            warning('cleanupMockUtility:rmdirFailed', 'Failed to remove directory: %s. It might be in use or permissions are lacking.', testSpecificUtilDir);
        end
    end
    % If you needed to restore the original path state more precisely:
    % path(originalUtilPath); 
end
   