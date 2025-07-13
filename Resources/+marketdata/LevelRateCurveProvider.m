% File: LevelRateCurveProvider.m
classdef LevelRateCurveProvider < marketdata.RateCurveProviderBase
    %LEVELRATECURVEPROVIDER Generates flat rate curves on-the-fly from a vector of rates.
    %   This class implements the RateCurveProviderBase interface. It is used for
    %   sensitivity analysis where the "interest rate" is varied as a flat curve.

    properties (SetAccess = private)
        InterestRates(1,:) double % A row vector of interest rates, e.g., [0.01, 0.02, 0.03]
        SettleDate datetime       % The settlement or valuation date for the curves
        CurveTenors(1,:) calendarDuration % The tenors for the generated curves (e.g., 1yr, 5yr, 10yr)
    end

    methods
        function obj = LevelRateCurveProvider(interestRates, settleDate)
            % Constructor for the LevelRateCurveProvider.
            % Inputs:
            %   interestRates: A vector of decimal interest rates to be used as identifiers.
            %   settleDate:    The single settlement date for all generated curves.
            if ~isnumeric(interestRates) || ~isvector(interestRates)
                error('LevelRateCurveProvider:InvalidInput', 'interestRates must be a numeric vector.');
            end
            if ~isdatetime(settleDate) || ~isscalar(settleDate)
                error('LevelRateCurveProvider:InvalidInput', 'settleDate must be a scalar datetime object.');
            end
            
            obj.InterestRates = interestRates;
            obj.SettleDate = settleDate;
            % Define a standard set of tenors for the flat curves
            obj.CurveTenors = calyears([1, 3, 5, 10, 20, 30, 40]);
        end

        function rateCurve = getCurve(obj, identifier)
            % Returns a RateCurveKaparra object for a given interest rate.
            % The 'identifier' for this provider is a single numeric interest rate.
            
            % 1. Validate the identifier
            if ~isnumeric(identifier) || ~isscalar(identifier)
                error('LevelRateCurveProvider:InvalidIdentifier', 'Identifier for this provider must be a single numeric interest rate.');
            end
            
            % 2. Create the data for the flat curve
            curveDates = obj.SettleDate + obj.CurveTenors;
            flatRates = ones(size(obj.CurveTenors)) * identifier; % All rates are the same
            
            % 3. Instantiate and return the RateCurveKaparra object
            %    (Assuming these are the correct parameters for its constructor)
            rateCurve = marketdata.RateCurveKaparra('zero', obj.SettleDate, curveDates, flatRates, -1, 0);
        end
        
        function identifierList = getAvailableIdentifiers(obj)
            % Returns the list of interest rates this provider can generate curves for.
            % This is used by the AnnuityValuationEngine to know what to loop over.
            identifierList = obj.InterestRates;
        end
    end
end