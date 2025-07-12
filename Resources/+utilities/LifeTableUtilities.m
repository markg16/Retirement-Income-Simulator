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
        
        function interpolatedPeriodicProbs = interpolateAnnualSurvivorship(annualCompleteAgeProbs, paymentsPerYear)
            numCompleteYears = length(annualCompleteAgeProbs);
            if numCompleteYears == 0
                interpolatedPeriodicProbs = [];
                return;
            end

            % Prepend probability of surviving 0 years (which is 1) for interpolation base
            probsForInterpolation = [1, annualCompleteAgeProbs]; % Now [P0, P1, P2, ..., PN]

            numInterpolatedPeriods = numCompleteYears * paymentsPerYear;
            interpolatedPeriodicProbs = zeros(1, numInterpolatedPeriods);

            for iYear = 1:numCompleteYears % Corresponds to P(iYear-1) to P(iYear) from probsForInterpolation
                p_start_of_year = probsForInterpolation(iYear);     % This is P_(iYear-1)
                p_end_of_year   = probsForInterpolation(iYear+1); % This is P_(iYear)

                for iPeriodInYear = 0:paymentsPerYear
                    idx = (iYear-1) * paymentsPerYear + iPeriodInYear;
                    interpolatedPeriodicProbs(idx+1) = p_start_of_year + ...
                        (p_end_of_year - p_start_of_year) * (iPeriodInYear / paymentsPerYear);
                end
            end
        end

        function survivorshipProbabilities = getSurvivorship(tableInstance, gender, currentAge, finalAge)
            % Calculates survivorship probabilities using getLx and getRate from the tableInstance.
            % Inputs:
            %   tableInstance: An object that implements the MortalityTable interface
            %                  (i.e., has getLx and getRate methods).
            %   gender: 'Male' or 'Female'
            %   currentAge: Starting age for survivorship
            %   finalAge: Ending age for survivorship

            if finalAge < currentAge
                error('MortalityCalculationUtils:InvalidAgeOrder', 'finalAge must be greater than or equal to currentAge.');
            end

            outputLength = finalAge - currentAge;
            survivorshipProbabilities = zeros(1, outputLength);

            % Use the getLx method of the passed tableInstance
            lx_current_age_val = tableInstance.getLx(gender, currentAge);

            if lx_current_age_val == 0
                survivorshipProbabilities(:) = 0; % No one alive at current age
                return;
            end

            for t = 1:outputLength
                age_future = currentAge + t;

                try

                    % Call getLx and capture all three outputs
                    [lx_future_val, wasFound, errMsg] = tableInstance.getLx(gender, age_future);

                    if  wasFound == true
                        survivorshipProbabilities(t) = lx_future_val / lx_current_age_val;
                    else
                        if isprop(tableInstance, 'MortalityRates') && ...
                                isfield(tableInstance.MortalityRates, gender) && ...
                                ~isempty(tableInstance.MortalityRates.(gender).Age)

                            ages_in_table = tableInstance.MortalityRates.(gender).Age;
                            max_age_in_table = ages_in_table(end);

                            if age_future > max_age_in_table
                                if t == 1 || (currentAge + t - 1) < ages_in_table(1) || (currentAge + t - 1) > max_age_in_table % Check if previous step was also extrapolation
                                    lx_at_max_table_age = tableInstance.getLx(gender, max_age_in_table);
                                    prob_surv_at_max_table_age = lx_at_max_table_age / lx_current_age_val;
                                    qx_at_max_table_age = tableInstance.getRate(gender, max_age_in_table);
                                    survivorshipProbabilities(t) = prob_surv_at_max_table_age * (1 - qx_at_max_table_age)^(age_future - max_age_in_table);
                                else
                                    % Extrapolate from the previously calculated survivorship probability
                                    qx_at_max_table_age = tableInstance.getRate(gender, max_age_in_table);
                                    survivorshipProbabilities(t) = survivorshipProbabilities(t-1) * (1 - qx_at_max_table_age);
                                end
                            end
                        end
                    end
                catch ME
                    warning('calculateSurvivorship:FailedLookup', 'Could not retrieve starting lx value. Reason: %s', errMsg);
                    survivorshipProbabilities(t)= 0;
                    return;
                end
            end
            % try
                %     % Try to get lx for the future age directly
                %     % This will use the getLx method of tableInstance (either base or improved)
                %     lx_future_val = tableInstance.getLx(gender, age_future);
                %     survivorshipProbabilities(t) = lx_future_val / lx_current_age_val;
                % catch ME
                %     % Handle cases where age_future might be beyond the table's explicit range
                %     % This requires extrapolation logic using the tableInstance's last qx
                %     if strcmp(ME.identifier, 'CachedImprovementFactorDecorator:AgeNotFound') || ...
                %        strcmp(ME.identifier, 'BasicMortalityTable:AgeNotFound') % Or whatever your getLx error ID is for out of bounds
                % 
                %         % Need to access the MortalityRates of the tableInstance to get its age range
                %         % This assumes MortalityRates is a public or protected property accessible here,
                %         % or that tableInstance has methods to get its max age and last qx.
                %         % For simplicity, let's assume we can get the max age and last qx from the tableInstance.
                %         % This part might need tableInstance to expose its max age and last qx.
                %         % Alternatively, the getLx method itself should handle extrapolation.
                %         % Assuming getLx errors if out of bounds for now, and we implement extrapolation here.
                % 
                %         % Get the maximum age explicitly defined in the tableInstance's rates
                %         % This is a bit of a hack; ideally, tableInstance would have a getMaxAge method.
                %         if isprop(tableInstance, 'MortalityRates') && ...
                %            isfield(tableInstance.MortalityRates, gender) && ...
                %            ~isempty(tableInstance.MortalityRates.(gender).Age)
                % 
                %             ages_in_table = tableInstance.MortalityRates.(gender).Age;
                %             max_age_in_table = ages_in_table(end);
                % 
                %             if age_future > max_age_in_table
                %                 if t == 1 || (currentAge + t - 1) < ages_in_table(1) || (currentAge + t - 1) > max_age_in_table % Check if previous step was also extrapolation
                %                     lx_at_max_table_age = tableInstance.getLx(gender, max_age_in_table);
                %                     prob_surv_at_max_table_age = lx_at_max_table_age / lx_current_age_val;
                %                     qx_at_max_table_age = tableInstance.getRate(gender, max_age_in_table);
                %                     survivorshipProbabilities(t) = prob_surv_at_max_table_age * (1 - qx_at_max_table_age)^(age_future - max_age_in_table);
                %                 else
                %                     % Extrapolate from the previously calculated survivorship probability
                %                     qx_at_max_table_age = tableInstance.getRate(gender, max_age_in_table);
                %                     survivorshipProbabilities(t) = survivorshipProbabilities(t-1) * (1 - qx_at_max_table_age);
                %                 end
                %             else
                %                 % This should not be reached if getLx errors for out of bounds
                %                 % but is a fallback.
                %                 rethrow(ME); % Rethrow original error if not an age not found error we can handle
                %             end
                %         else
                %             rethrow(ME); % Cannot determine max age, rethrow.
                %         end
                %     else
                %         rethrow(ME); % Rethrow other errors
                %     end
                % end
            % end
        % end
    % end
        end
    end
end