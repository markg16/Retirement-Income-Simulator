classdef ImprovementFactorStrategy < handle
    methods (Abstract)
         % This abstract method now takes the file path and base table.
        % Each concrete strategy will implement this, using the inputs it needs.
        averageImprovementFactors = calculateFactors(obj, improvementFactorsFilePath, baseTable)
    end
end