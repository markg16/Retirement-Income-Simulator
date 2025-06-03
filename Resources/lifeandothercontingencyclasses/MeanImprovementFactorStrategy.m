classdef MeanImprovementFactorStrategy < ImprovementFactorStrategy
    methods
        function averageImprovementFactors = calculateAverageFactors(obj, improvementFactorsData)
            
            % Extract relevant columns
            ages = table2array(improvementFactorsData(:,1));
            maleFactors = table2array(improvementFactorsData(:,2));
            femaleFactors = table2array(improvementFactorsData(:,3));


            binEdges = [0 50 65 85 Inf]; % Include 'Inf' for the last "> 85" group
            [ageCounts, binEdges,binIdx] = histcounts(ages, binEdges);
            averageImprovementFactors = zeros(length(binEdges) - 1, 3); % Store male and female factors
            

           

            for i = 1:length(binEdges) - 1
                inBin = binIdx == i;
                averageImprovementFactors(i, 1) = binEdges(i);
                averageImprovementFactors(i, 2) = mean(maleFactors(inBin));
                averageImprovementFactors(i, 3) = mean(femaleFactors(inBin));
            end

            fieldNames = {'Age','Male','Female'};
            averageImprovementFactors = array2table(averageImprovementFactors,'VariableNames', fieldNames);
            averageImprovementFactors = table2struct(averageImprovementFactors);
        end
    end
end