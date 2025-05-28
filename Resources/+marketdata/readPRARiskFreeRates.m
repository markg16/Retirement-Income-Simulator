function [RFR] = readPRARiskFreeRates(inputFolderRates,inputFileNameRates,sheetNameRates)
    %Read Risk Free Rates Summary

    % This function will read in a the term structure data provided by  EIOPA each month. 
    % The data is provided as an xlsx file with multiple sheets and extraneous info. The code
    % assumes the sheetname is an input . Each sheet name is a different
    % set of interest rates eg base,up,down with and wthout Volatility adjustments for credit spread vol.

    % Detailed explanation 

     % the input file structures are standard and provided by EIOPA. one of
     % the quirks is that the time variable does not have a header. This
     % code adds a header for Time once we have read the file in. This
     % means the data is not fixed at source of data. Unlikely to be able
     % to tell EIOPA what to do do.
     % output is a table with variable name for each rate curve.
       
    fileHeaderRows = 7;
    fullFilePath = fullfile(inputFolderRates, inputFileNameRates);    
    % approach to picking out the verbose curve descriptor but relies on
    % knowing the size of the table. not preferred.
        
    RFRRaw = readtable(fullFilePath, "Sheet",sheetNameRates,'NumHeaderLines', 1,'VariableNamingRule', 'preserve');
    RFRRaw.Properties.VariableNames(1) = {'Time'};
    RFRcurvenames = RFRRaw.Properties.VariableNames;
    RFRonly = RFRRaw((fileHeaderRows+1):end,:);  % header rows in standard file from EIOPA and PRA go from 1 to 7
    
    % Initialize logical index array for slecting variables to keep
        
       
    % code to select all variables that have names other than Varxx
    
    containsVar = cellfun(@(name) contains(name, 'Var'), RFRcurvenames); % this is a remnant piece fo code from reading PRA files which have a lot of blank columns
    
    selectRFRCurvesNames = RFRcurvenames(~containsVar);

    variabletokeep = selectRFRCurvesNames;
    
    % Check for empty cells or non-string elements
    nonStringIndices = find(~cellfun(@ischar, selectRFRCurvesNames));
        if ~isempty(nonStringIndices)
            error('Non-string element found at index: %d', nonStringIndices(1));
        end  % end check for nonstring names
    
    
    RFR = RFRonly(:,variabletokeep);

end % end function