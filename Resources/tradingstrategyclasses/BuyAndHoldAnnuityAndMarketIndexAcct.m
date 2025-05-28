classdef BuyAndHoldAnnuityAndMarketIndexAcct < BuyAndHoldAnnuity
    % concrete trading strategy class
    % ... (properties for the strategy exposure limits, lookback period, momentum indicators, etc.)
    
    properties
        MarketIndexAllocation
        MarketIndexAcctParameters
    end
    

    methods(Static)
        
        function obj = BuyAndHoldAnnuityAndMarketIndexAcct(benchmarkWeights,marketIndexAcctParameters)
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
            obj@BuyAndHoldAnnuity(benchmarkWeights);
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

           portfolioAnnuity =[];
           annuityPurchasePrice = 0;

            country = portfolio.PortfolioCountry;% as this is the portfolio trading stratgey do we need person country or portfolio country. Will need both for a life annuity.
            portfolioMarketData = portfolio.PortfolioMarketData; %scenarioData.ScenarioMarketData;
            if ~isprop(portfolioMarketData, 'RateCurvesCollection')
                error('portfolioMarketData must contain "RateCurvesCollection"  fields to determine trade.');
            end

            % inflate the initial owner payment. SHould be able to get this
            % from the person object allready. COME BACK AND SORT THIS.
            % This variable is used to determine the marketIndexAcct
            % withdrawals.
            initialPortfolioPayment = portfolio.CashflowsInputData.PortfolioPayment;
            inflationRate = scenarioData.getInflationAssumption();
            years = tradeDate.Year- scenarioData.ScenarioStartDate.Year;
            portfolioPayment = utilities.CashFlowUtils.adjustForInflation(initialPortfolioPayment, inflationRate, years);

            % if isempty(portfolio.PortfolioHoldings)  % only create instrument on initial trade for the portfolio
            %% if portfolio.PortfolioHoldings contains annuity skip creation of annuity


            %annuityTradingStrategy = BuyAndHoldAnnuity()
            %[portfolioAnnuity, purchasePrice] = BuyAndHoldAnnuity(determineTrade(portfolio,person,tradeDate, portfolioMarketData,scenarioData)


            portfolioContainsAnnuity = any(cellfun(@(x) isa(x, 'Annuity'), portfolio.PortfolioHoldings));
            portfolioContainsMarketIndxAcct = any(cellfun(@(x) isa(x, 'MarketIndexAccount'), portfolio.PortfolioHoldings));
            currentPortfolioValue = portfolio.calculatePortfolioValue(tradeDate,portfolioMarketData,scenarioData);
            if portfolioContainsAnnuity
                disp('portfolio.PortfolioHoldings contains an Annuity object so no trade recommendation.');
                [existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument('SingleLifeTimeAnnuity');
            else
                annuityFound = false;
                % Get the guaranteed payment ,increase rate and  frequency from the persons

                
                guaranteedPayment = portfolio.CashflowsInputData.GuaranteedPayment;
                guaranteedPaymentFrequency = portfolio.CashflowsInputData.GuaranteedPaymentFrequency;
                %baseLifeTableFolder ="blank";   % TODO create a annuity type enumeration  then decide on annuity typebased on scenario and trading stratgey eg if buy longevity then select lifetime annuity.
                annuityIncomeGtdIncrease= portfolio.CashflowsInputData.GuaranteedPaymentIncreaseRate; % use the portfolio cashflows definition .
                purchaseDate = tradeDate;
                deferment = portfolio.CashflowsInputData.GuaranteedIncomeDeferement;
                maxPayments= portfolio.CashflowsInputData.GuaranteedIncomeMaxNumPmts;

                annuityPaymentDates = scenarioData.PaymentDates.annuityPaymentEndDates;

                % get the interest rate curve scenario eg base, up or down from
                % the scenario definition
                rateScenario = scenarioData.getRateScenarios();

                % Extract rate curve and current date
                % tradeDate.TimeZone = '';
                rateCurve = portfolioMarketData.getRateCurveForScenario( tradeDate, country, rateScenario);

                % Create the FixedAnnuity object

                %annuityFactory = FixedAnnuityFactory();
                annuityFactory = SingleLifeTimeAnnuityFactory();

                tempPortfolioAnnuity = annuityFactory.createInstrument(person, guaranteedPayment,annuityIncomeGtdIncrease, purchaseDate, deferment, maxPayments, guaranteedPaymentFrequency,annuityPaymentDates);

                % Calculate purchase price and assign to this annuity Purchase
                % Price property
                tempPortfolioAnnuity.PurchasePrice = tempPortfolioAnnuity.getCurrentValue(purchaseDate,portfolioMarketData,scenarioData);
                % check encapsulated calcs are correct could delete
                % annuityPP2 = annuity.present_value(baseLifeTableFolder,rateCurve,inflationRateAssumption, purchaseDate);

                %check purchase price is less than available funds if not reduce income
                %guarantee update portfolioAnnuity and purchase price then recheck

                portfolio = portfolio.addInstrument(tempPortfolioAnnuity);
               
                annuityPurchasePrice = tempPortfolioAnnuity.PurchasePrice;
                %% prepare trade instructions for annuity purchase
                instrumentInstructions.annuityInstruction.annuity  = tempPortfolioAnnuity;
                instrumentInstructions.annuityInstruction.purchasePrice = annuityPurchasePrice;
                instrumentInstructions.annuityInstruction.tradeDate = tradeDate;

                
            end


            %determine if the marketIndexAccount needs to be rebalanced and prepare
            %trade instruction

            if portfolioContainsMarketIndxAcct
                disp('portfolio.PortfolioHoldings already contains a MarketIndex Acct object.');

                [MarketIndexAcct,marketIndexAcctIndex,marketIndexAcctFound] = portfolio.getInstrument('MarketIndexAccount');
            else %create a marketindexacct object
                marketIndexAcctFound = false;
                marketIndexAcctParameter = portfolio.TradingStrategy.ChildStrategies{1}.MarketIndexAcctParameters;
               % marketIndexAcctParameter= scenarioData.ScenarioMarketSimulationParameters.TradingStrategy.MarketIndexAcctParameters;
                marketIndexAcctParameter.startDate = tradeDate;
                MarketIndexAcct = MarketIndexAccount(marketIndexAcctParameter,portfolioMarketData);
                portfolio = portfolio.addInstrument(MarketIndexAcct);
            end

            if  portfolio.TradingStrategy.ChildStrategies{1}.MarketIndexAllocation == "Remainder"

                
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
                
   
                targetDeposit = currentPortfolioValue - annuityPurchasePrice - currentAnnuityValue - portfolioPayment-currentMarketIndexAcctValue;

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

        end

        function  portfolio = executeTrade(portfolio,instrumentInstructions)
            arguments
                portfolio AssetPortfolio
                instrumentInstructions
            end

            if isfield(instrumentInstructions,'annuityInstruction')
                annuityInstruction = instrumentInstructions.annuityInstruction;
            else
                annuityInstruction = [];
            end
            marketIndexAcctInstruction = instrumentInstructions.marketIndexAcctInstruction;



            % Access bank account
            [bankAccount,bankAccountIndex] = getBankAccount(portfolio);

            if ~isempty(annuityInstruction)
                % Get annuity purchase price
                purchasePrice = annuityInstruction.purchasePrice;
                % Withdraw from bank account
                bankAccount = bankAccount.withdraw(purchasePrice);
                % could put in some code to check if annuity exists and if
                % not then create the annuity
            end

            if ~isempty(marketIndexAcctInstruction)
                marketIndexDeposit = marketIndexAcctInstruction.deposit;
                marketIndexWithdrawal = marketIndexAcctInstruction.withdrawal;
                
                bankAccount = bankAccount.withdraw(marketIndexDeposit);                             
                bankAccount = bankAccount.deposit(marketIndexWithdrawal);

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