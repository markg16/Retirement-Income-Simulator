function marketData =initialiseMarketDataObject()


% Other Settings
inputArgs = runtimeclasses.initialiseInputArguments();

format(inputArgs.runtime.numericalOutputformat);
floatingPointTolerance = inputArgs.runtime.floatingPointTolerance;
verbose = inputArgs.runtime.verbose;
displayRateCurveNames =inputArgs.runtime.displayRateCurveNames;
displayProgressIndicator = 1;




referenceTime = inputArgs.Dates.referenceTime;
startDateRates = inputArgs.Dates.startDateRates+referenceTime; %= '2016-03-31';
endDateRates = inputArgs.Dates.endDateRates+referenceTime;
marketPriceInputFilePath = inputArgs.Folders.marketPriceInputFilePath; %'G:\My Drive\Kaparra Software\UNSWLecture\PriceReturnData';
inputFolderRates = inputArgs.Folders.inputFolderRates; %= 'data/rates/';
cacheFolder = inputArgs.Folders.cacheFolder; %'path/to/your/cache/folder'
outputFolder = inputArgs.Folders.outputFolder;

rateFileConstruct = inputArgs.RateFile;
rateFileInputFileFrequency = utilities.FrequencyType.Monthly;



% # Load Rates data
disp("loading rates data")
disp("generating rate file dates")
rateInputFileDates = utilities.generateDateArrays(startDateRates, endDateRates, rateFileInputFileFrequency);

disp("loading rate files for  dates from file or cached file if exists")
marketData = marketdata.MarketDataReader.generateAndLoadRatesData(inputFolderRates, rateFileConstruct, cacheFolder,rateInputFileDates,outputFolder, displayRateCurveNames, verbose);

disp("finished loading rate file dates")

disp("loading market index files")

% Load market Indexes

% Define a mapping between file names and time zones
timeZoneMapping = containers.Map;
indexMarketData = marketdata.MarketDataReader.readIndexPriceFiles(marketPriceInputFilePath,timeZoneMapping,outputFolder,verbose);
indexMarketData.Time=datetime(indexMarketData.Time +referenceTime,'Format','dd/MM/uuuu HH:mm:ss'); % assumes prices are returned as start of day. if the routine is changed to provide prices at close of business remove referenceTime

marketData.MarketIndexPrices = indexMarketData;

disp("finished loading market index files")

end
