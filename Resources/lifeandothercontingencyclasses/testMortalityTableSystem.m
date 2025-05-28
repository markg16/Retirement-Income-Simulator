% Test script for Mortality Table System
function testMortalityTableSystem()
    try
        % Create a test directory if it doesn't exist
        testDir = 'test_tables';
        if ~exist(testDir, 'dir')
            mkdir(testDir);
        end
        
        % Create a sample mortality table data structure
        testData = createTestMortalityData();
        
        % Save test data to a .mat file
        testFilePath = fullfile(testDir, 'test_mortality_table.mat');
        mortalityRates = testData;
        save(testFilePath, 'mortalityRates');
        
        % Test 1: Create table using factory
        fprintf('Test 1: Creating table using factory...\n');
        table = MortalityTableFactory.createTable('File', testFilePath, 'Test Table');
        assert(~isempty(table), 'Table creation failed');
        assert(strcmp(table.TableName, 'Test Table'), 'Table name not set correctly');
        assert(strcmp(table.SourceType, 'File'), 'Source type not set correctly');
        fprintf('Test 1 passed!\n\n');
        
        % Test 2: Validate table
        fprintf('Test 2: Validating table...\n');
        table.validate();
        assert(table.isValid(), 'Table validation failed');
        fprintf('Test 2 passed!\n\n');
        
        % Test 3: Test getRate method
        fprintf('Test 3: Testing getRate method...\n');
        rate = table.getRate('M', 25);
        assert(~isempty(rate), 'getRate failed');
        assert(rate > 0, 'Invalid rate value');
        fprintf('Test 3 passed!\n\n');
        
        % Test 4: Test getLx method
        fprintf('Test 4: Testing getLx method...\n');
        lx = table.getLx('F', 30);
        assert(~isempty(lx), 'getLx failed');
        assert(lx > 0, 'Invalid lx value');
        fprintf('Test 4 passed!\n\n');
        
        % Test 5: Test getSurvivorshipProbabilities
        fprintf('Test 5: Testing getSurvivorshipProbabilities...\n');
        probs = table.getSurvivorshipProbabilities('M', 25, 30);
        assert(~isempty(probs), 'getSurvivorshipProbabilities failed');
        assert(all(probs >= 0 & probs <= 1), 'Invalid probability values');
        fprintf('Test 5 passed!\n\n');
        
        % Test 6: Test getAvailableTables
        fprintf('Test 6: Testing getAvailableTables...\n');
        tables = MortalityTableFactory.getAvailableTables(testDir);
        assert(~isempty(tables), 'No tables found');
        assert(any(strcmp({tables.Name}, 'test_mortality_table')), 'Test table not found in list');
        fprintf('Test 6 passed!\n\n');
        
        % Test 7: Test error handling
        fprintf('Test 7: Testing error handling...\n');
        try
            table.getRate('M', 200); % Invalid age
            error('Should have thrown an error for invalid age');
        catch ME
            assert(contains(ME.message, 'Invalid age'), 'Wrong error message for invalid age');
        end
        fprintf('Test 7 passed!\n\n');
        
        % Clean up
        rmdir(testDir, 's');
        fprintf('All tests passed successfully!\n');
        
    catch ME
        fprintf('Test failed: %s\n', ME.message);
        fprintf('Error in: %s, line %d\n', ME.stack(1).name, ME.stack(1).line);
    end
end

function testData = createTestMortalityData()
    % Create sample mortality data structure
    ages = (0:100)';
    testData.M.Age = ages;
    testData.F.Age = ages;
    
    % Create sample lx values (starting with 100,000)
    % Using Gompertz-Makeham law for more realistic mortality rates
    a = 0.0001;  % Makeham parameter (base mortality)
    b = 0.00001; % Gompertz parameter (rate of mortality increase)
    c = 1.07;    % Gompertz parameter (age effect) - reduced from 1.1 for more realistic values
    
    % Male mortality (slightly higher than female)
    testData.M.lx = round(100000 * exp(-a * ages - (b/log(c)) * (c.^ages - 1)));
    testData.M.qx = -diff([testData.M.lx; 0]) ./ testData.M.lx;
    
    % Female mortality (80% of male mortality)
    testData.F.lx = round(100000 * exp(-0.8*a * ages - (0.8*b/log(c)) * (c.^ages - 1)));
    testData.F.qx = -diff([testData.F.lx; 0]) ./ testData.F.lx;
    
    % Ensure qx is between 0 and 1
    testData.M.qx = min(max(testData.M.qx, 0), 1);
    testData.F.qx = min(max(testData.F.qx, 0), 1);
end 