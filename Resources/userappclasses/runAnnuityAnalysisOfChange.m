function resultsTimeTable= runAnnuityAnalysisOfChange(varargin)
% This UI method orchestrates the creation of a progression analysis
% and its corresponding waterfall plot.
% defaultStartDate= utilities.DateUtilities.createDateTime(utilities.DefaultScenarioParameters.defaultStartDate);
%
%          defaultEndDate = utilities.DateUtilities.createDateTime(utilities.DefaultScenarioParameters.defaultEndDate);
%          % defaultStartDate = utilities.DefaultScenarioParameters.defaultStartDate;
%         % defaultStartDate.TimeZone = utilities.DefaultScenarioParameters.defaultTimeZone;
%         % defaultEndDate.TimeZone = utilities.DefaultScenarioParameters.defaultTimeZone;
%         defaultReferenceTime =  utilities.DefaultScenarioParameters.defaultReferenceTime;
%         defaultFrequency = utilities.FrequencyType.Annually;
%
%         [defaultAnnuityValuationStartDates, defaultAnnuityValuationEndDates]= utilities.generateDateArrays( defaultStartDate, defaultEndDate, defaultFrequency ,defaultReferenceTime);
%         defaultAnnuityValuationDates = [defaultAnnuityValuationStartDates defaultAnnuityValuationEndDates(end)];
%
%         defaultrateCurveProvider = marketdata.LevelRateCurveProvider(0.04,defaultStartDate);
%         defaultPerson = Person();
%Defaults handles in AnnuityAnalysisOfChangeConfig constructor

p = inputParser;
addParameter(p,'annuitant',@(x) isa(x, 'Person'));
addParameter(p,'valuationDates',@isdatetime);
%addParameter(p,'rateCurveProvider',@(x) isa(x,'marketdata.RateCurveProviderBase'));
%addParameter(p,'scenario',@(x) isa(x,'scenarios.Scenario'));

parse(p,varargin{:});
valuationDates = p.Results.valuationDates;
annuitant = p.Results.annuitant;

% % --- 1. GATHER INPUTS from the app state and UI controls ---
% person = app.Person;
%
% % --- 2. BUILD THE FULL SCENARIO OBJECT ---
% % This is where the complex, one-time setup happens.
% % This logic might be complex, but it now lives in ONE place.
% fprintf('Building full scenario for progression analysis...\n');
% try
%     % Assuming you have a helper method or builder to do this
%     scenario = app.buildFullScenarioForProjection();
%
%     % The scenario must have its market data generated
%     if isempty(scenario.ScenarioMarketData)
%         scenario.generateScenarioMarketData();
%     end
% catch ME
%     uialert(app.UIFigure, sprintf('Failed to build scenario: %s', ME.message), 'Scenario Error');
%     return;
% end

% --- 3. CREATE THE CONFIGURATION OBJECT ---
% The config object is now very simple to create.
analysisConfig = analysis.AnnuityAnalysisOfChangeConfig('annuitant',annuitant,'valuationDates',valuationDates );

% --- 4. RUN THE ANALYSIS ---
% Call the static 'runFromScratch' method.
try
    resultsTimeTable = analysis.AnnuityAnalysisOfChangeStrategyUsingRollFOrwardService.runFromScratch(analysisConfig);
catch ME
    % uialert(app.UIFigure, sprintf('Error running progression analysis: %s', ME.message), 'Analysis Error');
    return;
end


end
