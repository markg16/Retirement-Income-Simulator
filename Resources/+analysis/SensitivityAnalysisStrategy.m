% File: SensitivityAnalysisStrategy.m
classdef SensitivityAnalysisStrategy < AnalysisStrategy
    %SENSITIVITYANALYSISSTRATEGY Calculates a grid of annuity present values.

    methods
        function resultsTable = analyze(obj, person, config, rateCurveProvider)
            % This method contains the logic from your previous runAnnuitySensitivityAnalysis function.
            
            % (The full looping and PV calculation logic from your previous
            % AnnuityValuationEngine.runAnnuitySensitivityAnalysis goes here...)
            
            % For brevity, this is a simplified representation. Your full, detailed
            % loop with object reconstruction would be placed here.
            
            fprintf('Running Sensitivity Analysis...\n');
            xAxisValues = config.xAxis.values;
            lineVarValues = config.lineVar.values;
            numRows = length(xAxisValues) * length(lineVarValues);
            results(numRows) = struct(config.xAxis.name, [], config.lineVar.name, [], 'AnnuityValue', []);
            rowCounter = 1;

            for lineVal = lineVarValues
                for xVal = xAxisValues
                    % ... (reconstruct Person and CashflowStrategy for this iteration) ...
                    % ... (get the correct rateCurve from the rateCurveProvider) ...
                    % ... (create annuity instrument and calculate PV) ...
                    
                    % Placeholder calculation:
                    annuityValue = 100000 * (1 + xVal - lineVal); 
                    
                    results(rowCounter).(config.xAxis.name) = xVal;
                    results(rowCounter).(config.lineVar.name) = lineVal;
                    results(rowCounter).AnnuityValue = annuityValue;
                    rowCounter = rowCounter + 1;
                end
            end
            resultsTable = struct2table(results);
        end
    end
end
