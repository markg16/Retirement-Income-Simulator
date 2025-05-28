classdef MarketDataReader
    methods (Static)
        
        function marketData = generateAndLoadRatesData(inputFolderRates, rateFileConstruct, cacheFolder,rateCurveEndDates,outputFolder, displayRateCurveNames, verbose)
            %GENERATEMARKETDATA Fetches and processes rates market data for the scenario.
            %The market data is stored in the Scenario object as a containers map with the valuation date
            % as the key and the rate curve object as the value.
            % Read rate curves for all valuation dates


            %0 Establish local variables

            % inputFileNameRates;
            % cacheFolder;
            % inputFolderRates;
            % outputFolder;
            % displayRateCurveNames;


            import marketdata.*  % Import all classes from the marketdata package

            % 1. Check if cached rate curves or folder exist and load
            % cached rate curves


            rateCurveCollection = timetable(); % Initialize an empty timetable
            cacheFile = utilities.ValidationUtils.checkCachedFolderExists(cacheFolder,'cachedMarketData.mat');

            disp("importing existing cache if it exists")

            if isfile(cacheFile)
                disp("cache exists loading cache")
                s = load('cachedMarketData.mat');
                cachedMarketData = marketdata.MarketData.loadMarketData(s);
                defaultMapCountryToCurveName = cachedMarketData.MapCountryToCurveName;
                defaultRatesMetaData = cachedMarketData.RatesMetaData;
                rateCurveCollection = cachedMarketData.RateCurvesCollection;
                disp("cache loaded")
                % load(cacheFile, 'cachedMarketData');
                %marketData = cachedMarketData;
                % else
                %     marketData.RateCurvesCollection = containers.Map('KeyType', 'char', 'ValueType', 'any');  % Initialize empty map
            end



            disp(" %2. Load additional rate curves from source files (if not included in cached files or the source file has changed since cached file was created)")
            rateCurveDates = rateCurveEndDates;
            defaultRatesMetaData.EndDateRates = rateCurveEndDates(end);
            prefix = rateFileConstruct.Prefix;
            suffix = rateFileConstruct.Suffix;
            extension = rateFileConstruct.Extension;
            missingFiles = {}; % Cell array to store names of missing files
            curveCounter = 0;
            totalCurves =length(rateCurveDates);


            for i = 1:totalCurves  % Loop through valuation dates
                curveCounter = curveCounter + 1;
                valuationDate = rateCurveDates(i);

                inputFileNameRates = prefix+datestr(valuationDate,'yyyymmdd')+suffix+extension;
                rateFile = fullfile(inputFolderRates, inputFileNameRates);


                try
                    if ~isempty(rateCurveCollection)
                        % % Handle case where RateCurvesCollection is empty initially
                        % % You might want to initialize it, fetch data, or set a default value
                        % print('RateCurvesCollection is empty. Initializing or fetching data.');
                        % % ... (Your initialization or data fetching logic)
                        if isfile(rateFile) % only proceed with dir if it exists
                            if ismember(valuationDate, rateCurveCollection.Time)
                                %existingRateSet = rateCurveCollection.getRateCurveSet(valuationDate);
                                existingRateCurveSet = cachedMarketData.getRateCurveSet(valuationDate);

                                % Check if source file has changed since the last caching
                                %[~, fileInfo] = fileattrib(rateFile);

                                % Check if the file exists
                                listing = dir(rateFile);
                                if isempty(listing)
                                    error('File not found: %s', rateFile);
                                end

                                % Get file modification date as a datetime object
                                sourceFileDateSaved = datetime(listing.date, 'InputFormat', 'dd-MMM-yyyy HH:mm:ss');

                                %sourceFileDateSaved = dir(rateFile).date;

                                if sourceFileDateSaved > existingRateCurveSet.RateCurvesSetMetaData.SourceFileTimestamp
                                    % File has been modified, re-read from source
                                    %fprintf("Loading updated curve for date %s \n ",datestr(valuationDate) )
                                    fprintf("Loading updated curve %d of %d for date %s \n", curveCounter, totalCurves, datestr(valuationDate)); 

                                    newRateCurveSet = MarketDataReader.readRateCurveForDate(inputFolderRates, inputFileNameRates,valuationDate, outputFolder, displayRateCurveNames);


                                    % Add logging info to metadata
                                    newRateCurveSet.RateCurvesSetMetaData.SourceFileTimestamp = sourceFileDateSaved;
                                    newRateCurveSet.RateCurvesSetMetaData.SourceFileReread = true;

                                    % Optional: Log to screen if verbose flag is true
                                    if verbose
                                        %fprintf('Rate curve for %s reread from source file.\n', datestr(valuationDate));
                                        fprintf("Rate curve %d of %d for date %s reread from source file.\n", curveCounter, totalCurves, datestr(valuationDate));
                                    end
                                    newEntry = timetable(valuationDate', {newRateCurveSet}, 'VariableNames', {'Time', 'RateCurveSets'});
                                    rateCurveCollection = [rateCurveCollection; newEntry];  % Concatenate vertically
                                    %rateCurveCollection(valuationDate) = {newRateCurveSet};
                                else
                                    % Optional: Log to screen if verbose flag is true
                                    if verbose
                                        %fprintf('Existing Rate curve for %s not reread.\n', datestr(valuationDate));
                                        fprintf("Exisiting rate curve %d of %d for date %s is not reread.\n", curveCounter, totalCurves, datestr(valuationDate));
                                    end
                                    
                                end

                            else

                                rateFile =  fullfile(inputFolderRates, inputFileNameRates);
                                %[~, fileInfo] = fileattrib(rateFile);
                                sourceFileDateSaved = dir(rateFile).date;
                                % Rate curve not found in cache, read from source

                                fprintf("Loading new curve for date %s\n ",datestr(valuationDate) )

                                rateCurveSet = MarketDataReader.readRateCurveForDate(inputFolderRates, inputFileNameRates,valuationDate,outputFolder, displayRateCurveNames);
                                % Add logging info to metadata
                                rateCurveSet.RateCurvesSetMetaData.SourceFileTimestamp = sourceFileDateSaved;
                                rateCurveSet.RateCurvesSetMetaData.SourceFileReread = false;
                                ratesMetaData = rateCurveSet.RateCurvesSetMetaData;
                                if i == 1
                                    defaultMapCountryToCurveName = rateCurveSet.RateCurvesSetMapCountryToCurveName;
                                    defaultRatesMetaData = rateCurveSet.RateCurvesSetMetaData;
                                end
                                newEntry = timetable(valuationDate', {rateCurveSet}, 'VariableNames', {'RateCurveSets'});
                                rateCurveCollection = [rateCurveCollection; newEntry];  % Concatenate vertically
                                %rateCurveCollection(valuationDate) = {rateCurveSet};
                            end
                        else

                            % File not found, log the filename
                            missingFiles{end+1} = rateFile;
                            if verbose
                                warning('File not found: %s\n', rateFile);
                            end
                        end
                    else

                        rateFile = fullfile(inputFolderRates, inputFileNameRates);
                        %[~, fileInfo] = fileattrib(rateFile);

                        if isfile(rateFile) % only proceed with dir if it exists
                            listing = dir(rateFile);
                            sourceFileDateSaved = listing.date;
                            % Rate curve not found in cache, read from source
                            rateCurveSet = MarketDataReader.readRateCurveForDate(inputFolderRates, inputFileNameRates,valuationDate,outputFolder, displayRateCurveNames);
                            % Add logging info to metadata
                            rateCurveSet.RateCurvesSetMetaData.SourceFileTimestamp = sourceFileDateSaved;
                            rateCurveSet.RateCurvesSetMetaData.SourceFileReread = false;
                            if i == 1
                                defaultMapCountryToCurveName = rateCurveSet.RateCurvesSetMapCountryToCurveName;
                                defaultRatesMetaData = rateCurveSet.RateCurvesSetMetaData;
                            end

                            rateCurveCollection = timetable(valuationDate',{rateCurveSet},'VariableNames', {'RateCurveSets'});
                                
                            % File not found, log the filename
                            missingFiles{end+1} = rateFile;
                            if verbose
                                warning('File not found: %s\n', rateFile);
                            end
                        end

                    end

                catch ME
                    % Handle any other potential errors during the process
                    % You can customize this error handling based on your specific requirements
                    warning('RiskManagement:GeneralError',"An error occurred: %s", ME.message);
                end
            end

            marketData = marketdata.MarketData(rateCurveCollection,defaultMapCountryToCurveName,defaultRatesMetaData); %sets up the market data object assuming last valuation date has the metadat and country maps that apply to all ratecurvesets.

            %marketData = updatedMarketData; % Assuming readRateCurveForDate returns a RateCurveKaparra object

            disp("saving updated cachedMarketDataRATESONLY")

            % 3. Save updated rate curves to cache
            s = marketData.saveMarketData(marketData);

            save('cachedMarketData','-Struct', 's');

        end
        function rateCurvesSet = readRateCurveForDate(inputFolderRates, inputFileNameRates,valuationDate,outputFolder, displayRateCurveNames)
            %READRATECURVEFORDATE Reads and creates a RateCurveKaparra object for a given date.
            % ... (other parts of the description)
             
            % 1. Read Rate Files and Create RateCurves (multiple countries) for a valuation date(using existing function)
            [rateCurves, ~, mapCountryToCurveName] = marketdata.readRateFilesAndCreateRateCurves(inputFolderRates,inputFileNameRates,valuationDate, outputFolder,displayRateCurveNames);  % Pass in the necessary arguments

            % 2. Convert to RateCurveKaparra (using existing function)
            rateCurvesSet = marketdata.convertRateCurvesToRateCurveKaparra(rateCurves,mapCountryToCurveName);
                  
        end % end function

        function indexPrices = readIndexPriceFile(inputFilePath, timeZoneMapping,outputFolder,displayProgressIndicator)
            %READINDEXPRICESFILE  Reads price data for indexes from a file

            %1. Read in prices for each index
            % Read the data from the specified file
            opts = delimitedTextImportOptions('DataLines', 2);
            opts.VariableNames = ["Date","Price","Open","High","Low","Vol_","Change_"];
            raw_data = readtable(inputFilePath,opts); % filePath = fullfile(dataDirectory, dataFiles(i).name);

            % Create a table to store the preprocessed data
            data = table();
            % % Extract the file name without the extension to use as a field name
            [~, filename, ~] = fileparts(inputFilePath);

            %read resources associated with teh data file eg
            % Currency
            % date format
            if contains(inputFilePath, 'AccumReturn')
                raw_data_file_date_format = 'dd/MM/yyyy';
            elseif contains(inputFilePath,'PriceReturn')
                raw_data_file_date_format = 'MM/dd/yyyy';
            else
                raw_data_file_date_format = 'unknown date format';
            end

            %PreProcess Data to meet standard return data formats
            % assumes input files have teh following format as downloaded from
            % investing.com
            %%"Date","Price","Open","High","Low","Vol.","Change %"
            %%"10/27/2023","4,117.37","4,152.93","4,156.70","4,103.78","","-0.48%"
            % Convert the 'Date' column to datetime and add time stamp for the
            % relevant coountry

            data.Date = datetime(raw_data.Date, 'InputFormat', raw_data_file_date_format)+ hours(16);
            data.DateS = datetime(raw_data.Date, 'InputFormat', raw_data_file_date_format) + hours(16); % create a field for standardised time zone

            time_zone=marketdata.MarketDataReader.determineTimeZone(filename, timeZoneMapping);
            data.Date.TimeZone = time_zone; %set raw data tiemzone
            data.DateS.TimeZone = 'Australia/Sydney'; % Set a default time zone to synch on

            % Remove commas and convert Value columns to doubles. Have removed the
            % change data as I have no idea how it is calculated
            valueColumns = ["Price","Open","High","Low","Vol_"];
            for col = valueColumns
                data.(col) = str2double(strrep(raw_data.(col), ',', ''));
            end
            indexPrices = data;
        end


        function indexMarketData = readIndexPriceFiles(inputDataDirectory,timeZoneMapping,outputFolder,displayProgressIndicator)
            dataFiles = dir(fullfile(inputDataDirectory, '*.csv'));
            % Initialize a struct to store data
            dataStruct = struct();
            if isempty(timeZoneMapping)
                timeZoneMapping = containers.Map;
            end

            for i = 1:numel(dataFiles)

                inputFilePath = fullfile(inputDataDirectory, dataFiles(i).name);

                % Call the readAndPreprocessData function to read and preprocess data
                data = marketdata.MarketDataReader.readIndexPriceFile(inputFilePath, timeZoneMapping,outputFolder,displayProgressIndicator);

                % add per period returns based on close price
                %MUST CHECK THAT THE INDEXING IS CORRECT AND I UNDERSTAND WHY THIS
                %DIFFERS FROM DOING CALCS AFTER SYNCHRONISATION
                perPeriodReturn = log(data.Price(1:end-1)./data.Price(2:end));
                perPeriodReturn =[perPeriodReturn;0];

                data.return = perPeriodReturn;
                % Store the preprocessed data in the struct
                [~, filename, ~] = fileparts(dataFiles(i).name);
                cleanedFieldName = matlab.lang.makeValidName(filename);
                dataStruct.(cleanedFieldName) = data;
            end
            
            returnsStruct = dataStruct;
            returnsTimeTable = marketdata.MarketDataReader.convertReturnsTableToTimeTable(returnsStruct);
            synchronisedReturnsTimeTable = marketdata.MarketDataReader.synchroniseReturnsTimeTable(returnsTimeTable);
            indexReturns = synchronisedReturnsTimeTable;
            indexMarketData = indexReturns; %IndexMarketDataTimeTable;

            % indexMarketData = marketdata.MarketIndexAcctDataDecorator(indexReturns);

        end

        function outputReturnsTimeTable = convertReturnsTableToTimeTable(inputReturnsStruct)
            % Initialize a struct to store all data as timetables
            timetableStruct = struct();
            % Define the cell array of field names
            fieldNames = fieldnames(inputReturnsStruct);

            % Loop through data elements in the struct
            for i = 1 : numel(fieldNames)

                fieldName = fieldNames{i};

                % Access the field using dataStruct.(fieldName)
                rawData = inputReturnsStruct.(fieldName);
                % Specify the row times based on the 'DateS' column
                dataTimetable = table2timetable(rawData, 'RowTimes', rawData.DateS);

                % Store the resulting timetable in the new struct
                timetableStruct.(fieldName) = dataTimetable;

            end


            outputReturnsTimeTable = timetableStruct;
        end

        function outputSynchronisedReturnsTimeTable = synchroniseReturnsTimeTable(inputReturnsTimeTable)

            % SYNCHRONIZE TIME SERIES
            % lines up the US close with Australia next day. Could do better by lining up time stamps for close and open
            % there are NAT and Nan fo rthe last couple of days as data doe snot
            % include Australian open for next day
            % SP500Timetable= timetableStruct.S_P500HistoricalData;

            % Define the cell array of field names for timetableStruct
            fieldNames = fieldnames(inputReturnsTimeTable);

            % Initialize a cell array to store the variable names for each timetable
            variableNames = {};

            % loop through timetable struct  field names and produce a time table with
            % the index name eg SP500 then can use naming convention to relabel
            % synchronised timetable variable names as Index name + TT.properties.variable

            %% We Converts all local time stamps to Sydney Australia time zone and summarise all indexes prices by day
            %% Assumes US close is next day in SYdney Australia ( actual New York Close is closer to Australia open)

            % %
            % % fieldName =fieldNames{1};
            % %
            % % TT = timetableStruct.(fieldName);

            for i = 1:numel(fieldNames)

                fieldName = fieldNames{i};

                if contains(fieldName, 'S_P500')|| contains(fieldName, 'S&P 500')
                    indexName = 'SP500';
                elseif contains(fieldName, 'Nikkei225')
                    indexName = 'Nikkei225';
                elseif contains(fieldName, 'FTSE')
                    indexName = 'FTSE';;
                elseif contains (fieldName, 'ASX') && contains(fieldName, 'REIT')
                    indexName = 'ASX200REIT';
                elseif contains(fieldName, 'ASX')
                    indexName = 'ASX200';
                elseif contains(fieldName, 'TR10YrGov')
                    indexName = 'TR10YrGov';
                elseif contains(fieldName, 'EuroStoxx50')
                    indexName = 'EuroStoxx50';
                else
                    indexName = 'unknownindex';
                end
                % Store the variable name in the cell array
                variableNames{i} = indexName;

                newTimetable = inputReturnsTimeTable.(fieldName);

                % Rename the variables in the new timetable to match the index name
                varNames = newTimetable.Properties.VariableNames;
                for j = 1:numel(varNames)
                    varNames{j} = [indexName, '_', varNames{j}];
                end
                newTimetable.Properties.VariableNames = varNames;

                if i == 1
                    TT = newTimetable;
                else
                    TT = synchronize(TT, newTimetable, 'daily', 'next');
                end
            end

            outputSynchronisedReturnsTimeTable = TT;

        end



%2. create Matlab Index objects and populate with prices

%3 Convert Matlan index instruments to Kaparra Instruments (to encaspulate
% dependence on Matlab tool box)

       

        function time_zone = determineTimeZone(filename, timeZoneMapping)
            % Define a mapping between file names and time zones
            if isempty(timeZoneMapping)
                timeZoneMapping = containers.Map;
            end

            DefaultTimeZone = 'Australia/Sydney';
            if contains(filename, 'SP500')|| contains(filename, 'S&P 500')
                timeZoneMapping(filename) = 'America/New_York';
            elseif contains(filename, 'Nikkei')
                timeZoneMapping(filename) = 'Asia/Tokyo';
            elseif contains(filename, 'FTSE')
                timeZoneMapping(filename) = 'Europe/London';
            elseif contains(filename, 'ASX')

                timeZoneMapping(filename) = 'Australia/Sydney';
            else
                timeZoneMapping(filename) = DefaultTimeZone;
            end
            time_zone = timeZoneMapping(filename);
        end



        function fredData = readFredData()
            %https://au.mathworks.com/help/thingspeak/retrieve-current-financial-data-using-datafeed-toolbox.html
            openExample('thingspeak/RetrieveFREDExample')
            % ... (other methods)
        end
    end
end
