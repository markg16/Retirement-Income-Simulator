

function inputArgs = initialiseInputArguments()
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here


inputArgs.runtime.displayRateCurveNames = 0;
inputArgs.runtime.defaultCashflows = 0;
inputArgs.runtime.verbose = 1;
inputArgs.runtime.defaultFrequency = utilities.FrequencyType.Annually;
inputArgs.runtime.assetReturnFrequency = utilities.FrequencyType.Weekly;
inputArgs.runtime.annuityValuationFrequency = utilities.FrequencyType.Annually;
inputArgs.runtime.rootPath = 'G:\My Drive\Kaparra Software\Rates Analysis\Resources';
rootPath = inputArgs.runtime.rootPath;
inputArgs.runtime.newPath = utilities.PathManagement.addPaths(rootPath,'archive');
inputArgs.runtime.numericalOutputformat = 'bank';
inputArgs.runtime.floatingPointTolerance = 1e-10;



inputArgs.Dates.startDateRates = datetime('2016-03-31');% earliest date rate input file is available
inputArgs.Dates.endDateRates = datetime('2022-11-30');% latest date rate input file is available
inputArgs.Dates.startDates = datetime('2017-03-31');% scenario projection start date
inputArgs.Dates.endDates = datetime('2047-03-31');% scenario projection end date
inputArgs.Dates.referenceTime = hours(17);
inputArgs.Dates.localTimeZone = 'Australia/Sydney';
inputArgs.Dates.dateTimeFormat = 'dd/MM/uuuu HH:mm:ss';

startDateScenario = inputArgs.Dates.startDates;
startDateScenario.TimeZone = inputArgs.Dates.localTimeZone;
startDateScenario = datetime(startDateScenario,'Format',inputArgs.Dates.dateTimeFormat);
startDateScenario =  startDateScenario+inputArgs.Dates.referenceTime;
inputArgs.Dates.startDateScenario = startDateScenario ;
endDateScenario =inputArgs.Dates.endDates;
endDateScenario.TimeZone = inputArgs.Dates.localTimeZone;
endDateScenario= datetime(endDateScenario,'Format',inputArgs.Dates.dateTimeFormat);
inputArgs.Dates.endDateScenario = endDateScenario+inputArgs.Dates.referenceTime;
inputArgs.Dates.marketSimulationStartDate = inputArgs.Dates.startDateScenario;

inputArgs.Folders.inputFolderRates = 'G:\My Drive\Kaparra Software\RatesDataAquisition\EIOPAData';
inputArgs.Folders.assetReturnsFile = 'G:\My Drive\Kaparra Software\RatesDataAquisition\AssetReturnsData\asset_returns.csv';
inputArgs.Folders.outputFolder = 'G:\My Drive\Kaparra Software\Rates Analysis\Output';
inputArgs.Folders.inputFileNameRates ='EIOPA_RFR_20160131_Term_Structures.xlsx';
inputArgs.Folders.inputFolderMortality = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables';
inputArgs.Folders.storedMortalityFile = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat';
inputArgs.Folders.cacheFolder = 'G:\My Drive\Kaparra Software\Rates Analysis\Resources';
inputArgs.Folders.marketPriceInputFilePath  = 'G:\My Drive\Kaparra Software\UNSWLecture\PriceReturnData';

inputArgs.RateFile.Prefix = "EIOPA_RFR_";
inputArgs.RateFile.Suffix = "_Term_Structures";
inputArgs.RateFile.Extension = ".xlsx";
inputArgs.RateFile.rateScenarios = "_RFR_spot_no_VA";
inputArgs.RateFile.inputFileFrequency = utilities.FrequencyType.Monthly; % EIOPA only produce files monthly except in extraordinary circumstance

inputArgs.RateFile.rateScenarios = "_RFR_spot_no_VA";

inputArgs.person.gender = 'Male';
inputArgs.person.startAge = 65;
inputArgs.person.country = "AU";
inputArgs.person.initialValue = 1600000;

