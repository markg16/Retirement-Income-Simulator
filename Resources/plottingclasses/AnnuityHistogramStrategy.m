% File: HistogramStrategy.m
classdef AnnuityHistogramStrategy < PlotStrategy
    %HISTOGRAMSTRATEGY Plots distributions of annuity values.
    %   Creates a ridgeline plot using violins to show the distribution of
    %   annuity values for each category along the x-axis (e.g., for each age).

    methods
        function plot(obj, axesMap, allAnnuityValues, plotConfig)
            % Implements the plot method for distribution-based visualizations.
            
            % For this plot, the x-axis variable is the "category" (e.g., Age)
            % and the y-axis variable ('AnnuityValue') is the data to be distributed.
            xAxisEnum = plotConfig.xAxisEnum;
            xAxisVarName = char(xAxisEnum);

            for i = 1:length(allAnnuityValues)
                annuityTypeData = allAnnuityValues(i);
                annuityTypeName = annuityTypeData.AnnuityType;

                if ~axesMap.isKey(annuityTypeName)
                    warning('HistogramStrategy:MissingAxes', 'No axes handle for AnnuityType "%s". Skipping plot.', annuityTypeName);
                    continue;
                end
                ax = axesMap(annuityTypeName);
                

                dataForPlot = annuityTypeData.Data;
                if isempty(dataForPlot)
                    title(ax, sprintf('%s (No Data)', annuityTypeName));
                    continue;
                end

                % Extract the raw categorical data and the value data
                xCategoriesRaw = [dataForPlot.(xAxisVarName)];
                yValues = [dataForPlot.AnnuityValue];

                % Ensure data is valid for plotting
                if isempty(xCategoriesRaw) || isempty(yValues)
                    title(ax, sprintf('%s (Not enough data)', annuityTypeName));
                    continue;
                end

                % Convert to MATLAB categorical type for consistent behavior in violinplot
                % This helps manage the order and plotting positions.
                xCategoriesCategorical = categorical(xCategoriesRaw);

                % --- Plotting Logic using NATIVE violinplot ---
                %1. The violinplot function handles the grouping internally based on the categorical array.
                v = violinplot(ax, xCategoriesCategorical, yValues);

                % Customize the appearance of the violins
                for k=1:length(v)
                    v(k).FaceColor = '#0072BD';
                    v(k).FaceAlpha = 0.3; % Make it semi-transparent
                    % v(k).ShowData = false; % Don't show individual data points on the violin
                end
                              
                 hold(ax, 'on');

                  % 2. Overlay the Swarm Chart to show individual data points
                swarmchart(ax, xCategoriesCategorical, yValues, ...
                    'filled', ...
                    'MarkerFaceAlpha', 0.6, ... % Semi-transparent points
                    'MarkerFaceColor', '#4DBEEE', ...
                    'HandleVisibility', 'off'); % Hide from legend
              
                % 2. Combine data into a table for robust stats calculation.
                inputTable = table(xCategoriesCategorical', yValues', 'VariableNames', {'Group', 'Value'});

                % 3. Use grpstats to calculate mean and std for each group.
                %    This returns a single, convenient table with all results.
                statsTable = grpstats(inputTable, 'Group', {'mean', 'std'}, 'DataVars', 'Value');
                
                % statsTable now contains columns like: Group, GroupCount, mean_Value, std_Value

                % 4. Extract the results for plotting.
                % The violinplot places categories at positions 1, 2, 3...
                xPositionsForOverlay = 1:height(statsTable); 
                means = statsTable.mean_Value;
                stdevs = statsTable.std_Value;
                
                % 5. Plot the error bars using these extracted values.
                errorbar(ax, xPositionsForOverlay, means, stdevs, 'o', 'Color', 'r', ...
                         'MarkerFaceColor', 'r', 'MarkerSize', 6, 'LineStyle', 'none', ...
                         'CapSize', 10, 'LineWidth', 1.5, 'DisplayName', 'Mean & Std Dev')
                
                hold(ax, 'off');
                
                % --- Final Plot Formatting ---
                grid(ax, 'on');
                title(ax, sprintf('Distribution of Annuity PV vs. %s', strrep(xAxisVarName, '_', ' ')));
                subtitle(ax, annuityTypeName);
                xlabel(ax, strrep(xAxisVarName, '_', ' '));
                ylabel(ax, 'Annuity Present Value');
                
                % The native violinplot automatically sets numeric/categorical labels.
                % If you need to format datetime, you can adjust the ticks.
                if isdatetime(categories(xCategoriesCategorical))
                     xtickangle(ax, 45);
                end
                
               % legend(ax, 'off'); % Turn off default legend from violin/box plot if it appears
                % You could create a custom legend for the mean/stdev markers if desired.
            end
        end
    end
end