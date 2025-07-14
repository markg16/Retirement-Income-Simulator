classdef MarketData < marketdata.MarketDataProvider
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    

    properties
        RateCurvesCollection timetable
        MapCountryToCurveName  %dictionary
        RatesMetaData struct
        AssetReturns   % supposed to be market reference portfolio returns
        MarketIndexPrices timetable
    end
    methods
        function obj = MarketData(rateCurvesCollection,mapCountryToCurveName,ratesMetaData)
            %UNTITLED Factory Method for creating MarketData Objects.
            % Allows for two usage patterns:
            % 1. MarketData() - Creates an object with all properties set to null/empty.
            % 2. MarketData(rateCurvesCollection, mapCountryToCurveName, ratesMetaData) - 
            %    Initializes properties with provided values.

            % Check if any input arguments are provided


            if nargin == 0
                % No input arguments, initialize properties to null/empty
                rateCurvesCollection = marketdata.RateCurveCollection();
                obj.RateCurvesCollection = rateCurvesCollection.RateCurveSets;
                obj.MapCountryToCurveName = containers.Map();
                obj.RatesMetaData = struct();
                rowTimes = datetime("now");
                defaultTickerName = "DefaultTickerName";
                obj.MarketIndexPrices = timetable(rowTimes,defaultTickerName);
            else
                obj.RateCurvesCollection = rateCurvesCollection;
                obj.MapCountryToCurveName = mapCountryToCurveName;
                obj.RatesMetaData = ratesMetaData;

            end

        end

        function curveName = determineCurveName(obj,date, country, rateScenario)
            % DETERMMINECURVENAME Determine the curve name based on country and rate scenario.
            %
            %   CURVENAME = DETERMMINECURVENAME(date COUNTRY, RATESCENARIO)
            %   returns the curve name for a given country and rate scenario ona particualr date.
            %
            %   This method assumes the existence of a `MarketData` object with the
            %   property `MapCountryToCurveName`, which is a dictionary mapping countries
            %   to base curve names. It also expects a `rateScenarios` variable that 
            %   contains the current rate scenario information.
            %
            %   Example:
            %       curveName = marketData.determineCurveName(datetime('2024-07-03'), 'USA', 'Up');

            
             % Find indices where the Time is less than or equal to the provided date
            tempTimeList = obj.RateCurvesCollection.Time;
            date.TimeZone =tempTimeList.TimeZone;

            dateIndex = find(tempTimeList <= date);
             %dateIndex = find(obj.RateCurvesCollection.Time <= date);

            % If any matching dates are found
            if ~isempty(dateIndex)
                % Select the last (latest) matching date
                latestDateIndex = dateIndex(end);

                % Extract the rate curve for the latest date
                rateCurveSet = obj.RateCurvesCollection.RateCurveSets{latestDateIndex};
                if isprop(rateCurveSet, 'RateCurvesSetMapCountryToCurveName')
                    mapCountryToCurveName = rateCurveSet.RateCurvesSetMapCountryToCurveName;
                else
                    mapCountryToCurveName = obj.MapCountryToCurveName; % Default to object's map
                end
            else
                % Handle the case where no historical curves exist
                disp('No rate curve available before the provided date.');
                mapCountryToCurveName = []; % Or some other default value/error handling
            end
            
            
            
            % % Find the RateCurveSet for the given date
            % if ismember(date, obj.RateCurvesCollection.Time)
            %     rateCurveSet = obj.RateCurvesCollection(date, :);
            %      % Extract the RateCurveSet object from the cell array
            %      rateCurveSet = rateCurveSet.RateCurveSets{1}; % Access the first (and only) element of the cell array
            %     % Extract MapCountryToCurveName (if it exists)
            %     if isprop(rateCurveSet, 'RateCurvesSetMapCountryToCurveName')
            %         mapCountryToCurveName = rateCurveSet.RateCurvesSetMapCountryToCurveName;
            %     else
            %         mapCountryToCurveName = obj.MapCountryToCurveName; % Default to object's map
            %     end
            % 
            % else
            %     error('No RateCurveSet found for the specified date.');
            % end
                       
            % Extract the base curve name for the given country
            if mapCountryToCurveName.isKey(country)
                baseCurveName = mapCountryToCurveName(country);
            else
                error('Country not found in the RateCurveSet for the specified date or default map.');
            end
            % Extract the base curve name for the given country
           

            % Construct the full curve name based on the rate scenario
            curveName = baseCurveName + rateScenario;
        end
        function rateCurve = getRateCurveForScenario(obj, date, country, rateScenario)
            %GETRATECURVEFORSCENARIO Retrieve the rate curve for a specific scenario.
            %
            %   RATECURVE = GETRATECURVEFORSCENARIO(OBJ, DATE, COUNTRY, RATESCENARIO)
            %   returns the RateCurveKaparra object corresponding to the specified
            %   DATE, COUNTRY, and RATESCENARIO.
            %
            %   Inputs:
            %       OBJ: The MarketData object.
            %       DATE: The date for which you want the rate curve.
            %       
            
            %       COUNTRY: The country code (e.g., 'AU', 'US').
            %       RATESCENARIO: The rate scenario (e.g., 'base', 'up', 'down').
            %
            %   Outputs:
            %       RATECURVE: The RateCurveKaparra object for the specified scenario.

            % Find the RateCurveSet for the given date

            rateCurveSet = obj.getRateCurveSet(date);

            % dateIndex = find(obj.RateCurvesCollection.Time == date);
            % if isempty(dateIndex)
            %     error('No RateCurveSet found for the specified date: %s', datestr(date));
            % end
            % rateCurveSet = obj.RateCurvesCollection.RateCurveSets{dateIndex}; 

            % Use determineCurveName to get the curve name
            curveName = obj.determineCurveName(date, country, rateScenario);

            % Get the RateCurveKaparra object from the RateCurveSet
            if isKey(rateCurveSet.RateCurvesMap, curveName)
                rateCurve = rateCurveSet.RateCurvesMap(curveName);
            else
                error('Rate curve for the specified country and scenario not found on this date.');
            end
        end
        function rateCurveSet = getRateCurveSet(obj, date)
            %GETRATECURVESET Retrieves the latest available RateCurveSet on or before a given date.
            %
            %  (Similar description as above)

            % Find indices where the Time is less than or equal to the provided date
            tempTimeList = obj.RateCurvesCollection.Time;
            date.TimeZone =tempTimeList.TimeZone;

            dateIndex = find(tempTimeList <= date);

            % If any matching dates are found
            if ~isempty(dateIndex)
                % Select the last (latest) matching date
                latestDateIndex = dateIndex(end);

                % Extract the rate curve for the latest date
                rateCurveSet = obj.RateCurvesCollection.RateCurveSets{latestDateIndex};
            else
                % Handle the case where no historical curves exist
                disp('No rate curve available before the provided date.');
                rateCurveSet = []; % Or some other default value/error handling
            end

            % % old code for exact match  on date. Kept this in case I need
            % % it. Could use this as default and only use nearest code
            % when appropriate eg for simulations.
            % dateIndex = find(obj.RateCurvesCollection.Time == date);
            % if isempty(dateIndex)
            %     error('No RateCurveSet found for the specified date: %s', datestr(date));
            % end
            % rateCurveSet = obj.RateCurvesCollection.RateCurveSets{dateIndex}; 
        end
        
        function rateCurve = extractRateCurve(obj, valuationDate, country,scenarioDataProvider)
            % looks for valid valuation dates and existence of rate curve
            % in market data. Defaults to stale curve if no curve exists.

            % 1. Extract relevant annuity valuation dates
            scenarioAnnuityValuationDates = scenarioDataProvider.getAnnuityValuationDates();

            % 2. Check if valuationDate is a valid annuity valuation date
            isValuationDateValid = ismember(valuationDate, scenarioAnnuityValuationDates);
            
            %3. Get the relevant country for the rate curve
            

            % Initialize rateCurve (in case no match is found)
            rateCurve = []; 

            if isValuationDateValid
                % 3. Attempt to fetch the rate curve directly for valuationDate
                try
                    %valuationDate.TimeZone = '';
                    rateCurve = obj.getRateCurveForScenario(valuationDate, country, scenarioDataProvider.getRateScenarios()); % Accessing internal method
                catch ME
                    % Rate curve doesn't exist on valuationDate
                end
            end

            % 4. Find the preceding available rate curve (if necessary)
            if isempty(rateCurve)
                % Sort annuity valuation dates in descending order
                sortedAnnuityDates = sort(scenarioAnnuityValuationDates, 'descend');

                for i = 1:length(sortedAnnuityDates)
                    prevDate = sortedAnnuityDates(i);
                    if prevDate < valuationDate
                        try
                            rateCurve = obj.getRateCurveForScenario(prevDate, country, scenarioDataProvider.getRateScenarios()); % Accessing internal method
                            break; % Exit loop once a valid curve is found
                        catch ME
                            % No rate curve available for prevDate, continue searching
                        end
                    end
                end
            end

            if isempty(rateCurve)
                error('No rate curve available for valuationDate or any preceding date.');
            end
        end
       

        function dateLastHistoricalPrice = getDateLastHistoricalPrices(obj)
            disp('need to build function to get last historical prices')
            dateLastHistoricalPrice = 'need to build function to get last historical prices';
        end
        function marketPrices = getMarketPrices(obj,priceDate)
            
            %             This approach naturally handles all  scenarios without creating runtime failures but may give wierd results:
            %
            % If priceDate exists: It will be the last and latest date in the tempMarketPrices.Time <= priceDate subset, so its index will be returned.
            % If priceDate is after the last timestamp: The condition tempMarketPrices.Time <= priceDate will be true for all rows. The find command will return the index of the very last row (the latest available date).
            % If priceDate falls between two timestamps: The condition will be true for all rows up to the latest date before priceDate. The find command will return the index of that latest available row.
            % If priceDate is before all timestamps: The condition will be false for all rows, find will return an empty array, and the if statement correctly handles this by creating an empty result.
            %%TODO check that marketprices always haveNAN in last row if not remove
            %idx-1 and replace with idx
            tempMarketPrices = obj.ScenarioHistoricalMarketData.MarketIndexPrices;

            %tempMarketPrices = tempMarketPrices(tempMarketPrices.Time == priceDate,:);

            % Select the row corresponding to the latest time that is on or before the priceDate
            idx = find(tempMarketPrices.Time <= priceDate, 1, 'last');

            % Check if a valid index was found (i.e., priceDate is not before all available dates)
            if ~isempty(idx)
                tempMarketPrices = tempMarketPrices(idx-1, :);
            else
                % Handle the case where priceDate is before any data exists
                % Return an empty table with the same structure
                tempMarketPrices = tempMarketPrices([], :);
                disp('Warning: priceDate is earlier than all available market data.');
            end
            
            marketPrices = tempMarketPrices;
        end

        function marketDataSubSet = ExtractMarketDataBetweenTwoDates(obj,startDate,endDate)
            disp('extracting market data for scenario specific')
            
            if nargin == 2
                endDate = obj.getDateLastHistoricalPrices();
            end

            % Ensure startDate and endDate are datetime objects
            if ~isdatetime(startDate)
                startDate = datetime(startDate);
            end
            if ~isdatetime(endDate)
                endDate = datetime(endDate);
            end

            % Filter RateCurvesCollection
            startDateRates = startDate;
            startDateRates.TimeZone = '';
            endDateRates = endDate;
            endDateRates.TimeZone = '';

            filteredRateCurves = obj.RateCurvesCollection(obj.RateCurvesCollection.Time >= startDateRates & obj.RateCurvesCollection.Time <= endDateRates, :);

            % Filter AssetReturns (assuming it's a timetable as well)
            if isprop(obj, 'AssetReturns') && istimetable(obj.AssetReturns) 
                filteredAssetReturns = obj.AssetReturns(obj.AssetReturns.Time >= startDate & obj.AssetReturns.Time <= endDate, :);
            else
                filteredAssetReturns = []; % Or handle the case where AssetReturns is not a timetable or doesn't have a Time column
            end

            % Filter MarketIndexPrices (assuming it's a timetable as well)
            if isprop(obj, 'MarketIndexPrices') && istimetable(obj.MarketIndexPrices) 
                filteredMarketIndexPrices = obj.MarketIndexPrices(obj.MarketIndexPrices.Time >= startDate & obj.MarketIndexPrices.Time <= endDate, :);
            else
                filteredMarketIndexPrices = []; % Or handle the case where MarketIndexPrices is not a timetable or doesn't have a Time column
            end

            %  if isprop(obj, 'MarketIndexPrices') && istimetable(obj.MarketIndexPrices.IndexMarketDataTimeTable) 
            %     filteredMarketIndexPrices = obj.MarketIndexPrices.IndexMarketDataTimeTable(obj.MarketIndexPrices.IndexMarketDataTimeTable.Time >= startDate & obj.MarketIndexPrices.IndexMarketDataTimeTable.Time <= endDate, :);
            % else
            %     filteredMarketIndexPrices = []; % Or handle the case where MarketIndexPrices is not a timetable or doesn't have a Time column
            % end

            % Create a new MarketData object with the filtered data
            marketDataSubSet = marketdata.MarketData(filteredRateCurves, obj.MapCountryToCurveName, obj.RatesMetaData);
            marketDataSubSet.AssetReturns = filteredAssetReturns;
            marketDataSubSet.MarketIndexPrices = filteredMarketIndexPrices;
        end

        function obj= filterMarketPriceIndexes(obj, marketIndexesToExtract)

            % this fucntion is used to extract out
            % marketIndexesToExtract 

            marketIndexPrices = obj.MarketIndexPrices;

            % Get the variable names from the table
            varNames = marketIndexPrices.Properties.VariableNames;

            % Find the common variable names
            commonVars = intersect(varNames, marketIndexesToExtract);

            % Filter the timetable
            filteredmarketIndexPrices = marketIndexPrices(:, commonVars);

            obj.MarketIndexPrices = filteredmarketIndexPrices;

        end

        
        
    end
    methods (Static)
        % function obj = marketData()  % Default constructor
        %     % Initialize properties with default values (if needed)
        %     obj.RateCurvesCollection = timetable();
        %     obj.MapCountryToCurveName = containers.Map(); % Empty dictionary
        %     obj.RatesMetaData = struct();  % Empty struct
        %     obj.AssetReturns = [];  % Empty array
        %     obj.MarketIndexes = [];  % Empty array
        % end
        

        function s = saveMarketData(obj)
            % Convert MarketData object to a struct for saving

            s = struct();
            s.RateCurvesCollection = table(obj.RateCurvesCollection); % Convert timetable to table
            s.MapCountryToCurveName = obj.MapCountryToCurveName;
            s.RatesMetaData = obj.RatesMetaData;

            % For AssetReturns and MarketIndexes, handle them based on their types
            % If they are empty, include them as empty arrays in the struct
            s.AssetReturns = obj.AssetReturns;
            s.MarketIndexPrices = obj.MarketIndexPrices;
        end

        function obj = loadMarketData(s)
            % Reconstruct MarketData object from the saved struct

            rateCurvesCollection = s.RateCurvesCollection.Var1;
            mapCountryToCurveName = s.MapCountryToCurveName;
            ratesMetaData =s.RatesMetaData;
            obj = marketdata.MarketData(rateCurvesCollection,mapCountryToCurveName,ratesMetaData);
            if isprop(s, 'AssetReturns')
                obj.AssetReturns = s.AssetReturns;
            end

            if isprop(s, 'MarketIndexPrices')
                obj.MarketIndexPrices = s.MarketIndexPrices;
            end

        end
     end
end