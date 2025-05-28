classdef DateUtilities
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function frequencyPerYear = getFrequencyPerYear(frequency)
            %GETFREQUENCYPERYEAR Get the number of payments per year based on frequency.
            %
            %   FREQUENCYPERYEAR = GETPAYMENTSPERYEAR(FREQUENCY) returns the number of
            %   payments per year corresponding to the specified FREQUENCY.
            %
            %   Inputs:
            %       FREQUENCY: A string indicating the frequency of payments ('Monthly',
            %                  'Quarterly', 'Annually', etc.).
            %
            %   Outputs:
            %       FREQUENCYSPERYEAR: The number of payments per year.


            if isstring(frequency) %dealing with case where an enum has been stored as a string
                switch lower(frequency)
                    case "Minutely"
                        frequency = utilities.FrequencyType.Minutely;
                    case "Hourly"
                        frequency = utilities.FrequencyType.Hourly;
                    case "Daily"
                        frequency = utilities.FrequencyType.Daily;
                    case "Weekly"
                        frequency = utilities.FrequencyType.Weekly;
                    case "Monthly"
                        frequency = utilities.FrequencyType.Monthly;
                    case "Quarterly"
                        frequency = utilities.FrequencyType.Quarterly;
                    case "Annually"
                        frequency = utilities.FrequencyType.Annually;
                    otherwise
                        error('Invalid frequency. Supported frequencies: Monthly, Quarterly, Annually');
                end

            end

            switch lower(frequency)
                case utilities.FrequencyType.Minutely
                    frequencyPerYear = 525600;
                case utilities.FrequencyType.Hourly
                    frequencyPerYear = 8760;
                case utilities.FrequencyType.Daily
                    frequencyPerYear = 365;
                case utilities.FrequencyType.Weekly
                    frequencyPerYear = 52;
                case utilities.FrequencyType.Monthly
                    frequencyPerYear = 12;
                case utilities.FrequencyType.Quarterly
                    frequencyPerYear = 4;
                case utilities.FrequencyType.Annually
                    frequencyPerYear = 1;
                otherwise
                    error('Invalid frequency. Supported frequencies: Monthly, Quarterly, Annually');
            end


        end
        function yearDiff = calculateYearDiff(startDate, endDate)

            yearDiff = between(startDate,endDate,'Years');  % returns difference in years component of hte datetime variables



            % yearDiff = year(endDate) - year(startDate);
            %
            % % Adjust for cases where the endDate is earlier in the year than the startDate
            % if month(endDate) < month(startDate) || ...
            %         (month(endDate) == month(startDate) && day(endDate) < day(startDate))
            %     yearDiff = yearDiff - 1;
            % end
        end
        function numPeriods = calculateNumPeriodsBetweeenTwoDates(startDate, endDate,frequency)

            % numPeriods = year(endDate) - year(startDate);
            if isa(frequency,'utilities.FrequencyType')
                frequencyAlias = utilities.FrequencyType.getAlias(frequency);
                period = utilities.FrequencyType.getPeriod(frequency);

            end


            numPeriods = between(startDate,endDate,period);
            % % Adjust for cases where the endDate is earlier in the year than the startDate
            % if month(endDate) < month(startDate) || ...
            %         (month(endDate) == month(startDate) && day(endDate) < day(startDate))
            %     numPeriods = numPeriods - 1;
            % end
        end
        function numPeriods = convertDurationToPeriods(duration, frequency)

            if isa(frequency,'utilities.FrequencyType')
                frequencyAlias = utilities.FrequencyType.getAlias(frequency);

            end

            switch frequency
                case 'Daily'
                    numPeriods = days(duration);
                case 'Weekly'
                    numPeriods = calweeks(duration);
                case 'Monthly'
                    numPeriods = calmonths(duration);
                case 'Quarterly'
                    numPeriods = calquarters(duration);
                case 'Annually'
                    numPeriods = calyears(duration);
                case 'Hourly'
                    numPeriods = hours(duration);
                case 'Minutely'
                    numPeriods = minutes(duration);
                otherwise
                    error('Unsupported frequency type');
            end
        end
        function duration = convertFrequencyToDuration(frequency)

            if isa(frequency,'utilities.FrequencyType')
                frequencyAlias = utilities.FrequencyType.getAlias(frequency);

            end

            switch frequency
                case 'Daily'
                    duration = days(1);
                case 'Weekly'
                    duration = calweeks(1);
                case 'Monthly'
                    duration = calmonths(1);
                case 'Quarterly'
                    duration = calquarters(1);
                case 'Annually'
                    duration = calyears(1);
                case 'Hourly'
                    duration = hours(1);
                case 'Minutely'
                    duration = minutes(1);
                otherwise
                    error('Unsupported frequency type');
            end
        end
        function defaultSimulationStartDate = setDefaultSimulationStartDate()
            defaultSimulationStartDate = utilities.DefaultSimulationParameters.defaultSimulationStartDate + ...
                utilities.DefaultSimulationParameters.defaultReferenceTime;
            defaultTimeZone = utilities.DefaultSimulationParameters.defaultTimeZone;
            defaultSimulationStartDate.TimeZone = defaultTimeZone;

        end
        function result = isCalendarDurationGreaterThanTolerance(dur, varargin)
            defaultTol = utilities.Tolerance.AbsTol;

            p = inputParser;
            addRequired(p,'dur',@iscalendarduration)
            addParameter(p,'tol', defaultTol, @isdouble)

            parse(p,dur, varargin{:});

            dur = p.Results.dur;
            tol = p.Results.tol;

            % Assuming tol is also a calendarDuration
           %result = any(abs([calyears(dur),calmonths(dur), caldays(dur)]) > [tol,tol,tol]);

           [y,m,w,d,t] = split(dur,{'years','months','weeks','days','time'});
           
            result = any(abs([y,m,w,d,t]) > tol);
        end
        function [nextIndexationDate, nextEffectiveInflationDate] = calculateNextIndexationDate(currentDate, indexationMonthDays, effectiveInflationLag)

            % Assumes that effectvieInflationMonthDays and indexationDays
            % are sequenced so that indexx corresponds eg if the
            % position of indexationMonth is same as relevenat
            % effectiveInflationMonthDays
            % Input validation
            if ~isdatetime(indexationMonthDays)
                error("indexationMonthDays must be a datetime array.");
            end
            

            % Calculate the next indexation date after the current date
            currentYear = year(currentDate);
            currentMonth = month(currentDate);
            [~, indexationMonths, indexationDays] = datevec(indexationMonthDays);
                     
            %nextIndexMonth = indexationMonths(1); 
            nextIndexMonth = currentMonth; 

            for i = 1 : length(indexationMonths)

                if nextIndexMonth <= indexationMonths(i)
                    nextIndexMonth = indexationMonths(i);
                    indexationDay = indexationDays(i);
                     break;  % Exit the loop once the next month is found
                end
            end
            if i == length(indexationMonths) && currentMonth > indexationMonths(end)
                nextIndexMonth = indexationMonths(1);  % Wrap around to the first month if currentMonth is after the last indexation month
                currentYear = currentYear + 1; % Increment the year
                indexationDay = indexationDays(1);
            end
                
                nextIndexationDate = datetime(currentYear, nextIndexMonth, indexationDay)+utilities.DefaultSimulationParameters.defaultReferenceTime;
                nextIndexationDate.TimeZone = 'Australia/Sydney';
            % [~, indexationMonth, indexationDay] = datevec(indexationMonthDays);
            % nextIndexationDate = datetime(year, indexationMonth, indexationDay);
            if currentDate > nextIndexationDate
                currentYear = currentYear + 1;
                nextIndexationDate = datetime(currentYear, nextIndexMonth, indexationDay);
            end
            nextEffectiveInflationDate = dateshift(nextIndexationDate - effectiveInflationLag, 'end', 'month'); %eg 30/06/201-3 months = 31/03/2021
           
           
        end
        function [alignedIndices,lastNaN] = alignDates(datesToAlign, referenceDates, alignmentOption)
            % Aligns dates in 'datesToAlign' to the nearest dates in 'referenceDates'
            % based on the specified alignment option.

            % Input validation
            if ~isdatetime(datesToAlign) || ~isdatetime(referenceDates)
                error("Both datesToAlign and referenceDates must be datetime arrays.");
            end

            if ~ismember(alignmentOption, ["next", "previous", "exact"])
                error("Invalid alignmentOption. Must be 'next', 'previous', or 'exact'.");
            end

            alignedIndices = zeros(size(datesToAlign));
            lastNaN = 0;

            for i = 1:length(datesToAlign)
                date = datesToAlign(i);
                

                switch alignmentOption
                    case "next"
                        % Find the index of the first reference date that is greater than or equal to the current date

                        % Find the index of the first reference date that is greater than the current date
                        validIndexationIndices = find(date < referenceDates); % Find valid indices first

                        if ~isempty(validIndexationIndices) % Check if there are any valid indices
                            [~, idx] = min(referenceDates(validIndexationIndices) - date);
                            alignedIndices(i) = validIndexationIndices(idx);
                        else
                            alignedIndices(i) = NaN; % Or handle the "no next date" case differently
                            lastNAN = i;
                            % If no next date, align to the last reference date
                            %alignedIndices(i) = length(referenceDates);
                        end


                    case "previous"
                        
                        % Find the index of the first reference date that is less than the current date
                        validIndexationIndices = find(date > referenceDates); % Find valid indices first

                       if ~isempty(validIndexationIndices) % Check if there are any valid indices
                        [~, idx] = max(referenceDates(validIndexationIndices) - date);
                        
                        alignedIndices(i) = validIndexationIndices(idx);
                        else
                            alignedIndices(i) = NaN; % Or handle the "no prior date" case differently
                            lastNaN = i;
                            % If no next date, align to the last reference date
                            %alignedIndices(i) = length(referenceDates);
                        end


                    case "exact"
                        % Find the index of the reference date that exactly matches the current date
                        [~, idx] = min(abs(referenceDates - date));
                        if referenceDates(idx) == date
                            alignedIndices(i) = idx;
                        else
                            alignedIndices(i) = NaN; % Or handle the "no exact match" case differently
                        end
                end
            end
        end


    end
end