%inputArgs.person.ownerPayment =100000;
%inputArgs.person.deferment = 0;
%inputArgs.person.contribution = 0000;
%inputArgs.person.contributionFrequency ='Quarterly';
%inputArgs.person.ownerPayment =100000;
inputArgs.person.ownerPayment =65000;
inputArgs.person.deferment = 5;
inputArgs.person.contribution = 10000;
inputArgs.person.contributionPeriod = 5;
inputArgs.person.contributionFrequency = utilities.FrequencyType.Monthly;
inputArgs.person.ownerPaymentFrequency = utilities.FrequencyType.Annually;
inputArgs.person.defaultPersonLifeTable = "Null";
inputArgs.person.inflationRateAssumption = 0.03;
inputArgs.person.maxNumPayments = 45; %in years
inputArgs.person.paymentStartDate = startDateScenario;

inputArgs.marketUniverse.benchmarkPortfolioTickers = {'EuroStoxx50_Price','Nikkei225_Price','SP500_Price','ASX200_Price','ASX200REIT_Price','TR10YrGov_Price'};
inputArgs.marketUniverse.benchmarkPortfolioWeights = [0.17,0.17,0.17,0.17,0.15,0.17];
inputArgs.marketUniverse.benchmarkPortfolioWeightsTable = PortfolioWeights(inputArgs.marketUniverse.benchmarkPortfolioTickers,inputArgs.marketUniverse.benchmarkPortfolioWeights);
%inputArgs.marketUniverse.benchmarkPortfolioWeightsTable = array2table(inputArgs.portfolioParameters.benchmarkPortfolioWeights,'VariableNames',inputArgs.portfolioParameters.benchmarkPortfolioTickers);
inputArgs.marketUniverse.riskPremiums = [0.04,0.04,0.04,0.04,0.04,0.02];
inputArgs.marketUniverse.riskPremiumTickers = inputArgs.marketUniverse.benchmarkPortfolioTickers;
inputArgs.marketUniverse.allowablePortfolioHoldings = inputArgs.marketUniverse.benchmarkPortfolioTickers;
inputArgs.marketUniverse.portfolioAvgRiskPremium = inputArgs.marketUniverse.benchmarkPortfolioWeights*inputArgs.marketUniverse.riskPremiums';
inputArgs.marketUniverse.defaultTradingStrategy  = {TradingStrategyType.BuyAndHoldBankAccount};
inputArgs.marketUniverse.tradingStrategyTypes = {TradingStrategyType.BuyAndHoldReferencePortfolio};
inputArgs.marketUniverse.rateScenarios = inputArgs.RateFile.rateScenarios;
inputArgs.marketUniverse.ESGModelType = utilities.EconomicScenarioGeneratorType.Deterministic;

inputArgs.referencePortfolioParameters.benchmarkPortfolioTickers = {'EuroStoxx50_Price','Nikkei225_Price','ASX200_Price','SP500_Price','ASX200REIT_Price','TR10YrGov_Price'};
inputArgs.referencePortfolioParameters.benchmarkPortfolioWeights = [0.0,0.0,0.4,0.6,0.0,0.0];
inputArgs.referencePortfolioParameters.defaultTradingStrategy  = {TradingStrategyType.BuyAndHoldBankAccount};
%inputArgs.referencePortfolioParameters.PortfolioWeights = PortfolioWeights(inputArgs.referencePortfolioParameters.benchmarkPortfolioTickers,inputArgs.referencePortfolioParameters.benchmarkPortfolioWeights);
inputArgs.referencePortfolioParameters.benchmarkPortfolioWeightsTable = PortfolioWeights(inputArgs.referencePortfolioParameters.benchmarkPortfolioTickers,inputArgs.referencePortfolioParameters.benchmarkPortfolioWeights);
inputArgs.referencePortfolioParameters.riskPremiums = inputArgs.marketUniverse.riskPremiums;
inputArgs.referencePortfolioParameters.rateScenarios = inputArgs.RateFile.rateScenarios;
inputArgs.referencePortfolioParameters.riskPremiumTickers = inputArgs.marketUniverse.benchmarkPortfolioTickers;
inputArgs.referencePortfolioParameters.allowablePortfolioHoldings = inputArgs.marketUniverse.benchmarkPortfolioTickers;
inputArgs.referencePortfolioParameters.tradingStrategyTypes = {TradingStrategyType.BuyAndHoldReferencePortfolio};



