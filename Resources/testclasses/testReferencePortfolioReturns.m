classdef testReferencePortfolioReturns < matlab.unittest.TestCase
    
    methods(TestClassSetup)
        % Shared setup for the entire test class
        referencePortfolioTickerRiskPremium = [0.04,0.04];
        referencePortfolioParameters = inputArgs.referencePortfolioParameters;
        referencePortfolioParameters.portfolioTradingStrategyType = 'BuyAndHoldReferencePortfolio';

        referencePortfolioParameters.startDate= startDateScenario;
        referencePortfolioParameters.country = country;
        referencePortfolioParameters.endDate = endDateScenario;
        referencePortfolioParameters.assetReturnFrequency = assetReturnFrequency;
        referencePortfolioParameters.riskPremiums=referencePortfolioTickerRiskPremium;
        referencePortfolioParameters.riskPremiumTickers =referencePortfolioParameters.portfolioTickers;
        referencePortfolioParameters.rateScenarios = rateScenarios;
        referencePortfolioParameters.allowablePortfolioHoldings = referencePortfolioParameters.portfolioTickers;

        referencePortfolioSimulationStartDate = startDateScenario;
        referencePortfolioSimulationStartDate.TimeZone = 'Australia/Sydney';
        startDateRatesScenario = startDateScenario;
        startDateRatesScenario.TimeZone = '';
        referenceReturnRateCurve = marketData.getRateCurveForScenario(startDateRatesScenario, country, rateScenarios);

        %remove timezone from dates when accessing rates data.
        forwardRateStartDates = assetReturnStartDates;
        forwardRateStartDates.TimeZone = '';
        forwardRateEndDates =assetReturnEndDates;
        forwardRateEndDates.TimeZone = '';
        forwardRates = referenceReturnRateCurve.getForwardRates(forwardRateStartDates, forwardRateEndDates);

        %Set up reference portfolio features and calculate expected reference portfolio returns for each future period

        referencePortfolioTickers = {'ASX200_Price','SP500_Price'};
        refencePortfolioWeights = [0.4,0.6];
        benchmarkPortfolioWeightsTable = array2table(refencePortfolioWeights,'VariableNames',referencePortfolioTickers);
        referencePortfolioTickerRiskPremium = [0.04,0.04];
        


    end
    
    methods(TestMethodSetup)
        % Setup for each test
    end
    
    methods(Test)
        % Test methods
        
        function unimplementedTest(testCase)
            referencePortfolioAvgRiskPremium = refencePortfolioWeights*referencePortfolioTickerRiskPremium';

        assetReturnFrequencyPerYear = utilities.DateUtilities.getFrequencyPerYear(assetReturnFrequency);
        benchmarkAssetReturns = exp(forwardRates+referencePortfolioAvgRiskPremium).^(1/assetReturnFrequencyPerYear) - 1 ; % ratecurve obj defaults to continuous compounding
        referencePortfolioAssetReturnsTimetable = utilities.InvestmentReturnUtilities.createAssetReturnsTimetable(benchmarkAssetReturns, assetReturnStartDates, assetReturnEndDates, assetReturnFrequency,"Benchmark_Return");

            referencePortfolioReturnsTT = InitialiseScenarioWorkflows.simulateReferencePortfolioReturns(marketData,referencePortfolioParameters,referencePortfolioSimulationStartDate);
            
            
            assert(referencePortfolioReturnsTT == referencePortfolioAssetReturnsTimetable)
            
            testCase.verifyFail("Unimplemented test");
        end
    end
    
end