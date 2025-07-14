classdef BrownianMotionScenarioGenerator < marketdatasimulationclasses.EconomicScenarioGenerator
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        SimulationParameters marketdatasimulationclasses.SimulationParameters
    end

    methods (Static)
        function obj = BrownianMotionScenarioGenerator(simulationParameters)
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
            numSimulations = 1; %n = obj.SimulationParameters.numSimulations

            forwardRates= obj.SimulationParameters.ForwardRates;

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
            
            
       
           

            corr_table = readtable("+runtimeclasses\Correlation_Matrix_Sample - Sheet1.csv");
            corr_matrix = corr_table{1:6,["ASX200","SP500","Eurostoxx50","FTSE100","Nikkei","Property"]};
            eigenv = eig(corr_matrix); % add test if all positive
            num_assets = numel(eigenv);
            [V,D] = eig(corr_matrix);
            corr_matrix_sqrt = V*sqrt(D);
            %portfolio_weights = obj.SimulationParameters.TradingStrategy.BenchmarkWeights;  % [0.2 0.2 0.2 0.2 0.1 0.1]';
%TODO make these inputs from the paramter file eg risk premiums
            sigma = 0.15;
            mu = 0.04;

            vol_matrix = sigma*eye(num_assets)*100;
            mu_vector = mu*ones(num_assets,1)*100;
            perPeriodReturns  = obj.VectorGeometricBrownianMotionPerPeriodReturns(num_assets,vol_matrix, mu_vector, corr_matrix_sqrt, assetReturnStartDates, assetReturnEndDates);
            % calculate per period returns for each asset
            %perPeriodReturns = exp(extendedForwardRates + tempRiskPremiums).^(1/assetReturnFrequencyPerYear) - 1;

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

        function [perPeriodReturn, perPeriodReturnTT] = VectorGeometricBrownianMotionPerPeriodReturns(obj,n,vol, mu, corr_matrix_sqrt, assetReturnStartDates, assetReturnEndDates)

            % n = numel(diag(vol));
            %assumes mu and vol are read in as 5 for 5% and 18 for 18%

            % % S(:,1) = S0;
            %S(:,1) = S0*ones(n,1);
            t_points = length(assetReturnEndDates);

            count = 1;
            for t = 1:t_points

                if (count > 1 )
                    time_increment = -hours(assetReturnStartDates(count) - assetReturnEndDates(count))/(24*365); % dt as a fraction of a year in hours
                    drift = (mu/100 - 0.5*diag(vol./100).^2)*time_increment;
                    diffusion = sqrt(time_increment).*diag(vol./100).*corr_matrix_sqrt*randn(n,1);
                    perPeriodReturn(:,count) = exp(  drift + diffusion )-1;
                end
                count = count + 1;
            end
        end
    end
end