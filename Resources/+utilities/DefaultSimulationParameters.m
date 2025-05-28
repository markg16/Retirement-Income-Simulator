classdef DefaultSimulationParameters
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties(Constant)
        defaultReferenceTime = hours(17)
        defaultSimulationStartDate = dateshift(datetime('03/31/2018','InputFormat','MM/dd/uuuu'),'start','day')
        defaultTimeZone ='Australia/Sydney';
        defaultRiskPremium = 0.03;
        
    end

   
end