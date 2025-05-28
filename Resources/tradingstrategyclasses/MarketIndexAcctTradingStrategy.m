classdef MarketIndexAcctTradingStrategy<TradingStrategy
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        AllowableIndexes
        ExposureLimits
        TargetWeights;
      
    end

    methods (Static)

        function obj = MarketIndexAcctTradingStrategy(marketIndexAcctParameters)
            % Constructor for MarketIndexAcctTradingStrategy
            arguments
                marketIndexAcctParameters
                % lookbackPeriod (1, 1) {mustBeInteger, mustBePositive} = 20; % Example default value
                % momentumIndicators (1, :) cell = {}; % Example default value
            end
            obj.ExposureLimits = marketIndexAcctParameters.exposureLimits;
            obj.AllowableIndexes = marketIndexAcctParameters.allowableIndexes;
            obj.TargetWeights = marketIndexAcctParameters.targetWeights;
            obj.BenchmarkWeights = marketIndexAcctParameters.benchmarkWeights;
            % obj.LookbackPeriod = lookbackPeriod;
            % obj.MomentumIndicators = momentumIndicators;

        end
        function instructions = determineTrade(portfolio,person,tradeDate, portfolioMarketData, scenarioData)
            instructions.Quantities = 0;
            instructions.Tickers = portfolioMarketData.Tickers;
        end
        function marketIndexAcct = executeTrade(marketIndexAcct,instructions)

            marketIndexAcct.Tickers = marketIndexAcct.Tickers;
            marketIndexAcct.TickerQuantities = marketIndexAcct.TickerQuantities - instructions.Quantities;

        end
    end
end