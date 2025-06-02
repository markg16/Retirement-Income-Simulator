classdef test_AGA < matlab.unittest.TestCase
    %TEST_AGA Test suite for AustralianGovernmentActuarySource
    %   Tests the functionality of the AGA data source implementation.
    %   This includes:
    %   - Data fetching and caching
    %   - URL pattern handling
    %   - Data parsing and validation
    %   - Error handling and recovery
    
    properties
        Source  % AGA data source instance
    end
    
    methods (TestMethodSetup)
        function setup(testCase)
            %SETUP Test setup
            %   Creates a fresh AGA source instance for each test
            try
                % Ensure we're in the correct directory
                currentDir = pwd;
                testDir = fileparts(mfilename('fullpath'));
                if ~strcmp(currentDir, testDir)
                    cd(testDir);
                end
                
                % Create a new instance
                testCase.Source = AustralianGovernmentActuarySource('OverwriteExisting', true);
                
                % Verify the instance was created properly
                testCase.verifyClass(testCase.Source, 'AustralianGovernmentActuarySource', ...
                    'Source should be an instance of AustralianGovernmentActuarySource');
                testCase.verifyNotEmpty(testCase.Source, 'Source should not be empty');
                
            catch ME
                testCase.verifyFail(['Failed to initialize AGA source: ' ME.message]);
            end
        end
    end
    
    methods (TestMethodTeardown)
        function teardown(testCase)
            %TEARDOWN Clean up after each test
            %   Clears the cache and resets the source
            try
                if ~isempty(testCase.Source) && isobject(testCase.Source)
                    testCase.Source.clearCache();
                end
            catch ME
                warning('test_AGA:teardown:cacheClearFailed', 'Failed to clear cache during teardown: %s', ME.message);
            end
        end
    end
    
    methods (Test)
        function testInitialization(testCase)
            %TESTINITIALIZATION Test initialization of AGA source
            %   Verifies that AGA source initializes correctly
            testCase.verifyNotEmpty(testCase.Source, 'Source should not be empty');
            testCase.verifyEqual(testCase.Source.SourceName, 'Australian Government Actuary', 'Source name should be correct');
            testCase.verifyEqual(testCase.Source.SourceURL, 'https://aga.gov.au/publications/life-tables', 'Source URL should be correct');
            testCase.verifyEqual(testCase.Source.UrlCache.Count, uint64(4), 'UrlCache should have 4 tables at initialization');
        end
        
        function testFetchLatestData(testCase)
            %TESTFETCHLATESTDATA Test latest data fetching
            %   Verifies fetching of most recent mortality table
            %% 
            data = testCase.Source.fetchLatestData; %TODO make latest data either an
            testCase.verifyNotEmpty(data);
            testCase.verifyTrue(isfield(data, 'Male'));
            testCase.verifyTrue(isfield(data, 'Female'));
            testCase.verifyNotEmpty(data.Male.Age);
            testCase.verifyNotEmpty(data.Female.Age);
        end
        
        function testFetchAllTables(testCase)
            %TESTFETCHALLTABLES Test fetching all tables
            %% 
            %   Verifies fetching of all available tables
            testCase.Source.fetchAllTables();
            tables = testCase.Source.getAvailableTables();
            testCase.verifyNotEmpty(tables);
            testCase.verifyTrue(length(tables) > 0);
        end
        
        function testTableValidation(testCase)
            %TESTTABLEVALIDATION Test table data validation
            %   Verifies validation of table data structure
            data = testCase.Source.fetchLatestData();
            testCase.verifyTrue(testCase.Source.validateTableData(data.Male));
            testCase.verifyTrue(testCase.Source.validateTableData(data.Female));
        end
        
        function testUrlPatterns(testCase)
            %TESTURLPATTERNS Test URL pattern handling
            %   Verifies URL pattern generation and matching
            %TODO this test is using the generateURLsmethod() which has
            %TODO incorrect patterns. Base the patterns off the JSON file
            testCase.Source.testUrlPatterns();
            testCase.verifyNotEmpty(testCase.Source.UrlCache);
        end
        
        function testErrorHandling(testCase)
            %TESTERRORHANDLING Test error handling
            %   Verifies proper handling of invalid inputs
            testCase.verifyError(@() testCase.Source.getMortalityTable('InvalidTable'), 'MATLAB:invalidType');
        end
        
        function testCacheManagement(testCase)
            %TESTCACHEMANAGEMENT Test cache management
            %   Verifies proper cache initialization and clearing
            testCase.Source.clearCache();
            testCase.verifyEmpty(testCase.Source.getAvailableTables());
            
            data = testCase.Source.fetchLatestData();
            testCase.verifyNotEmpty(testCase.Source.getAvailableTables());
            
            testCase.Source.clearCache();
            testCase.verifyEmpty(testCase.Source.getAvailableTables());
        end
        
        function testDataConsistency(testCase)
            %TESTDATACONSISTENCY Test data consistency
            %   Verifies consistency of fetched data
            data1 = testCase.Source.fetchLatestData();
            data2 = testCase.Source.fetchLatestData();
            
            testCase.verifyEqual(data1.Male.Age, data2.Male.Age);
            testCase.verifyEqual(data1.Male.qx, data2.Male.qx);
            testCase.verifyEqual(data1.Male.lx, data2.Male.lx);
            testCase.verifyEqual(data1.Female.Age, data2.Female.Age);
            testCase.verifyEqual(data1.Female.qx, data2.Female.qx);
            testCase.verifyEqual(data1.Female.lx, data2.Female.lx);
        end
        
        function testUrlCache(testCase)
            %TESTURLCACHE Test URL caching
            %   Verifies URL cache functionality
            testCase.Source.fetchLatestData();
            testCase.verifyNotEmpty(testCase.Source.UrlCache);
            
            % Test cache persistence
            source2 = AustralianGovernmentActuarySource();
            testCase.verifyNotEmpty(source2.UrlCache);
        end
        
        function testLogging(testCase)
            %TESTLOGGING Test logging functionality
            %   Verifies proper logging of operations
            logDir = fullfile(fileparts(mfilename('fullpath')), 'logs');
            testCase.verifyTrue(exist(logDir, 'dir') == 7);
            
            testCase.Source.log('Test log message');
            logFiles = dir(fullfile(logDir, '*.log'));
            testCase.verifyNotEmpty(logFiles);
        end
    end
end 