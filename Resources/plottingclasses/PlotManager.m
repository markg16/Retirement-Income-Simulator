% File: PlotManager.m
% This can be saved as a standalone class file.
classdef PlotManager
    %PLOTMANAGER A utility class to orchestrate the plotting of annuity sensitivity data.
    %   It acts as a client to the PlottingEngine and various PlotStrategy classes.

    methods (Static)
        function plotAnnuityValues(axesMap, allAnnuityValues, annuityParametersToPlot, plotType)
            % This static method is the main entry point for all plotting.
            % It is completely decoupled from the UI app.
            %
            % Inputs:
            %   axesHandles:             A cell array of axes handles to draw on.
            %   allAnnuityValues:        The struct array containing the data to plot.
            %   annuityParametersToPlot: A 1x2 array of indices for the x-axis and line variables.
            %   plotType:                A string, either 'line' or 'histogram'.
            
            % --- 1. SETUP ---
            
            % Input validation
            % --- 1. SETUP ---
            if nargin < 4, plotType = 'line'; end
            if ~isa(axesMap, 'containers.Map')
                error('PlotManager:InvalidInput', 'axesMap must be a containers.Map object.');
            end
            
            % Clear all provided axes before starting
            allAxes = axesMap.values;
            for i = 1:length(allAxes)
                cla(allAxes{i}, 'reset');
            end

           
            if isempty(allAnnuityValues)
                fprintf('PlotManager: No data provided to plot.\n');
                return;
            end

            % Define a configuration struct to pass to the plot strategies
            [annuityInputEnums, ~] = enumeration('AnnuityInputType');
            plotConfig = struct();
            plotConfig.xAxisEnum = annuityInputEnums(annuityParametersToPlot(1));
            plotConfig.lineVarEnum = annuityInputEnums(annuityParametersToPlot(2));
            
            % Determine which plotting strategy to use based on the requested plotType
            switch plotType
                case PlotType.AnnuityHistogramPlot
                    plotStrategy = AnnuityHistogramStrategy();
                case PlotType.AnnuityLinePlot
                    plotStrategy = AnnuityLinePlotStrategy();

               
                otherwise
                    error('PlotManager:InvalidPlotType', 'Invalid plotType specified. Use "line" or "histogram".');
            end

            % --- 2. EXECUTION ---
            
            % Create the plotting engine with the chosen strategy
            engine = PlottingEngine(plotStrategy);
            
            % The strategy now receives the axesMap instead of a cell array
            engine.render(axesMap, allAnnuityValues, plotConfig);
        end
        function plotProgression(axesMap, plotData,plotConfig)
            % This method handles plots that show a time-based progression,
            % like a waterfall chart. It does not need sensitivity parameters.
            %
            % Inputs:
            %   axesMap:          A containers.Map linking type names to axes handles.
            %   allAnnuityValues: The struct array containing the progression data.

            if ~isa(axesMap, 'containers.Map')
                error('PlotManager:InvalidInput', 'axesMap must be a containers.Map object.');
            end
            % This method now accepts a plotConfig object.
            if nargin < 3 || isempty(plotConfig)
                % Create a default config if one isn't provided
                plotConfig = WaterfallPlotConfig();
            end
            allAxes = axesMap.values;
            for i = 1:length(allAxes), cla(allAxes{i}, 'reset'); end

            if isempty(plotData), return; end

            % Directly create the specific strategy for this plot type
            plotStrategy = AnnuityWaterFallProgressionStrategy();

            % Create the engine and render the plot.
            % We pass an empty plotConfig because this strategy doesn't need it.
            engine = PlottingEngine(plotStrategy);
            engine.render(axesMap, plotData, plotConfig);
        end
    end
end
