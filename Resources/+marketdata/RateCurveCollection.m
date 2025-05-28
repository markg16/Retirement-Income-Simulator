classdef RateCurveCollection
    properties
        RateCurveSets timetable
        RateCurveStesMetaData struct% Timetable to store RateCurveSet objects with dates as the time index
    end

    methods
        function obj = RateCurveCollection(rateCurveSets)
            % Constructor

            if nargin ==0
                valuationDate = datetime("now");
                rateCurveSet = marketdata.RateCurveSet();
                rateCurveSets = timetable(valuationDate',{rateCurveSet},'VariableNames', {'RateCurveSets'});
                obj.RateCurveSets = rateCurveSets;
            else
                obj.RateCurveSets = rateCurveSets;
            end
        end
        function rateCurveSet = getRateCurveSet(obj, date)
            %GETRATECURVESET Retrieves the RateCurveSet for a given date.
            %
            %  (Similar description as above)

            dateIndex = find(obj.RateCurveSets.Time == date);
            if isempty(dateIndex)
                error('No RateCurveSet found for the specified date: %s', datestr(date));
            end
            rateCurveSet = obj.RateCurveSets.RateCurveSet{dateIndex}; 
        end

        % ... (Methods to access, modify, and query RateCurveSet objects in the timetable) ...
    end
end