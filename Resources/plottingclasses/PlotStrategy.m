% File: PlotStrategy.m
classdef (Abstract) PlotStrategy < handle
    %PLOTSTRATEGY Abstract base class for different plotting strategies.
    %   Defines the interface for any class that can take annuity valuation
    %   data and render it onto a set of axes.

    methods (Abstract)
        % The main method that any concrete strategy must implement.
        plot(obj, axesMap, allAnnuityValues, plotConfig);
    end
end