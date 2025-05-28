classdef TradingStrategyType
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
       
       BuyAndHoldBankAccount
       BuyAndHoldAnnuity
       BuyAndHoldAMarketIndexAcct
       BuyAndHoldAnnuityAndMarketIndexAcct
       BuyAndHoldReferencePortfolio
       MarketIndexAcctTradingStrategy
    end

    methods(Static)
        function alias = getAlias(tradingStrategyType)
            switch tradingStrategyType
                case TradingStrategyType.BuyAndHoldBankAccount
                    alias = 'BuyAndHoldBankAccount';
                case TradingStrategyType.BuyAndHoldAnnuity
                    alias = 'BuyAndHoldAnnuity';
                case TradingStrategyType.BuyAndHoldAMarketIndexAcct
                    alias = 'BuyAndHoldAMarketIndexAcct';
                case TradingStrategyType.BuyAndHoldAnnuityAndMarketIndexAcct
                    alias = 'BuyAndHoldAnnuityAndMarketIndexAcct';
                case TradingStrategyType.BuyAndHoldReferencePortfolio
                    alias = 'BuyAndHoldReferencePortfolio';
                case TradingStrategyType.MarketIndexAcctTradingStrategy
                    alias = 'MarketIndexAcctTradingStrategy';
                otherwise
                    error('Unsupported trading strategy type');
            end
        end
    end
end