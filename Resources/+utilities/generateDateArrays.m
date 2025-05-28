function [startDates, endDates] = generateDateArrays(startDate, endDate, frequency, referenceTime)
%GENERATEDATEARRAYS Generate start and end date arrays with a reference time.
%   [STARTDATES, ENDDATES] = GENERATEDATEARRAYS(STARTDATE, ENDDATE, FREQUENCY, REFERENCETIME)
%   generates datetime arrays STARTDATES and ENDDATES for a given time period,
%   with a specific frequency and optional reference time.
%
%   Inputs:
%   - STARTDATE: Start date (datetime).
%   - ENDDATE: End date (datetime).
%   - FREQUENCY: String specifying frequency ('daily', 'weekly', 'monthly', 'quarterly', 'annually', 'hourly', 'minute').
%   - REFERENCETIME: (Optional) Time of day for all dates (duration). Defaults to 0 (start of day).
%
%   Outputs:
%   - STARTDATES: Array of datetime objects representing start of each period.
%   - ENDDATES: Array of datetime objects representing end of each period.

% Input validation (ensure valid datetime objects and frequency)
arguments
    startDate datetime
    endDate datetime
    frequency (1,1) string {utilities.ValidationUtils.mustBeValidFrequency} % Call from the utils package 
    referenceTime (1,1) duration = hours(17) % Default to start of day (midnight)
end
% Check if the reference time was provided
if nargin < 4 
    referenceTime = hours(17);  % Set default if referenceTime is not provided
end

% Additional check: Ensure referenceTime is a duration
if ~isduration(referenceTime)
    error('REFERENCETIME must be a duration object (e.g., hours(12)).');
end

if startDate > endDate
    error('STARTDATE must be before or equal to ENDDATE.');
end

% Rebase to start of day
startDate = dateshift(startDate, 'start', 'day');
endDate = dateshift(endDate, 'start', 'day');

% Generate dates based on frequency and reference time
switch lower(frequency) 
    case 'daily'
        allDates = startDate + referenceTime : endDate + referenceTime;
    case 'weekly'
        allDates = startDate + referenceTime : caldays(7) : endDate + referenceTime;
    case 'monthly'
        allDates = startDate + referenceTime : calmonths(1) : endDate + referenceTime;
    case 'quarterly'
        allDates = startDate + referenceTime : calquarters(1) : endDate + referenceTime;
    case 'annually'
        allDates = startDate + referenceTime : calyears(1) : endDate + referenceTime;
    case 'hourly'
        allDates = startDate + referenceTime : hours(1) : endDate + referenceTime;
    case 'minute'
        allDates = startDate + referenceTime : minutes(1) : endDate + referenceTime;
end

% Split dates into start and end of each period
startDates = allDates(1:end-1);   
endDates = allDates(2:end);     
end