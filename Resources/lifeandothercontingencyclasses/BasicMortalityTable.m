% Basic Mortality Table (Reads from file or creates if not found)
classdef BasicMortalityTable < MortalityTable
    properties
        TableFilePath
        MortalityRates struct % Add a property to store the loaded rates
        TableName
        SourceType
        SourcePath
        LastUpdated
    end
    
    methods (Static)
        function obj = BasicMortalityTable(tableFilePath, mortalityRates)
            obj.TableFilePath = tableFilePath;
            obj.MortalityRates = mortalityRates;
            obj.SourceType = 'File';
            obj.SourcePath = tableFilePath;
            obj.LastUpdated = datetime('now');
            obj.TableName = '';
            
            % Validate the data structure
            %TODO add error handling to log
            MortalityTableFactory.validateTableData(mortalityRates);
        end

        function obj = loadFromMAT(tableFilePath)
            data = load(tableFilePath);
            obj = BasicMortalityTable(tableFilePath, data.mortalityRates);
        end
    end

    methods
        function saveToMAT(obj)
            mortalityRates = obj.MortalityRates; % Extract for saving
            save(obj.TableFilePath, 'mortalityRates'); % Save to MAT file
        end
       
        function rate = getRate(obj, gender, age)
            % Get mortality rate for a specific age and gender
            ages = obj.MortalityRates.(gender).Age(:);
            idxAge = find(ages == age, 1);
            
            if isempty(idxAge)
                error('Invalid age: %d', age);
            end
            
            rate = obj.MortalityRates.(gender).qx(idxAge);
        end

        function lx = getLx(obj, gender, age)
            % TODO change this code to be a test of age is an element of
            % ages
            ages = obj.MortalityRates.(gender).Age(:);
            startAge = ages(1);
            startAgeIndex = find(ages == startAge);
            endAge = ages(end);
            endAgeIndex = find(ages == endAge);
            idxAge = find(ages == age);

            if idxAge >= startAgeIndex && idxAge <= endAgeIndex
                lx = obj.MortalityRates.(gender).lx(idxAge); % Assuming lx are stored in a vector indexed by age
            else
                error('Invalid age: %d', age);
            end
        end
        
        function survivorshipProbabilities = getSurvivorshipProbabilities(obj, gender, currentAge, finalAge)
            
            % Delegate the calculation to the utility function
          
            survivorshipProbabilities = utilities.LifeTableUtilities.getSurvivorship(obj, gender, currentAge, finalAge);
            
            
        end
        
        
    end
end