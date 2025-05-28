classdef (Abstract) ScenarioDataProvider
    methods (Abstract)
        rateCurve = getInflationAssumption(obj);
        % ... (add other methods for retrieving equity prices, bond yields, etc.)
        rateScenarios = getRateScenarios(obj); %returns the rate scenario property of the scenario object

    end
end