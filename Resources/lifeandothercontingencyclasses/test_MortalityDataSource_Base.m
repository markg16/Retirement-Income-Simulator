% File: test_MortalityDataSource_Base.m
classdef (Abstract) test_MortalityDataSource_Base < matlab.unittest.TestCase
    %TEST_MORTALITYDATASOURCE_BASE Abstract base class for testing any MortalityDataSource.
    %   Contains generic tests for caching, error handling, and basic data structure.
    %   Subclasses must implement the 'createDataSource' method to provide the
    %   specific data source instance to be tested, and helper methods to provide
    %   valid/invalid table identifiers.

    properties
        DataSource % Property to hold the specific data source instance under test
    end

    % --- Abstract methods that concrete test classes MUST implement ---
    methods (Abstract, TestMethodSetup)
        % This method is responsible for creating an instance of the specific
        % data source subclass (e.g., AustralianGovernmentActuarySource).
        createDataSource(testCase);
    end
    
    methods (Abstract, Access = protected)
        % This method must return a valid table identifier for the specific data source.
        % For AGA, it's a TableNames enum. For Analytical, it's a struct.
        identifier = getValidTableIdentifier(testCase);
        
        % This method must return an invalid table identifier.
        identifier = getInvalidTableIdentifier(testCase);
    end
    
    % --- Teardown method, runs after every test ---
    methods (TestMethodTeardown)
        function cleanupDataSource(testCase)
            % Clean up after each test by clearing the cache and deleting the object.
            if ~isempty(testCase.DataSource) && isvalid(testCase.DataSource)
                testCase.DataSource.clearCache();
                delete(testCase.DataSource);
            end
        end
    end

    % --- GENERIC TESTS APPLICABLE TO ALL DATA SOURCES ---
    methods (Test)
        function testConstructorAndProperties(testCase)
            % This generic test verifies that any created source is valid.
            testCase.verifyClass(testCase.DataSource, 'MortalityDataSource', ...
                'The created source must be a subclass of MortalityDataSource.');
            testCase.verifyNotEmpty(testCase.DataSource.SourceName, 'SourceName property must be set in the constructor.');

            % Instead of accessing the property directly, use the public getter method.
            testCase.verifyNotEmpty(testCase.DataSource.getCacheManager(), 'CacheManager must be initialized.');

        end

        function testGenericCacheManagement(testCase)
            % This generic test verifies the fundamental caching logic.
            
            % Get a valid table identifier from the concrete test class
            validIdentifier = testCase.getValidTableIdentifier();
            
            % First call should generate and cache the data.
            table1 = testCase.DataSource.getMortalityTable(validIdentifier);
            
            % Verify it's now in the cache
            availableTables = testCase.DataSource.getAvailableTables();
            testCase.verifyNumElements(availableTables, 1, 'Cache should contain exactly one table after fetching.');
            
            % Get the same table again. Because we are using handle classes for our tables,
            % we expect the exact same object handle to be returned from the cache.
            table2 = testCase.DataSource.getMortalityTable(validIdentifier);
            testCase.verifySameHandle(table1, table2, 'A second call for the same identifier should return the same cached object handle.');
        end
        
        function testGenericErrorHandling(testCase)
            % Tests that the source correctly errors on invalid input.
            invalidIdentifier = testCase.getInvalidTableIdentifier();
            
            % We verify that *an* error is thrown. The specific error ID might differ
            % between sources, so verifying against the base MException is robust.
            testCase.verifyError(@() testCase.DataSource.getMortalityTable(invalidIdentifier), ?MException, ...
                'The getMortalityTable method should throw an exception for an invalid table identifier.');
        end
    end
end
