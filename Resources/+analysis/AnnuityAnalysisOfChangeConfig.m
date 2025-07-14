% File: AnnuityAnalysisOfChangeConfig.m
classdef AnnuityAnalysisOfChangeConfig < handle
     %PROGRESSIONCONFIG Encapsulates the configuration for a progression analysis.
    %   Its primary role is to hold the fully-built Scenario object that
    %   contains all necessary data for the analysis

    properties
        
        Annuitant
        ValuationDates
        Scenario %scenarios.Scenario
        RateCurveProvider %marketdata.RateCurveProviderBase
    end

    methods
        function obj = AnnuityAnalysisOfChangeConfig(varargin)
           
            defaultStartDate= utilities.DateUtilities.createDateTime('inputDate',utilities.DefaultScenarioParameters.defaultStartDate);
           
             defaultEndDate = utilities.DateUtilities.createDateTime('inputDate',utilities.DefaultScenarioParameters.defaultEndDate);
             % defaultStartDate = utilities.DefaultScenarioParameters.defaultStartDate;
            % defaultStartDate.TimeZone = utilities.DefaultScenarioParameters.defaultTimeZone;
            % defaultEndDate.TimeZone = utilities.DefaultScenarioParameters.defaultTimeZone;
            defaultReferenceTime =  utilities.DefaultScenarioParameters.defaultReferenceTime;
            defaultFrequency = utilities.FrequencyType.Annually;
            
            [defaultAnnuityValuationStartDates, defaultAnnuityValuationEndDates]= utilities.generateDateArrays( defaultStartDate, defaultEndDate, defaultFrequency ,defaultReferenceTime);
            defaultAnnuityValuationDates = [defaultAnnuityValuationStartDates defaultAnnuityValuationEndDates(end)];
            
            defaultrateCurveProvider = marketdata.LevelRateCurveProvider(0.04,defaultStartDate);
            defaultPerson = Person();

            p = inputParser;
            addParameter(p,'annuitant',defaultPerson,@(x) isa(x, 'Person'));            
            addParameter(p,'valuationDates',defaultAnnuityValuationDates,@isdatetime);
            addParameter(p,'rateCurveProvider',defaultrateCurveProvider,@(x) isa(x,'marketdata.RateCurveProviderBase'));
            addParameter(p,'scenario',[],@(x) isa(x,'scenarios.Scenario'));
            
            parse(p,varargin{:});

            
            % The constructor now takes the fully-built Scenario object or the three variables.
            if ~isempty(p.Results.scenario)

                if ~isa(scenario, 'scenarios.Scenario')
                    error('ProgressionConfig:InvalidInput', 'Input must be a valid Scenario object.');
                end
                if isempty(scenario.ScenarioMarketData)
                    error('ProgressionConfig:InvalidState', 'The provided Scenario object has not generated its ScenarioMarketData yet. ');
                end

                obj.Scenario = p.Results.scenario;
                obj.Annuitant = obj.Scenario.Person;
                obj.ValuationDates = obj.Scenario.AnnuityValuationDates;

                % The RateCurveProvider is now always the adapter for the scenario's data.
                obj.RateCurveProvider = marketdata.ScenarioMarketDataAdapter(scenario);

            else
                obj.Annuitant = p.Results.annuitant;
                obj.ValuationDates = p.Results.valuationDates;
                obj.RateCurveProvider = p.Results.rateCurveProvider;
            end
        end
        
        function valuationDates = getValuationDates(obj)
           if exists(obj.Scenario)
            % Helper method to get the dates directly from the scenario.
            valuationDates = obj.Scenario.AnnuityValuationDates;
           else
               valuationDates = obj.ValuationDates;
           end
        end
         % --- ADD THIS SET ACCESSOR METHOD ---
        function set.RateCurveProvider(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'RateCurveProvider' property.

            % We allow setting it to empty, but if a value is provided,
            % we validate that it is the correct type of handle object.
            if ~isempty(value)
                % mustBeA checks if 'value' is an instance of the class
                % or any of its subclasses. This is perfect for your abstract class.
                mustBeA(value, 'marketdata.RateCurveProviderBase'); 
            end
            
            % If validation passes, assign the value to the property.
            obj.RateCurveProvider = value;
        end
        function set.Scenario(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'RateCurveProvider' property.

            % We allow setting it to empty, but if a value is provided,
            % we validate that it is the correct type of handle object.
            if ~isempty(value)
                % mustBeA checks if 'value' is an instance of the class
                % or any of its subclasses. This is perfect for your abstract class.
                mustBeA(value, 'scenarios.Scenario'); 
            end
            
            % If validation passes, assign the value to the property.
            obj.Sceanrio = value;
        end
    end
end