% File: RateCurveProviderBase.m
classdef (Abstract) RateCurveProviderBase < handle
    %RATECURVEPROVIDERBASE Abstract interface for any object that can provide a RateCurve.

    methods (Abstract)
        % Returns a RateCurve object based on a given identifier.
        % The identifier could be a date, a numeric rate, etc.
        rateCurve = getCurve(obj, identifier);
        
        % Returns the list of available identifiers (e.g., all dates, all rates).
        identifierList = getAvailableIdentifiers(obj);
    end
end