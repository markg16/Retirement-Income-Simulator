function [mainScenario, genericScenario] = testScenarioBuilder()

% import input arguments from file

inputArgs = runtimeclasses.initialiseInputArguments();


%set up person parameters

parameters.person = inputArgs.person;
storedMortalityFile = inputArgs.Folders.storedMortalityFile;
baseLifeTable  = utilities.LifeTableUtilities.loadOrCreateBaseTable(storedMortalityFile);
inflationRateAssumption =  inputArgs.person.inflationRateAssumption;
personBaseMortalityTable = baseLifeTable;
annuityBaseMortalityTable = baseLifeTable;

contributionAmount = parameters.person.contribution;
contributionFrequency = parameters.person.contributionFrequency;

parameters.person.ownerContributionCashflowStrategy = CashflowStrategy('AnnualAmount',contributionAmount,'Frequency',contributionFrequency, ...
    'InflationRate', inflationRateAssumption,'BaseLifeTable', personBaseMortalityTable);

ownerPayment = parameters.person.ownerPayment;
annuityStartDate = inputArgs.Dates.startDateScenario;       
ownerPaymentFrequency =parameters.person.ownerPaymentFrequency; 


parameters.annuity.ownerPayment = ownerPayment;
parameters.annuity.inflationRateAssumption=inflationRateAssumption;
parameters.annuity.startDate = annuityStartDate;
parameters.annuity.ownerPaymentDeferment= parameters.person.deferment;
parameters.annuity.maxNumPayments=parameters.person.maxNumPayments;
parameters.annuity.ownerPaymentFrequency= ownerPaymentFrequency;
%parameters.annuityParameters.paymentEndDates

%parameters.person.annuityParams.PaymentEndDates;


parameters.annuity.ownerPaymentCashflowStrategy = CashflowStrategy('AnnualAmount',ownerPayment, ...
    'StartDate',annuityStartDate, ...
    'Frequency',ownerPaymentFrequency, ...
    'InflationRate', inflationRateAssumption, 'BaseLifeTable',annuityBaseMortalityTable);


% set up portfolio parameters
parameters.portfolio = inputArgs.portfolioParameters;

marketIndexAcctParameters = inputArgs.instruments.marketIndexAcctParameters;
marketIndexAcctParameters.marketIndexAcctStrategyTypes = inputArgs.instruments.marketIndexAcctParameters.marketIndexAcctStrategyTypes;
marketIndexAcctTradingStrategy = TradingStrategyFactory.createTradingStrategy(marketIndexAcctParameters.marketIndexAcctStrategyTypes, ...
    'MarketIndexAcctParameters',marketIndexAcctParameters);
marketIndexAcctParameters.TradingStrategy = marketIndexAcctTradingStrategy;
parameters.portfolio.marketIndexAcctParameters = marketIndexAcctParameters;


% Determine planned cashflows for portfolio and the type of hedge annuity purchased
disp("generating portfolio cashflow data")
cashflowsData = utilities.CashFlowUtils.createCashFlowDataStruct(inputArgs);

parameters.portfolio.cashflowsInputData = cashflowsData;
parameters.portfolio.startDate = inputArgs.Dates.startDateScenario;


% set up scenario parameters

parameters.scenario = inputArgs.Dates;
parameters.scenario.AssetReturnFrequency = inputArgs.runtime.assetReturnFrequency;
parameters.scenario.RiskPremiums  = inputArgs.portfolioParameters.portfolioTickerRiskPremium;
parameters.scenario.RiskPremiumTickers = inputArgs.portfolioParameters.benchmarkPortfolioTickers;
parameters.scenario.BaseLifeTable = baseLifeTable;
parameters.scenario.rateScenarios = inputArgs.RateFile.rateScenarios;

parameters.scenario.annuityValuationFrequency = inputArgs.runtime.annuityValuationFrequency;
parameters.scenario.inflationAssumptions = inputArgs.person.inflationRateAssumption;

% build scenario using these parameters

builderObject = scenarios.MainSimulationScenarioBuilder(parameters);
mainScenario = scenarios.InitialiseScenarioWorkflows.initializeScenario(builderObject, parameters);

builderObject = scenarios.GenericPortfolioScenarioBuilder(parameters);
genericScenario = scenarios.InitialiseScenarioWorkflows.initializeScenario(builderObject, parameters);


end