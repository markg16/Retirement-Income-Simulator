classdef MainSimulationScenarioBuilder < scenarios.ScenarioBuilder
    properties (Access = private)
        ScenarioBuilder;
        Parameters;
    end
    methods
        % Constructor

        function obj = MainSimulationScenarioBuilder(parameters)
            % Initialize any properties or settings here if needed
            % ...

            obj.Parameters = parameters;
            %obj.ScenarioBuilder = Scenario();
        end
        function person = buildPerson(obj, personParameters)
            % Create Person with annuity (consider adding buildAnnuity())
            person = Person('Gender', personParameters.gender, ...
                'Age', personParameters.startAge, ...
                'Country', personParameters.country, ...
                'InitialValue', personParameters.initialValue, ...
                'TargetIncome', personParameters.ownerPayment, ...
                'IncomeDeferement', personParameters.deferment, ...
                'Contribution', personParameters.contribution, ...
                'ContributionPeriod',personParameters.contributionPeriod,...
                'ContributionFrequency', personParameters.contributionFrequency, ...
                'CashflowStrategy', personParameters.ownerContributionCashflowStrategy);
            
        end
        function person = addAnnuity(obj,person, annuityParameters)

            if ~isempty(annuityParameters)
                
                annuity = SingleLifeTimeAnnuityFactory().createInstrument( ...
                    person, ...  % Pass the person object
                    annuityParameters.ownerPayment, ...
                    annuityParameters.inflationRateAssumption, ...
                    annuityParameters.startDate, ...
                    annuityParameters.ownerPaymentDeferment, ...
                    annuityParameters.maxNumPayments, ...
                    annuityParameters.ownerPaymentFrequency); %Annuity class calculates payments dates based on the annuity specs and start date.
                annuity.AnnuityCashflowStrategy = annuityParameters.ownerPaymentCashflowStrategy;
                person.Annuity = annuity;

            end
        end


        function portfolio = buildPortfolio(obj, portfolioParameters)
            % Create AssetPortfolio (consdier adding buildMarketIndexAcct())

            if isfield(portfolioParameters,'marketIndexAcctParameters')
                marketIndexAcctParameters = portfolioParameters.marketIndexAcctParameters;
                marketIndexAcctStrategyTypes =marketIndexAcctParameters.marketIndexAcctStrategyTypes;
                marketIndexAcctTradingStrategy = TradingStrategyFactory.createTradingStrategy(marketIndexAcctStrategyTypes, ...
                    'MarketIndexAcctParameters',marketIndexAcctParameters);
                marketIndexAcctParameters.TradingStrategy = marketIndexAcctTradingStrategy;
            else
                marketIndexAcctParameters = struct();
            end

            portfolio = AssetPortfolioFactory.createPortfolio( ...
                portfolioParameters.tradingStrategyTypes, ...
                portfolioParameters.startDate, ...
                'PortfolioCountry', portfolioParameters.country, ...
                'InitialValue', portfolioParameters.initialValue, ...
                'CashflowsInputData', portfolioParameters.cashflowsInputData, ...
                'TargetPortfolioWeights', portfolioParameters.benchmarkPortfolioWeightsTable, ...               
                'MarketIndexAcctParameters', marketIndexAcctParameters, ...
                'AllowablePortfolioHoldings', portfolioParameters.allowablePortfolioHoldings);
        end

        % add hedgeAnnuitgyParameters to the createPortfolio signature

        %'BenchmarkReturns', portfolioParameters.BenchmarkReturns, ...

        function scenario = buildScenario(obj, person, scenarioParameters)
            % Initialize scenario (as in your original code)

            rateScenarios = scenarioParameters.rateScenarios;
            startDateScenario = scenarioParameters.startDateScenario;
            endDateScenario = scenarioParameters.endDateScenario;
            referenceTime = scenarioParameters.referenceTime;
            inflationRateAssumption =scenarioParameters.inflationAssumptions;

            assetReturnFrequency = scenarioParameters.AssetReturnFrequency;
            annuityValuationFrequency = scenarioParameters.annuityValuationFrequency;
            maxNumPayments =person.Annuity.MaxNumPayments;


            guaranteedPaymentFrequency =person.Annuity.PaymentFrequency;
            ownerPaymentFrequency = person.Annuity.PaymentFrequency;
            ownerPaymentPlanningHorizon = startDateScenario + years(person.Annuity.MaxNumPayments);
            ownerPaymentStartDate =person.Annuity.StartDate;
            deferment = person.IncomeDeferement;
            contributionPeriod = person.ContributionPeriod;
            contributionFrequency = person.ContributionFrequency;
            annuityPaymentStartDate = startDateScenario+years(deferment);  % this should be the hedge annuity payment start


            annuityStartDate = person.Annuity.StartDate;


            disp("generating cashflow dates")
            % These variables define the start and end of the period over which asset returns are calculated

            [assetReturnStartDates,assetReturnEndDates] = utilities.generateDateArrays(startDateScenario, endDateScenario, assetReturnFrequency,referenceTime);

            % use annuityPaymentEndDates for annuities assume payments at end of period
            % and go for max num of payments so can be used in valuation
            dateLastAnnuityPayment = startDateScenario + calyears(maxNumPayments);

            annuityValuationDates = utilities.generateDateArrays(startDateScenario, endDateScenario, annuityValuationFrequency,referenceTime);

            [annuityPaymentStartDates,paymentDates.annuityPaymentEndDates] = utilities.generateDateArrays(annuityPaymentStartDate, dateLastAnnuityPayment, guaranteedPaymentFrequency,referenceTime );

            % use ownerPaymentEndDates assume  payments at end of each period , only
            % interested in payments to end of scenario period
            [ownerPaymentStartDates,paymentDates.ownerPaymentEndDates] = utilities.generateDateArrays(ownerPaymentStartDate, ownerPaymentPlanningHorizon, ownerPaymentFrequency,referenceTime);
            % use contributionEndDates for  contributions at end of each period up to
            % end of deferment
            [contributionStartDates,paymentDates.contributionEndDates] = utilities.generateDateArrays(startDateScenario, startDateScenario+ years(contributionPeriod), contributionFrequency,referenceTime);




            scenario = scenarios.Scenario(person,rateScenarios,'startDate',startDateScenario, ...
                'endDate',endDateScenario,'assetReturnStartDates',assetReturnStartDates,'assetReturnEndDates',assetReturnEndDates, ...
                'assetReturnFrequency',assetReturnFrequency,'paymentDates',paymentDates, ...
                'annuityStartDate', annuityStartDate,'annuityValuationDates',annuityValuationDates, ...
                'scenarioInflationAssumptions' ,inflationRateAssumption);

            riskPremiums = scenarioParameters.RiskPremiums;
            tickers  = scenarioParameters.RiskPremiumTickers ;
            scenario = scenarios.InitialiseScenarioWorkflows.initialiseRiskPremiumAssumptionsTable(scenario,riskPremiums,tickers);


            % set up and store the risk premium calculator which converts the
            % risk premium assumption table to structures that can be used in the
            % simulation

            % Create the base risk premium calculator
            baseRiskPremiumCalculator = marketdatasimulationclasses.DefaultRiskPremiumCalculator(scenario.RiskPremiumAssumptions);

            % Add asset-class-specific adjustments
            assetClassMap = containers.Map(); % Populate with your asset class mappings
            scenario.RiskPremiumCalculator = marketdatasimulationclasses.AssetClassSpecificRiskPremiumDecorator(baseRiskPremiumCalculator, assetClassMap);


            %     scenario = scenarios.InitialiseScenarioWorkflows.initialiseAScenario(person, ...
            %         scenarioParameters.rateScenarios, ...
            %         scenarioParameters.startDateScenario, ...
            %         scenarioParameters.endDateScenario, ...
            %         scenarioParameters.AssetReturnFrequency, ...
            %         scenarioParameters.RiskPremiums, ...
            %         scenarioParameters.RiskPremiumTickers);
            % end
        end
    end
end
