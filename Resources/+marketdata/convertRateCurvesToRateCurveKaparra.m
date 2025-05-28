function rateCurveSet= convertRateCurvesToRateCurveKaparra(rateCurves,mapCountryToCurveName)
%Convert RateCurvesKaparra This function converts a dictionary of rateCurve
%objects to RateCurveKaparra objects and returns  a RateCurveSet object

% cacheFile is expected to be a RateCurveSet object withproperties: 
%         RateCurvesMap  %containers.map      % Dictionary (containers.Map) to store RateCurveKaparra objects
%         RateCurvesSetMetaData %struct            % Struct to store metadata (e.g., SourceFileReread, SourceFileDateSaved)
%         RateCurvesSetMapCountryToCurveName  %dictionary% Dictionary mapping countries to curve names
%   Detailed explanation goes here


% Initialize a dictionary
    % Initialize a dictionary to store RateCurveKaparra objects by country code
    rateCurvesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');

    % Get the keys (country names) from the input dictionary
    keys = rateCurves.keys;

    for i = 1:length(keys)
        key = keys{i};  % Get the country name (key)

        % Extract data from the RateCurve corresponding to the key
        type = rateCurves(key).Type;
        settle = rateCurves(key).Settle;
        dates = rateCurves(key).Dates;
        rates = rateCurves(key).Rates;
        compounding = rateCurves(key).Compounding;
        basis = rateCurves(key).Basis;


        % % Get the metadata for the curve if it is already in the cacheFile
        % if ~isempty(cacheFile)
        %     % load(cacheFile, 'cachedRateCurveCollection');
        %     metaData = cacheFile.RateCurvesSetMetaData;  % the settle date should be the valuation date associated with the set
        % else
        %     metaData = []; % No metadata if the curve is not cached
        % end
        % Create RateCurveKaparra object and store it in the dictionary
        rateCurveK = marketdata.RateCurveKaparra(type,settle,dates, rates,compounding, basis);  
        % Determine curve name (adjust the function based on your naming convention)
        % curveName = strcat(key, '_', datestr(settle, 'dd_mm_yyyy'), '_', type);
        curveName = key;

        % Add the RateCurveKaparra object to the RateCUrveSet dictionary with curveName as the key
        rateCurvesMap(curveName) = rateCurveK; 
    end

    % Create a RateCurveSet object and return it
    rateCurvesSetCountryToCurveName = mapCountryToCurveName;
    %rateCurvesSetMetaData = [];
    rateCurveSet = marketdata.RateCurveSet(rateCurvesMap,rateCurvesSetCountryToCurveName);% call the RateCUrveSet  constructor
end