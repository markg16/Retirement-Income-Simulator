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
            survivorshipProbabilities = utilities.LifeTableUtilities.calculateSurvivorship(obj, gender, currentAge, finalAge);
            
            % %test to see if final age for survivorship is beyond the length
            % %of the mortality rates table.
            % ages = obj.MortalityRates.(gender).Age(:);
            % startAgeofTable = ages(1);
            % endAgeofTable = ages(end);
            % qxEndAgeofTable = obj.MortalityRates.(gender).qx(end); % use this to extend prob survival past end of table
            % 
            % % Initialize output array
            % survivorshipProbabilities = zeros(1, finalAge-currentAge);
            % 
            % % Calculate probabilities for each age
            % for i = 1:length(survivorshipProbabilities)
            %     age = currentAge + i - 1;
            %     if age <= endAgeofTable
            %         % Get index for current age
            %         ageIdx = find(ages == age, 1);
            %         if isempty(ageIdx)
            %             error('Invalid age: %d', age);
            %         end
            %         % Calculate survivorship probability
            %         survivorshipProbabilities(i) = obj.MortalityRates.(gender).lx(ageIdx)/obj.MortalityRates.(gender).lx(1);
            %     else
            %         % Extend past end of table assuming constant mortality
            %         lastValidProb = survivorshipProbabilities(i-1);
            %         survivorshipProbabilities(i) = lastValidProb * (1 - qxEndAgeofTable);
            %     end
            % end
        end
        
        function survivorshipProbabilitiesAtPaymentDates = getSurvivorshipProbabilitiesForEachPaymentDate(obj, survivorshipProbabilitiesToCompleteAge, paymentDatesToValue, paymentsPerYear)
            % probably would be better to use a decorator pattern

            % INPUT a table of survivorship probabilities nPx  life aged x at
            % inception survives to x+n complete years of age
            %OUTPUT  Return a timetable of survivorship probabilities linearly
            %interpolated from n to n+1 and only for ages included in the payment dates to value. Returning a timetable to make it
            %easier to check.
            % current code is not great. need toconvert to using
            % timetables. refactor annuity module around a timetable.

            totalYears = length(survivorshipProbabilitiesToCompleteAge);
            totalNumberFuturePayments = length(paymentDatesToValue);
            startIndex = totalYears*paymentsPerYear - totalNumberFuturePayments;
           
            tempSurvivorshipProbabilitiesAtPaymentDates = zeros(1, totalYears*paymentsPerYear-1);
            for idYears = 1:totalYears-1
                for idMonths = 1:paymentsPerYear
                    i = (idYears-1)*paymentsPerYear + idMonths;
                    tempSurvivorshipProbabilitiesAtPaymentDates(i) = survivorshipProbabilitiesToCompleteAge(idYears)+(survivorshipProbabilitiesToCompleteAge(idYears+1)-survivorshipProbabilitiesToCompleteAge(idYears))*idMonths/paymentsPerYear;
                end
               
               testId = 1 + (idYears-1)*paymentsPerYear;
               test(idYears) = tempSurvivorshipProbabilitiesAtPaymentDates(testId)-survivorshipProbabilitiesToCompleteAge(idYears);
            end

            survivorshipProbabilitiesAtPaymentDates = tempSurvivorshipProbabilitiesAtPaymentDates(startIndex:end)*1/tempSurvivorshipProbabilitiesAtPaymentDates(startIndex);
        end
    end
end