% File: LinePlotStrategy.m
classdef AnnuityLinePlotStrategy < PlotStrategy
    %LINEPLOTSTRATEGY Plots sensitivity data as a series of lines.
    %   Handles smart legend generation to avoid clutter.

    methods
        function plot(obj, axesMap, allAnnuityValues, plotConfig)
            % Implements the plot method for line-based graphs.
            
            colors = {'#0072BD', '#D95319', '#EDB120', '#7E2F8E', '#77AC30', '#4DBEEE', '#A2142F'}; % MATLAB's default color order

            % Determine which legend entries to show using the smart selection logic
             if ~isempty(allAnnuityValues)
                lineVarName = char(plotConfig.lineVarEnum);
                firstAnnuityData = allAnnuityValues(1).Data;
                uniqueLineParams = unique([firstAnnuityData.(lineVarName)]);
                legendIndicesToShow = obj.selectLegendEntries(uniqueLineParams);
            else
                return; % Nothing to plot
            end
            %Initialize arrays to store handles for the legend ---
            legendHandles = [];
            % Plot data for each annuity type
            for i = 1:length(allAnnuityValues)
                annuityTypeData = allAnnuityValues(i);
                % Correctly get the name of the annuity type from the data struct.
                annuityTypeName = annuityTypeData.AnnuityType;
                % Use the map to get the correct axes handle for this data type
                if ~axesMap.isKey(annuityTypeName)
                    warning('LinePlotStrategy:MissingAxes', 'No axes handle provided for AnnuityType "%s". Skipping plot.', annuityTypeName);
                    continue;
                end
                ax = axesMap(annuityTypeName);
                hold(ax, 'on');

                dataForPlot = annuityTypeData.Data;
                
                for j = 1:length(uniqueLineParams)
                    currentLineValue = uniqueLineParams(j);
                    indices = [dataForPlot.(lineVarName)] == currentLineValue;
                    
                    xAxisValues = [dataForPlot(indices).(char(plotConfig.xAxisEnum))];
                    yAxisValues = [dataForPlot(indices).AnnuityValue];

                    % Only provide 'DisplayName' for selected legend entries
                    if legendIndicesToShow(j)
                        displayName = utilities.PlottingUtils.formatAnnuityInputTypeLegendEntry(plotConfig.lineVarEnum, currentLineValue);
                        % plot(ax, xAxisValues, yAxisValues, 'LineWidth', 1.5, ...
                        %      'Color', colors{mod(j-1, length(colors)) + 1}, ...
                        %      'DisplayName', displayName);
                        h = stairs(ax, xAxisValues, yAxisValues/1000, 'LineStyle', '-.','LineWidth', 1.5, ...
                             'Color', colors{mod(j-1, length(colors)) + 1}, ...
                             'Marker','o',...
                             'DisplayName', displayName);
                        % Only add the handle for the first annuity type to avoid duplicates in the legend
                        if i == 1
                            legendHandles(end+1) = h;
                        end
                    else
                        % plot(ax, xAxisValues, yAxisValues, 'LineWidth', 1.5, ...
                             % 'Color', colors{mod(j-1, length(colors)) + 1}, ...
                             % 'HandleVisibility', 'off'); % Hide from legend
                         stairs(ax, xAxisValues, yAxisValues, 'LineWidth', 1.5, ...
                             'Color', colors{mod(j-1, length(colors)) + 1}, ...
                             'HandleVisibility', 'off'); % Hide from legend
                    end
                end
                
                hold(ax, 'off');
                grid(ax, 'on');
                xlabel(ax, strrep(char(plotConfig.xAxisEnum), '_', ' '));
                ylabel(ax, 'Present Value');
                title(ax, 'Sensitivity Analysis');
                subtitle(ax, AnnuityType.getDisplayTermContingency(annuityTypeData.AnnuityType));
                ytickformat(ax, '$%gk');
                ylabel(ax, 'Present Value (in thousands)');
                %utilities.PlottingUtils.format_yaxis('$k',ax)
            end
            %Create ONE shared legend for the entire figure ---
            if ~isempty(legendHandles)
               
                % Create the legend on the figure, not a specific subplot
                lgd = legend( legendHandles, 'Location', 'eastoutside');
                title(lgd, strrep(lineVarName, '_', ' '));
            end
            % --- NEW FINAL STEP: SET THE PRE-COPY CALLBACK ---
            % % Find the parent FIGURE of the axes, skipping over any layout managers.
            % fig = ancestor(ax, 'figure');
            % % Call the utility to set the callback. Use the appropriate dimension.
            % utilities.PlottingUtils.setPrintCallback(fig, axesMap, '$k');
            
        end
    end
    
    methods (Access = private, Static)
        function indicesToShow = selectLegendEntries(lineParams, maxEntries)
            % Selects a representative sample of legend entries to show.
            if nargin < 2, maxEntries = 10; end
            
            n = length(lineParams);
            indicesToShow = false(1, n);

            if n <= maxEntries
                indicesToShow(:) = true; % Show all if there are few
            else
                % Show first, last, and a sample in between
                indicesToShow(1) = true;
                indicesToShow(end) = true;
                
                % Select evenly spaced indices for the middle entries
                numMiddleEntries = maxEntries - 2;
                middleIndices = round(linspace(2, n-1, numMiddleEntries));
                indicesToShow(middleIndices) = true;
            end
        end
    end
end