classdef ImprovementFactorStrategy < handle
    methods (Abstract)
        averageImprovementFactors = calculateAverageFactors(obj, improvementFactors)
    end
end