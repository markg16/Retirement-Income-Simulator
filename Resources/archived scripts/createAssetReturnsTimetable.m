function assetReturnsTimetable = createAssetReturnsTimetable(assetReturns, assetReturnStartDates, assetReturnEndDates, frequency)
%CREATEASSETRETURNSTIMETABLE Create a timetable of asset returns with metadata from a numeric array.
%
%   ASSETRETURNSTIMETABLE = CREATEASSETRETURNSTIMETABLE(ASSETRETURNS, ASSETRETURNSTARTDATES, ASSETRETURNENDDATES, FREQUENCY)
%   takes the following inputs:
%       ASSETRETURNS: A numeric array containing asset returns for each period.
%       ASSETRETURNSTARTDATES: A vector of datetime objects representing the start dates of each period.
%       ASSETRETURNENDDATES: A vector of datetime objects representing the end dates of each period.
%       FREQUENCY: A string indicating the frequency of the returns ('daily', 'weekly', 'monthly', etc.).
%
%   It returns a timetable ASSETRETURNSTIMETABLE with the following variables:
%       Time: The end dates of each period.
%       Return: The corresponding asset returns for each period.
%       Frequency: The specified frequency as a categorical variable.

% pass in underlying asset returns for each index eg RFR, S&P500 S&P200 
% returns could be actual or best estimate or from an ESG
% marketIndexAccount instruments needs ticker prices so need to convert returns to ticker prices orwork out how to carry ticker prices through the projection
% remember asset returns are used for simplified analysis. 
% main simulation uses teh instrument class to model actual portofolios based on prices ge price and cashflow of an annuity

% Validate input lengths

if ~isequal(length(assetReturns), length(assetReturnStartDates), length(assetReturnEndDates))
    error('Input arrays must have the same length.');
end

% Create the timetable
assetReturnsTimetable = timetable(assetReturnEndDates', assetReturns', 'VariableNames', {'Return'});

% Add frequency information
if isempty(assetReturns)
    assetReturnsTimetable.Frequency = strings(0, 1); % Empty string array if no returns
else
    assetReturnsTimetable.Frequency = repmat(string(frequency), size(assetReturnsTimetable, 1), 1);
end
end

