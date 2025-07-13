% File: PlottingEngine.m
classdef PlottingEngine < handle
    %PLOTTINGENGINE Orchestrates the plotting of data using a given strategy.

    properties
        Strategy 
    end

    methods
        function obj = PlottingEngine(plotStrategy)
            % Constructor injects the desired plotting strategy.
            if ~isa(plotStrategy, 'PlotStrategy')
                error('PlottingEngine:InvalidStrategy', 'Input must be a valid PlotStrategy object.');
            end
            obj.Strategy = plotStrategy;
        end
        
        function set.Strategy(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'Strategy' property.

            % We validate that the incoming value is a valid PlotStrategy object.
            if ~isempty(value)
                mustBeA(value, 'PlotStrategy');
            end
            
            % If validation passes, assign the value to the property.
            obj.Strategy = value;
        end

        function render(obj, axesMap, data, plotConfig)
            % Delegates the actual plotting work to the injected strategy.
            try
                obj.Strategy.plot(axesMap, data, plotConfig);
            catch ME
                % Provide more context if the strategy fails
                fprintf(2, 'ERROR during plotting with strategy %s: %s\n', class(obj.Strategy), ME.message);
                % Optionally rethrow or handle gracefully
                rethrow(ME);
            end
        end
    end
end
