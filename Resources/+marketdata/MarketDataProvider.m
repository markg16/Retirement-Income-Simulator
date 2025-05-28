classdef (Abstract) MarketDataProvider
    methods (Abstract)
        rateCurve = getRateCurveForScenario(obj, valuationDate, country, rateScenario);
        rateCurveSet = getRateCurveSet(obj, date);
        % ... (add other methods for retrieving equity prices, bond yields, etc.)
    end
end