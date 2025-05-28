classdef RateCurveKaparra < ratecurve
    %UNTITLED5 Summary of this class goes here
    %   Inherits from Matlab ratecurve class

    properties
        RateCurveKaparraMetaData  = struct('SourceFileTimestamp', datetime('now'), 'SourceFileReread', false); % Default to false  % Add property for the timestampSourceFileTimestamp datetime
    end

    methods
        % Inherits constructor from RateCurve class. 
        function obj = RateCurveKaparra(type, settle, dates, rates, compounding, basis, metadata)
            if nargin == 0
                % defaultType ='zero';
                % defaultSettle = datetime("now");
                % defaultRates = [0.03,0.03, 0.03, 0.03];
                % defaultTimes = [calmonths(6),calyears([1, 10, 30])]';
                % defaultZeroDates = defaultSettle + defaultTimes;
                % obj@ratecurve(defaultType,defaultSettle,defaultZeroDates,defaultRates);

                type ='zero';
                settle = datetime("now");
                rates = [0.03,0.03, 0.03, 0.03];
                times = [calmonths(6),calyears([1, 10, 30])]';
                dates = settle + times;
            end
              
            settle.TimeZone = '';
            if ~isdatetime(dates)
                dates = settle + dates;
            end
            dates.TimeZone = '';
            obj@ratecurve(type, settle, dates, rates);  % Call superclass constructor
            if nargin == 7  && ~isempty(metaData) % If metadata is provided
                obj.RateCurveKaparraMetaData = metadata;
            end
        end

        function  [discountFactors, discountFactorsTT] = getDiscountFactors(obj,dates);
            % Convert dates to datetime array if it is not already
            if ~isdatetime(dates)
                dates = datetime(dates);
            end

            % Ensure dates have the same time zone as the ratecurve object
            dates.TimeZone = obj.Settle.TimeZone;

            % Calculate discount factors using the toolbox function
            discountFactors = discountfactors(obj,dates);

            % Create a timetable with the dates and discount factors
            discountFactorsTT = timetable(dates',discountFactors','VariableNames',{'DiscountFactor'});
        end

        function [forwardRates, forwardRatesTT] = getForwardRates(obj,startDates,endDates)
            % Convert startDates and endDates to datetime arrays if they are not already
            if ~isdatetime(startDates)
                startDates = datetime(startDates);
            end
            if ~isdatetime(endDates)
                endDates = datetime(endDates);
            end

            % Ensure startDates and endDates have the same time zone as the ratecurve object
            startDates.TimeZone = obj.Settle.TimeZone;
            endDates.TimeZone = obj.Settle.TimeZone;

            % Calculate forward rates using the toolbox function
            forwardRates = forwardrates(obj,startDates,endDates);

            % Create a timetable with the dates and rates
            
            forwardRatesTT = timetable(endDates', forwardRates', 'RowTimes', startDates','VariableNames', {'EndDate', 'Rate'});
        end

        function [zeroRates, zeroRatesTT] = getZeroRates(obj,startDates,endDates)
            % Convert startDates and endDates to datetime arrays if they are not already
            if ~isdatetime(startDates)
                startDates = datetime(startDates);
            end
            if ~isdatetime(endDates)
                endDates = datetime(endDates);
            end
            % Check if startDates and endDates have the same length
            if length(startDates) ~= length(endDates)

                if length(startDates) == 1 % Replicate startDates to match the length of endDates
                    startDates = repmat(startDates, length(endDates), 1);
                else
                    error('startDates and endDates must have the same length.');
                end
            end


            % Ensure startDates and endDates have the same time zone as the ratecurve object
            startDates.TimeZone = obj.Settle.TimeZone;
            endDates.TimeZone = obj.Settle.TimeZone;

            % Calculate zero rates using the toolbox function with the provided logic
            if isequal(obj.Settle, endDates(1)) % Use isequal for datetime comparison% the zerorate for t= 0 is 0
                if length(endDates) > 1
                    zeroRates = [0,zerorates(obj,endDates(2:end))];
                else
                    zeroRates = 0;
                end
            else
                zeroRates = zerorates(obj,endDates);
            end

            % Create a timetable with the dates and zero rates
            zeroRatesTT = timetable(startDates,endDates',zeroRates','VariableNames',{'EndDates','ZeroRate'});
        end
    end
end