% File: WaterfallPlotConfig.m
classdef WaterfallPlotConfig < handle
    %WATERFALLPLOTCONFIG Holds configuration settings for a progression waterfall plot.

    properties
        % If true, shows both the 'End Value' of one period and the 'Start Value'
        % of the next for testing. If false, hides the redundant 'Start Value'
        % for a cleaner presentation plot.
        ShowRedundantTotals (1,1) logical = false;
        
        % The interval for plotting. 1 means plot every period, 5 means plot
        % every fifth period, etc.
        PlotInterval (1,1) {mustBeInteger, mustBePositive} = 1;
    end

    methods
        function obj = WaterfallPlotConfig(varargin)
            % Constructor allows setting properties via name-value pairs.
            % Example: WaterfallPlotConfig('PlotInterval', 5)
            p = inputParser;
            addParameter(p, 'ShowRedundantTotals', obj.ShowRedundantTotals, @islogical);
            addParameter(p, 'PlotInterval', obj.PlotInterval, @isnumeric);
            parse(p, varargin{:});
            
            obj.ShowRedundantTotals = p.Results.ShowRedundantTotals;
            obj.PlotInterval = p.Results.PlotInterval;
        end
    end
end
