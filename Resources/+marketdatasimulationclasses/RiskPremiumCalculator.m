classdef (Abstract) RiskPremiumCalculator
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
     
    end

    methods (Abstract)
        riskPremiums = calculateRiskPremiums(obj,simulationStartDate, assetReturnStartDates, assetReturnFrequencyPerYear, marketDataAssetNames)
    end
end