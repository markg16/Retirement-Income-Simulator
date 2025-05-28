classdef BuyAndHoldAMarketIndexAcct < TradingStrategy
    % concrete trading strategy class
    % ... (properties for the strategy exposure limits, lookback period, momentum indicators, etc.)
    
    properties
        MarketIndexAllocation
        MarketIndexAcctParameters
    end
    

    methods(Static)
        
        function obj = BuyAndHoldAMarketIndexAcct(benchmarkWeights,marketIndexAcctParameters)
            % Constructor for BuyAndHoldAnnuity
            arguments
                benchmarkWeights
                marketIndexAcctParameters
                % marketIndexAllocation
                % exposureLimits 
                % lookbackPeriod (1, 1) {mustBeInteger, mustBePositive} = 20; % Example default value
                % momentumIndicators (1, :) cell = {}; % Example default value
            end
            % obj.ExposureLimits = exposureLimits;
            % obj.LookbackPeriod = lookbackPeriod;
            % obj.MomentumIndicators = momentumIndicators;
           
            obj.MarketIndexAllocation = "Remainder";
            obj.MarketIndexAcctParameters = marketIndexAcctParameters;
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

           

            country = portfolio.PortfolioCountry;% as this is the portfolio trading stratgey do we need person country or portfolio country. Will need both for a life annuity.
            portfolioMarketData = portfolio.PortfolioMarketData; %scenarioData.ScenarioMarketData;
            initialPortfolioPayment = person.Annuity.GuaranteedPayment;
            
            inflationRate = scenarioData.getInflationAssumption();
            years = tradeDate.Year- scenarioData.ScenarioStartDate.Year;
            portfolioPaymentEstimate = utilities.CashFlowUtils.adjustForInflation(initialPortfolioPayment, inflationRate, years);
            
            portfolioContainsAnnuity = any(cellfun(@(x) isa(x, 'Annuity'), portfolio.PortfolioHoldings));
            if portfolioContainsAnnuity
                disp('portfolio.PortfolioHoldings contains an Annuity object so no trade recommendation.');
               [existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument('Annuity');
                %[existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument('SingleLifeTimeAnnuity');
                %[existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument('FixedAnnuity');

            else
                annuityFound = false;

            end

            portfolioContainsMarketIndxAcct = any(cellfun(@(x) isa(x, 'MarketIndexAccount'), portfolio.PortfolioHoldings));
            currentPortfolioValue = portfolio.calculatePortfolioValue(tradeDate,portfolioMarketData,scenarioData);
            tradingStrategy = portfolio.TradingStrategy.getStrategyByType(TradingStrategyType.BuyAndHoldAMarketIndexAcct);
            marketIndexAcctParameter = tradingStrategy.MarketIndexAcctParameters;

            %determine if the marketIndexAccount needs to be rebalanced and prepare
            %trade instruction

            if portfolioContainsMarketIndxAcct
                disp('portfolio.PortfolioHoldings already contains a MarketIndex Acct object.');

                [MarketIndexAcct,marketIndexAcctIndex,marketIndexAcctFound] = portfolio.getInstrument('MarketIndexAccount');
            else %create a marketindexacct object
                marketIndexAcctFound = false;
               
               % marketIndexAcctParameter= scenarioData.ScenarioMarketSimulationParameters.TradingStrategy.MarketIndexAcctParameters;
                marketIndexAcctParameter.startDate = tradeDate;
                MarketIndexAcct = MarketIndexAccount(marketIndexAcctParameter,scenarioData,portfolioMarketData);
                portfolio = portfolio.addInstrument(MarketIndexAcct);
            end

            if  tradingStrategy.MarketIndexAllocation == "Remainder"

                
                %[existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument('FixedAnnuity');
                                
                if annuityFound == true
                    currentAnnuityValue = portfolio.PortfolioHoldings{existingAnnuityIndex}.getCurrentValue(tradeDate,portfolioMarketData,scenarioData);
                else
                    currentAnnuityValue = 0;
                end

                if marketIndexAcctFound == true
                    currentMarketIndexAcctValue = portfolio.PortfolioHoldings{marketIndexAcctIndex}.getCurrentValue(tradeDate,portfolioMarketData,scenarioData);
                else
                    currentMarketIndexAcctValue =0;
                end
                
   
                targetDeposit = currentPortfolioValue - currentAnnuityValue - portfolioPaymentEstimate-currentMarketIndexAcctValue;

                if targetDeposit > 0
                    marketIndexAcctDeposit = targetDeposit;
                    marketIndexAcctWithdrawal =0;
                elseif targetDeposit ==0
                    marketIndexAcctDeposit = 0;
                    marketIndexAcctWithdrawal =0;
                else
                    marketIndexAcctDeposit = 0;
                    marketIndexAcctWithdrawal = -targetDeposit;
                end
            
            end

          
            instrumentInstructions.marketIndexAcctInstruction.account = MarketIndexAcct;
            instrumentInstructions.marketIndexAcctInstruction.deposit = marketIndexAcctDeposit;
            instrumentInstructions.marketIndexAcctInstruction.tradeDate = tradeDate;
            instrumentInstructions.marketIndexAcctInstruction.withdrawal = marketIndexAcctWithdrawal;
            [bankAccount,bankAccountIndex] = getBankAccount(portfolio);
            bankAccount = bankAccount.applyPendingTrade(-marketIndexAcctDeposit+marketIndexAcctWithdrawal);
            portfolio.PortfolioHoldings{bankAccountIndex} = bankAccount;

        end

        function  portfolio = executeTrade(portfolio,instrumentInstructions)
            arguments
                portfolio AssetPortfolio
                instrumentInstructions
            end

            if isfield(instrumentInstructions,'marketIndexAcctInstruction')
                marketIndexAcctInstruction = instrumentInstructions.marketIndexAcctInstruction;
                
            else
                marketIndexAcctInstruction = [];
            end
            
            % Access bank account
            [bankAccount,bankAccountIndex] = getBankAccount(portfolio);

            % if ~isempty(annuityInstruction)
            %     % Get annuity purchase price
            %     purchasePrice = annuityInstruction.purchasePrice;
            %     % Withdraw from bank account
            %     bankAccount = bankAccount.withdraw(purchasePrice);
            %     % could put in some code to check if annuity exists and if
            %     % not then create the annuity
            % end

            if ~isempty(marketIndexAcctInstruction)
                marketIndexDeposit = marketIndexAcctInstruction.deposit;
                marketIndexWithdrawal = marketIndexAcctInstruction.withdrawal;
                
                bankAccount = bankAccount.withdraw(marketIndexDeposit);                             
                bankAccount = bankAccount.deposit(marketIndexWithdrawal);
                %bankAccount = bankAccount.applyPendingTrade(marketIndexAcctDeposit-marketIndexAcctWithdrawal);

                [marketIndexAcct,marketIndexAcctIndex,found] = portfolio.getInstrument('MarketIndexAccount');

                if found == false
                    portfolio = portfolio.addInstrument(marketIndexAcctInstruction.account);
                    [marketIndexAcct,marketIndexAcctIndex,found]= portfolio.getInstrument('MarketIndexAccount');
               
                end
                tradeDate = marketIndexAcctInstruction.tradeDate;
                marketIndexAcct = marketIndexAcct.deposit(marketIndexDeposit,tradeDate);
                marketIndexAcct = marketIndexAcct.withdraw(marketIndexWithdrawal,tradeDate);

            end

            portfolio.PortfolioHoldings{bankAccountIndex} = bankAccount;

            portfolio.PortfolioHoldings{marketIndexAcctIndex} = marketIndexAcct;
        end
    end
end