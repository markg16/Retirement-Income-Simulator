% File: AnnuityWaterFallProgressionStrategy.m
classdef AnnuityWaterFallProgressionStrategy < PlotStrategy
    %HISTOGRAMSTRATEGY Plots distributions of annuity values.
    %   Creates a ridgeline plot using violins to show the distribution of
    %   annuity values for each category along the x-axis (e.g., for each age).

    methods
        
        function plot(obj, axesMap, allAnnuityValues, plotConfig)
            % This method now orchestrates the plotting of multiple waterfall segments
            % with custom ordering, coloring, labels, and annotations.
            
            if isempty(allAnnuityValues) || isempty(allAnnuityValues(1).Data), return; end

            annuityTypesToPlot = axesMap.keys;
            
            % annuityTypeData = allAnnuityValues(1);
            % annuityTypeName = annuityTypeData.AnnuityType;
            
            % if ~axesMap.isKey(annuityTypeName), return; end
            
            
            for j = 1:length(annuityTypesToPlot)
                annuityTypeData = allAnnuityValues(j);

                ax = axesMap(annuityTypesToPlot{j});
                cla(ax, 'reset');
                hold(ax, 'on');

                progressionResults = annuityTypeData.Data;
                numPeriods = height(progressionResults);

                % --- 1. Define the Plotting Configuration (Order and Colors) ---
                preferredOrder = {'Payment Out', 'Interest Earned', 'Cost of Mortality', 'Yield Curve Effect', 'Other'};

                % Use a containers.Map for the color lookup. It is more flexible
                % for this type of ad-hoc key-value assignment.
                colorMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
                colorMap('Payment Out')        = [0.85 0.33 0.10]; % Red
                colorMap('Interest Earned')    = [0.47 0.67 0.19]; % Green
                colorMap('Mortality Transfer')  = [0.6350 0.0780 0.1840]; % Maroon
                colorMap('Yield Curve Effect') = [0.9290 0.6940 0.1250]; % Amber
                colorMap('Other')              = [0.7 0.7 0.7];      % Grey
                startEndColor                  = [0 0.4470 0.7410]; % Blue
                preferredOrder = {'Payment Out', 'Interest Earned', 'Mortality Transfer', 'Yield Curve Effect', 'Other'};
                %preferredOrder = colorMap.keys; % The order is now driven by the map

                x_offset = 1.5; % Starting horizontal position for the first plot

                for i = 1:numPeriods
                    if mod(i-1, plotConfig.PlotInterval) ~= 0 && i ~= numPeriods, continue; end

                    progressionTimetable = progressionResults.ProgressionData{i};

                    categories = progressionTimetable.Categories; % The Time dimension
                    values = progressionTimetable.Change;

                    % --- Plot the Start Value ---
                    % Use logical indexing to find the 'Start Value' row
                    startValue = values(categories == 'Start Value');
                    bar(ax, x_offset, startValue, 'BarWidth', 0.8, 'FaceColor', startEndColor);
                    runningTotal = startValue;

                    % --- Reorder and Plot the Change Components ---
                    for k = 1:length(preferredOrder)
                        categoryName = preferredOrder{k};
                        if ~ismember(categoryName, categories), continue; end

                        % Use logical indexing to get the change for this category
                        currentChange = values(categories == categoryName);
                        barXPosition = x_offset + k;

                        utilities.PlottingUtils.plotFloatingBar(ax, barXPosition, runningTotal, runningTotal + currentChange, colorMap(categoryName));
                        plot(ax, [barXPosition - 0.5, barXPosition + 0.5], [runningTotal, runningTotal], 'k:');


                        % Add a text label inside or near the floating barwith
                        % the change value

                        % 1. Divide by 1000 to get value in thousands.
                        valueInK = currentChange / 1000;
                        % 2. Format the number with a sign and no decimal places.
                        formattedNum = sprintf('%+.0f', valueInK);
                        % 3. Concatenate with the desired currency and suffix.
                        formattedText = ['$' formattedNum 'k'];
                        %formattedText.Font = 14;

                        % Determine the Y position and alignment for the text
                        if currentChange > 0
                            % For positive bars, place text just above the starting baseline
                            textYPosition = runningTotal;
                            verticalAlign = 'bottom';
                        else
                            % For negative bars, place text just below the ending baseline
                            textYPosition = runningTotal + currentChange;
                            verticalAlign = 'top';
                        end

                        text(ax, barXPosition, textYPosition, formattedText, ...
                            'HorizontalAlignment', 'center', ...
                            'VerticalAlignment', verticalAlign, ...
                            'FontSize', 8, 'FontWeight', 'bold', 'Color', [0.2 0.2 0.2]);

                        runningTotal = runningTotal + currentChange;
                    end

                    % --- Plot the End Value ---
                    endValue = values(categories == 'End Value');
                    endBarPosition = x_offset + length(preferredOrder) + 1;
                    plot(ax, [endBarPosition - 1.5, endBarPosition], [runningTotal, runningTotal], 'k:');
                    bar(ax, endBarPosition, endValue, 'BarWidth', 0.8, 'FaceColor', startEndColor);


                    % --- 5. Add Arrow Annotation for this Period ---
                    startBarTop = values(1);
                    endBarTop = values(end);
                    textYPos = max(startBarTop, endBarTop) * 1.08; % Position arrow above the bars
                    arrowYPosStartBar =startBarTop *1.08;
                    arrowYPosEndBar = endBarTop*1.08;

                    % Draw the horizontal line of the arrow
                    plot(ax, [x_offset, endBarPosition], [arrowYPosStartBar, arrowYPosEndBar], 'k-', 'LineWidth', 1.5);
                    % Draw the left and right arrowheads as markers
                    plot(ax, x_offset, arrowYPosStartBar, '<k', 'MarkerFaceColor', 'k', 'MarkerSize', 8);
                    plot(ax, endBarPosition,  arrowYPosEndBar, '>k', 'MarkerFaceColor', 'k', 'MarkerSize', 8);

                    % Add the text label above the arrow with larger, bold font
                    meta = progressionTimetable.Properties.UserData;
                    arrowText = sprintf('Age %d to %d', meta.startAge, meta.endAge);
                    text(ax, x_offset + (endBarPosition - x_offset)/2, textYPos, arrowText, ...
                        'HorizontalAlignment', 'center', ...
                        'VerticalAlignment', 'bottom', ... % Position text above the arrow's Y coordinate
                        'FontSize', 10, 'FontWeight', 'bold');

                    % % Draw arrow
                    % a=annotation(ax.Parent, 'textarrow', ...
                    %     'X', [.1, .5], 'Y', [.8,.9], ...
                    %     'HeadStyle', 'vback2', 'HeadWidth', 8, 'HeadLength', 8);
                    %
                    % % Add text label for the arrow
                    % meta = progressionTimetable.Properties.UserData;
                    % arrowText = sprintf('Age %d to %d', meta.startAge, meta.endAge);
                    % a.String = arrowText;
                    %
                    % % text(ax, .2, .8, arrowText, ...
                    % %     'HorizontalAlignment', 'center', 'VerticalAlignment', 'bottom', 'FontSize', 10, 'FontWeight', 'bold');

                    % Update the offset for the next segment
                    x_offset = endBarPosition + 2; % Add a larger gap
                end

                % --- 5. Add Arrow and Text using Data Coordinates ---


                % --- 6. Store Tick Positions and Labels ---
                % % We set the ticks at the position of each bar.
                % allTickPositions = [allTickPositions, x_offset, (x_offset+1:endBarPosition-1), endBarPosition];
                % segmentLabels = [{'Start Value'}, preferredOrder, {'End Value'}];
                % allTickLabels = [allTickLabels, segmentLabels];
                % --- 6. Create a Single, Shared Legend ---
                legendEntries = {};
                proxyPlots = [];
                for k = 1:length(preferredOrder)
                    categoryName = preferredOrder{k};
                    % Plot an invisible point just to create a legend entry
                    proxyPlots(k) = patch(ax, NaN, NaN, colorMap(categoryName));
                    legendEntries{k} = categoryName;
                end
                legend(ax, proxyPlots, legendEntries, 'Location', 'bestoutside');

                % --- 7. Final Plot Formatting ---
                hold(ax, 'off');
                grid(ax, 'on');
                ylabel(ax, 'Annuity Present Value');
                xlabel(ax, 'Progression Period');
                title(ax, 'Multi-Period Annuity Value Progression');
                subtitle(ax,annuityTypeData.AnnuityType)
                set(ax, 'XTick', []); % Remove the numeric x-ticks
            end
        end


    end
