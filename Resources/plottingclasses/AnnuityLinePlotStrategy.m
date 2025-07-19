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
                        stairs(ax, xAxisValues, yAxisValues, 'LineStyle', '-.','LineWidth', 1.5, ...
                             'Color', colors{mod(j-1, length(colors)) + 1}, ...
                             'Marker','o',...
                             'DisplayName', displayName);
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
                ylabel(ax, 'Annuity Present Value');
                title(ax, 'Sensitivity Analysis');
                subtitle(ax, annuityTypeData.AnnuityType);
            end

            % Create a SINGLE shared legend on the FIRST axes object
            if ~isempty(axesMap)
                lgd = legend(axesMap(annuityTypeName), 'show', 'Location', 'best');
                title(lgd, strrep(lineVarName, '_', ' '));
            end
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