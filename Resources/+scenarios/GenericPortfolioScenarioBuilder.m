classdef GenericPortfolioScenarioBuilder < scenarios.ScenarioBuilder 
    properties (Access = private)
        ScenarioBuilder;
        Parameters;
    end
    
    methods
        function obj = GenericPortfolioScenarioBuilder(parameters)
            % Initialize any properties or settings here if needed
            % ...

            obj.Parameters = parameters;
            %obj.ScenarioBuilder = Scenario();
        end

        function person = buildPerson(obj, personParameters, baseLifeTable)
            % Create Person with no annuity 
           person = Person(); % Create a basic Person object with only default fields and no annuity
        end
        function person = addAnnuity(obj, person, annuityParameters)
            if nargin == 3
             annuityParameters = []  ;
            end
            % Create Person with no annuity 
           person = person; % do nothing for this portfolio
        end

        function portfolio = buildPortfolio(obj, portfolioParameters)
            % Create AssetPortfolio 
          
            portfolio = AssetPortfolioFactory.createPortfolio( ...
                portfolioParameters.tradingStrategyTypes, ...
                portfolioParameters.startDate, ...
                'PortfolioCountry', portfolioParameters.country, ...                
                'TargetPortfolioWeights', portfolioParameters.benchmarkPortfolioWeightsTable, ...             
                'AllowablePortfolioHoldings', portfolioParameters.allowablePortfolioHoldings);
        end
       

        function scenario = buildScenario(obj, person, scenarioParameters)
            % Initialize scenario 
            
            rateScenarios = scenarioParameters.rateScenarios;
            startDateScenario = scenarioParameters.startDateScenario;
            endDateScenario = scenarioParameters.endDateScenario;
            referenceTime = scenarioParameters.referenceTime;
                        assetReturnFrequency = scenarioParameters.AssetReturnFrequency;                   
            
            disp("generating cashflow dates")
            % These variables define the start and end of the period over which asset returns are calculated

            [assetReturnStartDates,assetReturnEndDates] = utilities.generateDateArrays(startDateScenario, endDateScenario, assetReturnFrequency,referenceTime);

            % use annuityPaymentEndDates for annuities assume payments at end of period
            % and go for max num of payments so can be used in valuation
            scenario = scenarios.Scenario(person,rateScenarios,'startDate',startDateScenario, ...
                'endDate',endDateScenario,'assetReturnStartDates',assetReturnStartDates,'assetReturnEndDates',assetReturnEndDates, ...
                'assetReturnFrequency',assetReturnFrequency);

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

        end
    end
end
