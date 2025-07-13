% File: SensitivityRequest.m
classdef AnnuitySensitivityRequest < ValuationRequest
    %SENSITIVITYREQUEST Encapsulates the parameters for a sensitivity analysis.
    properties
        XAxisEnum AnnuityInputType
        LineVarEnum AnnuityInputType
        RateCurveProvider marketdata.RateCurveProviderBase
    end
    methods
        function obj = AnnuitySensitivityRequest(xAxisEnum, lineVarEnum, rateCurveProvider)
            obj.XAxisEnum = xAxisEnum;
            obj.LineVarEnum = lineVarEnum;
            obj.RateCurveProvider = rateCurveProvider;
        end
    end
end