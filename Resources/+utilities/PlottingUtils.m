% File: +utilities/PlottingUtils.m
classdef PlottingUtils
    %PLOTTINGUTILS A collection of static helper methods for plotting.

    methods (Static)
        

        function ax = plotWaterFallSegment(ax, categories,values,x_offset,colors)
                 % This self-contained helper function draws a complete waterfall chart
            % using fundamental bar objects and their BaseValue property.
            
            hold(ax, 'on');
            numBars = length(values);
            % xlim(ax, [+0.5, x_offset+numBars + 0.5]);
            
            % Define colors for different bar types
            startEndColor = colors.startEnd; % Blue
            increaseColor =  colors.increase; % Green
            decreaseColor = colors.decrease; % Red

            % Plot the first bar (Start Value) which always starts at 0
            b = bar(ax, x_offset, values(1), 'BarWidth', 0.6, 'FaceColor', startEndColor);
            b.BaseValue = 0;
            
            %runningTotal = values(1);
            runningTotal =0;
            
            % Plot intermediate bars (the changes)
            % 2. Loop through the intermediate "change" bars.
            for i = 1:(numBars - 1)
                x_index = x_offset -1 +i;
                currentChange = values(i);

                % --- This is the key technique for floating bars ---
                % Plot two bars stacked: an invisible base and a visible change.

                if currentChange >=0
                    b = bar(ax, x_index, [runningTotal, currentChange], 'stacked', 'BarWidth', 0.6);
                else
                    b = bar(ax, x_index, [runningTotal+currentChange, -currentChange], 'stacked', 'BarWidth', 0.6);
                end

                %b = bar(ax, i, currentChange, 'baseValue',  runningTotal,'ShowBaseLine', 'off', 'BarWidth', 0.6,'CData', increaseColor)

                %h(end+1) = bar(ax(i+1), i+1, to(i), 'CData', c(i), 'BaseValue', from(i), 'ShowBaseLine', 'off')

                % Make the base bar invisible
                b(1).FaceColor = 'none';
                b(1).EdgeColor = 'none';
                
                % Color the visible change bar
                if currentChange > 0
                   b(1).FaceColor = 'none';
                   b(2).FaceColor = increaseColor;
                else
                    b(2).FaceColor = decreaseColor;
                end
                
                % Draw the connector line from the top of the previous total
                plot(ax, [x_index - 1, x_index], [runningTotal, runningTotal], 'k--');
                
                % Update the running total for the next bar's baseline
                runningTotal = runningTotal + currentChange;
            end
            
            % 3. Plot the final bar (End Value). It's also an absolute total.
            if numBars > 1
                % Draw the final connector line
                plot(ax, [x_offset+numBars - 1, x_offset+numBars], [runningTotal, runningTotal], 'k--');
                
                % Plot the final bar
                bar(ax, x_offset+numBars-1, values(numBars), 'BarWidth', 0.6, 'FaceColor', startEndColor);
            end
            
            hold(ax, 'off');
            
            % --- Final Plot Formatting ---
            grid(ax, 'on');
                       
        end
        
        function plotFloatingBar(ax, x_pos, y_start, y_end, color)
            % This helper function draws a single floating rectangular bar (a patch).
            % It is the fundamental building block for the waterfall chart.
             % --- 1. Draw the Patch Object  ---
            % Define the four corners of the rectangle
            % [x-left, x-right, x-right, x-left]
            patchX = [x_pos - 0.4, x_pos + 0.4, x_pos + 0.4, x_pos - 0.4];
            % [y-bottom, y-bottom, y-top, y-top]
            patchY = [y_start, y_start, y_end, y_end];
            
            % Draw the patch object
            patch(ax, patchX, patchY, color, 'EdgeColor', 'k');

            % --- 2. Create and Apply the Custom Data Tip ---
            
            % % Create a new data tip template object (NO OUT OF BOX
            % % datatiptemplate for patches
            % dtt = datatip().DataTipTemplate;
            % 
            % % Add a row to the data tip for the category name
            % dtt.DataTipRows(1) = dataTipTextRow('Component', {categoryName});
            % 
            % % Add a row for the change value, formatted nicely
            % changeValue = y_end-y_start;
            % formattedChange = sprintf('%+,.2f', changeValue); % Shows +/- and commas
            % dtt.DataTipRows(2) = dataTipTextRow('Change', {formattedChange});
            % 
            % % Store the change value in the patch's UserData property.
            % % This is not strictly needed for the data tip above, but is good practice
            % % if you ever want to programmatically access the value from the patch handle.
            % p.UserData.ChangeValue = changeValue;
            % 
            % % Assign the custom template to this specific patch object
            % p.DataTipTemplate = dtt;
        end

        
       
        function legendStr = formatAnnuityInputTypeLegendEntry(annuityParamEnum, value)
            % Formats a value for a plot legend based on its AnnuityInputType.
            % Inputs:
            %   paramEnum: The AnnuityInputType enum member corresponding to the value.
            %   value:     The actual data value (can be numeric, datetime, etc.).
            
            % Use a switch statement to handle different formatting rules.
            switch annuityParamEnum
                case AnnuityInputType.InterestRate
                    legendStr = sprintf('%.2f%%', value * 100);

                case AnnuityInputType.ValuationDate
                    if isdatetime(value)
                        % Use a clear, unambiguous date format.
                        legendStr = datestr(value, 'dd-mmm-yyyy');
                    else
                        % Fallback if the value isn't a datetime object.
                        legendStr = num2str(value);
                    end
                    
                case AnnuityInputType.Age
                    legendStr = sprintf('%d years old', round(value));
                    
                case AnnuityInputType.AnnuityTerm
                    legendStr = sprintf('%d year term', round(value));
                    
                case AnnuityInputType.DefermentPeriod
                    legendStr = sprintf('%d year deferment', round(value));
                    
                case AnnuityInputType.AnnuityIncomeGtdIncrease
                    legendStr = sprintf('%.1f%% p.a. increase', value * 100);
                case AnnuityInputType.MortalityIdentifier
                    % Check if the value is an enum (like TableNames)
                    if isenum(value)
                        % Convert the enum member to its character string name
                        legendStr = char(value);
                        % Replace underscores with spaces for a cleaner look
                        legendStr = strrep(legendStr, '_', ' ');
                    elseif isstruct(value)
                        % Handle the analytical model struct identifier
                        legendStr = sprintf('%s (B=%.4f, c=%.2f)', value.Model, value.B, value.c);
                    else
                        % Fallback for any other type
                        legendStr = char(value);
                    end

                otherwise
                    % A generic fallback for any other numeric type.
                    legendStr = num2str(value);
            end
        end
    end
end