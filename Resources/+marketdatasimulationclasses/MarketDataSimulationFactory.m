classdef (Abstract) MarketDataSimulationFactory
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    methods (Abstract)
        futureValues = simulate(obj,startValues);
        end

end