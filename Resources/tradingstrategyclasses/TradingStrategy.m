classdef (Abstract) TradingStrategy <handle

    properties
        BenchmarkWeights table
        StrategyType TradingStrategyType 

    end
    methods (Abstract)
        [assets, quantities] = determineTrade(portfolio,person,tradeDate, portfolioMarketData, scenarioData);
         portfolio = executeTrade(portfolio,instrument1,~);
    end
end