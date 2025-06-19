classdef MeanImprovementFactorStrategy < ImprovementFactorStrategy
    methods
        % function averageImprovementFactors = calculateAverageFactors(obj, improvementFactorsData)
        % 
        %     % Extract relevant columns
        %     ages = table2array(improvementFactorsData(:,1));
        %     maleFactors = table2array(improvementFactorsData(:,2));
        %     femaleFactors = table2array(improvementFactorsData(:,3));
        % 
        % 
        %     binEdges = [0 50 65 85 Inf]; % Include 'Inf' for the last "> 85" group
        %     [ageCounts, binEdges,binIdx] = histcounts(ages, binEdges);
        %     averageImprovementFactors = zeros(length(binEdges) - 1, 3); % Store male and female factors
        % 
        % 
        % 
        % 
        %     for i = 1:length(binEdges) - 1
        %         inBin = binIdx == i;
        %         averageImprovementFactors(i, 1) = binEdges(i);
        %         averageImprovementFactors(i, 2) = mean(maleFactors(inBin));
        %         averageImprovementFactors(i, 3) = mean(femaleFactors(inBin));
        %     end
        % 
        %     fieldNames = {'Age','Male','Female'};
        %     averageImprovementFactors = array2table(averageImprovementFactors,'VariableNames', fieldNames);
        %     averageImprovementFactors = table2struct(averageImprovementFactors);
        % end
         function averageImprovementFactors = calculateFactors(obj, improvementFactorsFilePath, ~)
            % This strategy USES the file path.

            % 1. Validate that a valid file path was provided.
            if isempty(improvementFactorsFilePath)
                error('MeanImprovementFactorStrategy:MissingFile', 'This strategy requires a valid improvementFactorsFilePath.');
            elseif ~isfile(improvementFactorsFilePath)
                 error('MeanImprovementFactorStrategy:FileNotFound', 'The specified improvementFactorsFilePath was not found: %s', improvementFactorsFilePath);
            end

            % 2. Load the raw data from the file.
            improvementFactorsData = utilities.LifeTableUtilities.loadImprovementFactors(improvementFactorsFilePath);

            % 3. Perform the averaging logic.
            ages = table2array(improvementFactorsData(:,1));
            maleFactors = table2array(improvementFactorsData(:,2));
            femaleFactors = table2array(improvementFactorsData(:,3));
            binEdges = [0 50 65 85 Inf]; 
            [~, ~, binIdx] = histcounts(ages, binEdges);
            
            avgFactorsMatrix = zeros(length(binEdges) - 1, 3);
            for i = 1:length(binEdges) - 1
                inBin = binIdx == i;
                avgFactorsMatrix(i, 1) = binEdges(i);
                avgFactorsMatrix(i, 2) = mean(maleFactors(inBin));
                avgFactorsMatrix(i, 3) = mean(femaleFactors(inBin));
            end
            
            % 4. Return a struct with the expected 'Age', 'Male', 'Female' fields.
            fieldNames = {'Age','Male','Female'};
            averageFactorsTable = array2table(avgFactorsMatrix, 'VariableNames', fieldNames);
            % Use 'struct' option for row-wise conversion to struct array
            averageImprovementFactors = table2struct(averageFactorsTable);
        end
    end
end