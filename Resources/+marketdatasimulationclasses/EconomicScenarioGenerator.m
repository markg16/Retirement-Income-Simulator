classdef (Abstract) EconomicScenarioGenerator
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    methods (Abstract)
        futureValues = simulateValues(obj,startValues);
        futureAssetReturns = simulateAssetReturns(obj);
        futureReturns = simulateFutureReturns(obj);
        end

end