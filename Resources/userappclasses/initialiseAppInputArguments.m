function inputArgs = initialiseAppInputArguments()
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

inputArgs.runtime.displayRateCurveNames = 0;
inputArgs.runtime.defaultCashflows = 0;
inputArgs.runtime.verbose = 1;
inputArgs.runtime.defaultFrequency = utilities.FrequencyType.Annually;
inputArgs.runtime.assetReturnFrequency = utilities.FrequencyType.Weekly;
% inputArgs.runtime.matlabPath = 'G:\My Drive\Kaparra Software\Rates Analysis\Resources';
% inputArgs.runtime.newPath = utilities.PathManagement.addPaths(rootPath,'archive');
inputArgs.runtime.numericalOutputformat = 'bank';
inputArgs.runtime.floatingPointTolerance = 1e-10;

inputArgs.Dates.startDateRates = datetime('2016-03-31');% earliest date rate input file is available
inputArgs.Dates.endDateRates = datetime('2022-11-30');% latest date rate input file is available
inputArgs.Dates.startDates = datetime('2017-03-31');% scenario projection start date
inputArgs.Dates.endDates = datetime('2040-11-30');% scenario projection end date
inputArgs.Dates.referenceTime = hours(17);
inputArgs.Dates.localTimeZone = 'Australia/Sydney';
inputArgs.Dates.dateTimeFormat = 'dd/MM/uuuu HH:mm:ss';

inputArgs.Folders.inputFolderRates = 'G:\My Drive\Kaparra Software\RatesDataAquisition\EIOPAData';
inputArgs.Folders.assetReturnsFile = 'G:\My Drive\Kaparra Software\RatesDataAquisition\AssetReturnsData\asset_returns.csv';
inputArgs.Folders.outputFolder = 'G:\My Drive\Kaparra Software\Rates Analysis\Output';
inputArgs.Folders.inputFileNameRates ='EIOPA_RFR_20160131_Term_Structures.xlsx';

inputArgs.Folders.inputFolderMortality = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables';
inputArgs.Folders.cacheFolder = 'G:\My Drive\Kaparra Software\Rates Analysis\Resources';
inputArgs.Folders.marketPriceInputFilePath  = 'G:\My Drive\Kaparra Software\UNSWLecture\PriceReturnData';

inputArgs.RateFile.Prefix = "EIOPA_RFR_";
inputArgs.RateFile.Suffix = "_Term_Structures";
inputArgs.RateFile.Extension = ".xlsx";
inputArgs.RateFile.rateScenarios = "_RFR_spot_no_VA";
inputArgs.RateFile.inputFileFrequency = utilities.FrequencyType.Monthly;

inputArgs.person.gender = utilities.GenderType.Female;
inputArgs.person.startAge = 65;
inputArgs.person.country = "AU";
inputArgs.person.initialValue = 1600000;
inputArgs.person.ownerPayment =100000;
inputArgs.person.deferment = 0;
inputArgs.person.contribution = 0000;
inputArgs.person.contributionFrequency = utilities.FrequencyType.Quarterly;
inputArgs.person.ownerPaymentFrequency = utilities.FrequencyType.Annually;
inputArgs.person.defaultPersonLifeTable = "Null";
inputArgs.person.inflationRateAssumption = 0.03;


inputArgs.hedgeannuity.maxNumPayments = 45; %in years
inputArgs.hedgeannuity.inflationRateAssumption = 0.03;
inputArgs.hedgeannuity.guaranteedPaymentFrequency = utilities.FrequencyType.Annually;
inputArgs.hedgeannuity.defaultAnnuityMortalityTable = "Null";
inputArgs.hedgeannuity.valuationFrequency= utilities.FrequencyType.Monthly;
inputArgs.hedgeannuity.guaranteedPayment = 65000;

inputArgs.portfolioParameters.benchmarkPortfolioTickers = {'ASX200_Price','SP500_Price'};
inputArgs.portfolioParameters.benchmarkPortfolioWeights = [0.4,0.6];
inputArgs.portfolioParameters.benchmarkPortfolioWeightsTable = array2table(inputArgs.portfolioParameters.benchmarkPortfolioWeights,'VariableNames',inputArgs.portfolioParameters.benchmarkPortfolioTickers);
inputArgs.portfolioParameters.portfolioTickerRiskPremium = [0.04,0.04];
inputArgs.portfolioParameters.portfolioAvgRiskPremium = inputArgs.portfolioParameters.benchmarkPortfolioWeights*inputArgs.portfolioParameters.portfolioTickerRiskPremium';

inputArgs.instruments.marketIndexAcctParameters.name = 'testAccount';
inputArgs.instruments.marketIndexAcctParameters.tickers = {'ASX200_Price','SP500_Price'};
inputArgs.instruments.marketIndexAcctParameters.targetWeights=[0.4,0.6];
inputArgs.instruments.marketIndexAcctParameters.accountCurrency = inputArgs.person.country;
inputArgs.instruments.marketIndexAcctParameters.accumulationIndicator= 'accumulation';
inputArgs.instruments.marketIndexAcctParameters.exposureLimits = 0.05;
inputArgs.instruments.marketIndexAcctParameters.allowableIndexes = {'ASX200_Price','SP500_Price'};
inputArgs.instruments.marketIndexAcctParameters.benchmarkWeights = array2table(inputArgs.instruments.marketIndexAcctParameters.targetWeights,'VariableNames',{'ASX200_Price','SP500_Price'});

inputArgs.marketData.tickerfilter = '_Price';
inputArgs.marketData.riskPremiums = [0.04 0.04,0.04 0.04,0.04 0.04];
    
    
end