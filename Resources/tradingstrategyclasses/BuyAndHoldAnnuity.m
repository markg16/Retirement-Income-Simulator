classdef BuyAndHoldAnnuity < TradingStrategy
    % concrete trading strategy class
    % ... (properties for the strategy exposure limits, lookback period, momentum indicators, etc.)
    properties
    AnnuityType
    HedgeAnnuityParameters
    end


    methods(Static)
        
        function obj = BuyAndHoldAnnuity(hedgeAnnuityParameters,annuityType)
            % Constructor for BuyAndHoldAnnuity
            arguments
                hedgeAnnuityParameters 
                annuityType AnnuityType
                % exposureLimits 
                % lookbackPeriod (1, 1) {mustBeInteger, mustBePositive} = 20; % Example default value
                % momentumIndicators (1, :) cell = {}; % Example default value
            end
            %obj.BenchmarkWeights = benchmarkWeights;
            obj.AnnuityType = annuityType;
            obj.HedgeAnnuityParameters = hedgeAnnuityParameters;

            % obj.ExposureLimits = exposureLimits;
            % obj.LookbackPeriod = lookbackPeriod;
            % obj.MomentumIndicators = momentumIndicators;
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
            % portfolioAnnuity =[];
            % annuityPurchasePrice = 0;

            country = portfolio.PortfolioCountry;% as this is the portfolio trading stratgey do we need person country or portfolio country. Will need both for a life annuity.
            portfolioMarketData = portfolio.PortfolioMarketData; %scenarioData.ScenarioMarketData;
            if ~isprop(portfolioMarketData, 'RateCurvesCollection')
                error('portfolioMarketData must contain "RateCurvesCollection"  fields to determine trade.');
            end

            % inflate the initial owner payment. SHould be able to get this
            % from the person object allready. COME BACK AND SORT THIS.
            % This variable is used to determine the marketIndexAcct
            % withdrawals.
            annuityStrategy = portfolio.TradingStrategy.getStrategyByType(TradingStrategyType.BuyAndHoldAnnuity);
            annuityType = annuityStrategy.AnnuityType;           
           annuityStartDate = portfolio.CashflowsInputData.HedgeAnnuityStartDate;  % want this to come from the tradingStrategy object properties. 
            %annuityStartDate = annuityStrategy.HedgeAnnuityParameters.annuityStartDate;
            initialPortfolioPayment = portfolio.CashflowsInputData.PortfolioPayment;
            inflationRate = scenarioData.getInflationAssumption();
            yearsToInflate = tradeDate.Year- scenarioData.ScenarioStartDate.Year;
            tradeDateIsLessThanAnnuityStartDate  = tradeDate < annuityStartDate;
            portfolioPayment = utilities.CashFlowUtils.adjustForInflation(initialPortfolioPayment, inflationRate, yearsToInflate);

            % if isempty(portfolio.PortfolioHoldings)  % only create instrument on initial trade for the portfolio


            % if portfolio.PortfolioHoldings contains annuity skip creation of annuity


            %annuityTradingStrategy = BuyAndHoldAnnuity()
            %[portfolioAnnuity, purchasePrice] = BuyAndHoldAnnuity(determineTrade(portfolio,person,tradeDate, portfolioMarketData,scenarioData)


            portfolioContainsAnnuity = any(cellfun(@(x) isa(x, 'Annuity'), portfolio.PortfolioHoldings));
            portfolioContainsMarketIndxAcct = any(cellfun(@(x) isa(x, 'MarketIndexAccount'), portfolio.PortfolioHoldings));
            currentPortfolioValue = portfolio.calculatePortfolioValue(tradeDate,portfolioMarketData,scenarioData);
            if or(portfolioContainsAnnuity,tradeDateIsLessThanAnnuityStartDate)
                disp('portfolio.PortfolioHoldings contains an Annuity object or i snot required todate  so no trade recommendation.');

                %[existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument('FixedAnnuity');
                [existingPortfolioAnnuity,existingAnnuityIndex,annuityFound]= portfolio.getInstrument(AnnuityType.getAlias(annuityType));
                instrumentInstructions.annuityInstruction.annuity  = [];
                instrumentInstructions.annuityInstruction.purchasePrice = [];
                instrumentInstructions.annuityInstruction.tradeDate = tradeDate;
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

                %Handle a date that does not have a curve?
                rateCurve = portfolioMarketData.getRateCurveForScenario( tradeDate, country, rateScenario);

                % Create the FixedAnnuity object

                annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);

                %annuityFactory = FixedAnnuityFactory();
                %annuityFactory = SingleLifeTimeAnnuityFactory();

                tempPortfolioAnnuity = annuityFactory.createInstrument(person, guaranteedPayment,annuityIncomeGtdIncrease, purchaseDate, deferment, maxPayments, guaranteedPaymentFrequency,annuityPaymentDates);

                % Calculate purchase price and assign to this annuity Purchase
                % Price property
                tempPortfolioAnnuity.PurchasePrice = tempPortfolioAnnuity.getCurrentValue(purchaseDate,portfolioMarketData,scenarioData);
                % check encapsulated calcs are correct could delete
                % annuityPP2 = annuity.present_value(baseLifeTableFolder,rateCurve,inflationRateAssumption, purchaseDate);

                %check purchase price is less than available funds if not reduce income
                %guarantee update portfolioAnnuity and purchase price then recheck



                % portfolio = portfolio.addInstrument(tempPortfolioAnnuity);

                annuityPurchasePrice = tempPortfolioAnnuity.PurchasePrice;
                %% prepare trade instructions for annuity purchase
                instrumentInstructions.annuityInstruction.annuity  = tempPortfolioAnnuity;
                instrumentInstructions.annuityInstruction.purchasePrice = annuityPurchasePrice;
                instrumentInstructions.annuityInstruction.tradeDate = tradeDate;

                %include pending trade in bank account
                % Access bank account
                [bankAccount,bankAccountIndex] = getBankAccount(portfolio);
                availableFunds = bankAccount.getCurrentValue();

                if annuityPurchasePrice > availableFunds
                    maxIncomeEstimate =guaranteedPayment*availableFunds/annuityPurchasePrice;

                    fprintf('Insufficient funds to buy the annuity. Reduce guaranteed income or term. Required income: %f',maxIncomeEstimate);
                    userChoice = input('Do you want to (r)educe income/term or (c)ancel? [r/c]: ', 's');

                    if strcmpi(userChoice, 'r')
                        % ... prompt the user for new income/term and recalculate ...
                        disp('code to adjust has not been developed');
                        error('Insufficient funds to buy the annuity. Reduce guaranteed income or term. Required income: %f', maxIncomeEstimate);

                    else
                        %return; % Or handle cancellation
                        error('Insufficient funds to buy the annuity. Reduce guaranteed income or term. Required income: %f', maxIncomeEstimate);
                    end
                else
                    bankAccount = bankAccount.applyPendingTrade(-annuityPurchasePrice);
                    portfolio.PortfolioHoldings{bankAccountIndex} = bankAccount;
                end
               
            end

        end
    
        

        function  portfolioOut = executeTrade(portfolio,instrumentInstructions)
            arguments
                portfolio AssetPortfolio
                instrumentInstructions
            end
            if isfield(instrumentInstructions,'annuityInstruction')
                annuityInstruction = instrumentInstructions.annuityInstruction;

                %marketIndexAcctInstruction = instrumentInstructions.marketIndexAcctInstruction;
                % Access bank account
                [bankAccount,bankAccountIndex] = getBankAccount(portfolio);
                
                if ~isempty(annuityInstruction.annuity)
                portfolioOut = portfolio.addInstrument(annuityInstruction.annuity);
                else
                    portfolioOut = portfolio;
                end


                if ~isempty(annuityInstruction.purchasePrice)
                    % Get annuity purchase price
                    purchasePrice = annuityInstruction.purchasePrice;
                    % Withdraw from bank account
                    bankAccount = bankAccount.withdraw(purchasePrice);
                    %bankAccount =  bankAccount.applyPendingTrade(purchasePrice);
                    % could put in some code to check if annuity exists and if
                    % not then create the annuity
                end
                
                portfolioOut.PortfolioHoldings{bankAccountIndex} = bankAccount;
                %portfolio = portfolio.addInstrument(annuity);

            else
                disp("No annuity transaction at " , annuityInstruction.tradeDate)
                
            end

            
        end
    end
end