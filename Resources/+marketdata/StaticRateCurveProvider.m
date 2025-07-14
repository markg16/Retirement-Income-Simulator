% File: StaticRateCurveProvider.m
classdef StaticRateCurveProvider < RateCurveProviderBase
    %STATICRATECURVEPROVIDER Stores a collection of level rate curves indexed by rate.

    properties
        CurveMap containers.Map % Map where Key=datetime, Value=RateCurve object
    end

    methods
        function obj = StaticRateCurveProvider(curveMap)
            % Constructor takes a pre-built map of curves.
            if nargin > 0 && isa(curveMap, 'containers.Map')
                obj.CurveMap = curveMap;
            else
                obj.CurveMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            end
        end

        function rateCurve = getCurve(obj, identifier)
            % Identifier is a datetime object representing the valuation date.
            if ~isdatetime(identifier) || ~isscalar(identifier)
                error('Identifier for StaticRateCurveProvider must be a single datetime object.');
            end
            % Dates must be stored as char keys in containers.Map
            dateKey = datestr(identifier, 'yyyymmdd');
            if obj.CurveMap.isKey(dateKey)
                rateCurve = obj.CurveMap(dateKey);
            else
                error('No rate curve found for date: %s', datestr(identifier));
            end
        end
        
        function identifierList = getAvailableIdentifiers(obj)
            dateKeys = obj.CurveMap.keys;
            identifierList = datetime(dateKeys, 'InputFormat', 'yyyymmdd');
        end
    end
end
