% File: SensitivityConfig.m
classdef AnnuitySensitivityConfig < handle
       %SENSITIVITYCONFIG Encapsulates all parameters for a sensitivity analysis run.
            %   This version ensures that the value ranges (XAxisValues, LineVarValues)
            %   are always returned as cell arrays for consistent use by the engine.

    properties
        XAxisEnum AnnuityInputType
        LineVarEnum AnnuityInputType
        
        XAxisValues
        LineVarValues
        RateCurveProvider %marketdata.RateCurveProviderBase
    end

    methods
        function obj = AnnuitySensitivityConfig(xAxisEnum, lineVarEnum, person,scenario, rangeOverrides)
         
            % Constructor acts as a builder.
            % Inputs:
            %   xAxisEnum, lineVarEnum: The enums selected by the user.
            %   person, scenario:       The application context needed to build defaults.
            %   rangeOverrides:         A struct with user-provided ranges (optional).
            %                           e.g., rangeOverrides.Age = [60, 2, 80]; % [start, step, end]
            if nargin < 5, rangeOverrides = struct(); end % Default to empty struct

            obj.XAxisEnum = xAxisEnum;
            obj.LineVarEnum = lineVarEnum;

            % --- 1. Create the appropriate RateCurveProvider ---
            % This logic is now cleanly encapsulated inside the config object.
            if xAxisEnum == AnnuityInputType.InterestRate || lineVarEnum == AnnuityInputType.InterestRate
                % If looping by InterestRate, create a LevelRateCurveProvider.
                % Check if the user provided a custom range for it.
                if isfield(rangeOverrides, 'InterestRate')
                    r = rangeOverrides.InterestRate; % e.g., [-0.01, 0.005, 0.05]
                    interestRates = r(1):r(2):r(3);
                else
                    interestRates = 0.04:0.01:0.04; % Default range
                end
            
                obj.RateCurveProvider = marketdata.LevelRateCurveProvider(interestRates, scenario.ScenarioStartDate);

            elseif xAxisEnum == AnnuityInputType.ValuationDate || lineVarEnum == AnnuityInputType.ValuationDate
                % If looping by ValuationDate, use the Scenario's market data.
                obj.RateCurveProvider = marketdata.ScenarioMarketDataAdapter(scenario);
            else
                % If not looping by a rate-based variable, create a default provider.
                obj.RateCurveProvider = marketdata.LevelRateCurveProvider(0.03, scenario.ScenarioStartDate);
            end

           % --- 2. Define the value ranges for the looping variables ---
            % This uses the helper method below, which now checks for user overrides.
            obj.XAxisValues = obj.getValuesForParam(xAxisEnum, person, obj.RateCurveProvider, rangeOverrides);
            obj.LineVarValues = obj.getValuesForParam(lineVarEnum, person, obj.RateCurveProvider, rangeOverrides);
        end
        function set.RateCurveProvider(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'RateCurveProvider' property.
            if ~isempty(value)
                mustBeA(value, 'marketdata.RateCurveProviderBase');
            end
            obj.RateCurveProvider = value;
        end
    end
    
    methods (Access = private)
        function valuesCell = getValuesForParam(~, paramEnum, person, rateCurveProvider, rangeOverrides)
            % This helper now checks for a user-provided override first,
            % then falls back to a calculated default.
            paramName = char(paramEnum);
            
            if isfield(rangeOverrides, paramName)
                % User provided a specific range [start, step, end]
                r = rangeOverrides.(paramName);
                fprintf('Using user-provided range for %s.\n', paramName);
            % The switch determines how to interpret the override vector 'r'.
                switch paramEnum
                    case AnnuityInputType.AnnuityTerm
                        % Interpret r(3) as an offset from the person's default term
                        endValue = person.CashflowStrategy.MaxNumPayments + r(3);
                        values = r(1):r(2):endValue;
                    
                    case AnnuityInputType.Age
                        % Interpret r(3) as an offset from the person's current age
                        endValue = person.Age + r(3);
                        values = r(1):r(2):endValue;
                        
                    case AnnuityInputType.DefermentPeriod
                        % Interpret r(3) as an offset from the person's default deferment
                        endValue = person.IncomeDeferement + r(3);
                        values = r(1):r(2):endValue;
                    case AnnuityInputType.AnnuityIncomeGtdIncrease
                        % Interpret r(3) as an offset from the person's default deferment
                        % endValue = person.IncomeDeferement + r(3);
                        values = r(1):r(2):r(3);
                    case AnnuityInputType.MortalityIdentifier
                        % For this type, the override 'r' is expected to be a cell array
                        % of the actual identifiers to loop through.
                        if ~iscell(r)
                            error('SensitivityConfig:InvalidOverride', 'Override for MortalityIdentifier must be a cell array.');
                        end
                        values = r;

                    otherwise
                        % For other types like InterestRate, assume r(3) is an absolute end value.
                        values = r(1):r(2):r(3);
                end

            else
                % Fallback to default calculated ranges if no override is provided
                fprintf('Using default calculated range for %s.\n', paramName);
                baseInflationRate = person.CashflowStrategy.InflationRate;
                switch paramEnum
                    case {AnnuityInputType.InterestRate, AnnuityInputType.ValuationDate}
                        values = rateCurveProvider.getAvailableIdentifiers();
                    case AnnuityInputType.AnnuityTerm
                        values = 5:5:(person.CashflowStrategy.MaxNumPayments + 10);
                    case AnnuityInputType.Age
                        values = person.Age:5:(person.Age + 20);
                    case AnnuityInputType.DefermentPeriod
                        values = 0:5:(person.IncomeDeferement + 10);
                    case AnnuityInputType.AnnuityIncomeGtdIncrease
                        values = 0:0.01:(baseInflationRate + 0.02);
                    case AnnuityInputType.MortalityIdentifier
                        % The default is to just use the person's current identifier.
                        values = {person.CashflowStrategy.MortalityIdentifier};
                    otherwise
                        values = [];
                end
            end
            
            % If the calculated 'values' is not already a cell array, convert it.
            if ~iscell(values)
                valuesCell = num2cell(values);
            else
                valuesCell = values;
            end
        end
        end
end