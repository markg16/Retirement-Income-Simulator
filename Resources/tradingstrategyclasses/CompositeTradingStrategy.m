classdef CompositeTradingStrategy < handle & TradingStrategy
    % CompositeStrategy is a container for multiple trading strategies.
    
    properties
        ChildStrategies
    end
    
    methods
        function obj = CompositeTradingStrategy(childStrategies,compositeBenchmarkWeights)
            % CompositeStrategy creates a new CompositeStrategy object.
            obj.ChildStrategies = childStrategies;
            obj.BenchmarkWeights = compositeBenchmarkWeights;
        end
        
        function [instrumentInstructions, portfolio] = determineTrade(obj, portfolio, person, tradeDate, portfolioMarketData, scenarioData)
            % getTradeRecommendations returns the trade recommendations from all child strategies.
            
            for i = 1:length(obj.ChildStrategies)
                childStrategy = obj.ChildStrategies{i};
                % Get instructions and potentially updated portfolio from the child strategy
                [childInstructions, portfolio] = childStrategy.determineTrade(portfolio, person, tradeDate, portfolioMarketData, scenarioData); 

                % Append to the struct (similar to previous example)
                if ~isempty(fieldnames(childInstructions))
                    fieldName = sprintf('Strategy%d', i);
                    instrumentInstructions.(fieldName) = childInstructions;
                end
            end
        end
        
        function portfolio = executeTrade(obj, portfolio, instrumentInstructions) 
            % executeTrades executes the given trade recommendations on all child strategies.
            for i = 1:length(obj.ChildStrategies)
                childStrategy = obj.ChildStrategies{i};
                fieldName = sprintf('Strategy%d', i);

                % Check if instructions exist for the current child strategy
                if isfield(instrumentInstructions, fieldName)
                    childInstructions = instrumentInstructions.(fieldName);
                    portfolio = childStrategy.executeTrade(portfolio, childInstructions); 
                end
            end
        end
        function tradingStrategy = getStrategyByType(obj, strategyType)
            %GETSTRATEGYBYTYPE Returns the child strategy that matches the specified TradingStrategyType enum.

            tradingStrategy = []; % Initialize to empty in case the strategy is not found

            for i = 1:length(obj.ChildStrategies)
                childStrategy = obj.ChildStrategies{i};

                % Determine the TradingStrategyType of the child strategy
                childStrategyType = childStrategy.StrategyType; % You'll need to implement this function

                if childStrategyType == strategyType
                    tradingStrategy = childStrategy;
                    break; 
                end
            end
        end
    end
end