inputArgs.hedgeAnnuity.guaranteedPayment = 65000;
%inputArgs.hedgeAnnuity.guaranteedPayment = 100000;
inputArgs.hedgeAnnuity.annuityStartDate = inputArgs.person.paymentStartDate;
inputArgs.hedgeAnnuity.maxNumPayments = inputArgs.person.maxNumPayments; %in years
inputArgs.hedgeAnnuity.inflationRateAssumption = 0.00;
inputArgs.hedgeAnnuity.guaranteedPaymentFrequency = utilities.FrequencyType.Annually;
inputArgs.hedgeAnnuity.GuaranteedPaymentIncreaseRate = 0.03;
inputArgs.hedgeAnnuity.GuaranteedIncomeDeferement = 5;
inputArgs.hedgeannuity.defaultAnnuityMortalityTable = "Null";
inputArgs.hedgeannuity.valuationFrequency= inputArgs.runtime.annuityValuationFrequency;
inputArgs.hedgeAnnuity.annuityType = AnnuityType.SingleLifeTimeAnnuity;
%inputArgs.hedgeAnnuity.annuityType = AnnuityType.FixedAnnuity;

inputArgs.portfolioParameters.initialValue = inputArgs.person.initialValue;

inputArgs.portfolioParameters.country = inputArgs.person.country;
inputArgs.portfolioParameters.benchmarkPortfolioTickers = inputArgs.marketUniverse.benchmarkPortfolioTickers;
inputArgs.portfolioParameters.benchmarkPortfolioWeights = [0.4,0.6,0,0,0,0];
inputArgs.portfolioParameters.benchmarkPortfolioWeightsTable = PortfolioWeights(inputArgs.portfolioParameters.benchmarkPortfolioTickers,inputArgs.portfolioParameters.benchmarkPortfolioWeights);
inputArgs.portfolioParameters.allowablePortfolioHoldings = inputArgs.marketUniverse.benchmarkPortfolioTickers;
%inputArgs.portfolioParameters.benchmarkPortfolioWeightsTable = array2table(inputArgs.portfolioParameters.benchmarkPortfolioWeights,'VariableNames',inputArgs.portfolioParameters.benchmarkPortfolioTickers);
inputArgs.portfolioParameters.portfolioTickerRiskPremium = inputArgs.marketUniverse.riskPremiums;
inputArgs.portfolioParameters.portfolioAvgRiskPremium = inputArgs.portfolioParameters.benchmarkPortfolioWeights*inputArgs.portfolioParameters.portfolioTickerRiskPremium';
%inputArgs.portfolioParameters.tradingStrategyTypes = {TradingStrategyType.BuyAndHoldAnnuity} ;
%inputArgs.portfolioParameters.tradingStrategyTypes = {TradingStrategyType.BuyAndHoldAnnuityAndMarketIndexAcct};
inputArgs.portfolioParameters.tradingStrategyTypes = {TradingStrategyType.BuyAndHoldAnnuity,TradingStrategyType.BuyAndHoldAMarketIndexAcct};



inputArgs.instruments.marketIndexAcctParameters.name = 'Multi Asset Account';
inputArgs.instruments.marketIndexAcctParameters.tickers = inputArgs.marketUniverse.benchmarkPortfolioTickers;
inputArgs.instruments.marketIndexAcctParameters.targetWeights=inputArgs.referencePortfolioParameters.benchmarkPortfolioWeights;
inputArgs.instruments.marketIndexAcctParameters.accountCurrency = inputArgs.person.country;
inputArgs.instruments.marketIndexAcctParameters.accumulationIndicator= 'accumulation';
inputArgs.instruments.marketIndexAcctParameters.exposureLimits = 0.05;
inputArgs.instruments.marketIndexAcctParameters.allowableIndexes = inputArgs.marketUniverse.allowablePortfolioHoldings;
inputArgs.instruments.marketIndexAcctParameters.benchmarkWeights = array2table(inputArgs.instruments.marketIndexAcctParameters.targetWeights,'VariableNames',inputArgs.instruments.marketIndexAcctParameters.tickers);
inputArgs.instruments.marketIndexAcctParameters.marketIndexAcctStrategyTypes = {TradingStrategyType.MarketIndexAcctTradingStrategy};




inputArgs.marketData.tickerfilter = '_Price';
inputArgs.marketData.riskPremiums = [0.04 0.04,0.04 0.04,0.04 0.04];
inputArgs.marketData.baseLevelInterestRate = 0.04;


inputArgs.simulations.defaultSimulatorType  = "DeterministicScenarioGenerator";

inputArgs.analysisDefaults.annuityParametersForTable = [3,1];
inputArgs.analysisDefaults.annuityParametersToPlot = [3,1];
end