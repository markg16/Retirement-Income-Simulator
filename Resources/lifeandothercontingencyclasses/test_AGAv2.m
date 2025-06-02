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

            % 1. Create a MockDataSource for this test
            %    This provides controlled base data and an isolated CacheManager
            mockBaseRates.Male.Age = (40:70)';
            mockBaseRates.Male.qx = linspace(0.005, 0.05, 31)';
            mockBaseRates.Male.lx = round(100000 * cumprod([1; (1-mockBaseRates.Male.qx(1:30))]));
            mockBaseRates.Female.Age = (40:70)';
            mockBaseRates.Female.qx = linspace(0.004, 0.04, 31)';
            mockBaseRates.Female.lx = round(100000 * cumprod([1; (1-mockBaseRates.Female.qx(1:30))]));
            
            % Create a mock table name for the mock data source to respond to
            mockBaseTableNameEnum = TableNames.Mock_Table; % Just pick one, it will be overridden by mock
            mockLocalDataSource = MockMortalityDataSource(mockBaseTableNameEnum, mockBaseRates);
            mockLocalDataSource.clearSpecificCache(); % Ensure it's clean for this test run

            % Create BasicMortalityTable from the mock data source
            baseTableDataStruct = mockLocalDataSource.getMortalityTable(mockBaseTableNameEnum);
            baseTable = BasicMortalityTable('mock_base_for_decorator', baseTableDataStruct); % Pass only rates
            baseTable.TableName = 'MockBaseTableForDecorator';


            % 2. Mock Improvement Factor Strategy and Data
            %    Using the MockImprovementFactorStrategy defined at the top of this file
            %    It will return a constant 1% improvement (0.01) for all ages/genders
            mockIFStrategy = ConstantImprovementFactorStrategy(0.01); % Input 0.01 for a 1% factor
            
            % The structure that calculateAverageFactors is expected to return by the decorator
            % (which is also the structure of obj.ImprovementFactors in the decorator)
            % For MockImprovementFactorStrategy, it will create this structure.
            % We need to pass a 'rawIF' structure that MockImprovementFactorStrategy can use for Age.
            mockRawIFForStrategy.Age    = (0:10:100)'; % Age bands for IF
            % Male/Female fields in mockRawIFForStrategy are not used by MockIFStrategy if ReturnConstantFactor is set
            mockRawIFForStrategy.Male   = ones(size(mockRawIFForStrategy.Age)); 
            mockRawIFForStrategy.Female = ones(size(mockRawIFForStrategy.Age));

            improvementFactorsFile = 'dummy_if_file.txt'; % Path isn't actually used due to mocking strategy
            startAgeForImprovement = 50;

           % 3. Use the MockDataSource's CacheManager for the decorator
            decoratorCacheManager = mockLocalDataSource.getCacheManager();

            % 4. Create the Decorator
            % Temporarily mock utilities.LifeTableUtilities.loadImprovementFactors
            originalUtilPath = path;
            testSpecificUtilDir = fullfile(pwd, 'testSpecificUtils');
            if exist(testSpecificUtilDir, 'dir'), rmdir(testSpecificUtilDir, 's'); end % Clean up previous run
            mkdir(testSpecificUtilDir);
            mkdir(fullfile(testSpecificUtilDir, '+utilities'));
            mkdir(fullfile(testSpecificUtilDir, '+utilities', '+LifeTableUtilities'));
            fid = fopen(fullfile(testSpecificUtilDir, '+utilities', '+LifeTableUtilities', 'loadImprovementFactors.m'), 'w');
            fprintf(fid, 'function S = loadImprovementFactors(varargin)\n');
            % This mock should return the structure that MockImprovementFactorStrategy's
            % calculateAverageFactors expects as input (rawImprovementFactors)
            fprintf(fid, '    S.Age = (0:10:100)'';\n'); 
            fprintf(fid, '    S.Male = ones(size(S.Age)) * 1;\n'); % Placeholder values
            fprintf(fid, '    S.Female = ones(size(S.Age)) * 1;\n');% Placeholder values
            fprintf(fid, 'end\n');
            fclose(fid);
            addpath(testSpecificUtilDir);
            
            % Ensure cleanup of the path and directory
            cleanupObj = onCleanup(@() cleanupMockUtility(testSpecificUtilDir, originalUtilPath));

            decorator = CachedImprovementFactorDecorator(baseTable, improvementFactorsFile, ...
                mockIFStrategy, startAgeForImprovement, decoratorCacheManager);
            
            % Cleanup is handled by onCleanup

            % 5. Verify Decorator Properties
            testCase.verifyClass(decorator, 'CachedImprovementFactorDecorator');
            testCase.verifyEqual(decorator.StartAgeForImprovement, startAgeForImprovement);
            testCase.verifyEqual(decorator.TableName, sprintf('%s_ImpFrom%d_%s', baseTable.TableName, startAgeForImprovement, class(mockIFStrategy)));
            testCase.verifyNotEmpty(decorator.MortalityRates, 'Decorator MortalityRates should be populated.');
            testCase.verifyTrue(isfield(decorator.MortalityRates, 'Male') && isfield(decorator.MortalityRates, 'Female'));

            % 6. Verify Improvement Logic
            ageToTest = 60; % This age is > startAgeForImprovement
            genderToTest = 'Male';

            baseRate = baseTable.getRate(genderToTest, ageToTest);
            decoratedRate = decorator.getRate(genderToTest, ageToTest);

            testCase.verifyNotEqual(decoratedRate, baseRate, 'Decorated rate should differ from base rate due to improvement.');

            % Expected calculation: qx_improved = qx_base * (1 - IF_annual)^duration
            duration = ageToTest - startAgeForImprovement;
            % MockIFStrategy was given 0.01. Its calculateAverageFactors outputs IF*100.
            % Decorator's getImprovementFactor divides by 100. So, annualImprovementFactor is 0.01.
            annualImprovementFactor = 0.01; 
            expectedDecoratedRate = baseRate * (1 - annualImprovementFactor)^duration;
            
            testCase.verifyEqual(decoratedRate, expectedDecoratedRate, 'AbsTol', 1e-9, 'Decorated rate calculation is incorrect.');

            % Test an age where decorator should error because its rates start at StartAgeForImprovement
            ageBeforeImprovement = 45; % This age is < startAgeForImprovement
            testCase.verifyError(@() decorator.getRate(genderToTest, ageBeforeImprovement), ...
                'CachedImprovementFactorDecorator:AgeNotFound', ...
                'Decorator should error for ages before its StartAgeForImprovement.');
            
            % Verify caching of improved rates struct
            baseTableNameForCache = regexprep(baseTable.TableName, '[^a-zA-Z0-9_]', '_');
            cacheKey = sprintf('ImprovedRates_%s_Start%d_%s', ...
                               baseTableNameForCache, ...
                               startAgeForImprovement, ...
                               class(mockIFStrategy));
            [cachedData, isCached] = decoratorCacheManager.getTable(cacheKey);
            testCase.verifyTrue(isCached, 'Improved rates struct should be cached.');
            testCase.verifyEqual(cachedData.Male.qx, decorator.MortalityRates.Male.qx, 'Cached qx should match decorator qx.');

            % 7. Test getSurvivorshipProbabilities delegation
            currentAge = 55; finalAge = 60; % Ages within the decorator's range
            survivorshipDecorator = decorator.getSurvivorshipProbabilities(genderToTest, currentAge, finalAge);
            
            expectedP_manual = 1;
            manualCalcProbs = zeros(1, finalAge - currentAge);
            for t_idx = 1:(finalAge - currentAge) % t from 1 to N
                age_loop = currentAge + t_idx -1; % age for qx is currentAge, currentAge+1, ...
                qx_imp_loop = decorator.getRate(genderToTest, age_loop);
                expectedP_manual = expectedP_manual * (1 - qx_imp_loop);
                manualCalcProbs(t_idx) = expectedP_manual; % Stores _{t}p_x where x=currentAge
            end
            testCase.verifyEqual(survivorshipDecorator, manualCalcProbs, 'AbsTol', 1e-9, 'Decorator survivorship probabilities are incorrect.');

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
   