classdef ScenarioSpecificMarketData < marketdata.MarketData
    %UNTITLED5 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        SimulationIdentifier
        ScenarioHistoricalMarketData
        CombinedMarketAndSimulatedData

    end

    methods
        function obj = ScenarioSpecificMarketData(simulationIdentifier,scenario,marketData)
            % extract data between two dates defined for the scenario. 
            % Add scenario as an input
            % historicalScenarioMarketData is allready a marketdata object

            % % Use varargin to handle optional input arguments
            % 
            % % Define default values for optional arguments
            % defaultSimulationIdentifier = '';
            % defaultScenario = scenarios.Scenario(); % Or your default scenario object
            % defaultMarketData = marketdata.MarketData(); % Or your default market data object
            % 
            % % Parse input arguments
            % p = inputParser;
            % addParameter(p, 'SimulationIdentifier', defaultSimulationIdentifier, @ischar);
            % addParameter(p, 'Scenario', defaultScenario, @(x) isa(x, 'scenarios.Scenario'));
            % addParameter(p, 'MarketData', defaultMarketData, @(x) isa(x, 'marketdata.MarketData'));
            % parse(p, varargin{:});

            % % Access parsed values
            % obj.SimulationIdentifier = p.Results.SimulationIdentifier;
            % scenario = p.Results.Scenario;
            % marketData = p.Results.MarketData;
            
            scenarioStartDate = scenario.ScenarioStartDate;
            scenarioEndDate = scenario.ScenarioEndDate;
            scenarioSpecificMarketDataSubSet = marketData.ExtractMarketDataBetweenTwoDates(scenarioStartDate,scenarioEndDate);

            allowablePortfolioHoldings = scenario.Person.AssetPortfolio.AllowablePortfolioHoldings;
            scenarioSpecificMarketDataSubSet = scenarioSpecificMarketDataSubSet.filterMarketPriceIndexes(allowablePortfolioHoldings);
            historicalPriceDataTT = scenarioSpecificMarketDataSubSet.MarketIndexPrices;
            portfolioWeightsTT = scenario.Person.AssetPortfolio.TradingStrategy.BenchmarkWeights;

            
            

            %obj.ScenarioHistoricalMarketData = historicalScenarioMarketData;

             rateCurvesCollection = scenarioSpecificMarketDataSubSet.RateCurvesCollection;
             mapCountryToCurveName = scenarioSpecificMarketDataSubSet.MapCountryToCurveName;
             ratesMetaData = scenarioSpecificMarketDataSubSet.RatesMetaData;
            % 
            % % Call the parent constructor
            obj@marketdata.MarketData(rateCurvesCollection, mapCountryToCurveName, ratesMetaData);

            scenarioSpecificPortfolioBenchmarkReturns =obj.calculateHistoricalPortfolioReturns(historicalPriceDataTT,portfolioWeightsTT);
            scenarioSpecificMarketDataSubSet.AssetReturns = scenarioSpecificPortfolioBenchmarkReturns;
            %scenarioSpecificMarketDataSubSet =scenarioSpecificMarketDataSubSet.calculateHistoricalReferencePortfolioReturns(historicalPriceDataTT,portfolioWeightsTT);
            obj.ScenarioHistoricalMarketData = scenarioSpecificMarketDataSubSet;
            obj.SimulationIdentifier = simulationIdentifier;

            
        end
        
                
        function obj = combineExistingAndSimulatedMarketData(obj,simulatedMarketData,cutoverDate)
            %METHOD1 Summary of this method goes here
            %   INPUTS  
            % existingMarketData  a MarketData object relevant to the
            % scenario
            % simulatedMarketData   a timetable or struct or to be added to
            % be combined with existing MarketData object 
            % Assumes that  simulate data extends the marketData from the
            % cutover date. This may repalce existing data from thta date
            % 
            % Ensure cutoverDate is a datetime object
            if ~isdatetime(cutoverDate)
                cutoverDate = datetime(cutoverDate);
            end

            % Filter historical data up to (and including) the cutover date
            % existingData = existingMarketData(existingMarketData.Time <= cutoverDate, :);
            existingAssetReturnsData = obj.ScenarioHistoricalMarketData.AssetReturns;
            % Filter simulated data starting from the day after the cutover date
            % simulatedData = simulatedMarketData(simulatedMarketData.Time > cutoverDate, :);
            simulatedAssetReturnsData = simulatedMarketData.AssetReturns;
            % Combine the filtered timetables etc 
            obj.AssetReturns = utilities.TimeTableUtilities.combineTimetablesByReplacement(existingAssetReturnsData, simulatedAssetReturnsData);

            existingMarketPricesData = obj.ScenarioHistoricalMarketData.MarketIndexPrices;
            simulatedMarketPricesData = simulatedMarketData.MarketIndexPrices;
            obj.MarketIndexPrices = utilities.TimeTableUtilities.combineTimetablesByReplacement(existingMarketPricesData, simulatedMarketPricesData);

        end

        function [forwardRates,forwardRatesTT] = getScenarioForwardRates(obj,simulationStartDate, forwardRateStartDates,forwardRateEndDates,country, rateScenarios)
            disp('getting scenario forward rate curves')
            simulationStartDate.TimeZone = ''; % matlab Ratecurves do not have a timezone associated with the date
            startDateRatesScenario = simulationStartDate;
            startDateRatesScenario.TimeZone = '';
            
            assetReturnRateCurve = obj.getRateCurveForScenario(simulationStartDate, country, rateScenarios);
            %forwardRateStartDates = obj.scenarioMarketSimulationParameters.AssetReturnStartDates;
            forwardRateStartDates.TimeZone = '';
            %forwardRateEndDates =obj.scenarioMarketSimulationParameters.AssetReturnEndDates;
            forwardRateEndDates.TimeZone = '';
          
           % forwardRates = 'need to build function getScenarioForwardRates';
            [forwardRates,forwardRatesTT] = assetReturnRateCurve.getForwardRates(forwardRateStartDates,forwardRateEndDates);
            forwardRatesTT.Time.TimeZone =  obj.ScenarioHistoricalMarketData.AssetReturns.Time.TimeZone;
        end

        function scenarioSpecificPortfolioBenchmarkReturns = calculateHistoricalPortfolioReturns(obj,historicalPriceDataTT,portfolioWeightsTT)

            % portfolioTargetWeights
            % marketIndexPrices =
          % historicalPriceDataTT = obj.ScenarioHistoricalMarketData.MarketIndexPrices;
           historicalPriceReturnsTT = utilities.InvestmentReturnUtilities.convertPriceDataToReturnsTT(historicalPriceDataTT);
           scenarioSpecificPortfolioBenchmarkReturns = utilities.InvestmentReturnUtilities.calculatePortfolioWtdReturns(historicalPriceReturnsTT,portfolioWeightsTT);
        end
    end
end
