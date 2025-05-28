classdef CashFlowInflationSpec
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Type  
        InflationRateCurve  % For Guaranteed and Scenario types
        Rules % For MarketImplied - could be a curve, a set of rates, etc.
    end

    methods
        function obj = CashFlowInflationSpec(type, rateCurve, rules)
            obj.Type = type;
            obj.InflationRateCurve = rateCurve;
            obj.Rules = rules;
        end

        function inflatedValues = adjustValue(obj, cashflows,cashflowDates,inflationBaseDate)
            
            switch obj.Type
                
                
                case utilities.CashFlowInflationType.Guaranteed
                    indexationDates = obj.Rules.indexationDates;
                    effectiveInflationDates = obj.Rules.effectiveInflationDates;

                    % 1. Align cash flow dates with indexation dates
                    % alignedIndices = utilities.DateUtilities.alignDates(cashflowDates, indexationDates, 'next'); % Find the next indexation date for each cash flow date
                    [alignedIndices,lastNaN] = utilities.DateUtilities.alignDates(cashflowDates, indexationDates, 'previous');
                    % 2. Calculate year differences
                    firstZeros = zeros(1,lastNaN);
                    firstNonNaN = lastNaN+1;
                    yearDiffs = [firstZeros,year(indexationDates(alignedIndices(firstNonNaN:end))) - year(inflationBaseDate)];
                    % 3. Get inflation rates for the effective inflation periods
                    % startDates = effectiveInflationDates(1:end-1);
                    % endDates = effectiveInflationDates(2:end);
                    %inflationRates = obj.InflationRateCurve.getForwardRate(startDates, endDates);
                    %startDates = repmat(inflationBaseDate, size(effectiveInflationDates(1:end-1))); % Use inflationBaseDate as start date for all rates
                    startDate = inflationBaseDate;
                    endDates = effectiveInflationDates(1:end);
                    inflationRates = obj.InflationRateCurve.getZeroRates(startDate, endDates);


                   % 4. Align inflation rates with cash flow dates, handling NaNs
                    validIndices =find(~isnan(alignedIndices)); % Find indices that are not NaN
                    alignedInflationRates = inflationRates(alignedIndices(validIndices)); % Get rates for valid indices only

                    % 5. Calculate inflated values
                    inflatedValues = cashflows; % Initialize with original cashflows
                    inflatedValues(validIndices) = inflatedValues(validIndices) .* (1 + alignedInflationRates) .^ yearDiffs(validIndices);

                   
                
                % case utilities.CashFlowInflationType.Guaranteed
                % 
                % 
                %     indexationDates = obj.Rules.indexationDates;
                %     effectiveInflationDates = obj.Rules.effectiveInflationDates;
                %     startDates = effectiveInflationDates(1:end-1);
                %     endDates = effectiveInflationDates(2:end);
                %     yearDiffs = (year(indexationDates) - year(inflationBaseDate));
                %     inflationRates = obj.InflationRateCurve.getForwardRate(startD ...
                %         ates,endDates); % Get rate for the specific date
                % 
                %     inflatedValue = cashflows .* (1 + inflationRates).^(yearDiffs);
                % % case CashFlowInflationType.MarketImplied
                %     % Use obj.Data (e.g., inflation curve) to calculate the appropriate inflation factor
                %     inflatedValue =  calculateInflatedValueFromMarketData(obj.Data, cashflowDates, inflationBaseDate); 
                % case CashFlowInflationType.ScenarioAssumption
                %     inflationRates = obj.InflationRateCurve.getRate(cashflowDates); % Get rate for the specific date
                %     inflatedValue = cashflows.* (1 + inflationRates).^(yearDiffs); 
                % case CashFlowInflationType.GreaterOf
                %     inflationRates = obj.InflationRateCurve.getRate(cashflowDates); % Get rate for the specific date
                %     inflatedValue = cashflows .* (1 + inflationRates).^(yearDiffs); 
                otherwise
                    error('Invalid inflation type');
            end
      
        end
    end
end