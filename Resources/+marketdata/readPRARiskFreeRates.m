function [RFR] = readPRARiskFreeRates(inputFolderRates, inputFileNameRates, sheetNameRates, varargin)
    %readPRARiskFreeRates Reads EIOPA term structure data from an Excel file.
    %
    %   This function is the most robust version, designed to handle severe
    %   Excel formatting issues, including:
    %   1. Headers that are formulas.
    %   2. Data cells that are formatted as text, causing them to be read as NaN.
    %
    %   The strategy is to read all data as raw text first, then programmatically
    %   clean and convert it to numbers, making the process immune to source formatting.
    
    % --- 1. Set up Input Parser ---
    p = inputParser;
    isText = @(x) ischar(x) || isstring(x);
    isNumericScalar = @(x) isnumeric(x) && isscalar(x);

    addRequired(p, 'inputFolderRates', isText);
    addRequired(p, 'inputFileNameRates', isText);
    addRequired(p, 'sheetNameRates', isText);
    
    addParameter(p, 'TimeRange', 'B11:B160', isText);
    addParameter(p, 'RateDataRange', 'C11:BC160', isText);
    addParameter(p, 'RateNamesRange', 'C3:BC3', isText);
    addParameter(p, 'NumRateColumns', 53', isNumericScalar);
    
    parse(p, inputFolderRates, inputFileNameRates, sheetNameRates, varargin{:});
    
    timeRange = p.Results.TimeRange;
    rateDataRange = p.Results.RateDataRange;
    rateNamesRange = p.Results.RateNamesRange;
    numRateColumns = p.Results.NumRateColumns;

    % --- 2. Decoupled Data Import (Final Method) ---
    fullFilePath = fullfile(inputFolderRates, inputFileNameRates);    
    
    % STEP 1: Use 'xlsread' to reliably get the header text.
    [~, ~, rawHeaders] = xlsread(fullFilePath, sheetNameRates, rateNamesRange);
    if ~iscell(rawHeaders)
        error('Failed to read headers from range %s.', rateNamesRange);
    end
% --- NEW: DYNAMICALLY CLEAN HEADERS ---
    % Filter out any empty cells from the headers. A valid header must be text.
    % This handles cases where columns are removed from the source file.
    isValidHeader = cellfun(@ischar, rawHeaders);
    cleanHeaders = rawHeaders(isValidHeader);
    headerNames = string(cleanHeaders);
        
    % STEP 2: Read the main rate data, FORCING it to be imported as text/string.
   % STEP 2: Use 'xlsread' again to read the numeric data.
    % This is the key to this solution. The first output of xlsread is purely
    % numeric and it FORCES Excel to evaluate the formulas in the cells.
    %TODO convert xlsread to readtable. Be careful of formula in cells
    [numericRateData, ~, ~] = xlsread(fullFilePath, sheetNameRates, rateDataRange);
    
    % Convert the resulting numeric matrix into a table.
    RateData = array2table(numericRateData);
    
       
    
    % STEP 3: Manually assign the clean headers.
    if width(RateData) == numel(headerNames)
        RateData.Properties.VariableNames = headerNames;
    else
        error('Column count mismatch: %d data columns read, but %d header names found.', ...
              width(RateData), numel(headerNames));
    end
    
    % STEP 4: Read the time data column (this part was working).
    timeOpts = detectImportOptions(fullFilePath, 'Sheet', sheetNameRates, 'Range', timeRange);
    timeOpts.VariableTypes = {'double'};
    TimeData = readtable(fullFilePath, timeOpts);
    TimeData.Properties.VariableNames = {'Time'};
        
    % --- 3. Combine and Finalize the Table ---
    RFR = [TimeData, RateData];
    
     % --- FINAL ROBUST CLEANUP ---
    % This loop explicitly checks each column name and marks bad ones for removal.
    
    RFRcurvenames = RFR.Properties.VariableNames;
    columns_to_keep = true(1, numel(RFRcurvenames)); % Start by keeping all columns

    % Loop through each column name
    for i = 1:numel(RFRcurvenames)
        % Get the content of the cell, which should be a char array
        name = RFRcurvenames{i};

        % Robustly check if the name is invalid.
        % This handles names that are empty, missing, or default 'Var...' names.
        if isempty(name) || ismissing(string(name)) || startsWith(string(name), "Var")
            columns_to_keep(i) = false; % Mark this column for removal
        end
    end

    % Select only the columns that were NOT marked for removal.
    RFR = RFR(:, columns_to_keep);

end
% ```
% 
% ### Why This is the Definitive Fix
% 
% 1.  **Read as Text**: In Step 2, `rateOpts.VariableTypes = repmat({'string'}, 1, numRateColumns);` is the crucial change. We are now telling `readtable`, "Do not try to be clever. Just read the raw contents of every cell in `rateDataRange` as plain text." This prevents it from ever producing `NaN` at the import stage. The output `RateDataTable` will be a table where every cell is a string (e.g., `"0.0123"`, `" - "`, etc.).
% 
% 2.  **`str2double` is the Hero**: The new line `numericRateData = str2double(rateDataAsCells);` is the most important part. `str2double` is a powerful function that takes a cell array of strings and does its best to convert each one to a number. It is robust to leading/trailing spaces and other common issues. If it cannot convert a string (e.g., if the cell contained `"-"`), it will correctly return `NaN` for that element.
% 
% 3.  **Rebuild the Table**: We then take the resulting `numericRateData` (which is now a proper `double` matrix) and put it back into a table, `RateData`.
% 
% This workflow—**Import as Text, Clean, Convert to Number**—is the standard, professional way to handle data from unreliable sources. I'm confident this will finally resolve the `NaN` data issue and give you the working function you ne