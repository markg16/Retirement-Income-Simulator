classdef LifeTableUtilities
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        % Helper function to load or create base table
        
        function baseTable = loadOrCreateBaseTable(tableFilePath)
            if isfile(tableFilePath)
                baseTable = BasicMortalityTable.loadFromMAT(tableFilePath); % Load from MAT file
            else
                [baseLifeTableFolder, tableName, ~] = fileparts(tableFilePath);
                %baseLifeTableFolder = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables';

                % Get male and female file paths based on table name
                maleFile = fullfile(baseLifeTableFolder, [tableName '_Males.xlsx']);
                femaleFile = fullfile(baseLifeTableFolder,  [tableName '_Females.xlsx']);

                % Read life tables (you need to implement readLifeTables function)
                baseTable = utilities.LifeTableUtilities.readLifeTables(maleFile, femaleFile);

                % Convert baseTable to BasicMortalityTable object
                baseTable = BasicMortalityTable(tableFilePath, baseTable);

                baseTable.saveToMAT(); % Save to MAT file
            end
        end
        
        
        function obj = loadBaseMortalityTable(obj,baseLifeTableFolder)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            %UNTITLED3 Summary of this function goes here
            %   Detailed explanation goes here
            % Read Base Life Table (assuming xlsx format)
            maleFile = fullfile(baseLifeTableFolder,"Australian_Life_Tables_2015-17_Males.xlsx");
            femaleFile = fullfile(baseLifeTableFolder,"Australian_Life_Tables_2015-17_Females.xlsx");
            baseLifeTable = utilities.LifeTableUtilities.readLifeTables(maleFile, femaleFile);
            obj = baseLifeTable;
            
        end
        
        
        function lifeTable = readLifeTables(maleFile, femaleFile)


            % Variable Names
            ageColumn = 1;
            lxColumn = 2;
            qxColumn = 5;


            try
                % Read Male Life Table
                maleData = readmatrix(maleFile, 'Sheet', 'Males', 'FileType', 'spreadsheet');
                % Check for sufficient number of columns
                if size(maleData, 2) < qxColumn
                    error('Male life table file has insufficient columns');
                end %end if

                lifeTable.M.Age = maleData(:, ageColumn);
                lifeTable.M.lx = maleData(:, lxColumn);
                lifeTable.M.qx = maleData(:, qxColumn);

                % Read Female Life Table
                femaleData = readmatrix(femaleFile, 'Sheet', 'Females', 'FileType', 'spreadsheet');
                % Check for sufficient number of columns
                if size(femaleData, 2) < qxColumn
                    error('Female life table file has insufficient columns');
                end %end if

                lifeTable.F.Age = femaleData(:, ageColumn);
                lifeTable.F.lx = femaleData(:, lxColumn);
                lifeTable.F.qx = femaleData(:, qxColumn);

            catch ME
                %handle errors gracefully
                disp('Error reading life tables: ');
                rethrow(ME);
            end % try catch block
        end
        
        function improvementFactors = loadImprovementFactors(filePath)
            try
                % Read from file
                improvementFactorsData = readmatrix(filePath, 'Sheet', 'ALT Improvement Factors', 'FileType', 'spreadsheet');

                % Error handling (as in your original code)
                if size(improvementFactorsData, 2) < 4
                    error('ImprovementFactors file has insufficient columns');
                end

                improvementFactors = table(improvementFactorsData(:,1), improvementFactorsData(:,2), improvementFactorsData(:,3), ...
                    'VariableNames', {'Age', 'MaleFactors', 'FemaleFactors'});

            catch ME

                %handle errors gracefully
                disp('Error reading improvement factors: ');
                rethrow(ME);

            end
        end

       
        function improvementFactor = selectImprovementFactor(age,lookupTable)

            numBins = size(lookupTable, 1);

            if age>= lookupTable(numBins,1)
                improvementFactor = lookupTable(numBins, 2);
            else
                for i = 1:numBins-1

                    if age >= lookupTable(i, 1) && age < lookupTable(i + 1, 1)
                        improvementFactor = -lookupTable(i, 2); % Select male/female factors from 2/3 columns
                        break; % improve perfromance by breaking out if match occurs
                    end

                end % end for
            end % end if else

        end

        function [revisedlx revisedqx] = adjustMortalityTable(qx,lx, localImprovementFactors, entryAge)

            revisedqx = qx;
            revisedlx = lx;



            % Error handling (check for valid age and gender in lifeTable)
            % ... (Implement checks based on your lifeTable structure)

            % % Identify entry Age group for the person
            % entryAgeGroup = find(localLifeTable.(gender).Age >= entryAge, 1, 'first');
            %

            % look through the remaining ages in the life table and calculate the
            % improvement factor for each
            maxAge = length(lx);

            for ii = 0:maxAge-entryAge
                %select the mortality rate to be improved
                xplusn = entryAge+ii;
                qxplusn = qx(xplusn);
                lxplusn = lx(xplusn);

                %select the improvement factor
                fxplusn = utilities.LifeTableUtilities.selectImprovementFactor(entryAge + ii,localImprovementFactors);

                % Apply improvement rates to base lx
                if ii == 0
                    revisedlx(xplusn) = lxplusn;
                    revisedqx(xplusn) = qxplusn;
                else
                    revisedqx(xplusn) = qxplusn* (1 - fxplusn/100)^ii;
                    revisedlx(xplusn) = revisedlx(xplusn-1) * (1-revisedqx(xplusn));
                end
            end

        end
    end
end