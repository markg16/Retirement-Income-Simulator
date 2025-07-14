% File: ScenarioMarketDataRatesProvider.m
% This should be saved in a directory on your MATLAB path.
classdef ScenarioMarketDataRatesProvider < marketdata.RateCurveProviderBase
    %SCENARIOMARKETDATAADAPTER An Adapter that makes a complex Scenario object
    %   behave like a simple RateCurveProvider.
    %   It holds a reference to the Scenario object and uses its internal data
    %   to provide rate curves on demand, fulfilling the RateCurveProviderBase contract.

    properties (SetAccess = private)
        ScenarioObj scenarios.Scenario % Holds the complete Scenario object it adapts
    end

    methods
        function obj = ScenarioMarketDataRatesProvider(scenarioObject)
            % The constructor takes the complex Scenario object to be adapted.
            
            % Input validation
            if ~isa(scenarioObject, 'scenarios.Scenario')
                error('ScenarioMarketDataAdapter:InvalidInput', 'Input must be a valid Scenario object.');
            end
            if isempty(scenarioObject.ScenarioMarketData)
                error('ScenarioMarketDataAdapter:InvalidState', 'The provided Scenario object has not generated its ScenarioMarketData yet.');
            end
            
            obj.ScenarioObj = scenarioObject;
        end

        function rateCurve = getCurve(obj, identifier)
            % Implements the abstract method from RateCurveProviderBase.
            % The 'identifier' for this provider is a datetime object representing the valuation date.
            
            if ~isdatetime(identifier) || ~isscalar(identifier)
                error('ScenarioMarketDataAdapter:InvalidIdentifier', 'Identifier for this provider must be a single datetime object.');
            end
            
            % --- This is the "Adapter" logic ---
            % It translates the simple request into calls on the complex underlying object.
            
            % 1. Get the components needed from the stored Scenario object.
            scenarioMarketData = obj.ScenarioObj.ScenarioMarketData;
            personCountry = obj.ScenarioObj.Person.Country;
            rateScenarios = obj.ScenarioObj.RateScenarios;
            
            % 2. Delegate the call to the underlying object's existing method to get the curve.
            try
                rateCurve = scenarioMarketData.getRateCurveForScenario(identifier, personCountry, rateScenarios);
            catch ME
                % Add more context to the error if it fails
                error('ScenarioMarketDataAdapter:GetCurveFailed', ...
                    'Failed to retrieve rate curve for date %s. Original error: %s', datestr(identifier), ME.message);
            end
        end
        
        function identifierList = getAvailableIdentifiers(obj)
            % Returns the list of valuation dates available in the Scenario.
            % This list is used by the AnnuityValuationEngine to know what dates to loop over.
            identifierList = obj.ScenarioObj.AnnuityValuationDates;
            
            % Ensure the list is sorted for predictable looping
            if ~isempty(identifierList)
                identifierList = sort(identifierList);
            end
        end
    end
end