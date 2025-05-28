classdef RateCurveSet 
    properties
        RateCurvesMap  %containers.map      % Dictionary (containers.Map) to store RateCurveKaparra objects
        RateCurvesSetMetaData %struct            % Struct to store metadata (e.g., SourceFileReread, SourceFileDateSaved)
        RateCurvesSetMapCountryToCurveName  %dictionary% Dictionary mapping countries to curve names
    end

    methods
        function obj = RateCurveSet(rateCurves, mapCountryToCurveName, metadata)% may need to add mapCountryToCurveName,

            if nargin == 0
                obj.RateCurvesMap = containers.Map();
                obj.RateCurvesSetMetaData = struct();
                obj.RateCurvesSetMapCountryToCurveName = dictionary();
            else
                obj.RateCurvesMap = rateCurves;
                if nargin >= 2
                    obj.RateCurvesSetMapCountryToCurveName =  mapCountryToCurveName;
                end
                %obj.MapCountryToCurveName = mapCountryToCurveName;
                if nargin == 3  % If metadata is provided
                    obj.RateCurvesSetMetaData = metadata;
                else
                    obj.RateCurvesSetMetaData.SourceFileReread = false; % Default value
                end
            end
        end

        % ... (Methods to access, modify, and query rate curves in the dictionary) ...
    end
end