end

% function plot(obj, axesMap, allAnnuityValues, plotConfig)
%             % This method now orchestrates the plotting of multiple waterfall segments and handles the formating of the chart.
% 
%             if isempty(allAnnuityValues) || isempty(allAnnuityValues(1).Data), return; end
% 
%             % For this plot, we use the first annuity type's data
%             annuityTypeData = allAnnuityValues(1);
%             annuityTypeName = annuityTypeData.AnnuityType;
% 
%             if ~axesMap.isKey(annuityTypeName), return; end
%             ax = axesMap(annuityTypeName);
%             cla(ax, 'reset');
%             hold(ax, 'on');
% 
%             progressionResults = annuityTypeData.Data;
%             numPeriods = height(progressionResults);
% 
%             % Define colors
%             colors.startEnd = [0 0.4470 0.7410]; % Blue
%             colors.increase = [0.47 0.67 0.19]; % Green
%             colors.decrease = [0.85 0.33 0.10]; % Red
% 
%             allTickPositions = [];
%             allTickLabels = {};
%             x_offset = 1;
% 
%             for i = 1:numPeriods
%                 % --- SAMPLING LOGIC ---
%                 % Check if this period should be plotted based on the interval
%                 if mod(i-1, plotConfig.PlotInterval) ~= 0 && i ~= numPeriods
%                     continue;
%                 end
% 
%                 progressionTimetable = progressionResults.ProgressionData{i};
%                 categories = progressionTimetable.Categories;
%                 values = progressionTimetable.Change;
% 
%                 % --- REDUNDANT TOTALS LOGIC ---
%                 if ~plotConfig.ShowRedundantTotals && i > 1
%                     % For presentation, remove the "Start Value" bar from all but the first segment
%                     categories = categories(2:end);
%                     values = values(2:end);
%                 end
% 
%                 % --- Build the labels and positions for this segment ---
%                 currentPositions = x_offset : (x_offset + length(categories) - 1);
%                 currentLabels = cellstr(categories);
% 
%                 % Add a detailed year/age label only to the first bar of the segment
%                 meta = progressionTimetable.Properties.UserData;
%                 currentLabels{1} = sprintf('%s\n(Age %d)', currentLabels{1}, meta.startAge);
% 
%                 allTickPositions = [allTickPositions, currentPositions];
%                 allTickLabels = [allTickLabels, currentLabels];
% 
%                 % Plot the segment using the helper
%                 utilities.PlottingUtils.plotWaterFallSegment(ax, categories, values, x_offset, colors);
% 
%                 % Update the offset for the next segment, adding a gap
%                 x_offset = x_offset + length(categories) + 1;
% 
%             end
% 
%             % % Add the final tick label for the very last end value
%             % if ~isempty(progressionResults)
%             %     finalTimetable = progressionResults.ProgressionData{end};
%             %     finalMeta = finalTimetable.Properties.UserData;
%             %     allTickPositions(end+1) = x_offset - 2; % Position under the last bar
%             %     % allTickLabels{end+1} = sprintf('%d\n(Age %d)', year(progressionResults.PeriodStart(end)) + 1, finalMeta.endAge);
%             % 
%             % end
% 
%             hold(ax, 'off');
%             grid(ax, 'on');
% 
%             % --- Final Plot Formatting ---
% 
%             ylabel(ax, 'Annuity Present Value');
%             xlabel(ax, 'Progression Start Year');
%             title(ax, 'Multi-Period Annuity Value Progression');
%             subtitle(ax, annuityTypeName);
% 
%             % Set the final, complete set of ticks and labels
%             set(ax, 'XTick', allTickPositions, 'XTickLabel', allTickLabels);
%             xtickangle(ax, 45); % Angle for readability
%             xlim(ax, [0.5, x_offset - 0.5]); % Tighten the x-axis limits
%         end
%     end
   


