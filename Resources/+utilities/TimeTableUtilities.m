classdef TimeTableUtilities
    %TIMETABLEUTILITIES Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods (Static)
        function obj = TimeTableUtilities(inputArg1,inputArg2)
            %TIMETABLEUTILITIES Construct an instance of this class
            %   Detailed explanation goes here
            obj.Property1 = inputArg1 + inputArg2;
        end

        function outputArg = method1(obj,inputArg)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            outputArg = obj.Property1 + inputArg;
        end

        function [combinedData,cutoverDate] = combineTimetablesByReplacement(existingTT, replacementTT)
            %COMBINETIMETABLESBYREPLACEMENT Combines two timetables, replacing existing data with new data from a specified cutover date.
            %
            %   combinedData = TimetableUtilities.combineTimetablesByReplacement(existingTT, replacementTT)
            %
            %   Inputs:
            %       existingTT: The original timetable containing existing data.
            %       replacementTT: The new timetable containing data to replace existing data from the cutover date onwards.
            %
            %   Outputs:
            %       combinedData: The combined timetable with replaced data.
            %
            %   Description:
            %   This function combines two timetables. It identifies the cutover date from the 'replacementTT'
            %   and replaces data in the 'existingTT' from that date onwards with data from the 'replacementTT'.
            %   If the cutover date is not found in the 'existingTT', the 'replacementTT' is simply appended.
            %
            %   Assumptions:
            %   - Both timetables have a 'Time' column representing the date/time index.
            %   - The 'replacementTT' is assumed to start from the cutover date.
            %
            %   Example:
            %   existingTT = timetable(datetime(2023,1,1:5)', [1:5]');
            %   replacementTT = timetable(datetime(2023,1,3:7)', [30:34]');
            %   combinedTT = TimetableUtilities.combineTimetablesByReplacement(existingTT, replacementTT);
            %   % combinedTT will contain data from 'existingTT' for 1st and 2nd Jan 2023,
            %   % and data from 'replacementTT' for 3rd to 7th Jan 2023.

            if ~isempty(existingTT) && ~isempty(replacementTT)
                % Extract the cutover date from the replacement timetable
                cutoverDate = replacementTT.Time(1);
                % % Harmonize Time formats before comparison and combination
                % desiredFormat ='dd-MM-yyyy';
                % existingTT.Time = datetime(existingTT.Time, 'Format', desiredFormat);
                % replacementTT.Time = datetime(replacementTT.Time, 'Format', desiredFormat);
                % cutoverDate = datetime(cutoverDate, 'Format', desiredFormat);

                % Create a time window around the cutoverDate
                timeWindow = [cutoverDate - minutes(90), cutoverDate + minutes(90)]; %allow for daylightsavings issues

                % Find indices within the time window
                cutoverIndex = find(existingTT.Time >= timeWindow(1) & existingTT.Time <= timeWindow(2));
                % Find the index in the existing data where the cutover date starts
                %cutoverIndex = find(existingTT.Time == cutoverDate);

                %TODO work out how to deal with no match or multiple
                %matches. Why are some times shifting an hour DLS? 

                % If the cutover date exists in the existing data, replace data from that point onwards
                if ~isempty(cutoverIndex)
                    combinedData = [existingTT(1:cutoverIndex-1,:); replacementTT];
                else
                    % If cutover date doesn't exist in the existingData TT, simply append replacement data to the end
                    combinedData = [existingTT; replacementTT];
                end
            elseif ~isempty(existingTT) && isempty(replacementTT)
                combinedData = existingTT;
            elseif isempty(existingTT) && ~isempty(replacementTT)
                combinedData = replacementTT;
            end

        end
        function rebasedData = rebaseTimeSeries(data, timeColumn, startValue, startDate)
            % rebaseTimeSeries Rebases a time series data to a specified value at a given start date.

            %   Inputs:
            %       data: Table containing the time series data.
            %       timeColumn: Name of the column containing time information (e.g., 'Time').
            %       startValue: The value to which the time series should be rebased (e.g., 10000).
            %       startDate: The date at which the rebasing should start.

            %   Output:
            %       rebasedData: Table with the rebased time series data.

            % Find the index of the start date
            startIndex = find(data.(timeColumn) >= startDate, 1);

            % Extract the original values
            valuesToRebase = data{startIndex:end, :}; % Assuming all columns need rebasing

            % Get the number of columns to rebase
            numColumns = size(valuesToRebase, 2);

            % Rebase each column individually
            rebasedValues = valuesToRebase; % Initialize with original values
            for col = 1:numColumns
                % Calculate the rebasing factor for the current column
                baseValue = valuesToRebase(1, col);
                rebaseFactor = startValue / baseValue;

                % Rebase the values for the current column
                rebasedValues(:, col) = valuesToRebase(:, col) * rebaseFactor;
            end
            % Create a new table with rebased values
            rebasedData = data;
            rebasedData{startIndex:end, :} = rebasedValues;
        end
        function numericVars = getNumericVariables(timetable)
            %GETNUMERICVARIABLES Returns the names of the numeric variables in a timetable.

            varNames = timetable.Properties.VariableNames;
            isNumeric = cellfun(@isnumeric, timetable.Variables, 'UniformOutput', false);
            numericVars = varNames(cell2mat(isNumeric));
            numericVars = varNames(varfun(@isnumeric, timetable, 'OutputFormat', 'uniform'));
        end
    end
end


