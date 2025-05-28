classdef BuyAndHoldReferencePortfolio < TradingStrategy
    % concrete trading strategy class
    % ... (properties for the strategy exposure limits, lookback period, momentum indicators, etc.)
    
    properties
        ReferencePortfolioWeights
        MarketIndexAcctParameters
    end
    

    methods(Static)
        
        function obj = BuyAndHoldReferencePortfolio(referencePortfolioWeights)
            % Constructor for BuyAndHoldAnnuity
            arguments
                referencePortfolioWeights table
               
                % marketIndexAllocation
                % exposureLimits 
                % lookbackPeriod (1, 1) {mustBeInteger, mustBePositive} = 20; % Example default value
                % momentumIndicators (1, :) cell = {}; % Example default value
            end
            % obj.ExposureLimits = exposureLimits;
            % obj.LookbackPeriod = lookbackPeriod;
            % obj.MomentumIndicators = momentumIndicators;
           
            obj.ReferencePortfolioWeights = referencePortfolioWeights;
            obj.BenchmarkWeights = referencePortfolioWeights;
            
        end
        function [instrumentInstructions,portfolio] = determineTrade(portfolio,person,tradeDate, portfolioMarketData,scenarioData)
            %DETERMINETRADE Determines the annuity trade for a buy-and-hold strategy.
            %
            %   [ANNUITY, PURCHASEPRICE] = DETERMINETRADE(OBJ, PORTFOLIO, MARKETDATA)
            %   calculates the purchase price of an annuity based on the
            %   target income of the person associated with the PORTFOLIO and the
            %   current MARKETDATA (which includes the interest rate curve). It
            %   returns the required ANNUITY object with its calculated PURCHASEPRICE.
            %
            %   Inputs:
            %       OBJ: The BuyAndHoldAnnuity object.
            %       PORTFOLIO: The AssetPortfolio object.
            %       MARKETDATA: A structure containing market data, including the interest
            %                   rate curve (rateCurve) and the current date (currentDate).
            %
            %   Outputs:
            %       ANNUITY: The Annuity object representing the annuity to be purchased.
            %       PURCHASEPRICE: The calculated purchase price of the annuity.

            % Input validation (ensure marketData contains rateCurve and currentDate)
                 
            instructions.Quantities = 0;
            instructions.Tickers = [];

        end

        function  portfolio = executeTrade(portfolio,instrumentInstructions)
            arguments
                portfolio AssetPortfolio
                instrumentInstructions
            end
           

            portfolio.PortfolioHoldings = portfolio.PortfolioHoldings;
        end
    end
end