% Test script for reading mortality tables from the LifeTables folder
function testMortalityTableReading()
    try
        % Get the path to the LifeTables folder
        lifeTablesPath = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables';
        addpath('G:\My Drive\Kaparra Software\Rates Analysis\Resources');
        
        % Test 1: Read Australian Life Tables 2015-17 using LifeTableUtilities
        fprintf('Test 1: Reading Australian Life Tables 2015-17...\n');
        maleFile = fullfile(lifeTablesPath, 'Australian_Life_Tables_2015-17_Males.xlsx');
        femaleFile = fullfile(lifeTablesPath, 'Australian_Life_Tables_2015-17_Females.xlsx');
        
        % Check if files exist
        if ~isfile(maleFile)
            error('Male file does not exist: %s', maleFile);
        end
        if ~isfile(femaleFile)
            error('Female file does not exist: %s', femaleFile);
        end
        
        % Get sheet names from files
        [~, maleSheets] = xlsfinfo(maleFile);
        [~, femaleSheets] = xlsfinfo(femaleFile);
        
        fprintf('Male file sheets: %s\n', strjoin(maleSheets, ', '));
        fprintf('Female file sheets: %s\n', strjoin(femaleSheets, ', '));
        
        % Read the tables using LifeTableUtilities
        try
            lifeTable = utilities.LifeTableUtilities.readLifeTables(maleFile, femaleFile);
        catch ME
            fprintf('Error reading life tables:\n');
            fprintf('Message: %s\n', ME.message);
            fprintf('Stack trace:\n');
            for i = 1:length(ME.stack)
                fprintf('  File: %s, Line: %d, Name: %s\n', ...
                    ME.stack(i).file, ME.stack(i).line, ME.stack(i).name);
            end
            rethrow(ME);
        end
        
        % Validate the structure
        assert(isfield(lifeTable, 'M'), 'Male table data missing');
        assert(isfield(lifeTable, 'F'), 'Female table data missing');
        assert(isfield(lifeTable.M, 'Age'), 'Age data missing from male table');
        assert(isfield(lifeTable.M, 'lx'), 'lx data missing from male table');
        assert(isfield(lifeTable.M, 'qx'), 'qx data missing from male table');
        assert(isfield(lifeTable.F, 'Age'), 'Age data missing from female table');
        assert(isfield(lifeTable.F, 'lx'), 'lx data missing from female table');
        assert(isfield(lifeTable.F, 'qx'), 'qx data missing from female table');
        
        % Validate data ranges
        assert(all(lifeTable.M.Age >= 0), 'Invalid age in male table');
        assert(all(lifeTable.F.Age >= 0), 'Invalid age in female table');
        assert(all(lifeTable.M.lx > 0), 'Invalid lx in male table');
        assert(all(lifeTable.F.lx > 0), 'Invalid lx in female table');
        assert(all(lifeTable.M.qx >= 0 & lifeTable.M.qx <= 1), 'Invalid qx in male table');
        assert(all(lifeTable.F.qx >= 0 & lifeTable.F.qx <= 1), 'Invalid qx in female table');
        
        fprintf('Test 1 passed!\n\n');
        
        % Test 2: Test loadOrCreateBaseTable functionality
        fprintf('Test 2: Testing loadOrCreateBaseTable...\n');
        tableFilePath = fullfile(lifeTablesPath, 'Australian_Life_Tables_2015-17.mat');
        
        % Load or create the table
        try
            table = utilities.LifeTableUtilities.loadOrCreateBaseTable(tableFilePath);
        catch ME
            fprintf('Error loading/creating base table:\n');
            fprintf('Message: %s\n', ME.message);
            fprintf('Stack trace:\n');
            for i = 1:length(ME.stack)
                fprintf('  File: %s, Line: %d, Name: %s\n', ...
                    ME.stack(i).file, ME.stack(i).line, ME.stack(i).name);
            end
            rethrow(ME);
        end
        
        assert(~isempty(table), 'Table creation failed');
        assert(isa(table, 'BasicMortalityTable'), 'Table is not a BasicMortalityTable instance');
        fprintf('Test 2 passed!\n\n');
        
        % Test 3: Test specific values
        fprintf('Test 3: Testing specific mortality rates...\n');
        
        % Test male mortality rate at age 65
        maleRate = table.getRate('M', 65);
        assert(~isempty(maleRate), 'Failed to get male mortality rate');
        assert(maleRate > 0 && maleRate < 1, 'Invalid male mortality rate');
        
        % Test female mortality rate at age 65
        femaleRate = table.getRate('F', 65);
        assert(~isempty(femaleRate), 'Failed to get female mortality rate');
        assert(femaleRate > 0 && femaleRate < 1, 'Invalid female mortality rate');
        
        % Verify female mortality is lower than male at same age
        assert(femaleRate < maleRate, 'Female mortality should be lower than male at same age');
        
        fprintf('Test 3 passed!\n\n');
        
        % Test 4: Test improvement factors
        fprintf('Test 4: Testing improvement factors...\n');
        improvementFactorsFile = fullfile(lifeTablesPath, 'Improvement_factors_2015-17.xlsx');
        
        % Check if file exists
        if ~isfile(improvementFactorsFile)
            error('Improvement factors file does not exist: %s', improvementFactorsFile);
        end
        
        % Get sheet names from file
        [~, improvementSheets] = xlsfinfo(improvementFactorsFile);
        fprintf('Improvement factors file sheets: %s\n', strjoin(improvementSheets, ', '));
        
        % Load improvement factors
        try
            improvementFactors = utilities.LifeTableUtilities.loadImprovementFactors(improvementFactorsFile);
        catch ME
            fprintf('Error loading improvement factors:\n');
            fprintf('Message: %s\n', ME.message);
            fprintf('Stack trace:\n');
            for i = 1:length(ME.stack)
                fprintf('  File: %s, Line: %d, Name: %s\n', ...
                    ME.stack(i).file, ME.stack(i).line, ME.stack(i).name);
            end
            rethrow(ME);
        end
        
        assert(~isempty(improvementFactors), 'Failed to load improvement factors');
        assert(isa(improvementFactors, 'table'), 'Improvement factors should be a table');
        assert(all(ismember({'Age', 'MaleFactors', 'FemaleFactors'}, improvementFactors.Properties.VariableNames)), ...
            'Improvement factors table missing required columns');
        
        % Test improvement factor selection
        age = 65;
        maleFactor = utilities.LifeTableUtilities.selectImprovementFactor(age, table2array(improvementFactors(:, [1,2])));
        femaleFactor = utilities.LifeTableUtilities.selectImprovementFactor(age, table2array(improvementFactors(:, [1,3])));
        assert(~isempty(maleFactor), 'Failed to get male improvement factor');
        assert(~isempty(femaleFactor), 'Failed to get female improvement factor');
        
        fprintf('Test 4 passed!\n\n');
        
        % Test 5: Test mortality table adjustment
        fprintf('Test 5: Testing mortality table adjustment...\n');
        entryAge = 65;
        [revisedlx, revisedqx] = utilities.LifeTableUtilities.adjustMortalityTable(...
            lifeTable.M.qx, lifeTable.M.lx, table2array(improvementFactors(:, [1,2])), entryAge);
        
        assert(~isempty(revisedlx), 'Failed to get revised lx values');
        assert(~isempty(revisedqx), 'Failed to get revised qx values');
        assert(length(revisedlx) == length(lifeTable.M.lx), 'Revised lx has incorrect length');
        assert(length(revisedqx) == length(lifeTable.M.qx), 'Revised qx has incorrect length');
        assert(all(revisedqx >= 0 & revisedqx <= 1), 'Invalid revised qx values');
        
        fprintf('Test 5 passed!\n\n');
        
        fprintf('All tests passed successfully!\n');
        
    catch ME
        fprintf('Test failed: %s\n', ME.message);
        fprintf('Error in: %s, line %d\n', ME.stack(1).name, ME.stack(1).line);
        rethrow(ME);
    end
end 