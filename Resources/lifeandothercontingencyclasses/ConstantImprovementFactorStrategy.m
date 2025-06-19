classdef ConstantImprovementFactorStrategy < ImprovementFactorStrategy
    % Mock ImprovementFactorStrategy for testing
    properties
        ReturnConstantFactor = 0; % Default to 0% improvement (as a decimal, e.g., 0.01 for 1%)
    end
    methods
        function obj = ConstantImprovementFactorStrategy(constantFactor)
            if nargin > 0 && isnumeric(constantFactor)
                obj.ReturnConstantFactor = constantFactor;
            end
        end
        
        function factorsStruct = calculateFactors(obj, ~, baseTable)
            % This strategy IGNORES the filePath input.
            % It uses the baseTable to get the correct age vector.

            if isempty(baseTable) || isempty(baseTable.MortalityRates)
                error('ConstantImprovementFactorStrategy:MissingBaseTable', 'This strategy requires a valid baseTable with loaded rates to determine the age vector.');
            end

            % 1. Get the age vector from the base table to ensure alignment.
            %    We'll use the male age vector, assuming male and female are the same.
            ages = baseTable.MortalityRates.Male.Age;

            % 2. Create the factors struct.
            % The decorator's getImprovementFactor method divides by 100,
            % so we store the value multiplied by 100 (i.e., as a percentage point).
            factorsStruct.Age = ages;
            factorsStruct.Male = ones(size(ages)) * obj.ReturnConstantFactor * 100;
            factorsStruct.Female = ones(size(ages)) * obj.ReturnConstantFactor * 100;
        end

        function factors = calculateAverageFactors(obj, rawImprovementFactors)
            % If ReturnConstantFactor is set, create factors struct with this constant.
            % The decorator expects obj.ImprovementFactors to have .Age, .Male, .Female fields.
            % The decorator's getImprovementFactor method will divide these by 100.
            % So, if we want an effective 0.01 factor, this method should output 1.
            if ~isempty(obj.ReturnConstantFactor)
                factors.Age = rawImprovementFactors.Age; % Use ages from the raw input
                % Explicitly create Male and Female fields with the constant factor
                % The decorator will later divide by 100, so store factor * 100 here.
                factors.Male   = ones(size(rawImprovementFactors.Age)) * obj.ReturnConstantFactor * 100;
                factors.Female = ones(size(rawImprovementFactors.Age)) * obj.ReturnConstantFactor * 100;
            else
                % If no constant factor, pass through rawImprovementFactors.
                % Ensure it has the expected .Age, .Male, .Female structure if used this way.
                factors = rawImprovementFactors; 
            end
        end
    end
end
