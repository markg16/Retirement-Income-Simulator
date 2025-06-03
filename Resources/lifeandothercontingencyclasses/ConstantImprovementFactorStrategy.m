classdef ConstantImprovementFactorStrategy < ImprovementFactorStrategy
    % Mock ImprovementFactorStrategy for testing
    properties
        ReturnConstantFactor = []; % e.g., 0.01 for 1% (input as a decimal)
    end
    methods
        function obj = ConstantImprovementFactorStrategy(constantFactor)
            if nargin > 0
                obj.ReturnConstantFactor = constantFactor;
            end
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
