classdef DefaultScenarioParameters
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties(Constant)
        defaultReferenceTime = hours(17)
        defaultStartDate = dateshift(datetime('03/31/2018','InputFormat','MM/dd/uuuu'),'start','day')
        defaultTimeZone ='Australia/Sydney';
        defaultEndDate = dateshift(datetime('03/31/2019','InputFormat','MM/dd/uuuu'),'start','day')
        defaultRateScenarios = "default level yield curve";
        defaultLevelRate = 0.03;
        defaultLevelInflationRate = 0.0;


    end

   
end