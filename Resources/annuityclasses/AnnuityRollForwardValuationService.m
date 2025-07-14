% File: AnnuityRollForwardValuationService.m
classdef AnnuityRollForwardValuationService
    %ANNUITYROLLFORWARDVALUATIONSERVICE A service class with static methods for performing
    %   a temporal "roll-forward" projection of annuity values.

    methods (Static)
        function annuityValuationCollection = generateValuationCollection(annuitant, valuationDates, rateCurveProvider)
            % This method creates an AnnuityValuationCollection.
            
            fprintf('--- AnnuityRollForwardValuationService: Starting generation of Valuation Collection ---\n');
            
            scenarioName = sprintf('Progression for %s starting at age %d', annuitant.Gender, annuitant.Age);
            inflationRate = annuitant.CashflowStrategy.InflationRate;
            
            annuityValuationTT = timetable();
            annuityValuationCollection = AnnuityValuationCollection(annuityValuationTT, scenarioName);
            
            % set up an annuity for the person if one has not allready been
            % set up.
            if isempty(annuitant.Annuity ) || ~isprop(annuitant, 'Annuity')
                annuity = SingleLifeTimeAnnuityFactory().createInstrument( ...
                    annuitant, ...
                    annuitant.CashflowStrategy.AnnualAmount, ...
                    annuitant.CashflowStrategy.InflationRate, ...
                    annuitant.CashflowStrategy.StartDate, ...
                    annuitant.IncomeDeferement, ...
                    annuitant.CashflowStrategy.MaxNumPayments, ...
                    annuitant.CashflowStrategy.Frequency);
                annuitant.Annuity = annuity;
            else
                annuity = annuitant.Annuity;
            end

            for i = 1:length(valuationDates)
                valuationDate = valuationDates(i);
                
                try
                    identifiers = rateCurveProvider.getAvailableIdentifiers();
                    rateCurve = rateCurveProvider.getCurve(identifiers(1));
                catch ME
                    fprintf('Warning: Could not get rate curve for %s. Stopping valuations. Error: %s\n', datestr(valuationDate), ME.message);
                    break;
                end
                
                rateCurveName = sprintf('Curve_%s', datestr(valuationDate, 'yyyymmdd'));
                
                % --- THIS IS THE FIX ---
                % Use the new, authoritative utility to calculate the person's age.
                ageAtValuation = utilities.AgeCalculationUtils.getAgeAtDate(annuitant, valuationDate);
                
                % Create a temporary Person object with the correct age for this valuation
                personAtValuation = annuitant.copy();
                personAtValuation.Age = ageAtValuation;
                personAtValuation.setFutureMortalityTable();

               

                futureValuationDates = valuationDates(i:end);

                futurePVs = annuity.present_value(personAtValuation.FutureMortalityTable, rateCurve, inflationRate, futureValuationDates);
                
                
                pvValuesForSet = futurePVs(1:length(futureValuationDates));
                
                % We will now add the correctly calculated age to the timetable,
                % preparing for the ProgressionAnalysisStrategy to use it.
                agesForSet = zeros(size(pvValuesForSet));
                for j = 1:length(futureValuationDates)
                    agesForSet(j) = utilities.AgeCalculationUtils.getAgeAtDate(annuitant, futureValuationDates(j));
                end
                
                pvTimetable = timetable(futureValuationDates', pvValuesForSet', agesForSet', 'VariableNames', {'AnnuityValue', 'Age'});
                
                annuityValuationSet = AnnuityValuationSet(pvTimetable, rateCurveName);
                annuityValuationCollection = annuityValuationCollection.addAnnuityValuationSet(annuityValuationSet, valuationDate);
            end
            
            fprintf('--- AnnuityRollForwardValuationService: Finished generation ---\n');
        end
    end
end