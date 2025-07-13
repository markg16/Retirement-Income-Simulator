% File: ProjectionRequest.m
classdef AnnuityProjectionRequest < ValuationRequest
    %PROJECTIONREQUEST Encapsulates the parameters for a temporal projection.
    properties
        ValuationDates (:,1) datetime
        RateCurveProvider marketdata.RateCurveProviderBase
    end
    methods
        function obj = AnnuityProjectionRequest(valuationDates, rateCurveProvider)
            obj.ValuationDates = sort(valuationDates);
            obj.RateCurveProvider = rateCurveProvider;
        end
    end
end