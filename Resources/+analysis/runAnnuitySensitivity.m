% File: +analysis/runAnnuitySensitivity.m

function allAnnuityValues = runAnnuitySensitivity(person, sensitivityConfig,mortalityDataSourceManager)  % xAxisVarEnum, lineVarEnum, scenario, valuationDate)
    % This standalone function orchestrates the valuation of multiple annuity types.
    % It is fully decoupled from the UI. and from configuration logic.
    % All parameters are provided via the sensitivityConfig object.
    
   

    % 1. Loop through each AnnuityType and run the valuation engine
    annuityTypesToCalculate = enumeration('AnnuityType');
    numTypes = length(annuityTypesToCalculate);
    allAnnuityValues = struct('AnnuityType', cell(1, numTypes), 'Data', cell(1, numTypes));

    for i = 1:numTypes
        currentAnnuityType = annuityTypesToCalculate(i);
        
        engine = AnnuityValuationEngine(person, currentAnnuityType,mortalityDataSourceManager); %, rateProvider);
        
        fprintf('Calculating values for Annuity Type: %s...\n', char(currentAnnuityType));
        resultsDataAsTable = engine.runAnnuitySensitivityAnalysis(sensitivityConfig); %xAxisVarEnum, lineVarEnum);
        
        allAnnuityValues(i).AnnuityType = char(currentAnnuityType);
        allAnnuityValues(i).Data = table2struct(resultsDataAsTable); 
    end
    
    fprintf('Annuity value calculations complete for all types.\n');
end