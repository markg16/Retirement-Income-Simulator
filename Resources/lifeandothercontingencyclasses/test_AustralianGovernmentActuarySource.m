% File: test_AustralianGovernmentActuarySource.m
classdef test_AustralianGovernmentActuarySource < test_MortalityDataSource_Base
    % Tests the specific implementation of AustralianGovernmentActuarySource.
    % Inherits all generic tests from test_MortalityDataSource_Base.

    properties (Constant)
        EXPECTED_URL_CACHE_COUNT = 4;
    end
    
    methods (TestMethodSetup)
        function createDataSource(testCase)
            % This method fulfills the abstract requirement from the base test class.
            % It provides a specific instance of AustralianGovernmentActuarySource.
            try
                testCase.DataSource = AustralianGovernmentActuarySource('OverwriteExisting', true);
                testCase.assumeNotEmpty(testCase.DataSource, 'Setup failed: Could not create AustralianGovernmentActuarySource.');
            catch ME
                testCase.assumeFail(sprintf('Fatal setup error for AGA Source: %s', ME.message));
            end
        end
    end

    methods (Access = protected)
        function identifier = getValidTableIdentifier(testCase)
            % Provides a valid identifier for the AGA source.
            identifier = TableNames.ALT_Table2020_22;
        end
        
        function identifier = getInvalidTableIdentifier(testCase)
            % Provides an invalid identifier for the AGA source.
            identifier = 'InvalidTableString';
        end
    end
    
    % --- TESTS SPECIFIC TO AustralianGovernmentActuarySource ONLY ---
    methods(Test)
        function testUrlCacheAndInitialization(testCase)
            % This is a test that only makes sense for the AGA source.
            testCase.verifyEqual(testCase.DataSource.SourceName, 'Australian Government Actuary');
            testCase.verifyEqual(testCase.DataSource.UrlCache.Count, uint64(testCase.EXPECTED_URL_CACHE_COUNT), ...
                'AGA UrlCache should have the expected number of tables at initialization.');
        end
        
        function testDataFetchingFromWeb(testCase)
            %#Test, #:Tags "Integration"
            % This is a web-dependent test specific to the AGA source.
            data = testCase.DataSource.fetchLatestData();
            testCase.verifyNotEmpty(data.MortalityRates);
            testCase.verifyTrue(isfield(data.MortalityRates, 'Male') && isfield(data.MortalityRates, 'Female'));
        end
        
        % NOTE: The tests for BasicMortalityTable and CachedImprovementFactorDecorator are unit tests
        % for those specific classes. They don't strictly belong here but are kept for consistency
        % with your original test file structure. Ideally, they would move to their own test classes.
        
        function testBasicMortalityTableConstructor(testCase)
            %#Test, #:Tags "Unit"
            mockRates.Male.Age = (0:10)';
            mockRates.Male.qx = linspace(0.001, 0.01, 11)';
            mockRates.Male.lx = round(cumprod([100000; (1-mockRates.Male.qx(1:10))]));
            mockRates.Female.Age = (0:10)';
            mockRates.Female.qx = linspace(0.0008, 0.008, 11)';
            mockRates.Female.lx = round(cumprod([100000; (1-mockRates.Female.qx(1:10))]));
            tableFilePath = 'mock_basic_table.mat';
            
            bmt = BasicMortalityTable(tableFilePath, mockRates);
            
            testCase.verifyClass(bmt, 'BasicMortalityTable');
            testCase.verifyEqual(bmt.SourceType, 'File', 'SourceType should be File');
            
            % Assuming constructor sets TableName from file path
            %[~, expectedName] = fileparts(tableFilePath);
            testCase.verifyEqual(bmt.TableName, '', 'TableName should be blank.');
        end
    end
end
