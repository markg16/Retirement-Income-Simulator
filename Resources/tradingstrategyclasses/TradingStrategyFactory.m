classdef TradingStrategyFactory
    %TRADINGSTRATEGYFACTORY Summary of this class goes here
    %   Detailed explanation goes here

    methods (Static)
        function tradingStrategy = createTradingStrategy(strategyTypes, varargin)
            %CREATETRADINGSTRATEGY Create a TradingStrategy object based on the strategyType.
            p = inputParser;
            
            addParameter(p, 'TargetPortfolioWeights', table.empty, @istable); % Provide default value
            addParameter(p, 'MarketIndexAcctParameters', struct.empty, @isstruct); % Provide default value
            addParameter(p, 'AnnuityType', AnnuityType.FixedAnnuity, @(x) utilities.ValidationUtils.validateWithParser(@utilities.ValidationUtils.validateAnnuityType,x,p))
            % addParameter(p, 'AnnuityType', AnnuityType.FixedAnnuity , @(x) isa(x,AnnuityType));
            parse(p, varargin{:});
            numTradingStrategyTypes =length(strategyTypes);

            tradingStrategy = cell(1,numTradingStrategyTypes);
            for i = 1 : numTradingStrategyTypes
                strategyType = strategyTypes{i};
                switch lower(strategyType) % Case-insensitive comparison
                    case TradingStrategyType.BuyAndHoldAnnuity
                        tradingStrategy{i} = BuyAndHoldAnnuity(p.Results.TargetPortfolioWeights,p.Results.AnnuityType);
                    case TradingStrategyType.BuyAndHoldAnnuityAndMarketIndexAcct
                        tradingStrategy{i} = BuyAndHoldAnnuityAndMarketIndexAcct(p.Results.TargetPortfolioWeights,p.Results.MarketIndexAcctParameters);
                    case TradingStrategyType.BuyAndHoldReferencePortfolio
                        tradingStrategy{i} = BuyAndHoldReferencePortfolio(p.Results.TargetPortfolioWeights);
                    case TradingStrategyType.MarketIndexAcctTradingStrategy
                        tradingStrategy{i} = MarketIndexAcctTradingStrategy(p.Results.MarketIndexAcctParameters);
                    case TradingStrategyType.BuyAndHoldAMarketIndexAcct 
                        tradingStrategy{i} = BuyAndHoldAMarketIndexAcct(p.Results.TargetPortfolioWeights,p.Results.MarketIndexAcctParameters);
                    otherwise
                        error('Invalid trading strategy type: %s', strategyType);
                end
                 tradingStrategy{i}.StrategyType = strategyType; % Assign the StrategyType here 
        
            end
        end
    end
end

