
displayProgressIndicator = 1;
outputFolder = 'test';
addpath('+marketdata\');




% Define a mapping between file names and time zones
    timeZoneMapping = containers.Map;
 % Define the directory where your data files are located
 % in future upgrade to read file paths
    %inputFilePath = 'G:\My Drive\Kaparra Software\UNSWLecture\AccumReturnData';
    inputFilePath = 'G:\My Drive\Kaparra Software\UNSWLecture\PriceReturnData';
    
    
    % Identify files with a specific extension (e.g., .csv)

    dataFiles = dir(fullfile(inputFilePath, '*.csv'));

indexMarketData = marketdata.MarketDataReader.readIndexPriceFiles(inputFilePath,timeZoneMapping,outputFolder,displayProgressIndicator);

display(indexMarketData)