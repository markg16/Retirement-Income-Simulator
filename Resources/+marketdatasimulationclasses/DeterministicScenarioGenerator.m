classdef DeterministicScenarioGenerator < marketdatasimulationclasses.EconomicScenarioGenerator
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        SimulationParameters marketdatasimulationclasses.SimulationParameters
    end

    methods (Static)
        function obj = DeterministicScenarioGenerator(simulationParameters)
            %UNTITLED3 Construct an instance of this class
            %   Detailed explanation goes here
            
            if nargin ==1 
            obj.SimulationParameters = simulationParameters;
            else

            end
        end
    end

    methods
        function  simulatedMarketData =generateSimulatedScenarioMarketData(obj)

            %simulatedScenarioMarketData = marketdata.MarketData();
            startValues = obj.SimulationParameters.SimulationStartValues;
            simulationTerm = obj.SimulationParameters.SimulationProjectionTerm;


            if utilities.DateUtilities.isCalendarDurationGreaterThanTolerance(simulationTerm)
                simulatedMarketData.AssetReturns = obj.simulateAssetReturns();
                % simulatedMarketIndexPrices= obj.simulateValues(startValues);
                simulatedMarketData.MarketIndexPrices = obj.simulateValues(startValues); % startValues should have headers as tickers
            else

                simulatedMarketData.AssetReturns = [];
                simulatedMarketData.MarketIndexPrices =[];

            end

        end
        
        function futureReturnsTT = simulateFutureReturns(obj)
            % Simulates future returns of each asset in the asset universe.The asset universe is defined by the risk
            % premium table supplied. The number time periods for returns
            % are calculated for is defined by the Simulation Parameters supplied.

            forwardRates=obj.SimulationParameters.ForwardRates;

            inputRiskPremiums =obj.SimulationParameters.RiskPremiums;
            assetReturnStartDates = obj.SimulationParameters.AssetReturnStartDates;
            assetReturnEndDates = obj.SimulationParameters.AssetReturnEndDates;
            assetReturnFrequency = obj.SimulationParameters.AssetReturnFrequency;

            %length(forwardRates);
            tickerNames =  inputRiskPremiums.Properties.VariableNames;
            tempRiskPremiums = table2array(inputRiskPremiums);
            tempRiskPremiums =  tempRiskPremiums';
            numAssets = size(tempRiskPremiums,1);
            extendedForwardRates = repmat(forwardRates,numAssets,1);
            assetReturnFrequencyPerYear = obj.SimulationParameters.AssetReturnFrequencyPerYear;
            
            % calculate per period returns for each asset
            perPeriodReturns = exp(extendedForwardRates + tempRiskPremiums).^(1/assetReturnFrequencyPerYear) - 1;

            % convert to a timetable
            perPeriodReturnsTT = utilities.InvestmentReturnUtilities.createAssetReturnsTimetable(perPeriodReturns, assetReturnStartDates, assetReturnEndDates, assetReturnFrequency,tickerNames);
            futureReturnsTT = perPeriodReturnsTT;

        end
        
        function futureReferencePortfolioReturnsTT = simulateAssetReturns(obj)
            % Simulates future returns from a portfolio of assets based on
            % benchmark weights. The asset universe is defined by the
            % defined by risk premiums info supplied. The number time periods for returns
            % are calculated for is defined by the Simulation Parameters
            % supplied.

            tradingStrategy = obj.SimulationParameters.TradingStrategy;
           
            portfolioWeightsTT = tradingStrategy.BenchmarkWeights;
            
            perPeriodReturnsTT = obj.simulateFutureReturns(); % calculate future returns for assets defined by risk premiums info

            futureReferencePortfolioReturnsTT = utilities.InvestmentReturnUtilities.calculatePortfolioWtdReturns(perPeriodReturnsTT,portfolioWeightsTT);
          

        end
        function futureValuesTT = simulateValues(obj,startValues)
            %METHOD1 Simulates future prices of each asset in the asset universe.The asset universe is defined by the risk
            % premium table supplied. The number time periods for returns are calculated for is defined by the Simulation Parameters supplied.
            %   Detailed explanation goes here
            
            tickers = startValues.Properties.VariableNames;
            startValuesTemp = timetable2table(startValues);
            startValuesTemp = startValuesTemp(:,2:end);
            startValuesTemp = table2array(startValuesTemp);
            perPeriodReturnsTT = obj.simulateFutureReturns();


            perPeriodReturnsTT = perPeriodReturnsTT(:,tickers);
            perPeriodReturns = table2array(perPeriodReturnsTT);
           
            numFuturePeriods = length(obj.SimulationParameters.AssetReturnEndDates);
            
            futureValues = zeros(1,numFuturePeriods);
            
            futureValues = [startValuesTemp ; startValuesTemp.*cumprod(1 + perPeriodReturns)];
           
            % convert to a timetable
            startDate = obj.SimulationParameters.AssetReturnStartDates(1);
            priceDates = [startDate, obj.SimulationParameters.AssetReturnEndDates];
            

            futureValuesTT = array2timetable(futureValues,"RowTimes",priceDates,"VariableNames",tickers);

                      
        end
    end
end