function [outputArg1,outputArg2] = plotRates(varargin)

%This function plots up to two sets of rates. Add the second axes and
% country at end of varargin. 
    % Requires a minimum set of variables  
    % ax1, rateScenariosToPlot, rateCurvesToPlot, keyCountry1ToPlot, and startDateRatesToPlot
    % Conceptually takes all country rates for a particular valuaiton date and
    % displays them. WIll need to think differently to display a countries
    % rates for all different valuation dates.
    % utilises outputs from readRateFilesAndCreateRateCurves()

    numInputs = nargin; % Count input arguments    
    if numInputs < 5
        error('Not enough input arguments. At least ax1, rateScenariosToPlot, rateCurvesToPlot, keyCountry1ToPlot, and startDateRatesToPlot are required.');
    end
ax1 = varargin{1};
    rateScenariosToPlot = varargin{2};
    rateCurvesToPlot = varargin{3};
    keyCountry1ToPlot = varargin{4};
    startDateRatesToPlot = varargin{5};
   %tiledlayout(2,1)
    
    %display("pre plot");
   
    hold(ax1, 'on');
    i = 1;
    for i = 1: length(rateScenariosToPlot) 
        keyScenario = rateScenariosToPlot(i);
        keysCurveNames = keys(rateCurvesToPlot);
        keysCurveNamesCountry = extractBetween(keysCurveNames,1,2);
        keyCurveNameIndices = contains(keysCurveNamesCountry,keyCountry1ToPlot) & contains(keysCurveNames,keyScenario); %logical array with 1 for elements that meet teh criteria
        keyRateCurveName = keysCurveNames(keyCurveNameIndices);
        selectedRateCurve = rateCurvesToPlot(keyRateCurveName);
        h(i) = plot(ax1,selectedRateCurve.Dates,selectedRateCurve.Rates);

        %display("ENTERED plot function post   plot in loop");
        % h(i) = plot(selectedRateCurve.Dates,selectedRateCurve.Rates);
        i = i+1;
    
    end % end for loop for scenarios

    %display("ENTERED plot function post   plot post loop");
    
    % Add labels and title
    xlabel(ax1,'Maturity Date');
    ylabel(ax1,'Zero Rates');
    subTitleString = 'Date: ' + string(datestr(startDateRatesToPlot,'dd/mm/yyyy')) + ' Country: '  + keyCountry1ToPlot;
    title(ax1, {'Plot of Zero Rates vs. Maturity', subTitleString},'Interpreter', 'none');
    
    % Add a legend
    leg = legend(ax1,rateScenariosToPlot,'Interpreter', 'none');
    leg.Location = 'east';
   
    hold(ax1, 'off');

if numInputs == 7  
    
    ax2 = varargin{6};
    keyCountry2ToPlot = varargin{7};
    hold(ax2, 'on');
    i = 1;
    for i = 1: length(rateScenariosToPlot) 
        keyScenario = rateScenariosToPlot(i);
        keysCurveNames = keys(rateCurvesToPlot);
        keysCurveNamesCountry = extractBetween(keysCurveNames,1,2);
        keyCurveNameIndices = contains(keysCurveNamesCountry,keyCountry2ToPlot) & contains(keysCurveNames,keyScenario); %logical array with 1 for elements that meet teh criteria
        keyRateCurveName = keysCurveNames(keyCurveNameIndices);
        selectedRateCurve = rateCurvesToPlot(keyRateCurveName);
        h(i) = plot(ax2,selectedRateCurve.Dates,selectedRateCurve.Rates);
        % h(i) = plot(selectedRateCurve.Dates,selectedRateCurve.Rates);
        i = i+1;
    
    end % end for loop for scenarios
    
    % Add labels and title
    xlabel(ax2,'Maturity Date');
    ylabel(ax2,'Zero Rates');
    subTitleString = 'Date: ' + string(datestr(startDateRatesToPlot,'dd/mm/yyyy')) + ' Country: '  + keyCountry2ToPlot;
    title(ax2, {'Plot of Zero Rates vs. Maturity', subTitleString},'Interpreter', 'none');
    
    % Add a legend
    leg = legend(ax2,rateScenariosToPlot,'Interpreter', 'none');
    leg.Location = 'east';
   
    hold(ax2, 'off');
end % end second set of axes

end