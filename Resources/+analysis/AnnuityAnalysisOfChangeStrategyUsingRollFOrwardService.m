% File: AnnuityAnalysisOfChangeStrategyUsingRollFOrwardService.m
classdef AnnuityAnalysisOfChangeStrategyUsingRollFOrwardService < analysis.AnalysisStrategy
    %PROGRESSIONANALYSISSTRATEGY Calculates the progression of an annuity's value.
    %   It can either operate on a pre-existing timetable of PVs and Ages, or generate
    %   one from scratch using its static factory method.

    methods (Static)
         function resultsTimeTable = runFromScratch(progressionConfig)
            
            % This static factory method orchestrates the entire process from scratch.
            % It is a self-contained analysis tool that does not require a full Scenario object.
            
            % --- 1. Extract the necessary components from the config object ---
            valuationDates = progressionConfig.ValuationDates;
            rateCurveProvider = progressionConfig.RateCurveProvider;
            annuitant = progressionConfig.Annuitant;

            annuityValuationCollection = AnnuityRollForwardValuationService.generateValuationCollection(annuitant, valuationDates, rateCurveProvider);
                        
            % 2. Create an instance of this strategy and call the core analyze method.
            strategy = analysis.AnnuityAnalysisOfChangeStrategyUsingRollFOrwardService();
            resultsTimeTable = strategy.analyze(annuitant,annuityValuationCollection,rateCurveProvider);
         end
    end

    methods
        function resultsTimeTable = analyze(obj, annuitant, annuityValuationCollection,rateCurveProvider)
            % This is the core analysis method. It takes the pre-calculated
            % AnnuityValuationCollection and derives the waterfall components.            
            
            if ~isa(annuityValuationCollection, 'AnnuityValuationCollection')
                error('ProgressionAnalysisStrategy:InvalidInput', 'Input must be an AnnuityValuationCollection object.');
            end
          
            valuationsTT = annuityValuationCollection.AnnuityValuationsTT;
            numPeriods = height(valuationsTT) - 1;
              valuationDates =valuationsTT.Time;
            if numPeriods < 1
                resultsTimeTable = table();
                warning('Progression analysis requires a collection with at least two valuation sets.');
                return;
            end
             % Pre-allocate cell arrays to hold the results from the loop.
            % This avoids the error with assigning timezone-aware datetimes into a
            % pre-allocated table with timezone-unaware NaTs.
            periodStartDates = NaT(numPeriods, 1, 'TimeZone', valuationDates.TimeZone);
            progressionDataCells = cell(numPeriods, 1);
            resultsTable = table('Size', [numPeriods, 5], ...
                                 'VariableTypes', {'datetime','string','double', 'double', 'cell'}, ...
                                  'VariableNames', {'PeriodStart','AnnuityType', 'StartAge', 'EndAge','ProgressionData'});

            for i = 1:numPeriods
                % --- 1. Extract the necessary data for the period ---
                periodStartDate = valuationsTT.Time(i);
                periodEndDate = valuationsTT.Time(i+1);
                startAge = valuationsTT.AnnuityValuationSets{i}.ValuationTimeTable.Age(1);
                endAge = valuationsTT.AnnuityValuationSets{i}.ValuationTimeTable.Age(end);
                % Get the valuation sets for the start and end of the period
                valuationSet_Start = valuationsTT.AnnuityValuationSets{i};
                valuationSet_End = valuationsTT.AnnuityValuationSets{i+1};
                
                % Get the timetables containing the series of future PVs
                pvTimetable_Start = valuationSet_Start.ValuationTimeTable;
                pvTimetable_End = valuationSet_End.ValuationTimeTable;
                
                % The PV at the beginning of the period is the first value in the first set
                pv_start = pvTimetable_Start.("AnnuityValue")(1);
                
                % The PV at the end of the period is the first value in the second set
                pv_end = pvTimetable_End.("AnnuityValue")(1);
                
                % --- This is the key to isolating the interest rate effect ---
                % This is the PV at the end of the period, but re-valued using the
                % START of period yield curve. Your AnnuityValuationSet already contains this!
                % It's the second value in the first valuation set's timetable.
                pv_end_revalued_with_start_curve = pvTimetable_Start.("AnnuityValue")(2);
                
                % --- 2. Derive the waterfall components ---
                periodChangesTable = obj.createPeriodAnalysisOfChange(periodStartDate,periodEndDate,...
                    annuitant, rateCurveProvider,...
                     pv_start, pv_end, pv_end_revalued_with_start_curve);
                
                % --- 3. Store the results as an array  ---

                periodStartDates(i) = periodStartDate;
                StartAges(i) = startAge;
                EndAges(i) = endAge; 
                progressionDataCells{i} = periodChangesTable;
            end
            % Create the final results table in a single step AFTER the loop.
            AnnuityType = repmat(annuitant.Annuity.AnnuityType,numPeriods,1);
            resultsTable = table(periodStartDates,AnnuityType, StartAges',EndAges',progressionDataCells, ...
                                 'VariableNames', {'PeriodStart','AnnuityType','StartAge', 'EndAge', 'ProgressionData'});
            resultsTimeTable = table2timetable(resultsTable);
            
        end
    end
    
    methods (Access = private)
        function periodChangesTable = createPeriodAnalysisOfChange(obj, startDate,endDate,annuitant, rateCurveProvider,startOfPeriodValuation, endOfPeriodValuation,endOfPeriodValuationAtStartOfPeriodCurve)
        % This private helper calculates all components of change between two valuation dates.
        % It uses the rich data provided by the AnnuityValuationSet objects.
        
        % % --- 1. Extract the three critical PVs ---
        % pvTimetable_Start = startOfPeriodValuation.ValuationTimeTable;
        % pvTimetable_End = endOfPeriodValuation.ValuationTimeTable;

        pv_start = startOfPeriodValuation;
        pv_end = endOfPeriodValuation;
        
        % pv_start = pvTimetable_Start.("PV_of_Portfolio_Owner_Payments")(1);
        % pv_end = pvTimetable_End.("PV_of_Portfolio_Owner_Payments")(1);
        
        % This is the PV at the end of the period, but re-valued using the START of period yield curve.
        % Your AnnuityValuationSet already contains this as the second value in the first set's timetable.

        pv_end_revalued = endOfPeriodValuationAtStartOfPeriodCurve;
        %pv_end_revalued = pvTimetable_Start.("PV_of_Portfolio_Owner_Payments")(2);

        % % --- 2. Get Context for the Period ---
        % startDate = pvTimetable_Start.Time(1);
        % endDate = pvTimetable_Start.Time(2);
        
       
        % Use the authoritative utility to calculate age, ensuring consistency.
        startAge = utilities.AgeCalculationUtils.getAgeAtDate(annuitant, startDate);
        endAge = utilities.AgeCalculationUtils.getAgeAtDate(annuitant, endDate);
        
        % --- 3. Find Actual Payments Made During the Period ---
        annuity = annuitant.Annuity; % Get the annuity object from the base person
        % allPaymentDates = annuity.PaymentDates;
        % paymentsInPeriod = allPaymentDates(allPaymentDates >= startDate & allPaymentDates < endDate);
        % totalPaymentsInPeriod = (annuity.AnnualAmount / double(annuity.Frequency)) * length(paymentsInPeriod);
        totalPaymentsInPeriod = annuity.getAnnuityPaymentAmount(startDate,endDate);

        % --- 4. Calculate All Components of Change ---
        
        % Interest is earned on the start value, after the payment is made.
        %interestRateForPeriod = (pv_end_revalued / (pv_start - totalPayments)) - 1;
        rateCurveIdentifiers = rateCurveProvider.getAvailableIdentifiers();
        rateCurveForPeriod = rateCurveProvider.getCurve(rateCurveIdentifiers(1));
        interestRateForPeriod =  rateCurveForPeriod.getForwardRates(startDate,endDate);

        interest_earned = (pv_start - totalPaymentsInPeriod) * (exp(interestRateForPeriod)-1);
        
        % --- THIS IS THE SECOND FIX ---
        % Calculate the probability of death DIRECTLY from the mortality table.
        periodDurationYears = years(endDate - startDate);
                
        %TODO consider refactoring so that the method is overwritten weh
        %performed on fixed annuity type.
        if ~(annuitant.Annuity.AnnuityType =="Fixed")
        annual_qx = annuitant.FutureMortalityTable.getRate(annuitant.Gender, startAge);
        prob_of_death_in_period = annual_qx * periodDurationYears;
        else
            prob_of_death_in_period = 0;
        end
        % Mortality cost is this probability applied to the expected reserve at year end.
        Mortality_Transfer = prob_of_death_in_period * pv_end_revalued;
        
        % The change due to yield curve movements is the difference between the
        % actual end-of-period value and what it would have been with the old curve.
        yield_curve_effect = pv_end - pv_end_revalued;
        
        % The "Other" component is now a much smaller balancing item, capturing
        % second-order effects and approximations.
        other_effects = pv_end_revalued - (pv_start + interest_earned - totalPaymentsInPeriod + Mortality_Transfer);
        
        % --- 5. Assemble the Timetable for the Waterfall Chart ---
        categories = categorical({'Start Value'; 'Interest Earned'; 'Payment Out'; 'Mortality Transfer'; 'Yield Curve Effect'; 'Other'; 'End Value'});
        changes = [pv_start; interest_earned; - totalPaymentsInPeriod; Mortality_Transfer; yield_curve_effect; other_effects; pv_end];
        periodChangesTable = table(categories, changes, 'VariableNames', {'Categories','Change'});
        periodChangesTable.Properties.UserData = struct('startAge', startAge, 'endAge', endAge);
       
        end
    end
end


