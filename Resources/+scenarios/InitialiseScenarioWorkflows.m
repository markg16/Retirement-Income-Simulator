classdef InitialiseScenarioWorkflows
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
  

    methods (Static)
        function scenario = initializeScenario(scenarioBuilder, parameters)
            % Initialize scenario using the provided builder

            
            if isfield(parameters,'person')
                person = scenarioBuilder.buildPerson(parameters.person);
            else
                person = Person();
            end
            if isfield(parameters,'annuity')
                person = scenarioBuilder.addAnnuity(person,parameters.annuity);
            end

            if isfield (parameters,'portfolio')
                portfolio = scenarioBuilder.buildPortfolio(parameters.portfolio);
            else
                portfolio = Portfolio(TradingStrategyType.BuyAndHoldReferencePortfolio,parameters.scenario.startDate);
            end
            person.AssetPortfolio = portfolio;

            scenario = scenarioBuilder.buildScenario(person, parameters.scenario);
        end
        
        
        function scenarioOutput = initialiseScenarioForReferencePortfolio(referencePortfolioParameters,varargin)
             % Use inputParser to handle optional arguments
            
             
            p = inputParser;
            
            addRequired(p, 'referencePortfolioParameters');
            %addRequired(p, 'scenario',@(x) isa(x, 'scenarios.Scenario'));
            %addRequired(p, 'marketData', @(x) isa(x, 'marketdata.MarketData'));
           
            addParameter(p, 'simulationStartDate',datetime('now'), @isdatetime);
            
            parse(p, referencePortfolioParameters,varargin{:});
          

            portfolioTradingStrategyType = referencePortfolioParameters.tradingStrategyTypes;
            
            referencePortfolioWeights = referencePortfolioParameters.benchmarkPortfolioWeightsTable;
            portfolioStartDate = referencePortfolioParameters.startDate;
            country = referencePortfolioParameters.country;
            portfolioEndDate =referencePortfolioParameters.endDate;
            assetReturnFrequency = referencePortfolioParameters.assetReturnFrequency;
            
            riskPremiums = referencePortfolioParameters.riskPremiums;
            riskPremiumTickers= referencePortfolioParameters.riskPremiumTickers;
            rateScenarios = referencePortfolioParameters.rateScenarios;
            allowablePortfolioHoldings = referencePortfolioParameters.allowablePortfolioHoldings;

            % % test = marketdatasimulationclasses.SimulationParameters(calyears(1),table.empty)

            tempPerson = Person();
            tempReferencePortfolio = AssetPortfolioFactory.createPortfolio(portfolioTradingStrategyType,portfolioStartDate,...
                'PortfolioCountry', country, ...            
                'TargetPortfolioWeights', referencePortfolioWeights, ...
                'AllowablePortfolioHoldings',allowablePortfolioHoldings );
            tempPerson.AssetPortfolio = tempReferencePortfolio;                 
            tempScenario = scenarios.InitialiseScenarioWorkflows.initialiseAScenario(tempPerson,rateScenarios,portfolioStartDate, portfolioEndDate, assetReturnFrequency,riskPremiums,riskPremiumTickers);
            
            scenarioOutput = tempScenario;

        end

        

        function scenario = simulateScenarioMarketData(inputScenario,marketData,varargin)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here
            % Get all MarketIndex Names from market index prices data
            % tickers= marketData.MarketIndexPrices.Properties.VariableNames;

            p = inputParser;
            
            defaultESGModelType = utilities.EconomicScenarioGeneratorType.Deterministic;
            defaultSimulationStartTime = utilities.DateUtilities.setDefaultSimulationStartDate();
            addRequired(p, 'inputScenario', @(x) isa(x, 'scenarios.Scenario'));
            addRequired(p, 'marketData', @(x) isa(x, 'marketdata.MarketData'));
           
            addParameter(p, 'simulationStartDate',defaultSimulationStartTime,@isdatetime);
            addParameter(p, 'ESGModelType', defaultESGModelType, @(x) isa(x,'utilities.EconomicScenarioGeneratorType') );
            
            parse(p, inputScenario,marketData, varargin{:});

            tempScenario = inputScenario;
            % scenarioStartDate = tempScenario.ScenarioStartDate;
            % scenarioEndDate = tempScenario.ScenarioEndDate;
            simulationStartDate =p.Results.simulationStartDate;
            simulationIdentifier = "test";
            ESGModelType = p.Results.ESGModelType;

          % test = marketdatasimulationclasses.SimulationParameters(calyears(2),table.empty)

            tempScenario.ScenarioMarketData = marketdata.ScenarioSpecificMarketData(simulationIdentifier,inputScenario,marketData); % populates historical market data for scenario period

            tempScenario = scenarios.InitialiseScenarioWorkflows.initialiseScenarioMarketSimulationParameters(tempScenario,'simulationStartDate',simulationStartDate,'ESGModelType',ESGModelType);
            
            tempScenario = tempScenario.generateScenarioMarketData();

            scenario = tempScenario;
            disp("finished setting up scenario with simulated marketdata")
        end

        
        function scenario = initialiseAScenario(person,rateScenarios,startDate, endDate, assetReturnFrequency,riskPremiums,riskPremiumTickers)
            %To simulate a portfolio return i need the trading strategy which has benchmark data, i need the tickers for the portfolio and market prices
            % also need country and asset return frequency start and end date and rate
            % scenarios to use.
            % minimum inputs from outside the method
            
            %simulationParameters = SimulationParameters(startValues,startDate,assetReturnFrequency,ScenarioLengthYears); % this gives me the default values for everything I need
            %Use Scenario constructor default values

            [assetReturnStartDates, assetReturnEndDates] = utilities.generateDateArrays(startDate, endDate, assetReturnFrequency);

            tempScenario = scenarios.Scenario(person,rateScenarios,'startDate',startDate,'endDate',endDate,'assetReturnStartDates',assetReturnStartDates, ...
                'assetReturnEndDates',assetReturnEndDates, 'assetReturnFrequency',assetReturnFrequency);
            tempScenario = scenarios.InitialiseScenarioWorkflows.initialiseRiskPremiumAssumptionsTable(tempScenario,riskPremiums,riskPremiumTickers);

            % initialise the scenarios  RiskPremiumCalculator
            baseRiskPremiumCalculator = marketdatasimulationclasses.DefaultRiskPremiumCalculator(tempScenario.RiskPremiumAssumptions);
            assetClassMap = containers.Map(); % Populate with your asset class mappings
            tempScenario.RiskPremiumCalculator = marketdatasimulationclasses.AssetClassSpecificRiskPremiumDecorator(baseRiskPremiumCalculator, assetClassMap);

            scenario = tempScenario;
        end
               

        function scenario = initialiseRiskPremiumAssumptionsTable(scenario,inputRiskPremiums,inputTickers)
            % scenario = inputScenario;
            % riskPremiums = [0.04 0.04,0.04 0.04,0.04 0.04];
            riskPremiumsTable = array2table(inputRiskPremiums,"VariableNames",inputTickers);
            scenario.RiskPremiumAssumptions = riskPremiumsTable;

        end
        function initialiseSimpleAnnuityCalculations(age,gender,startDate,endDate)


        end
        function scenarioOutput = initialiseScenarioMarketSimulationParameters(scenario,varargin)
             % Use inputParser to handle optional arguments
             % This function takes all market data and extracts out the
             % prices forall dates in scenario using marketData.filterMarketPriceIndexes(allowablePortfolioHoldings)

             %THIS IS DOING TOO MANY THING> WANT TO BREAK IT INTO TWO
             %FUNCTIONS> MAYBE USE THE BUILDER CONCEPT
             % BUILD A SCENARIO SPECIFIC MARKET DATA OBJECT   that :
             % 1. extracts marketdata between two dates 
             % 2. extracts allowable holdings only
             % 3. extracts market reference portfolio returns between two dates
             % Buidl ScenarioMarketSimulationParameters object using  


          
            
             
            p = inputParser;
            
            defaultESGModelType = utilities.EconomicScenarioGeneratorType.Deterministic;
            addRequired(p, 'scenario',@(x) isa(x, 'scenarios.Scenario'));
           %addRequired(p, 'scenarioSpecificMarketData', @(x) isa(x, 'marketdata.MarketData'));
           
            addParameter(p, 'simulationStartDate',datetime('now'), @isdatetime);
            addParameter(p, 'ESGModelType', defaultESGModelType, @(x) isa(x,'utilities.EconomicScenarioGeneratorType') );
            
            parse(p, scenario,varargin{:});
           
            tol = utilities.Tolerance.AbsTol;
            % test = SimulationParameters(calyears(3),table.empty)

            scenario = p.Results.scenario;
            ESGModelType = p.Results.ESGModelType;
            %scenarioSpecificMarketData = p.Results.scenarioSpecificMarketData;
            
            simulationStartDate = p.Results.simulationStartDate;
            scenarioStartDate = scenario.ScenarioStartDate;
            scenarioEndDate = scenario.ScenarioEndDate;
            scenarioSpecificMarketData = scenario.ScenarioMarketData;
            % if isempty(simulationStartDate) 
            %     simulationStartDate = marketData.getDateLastHistoricalPrices();
            %     simulationStartDate = datetime('10/27/2023','InputFormat','MM/dd/uuuu');
            %     simulationStartDate.TimeZone = 'Australia/Sydney';
            %     simulationStartDate = simulationStartDate+ hours(17);
            %     %simulationStartDate =scenarioStartDate+ calyears(5);
            % end
            %Summary converts market data to ScenarioSpecificMarketData object and initialises SimulationParamters object.
            %Both objects are returned with the input scenario object.

            scenarioLengthYears = between(scenarioStartDate,scenarioEndDate,'years');
            tempStartDate = scenario.AssetReturnStartDates;
            % tempStartDate.TimeZone = '';
            tempEndDate = scenario.AssetReturnEndDates;
            % tempEndDate.TimeZone = '';
            assetReturnFrequencyPerYear = scenario.getAssetReturnFrequencyPerYear();
            assetReturnFrequency = scenario.AssetReturnFrequency;

            % marketDataSubSet = marketData.ExtractMarketDataBetweenTwoDates(scenarioStartDate,scenarioEndDate);
            % 
            % allowablePortfolioHoldings = scenario.Person.AssetPortfolio.AllowablePortfolioHoldings;
            % marketDataSubSet = marketDataSubSet.filterMarketPriceIndexes(allowablePortfolioHoldings);

            riskPremiumAssumption = scenario.RiskPremiumAssumptions;

            % CREAT A BUILDER FOR SIMULATIONAPARAMETERS
            

            scenarioMarketSimulationParameters = marketdatasimulationclasses.SimulationParameters(scenarioLengthYears,riskPremiumAssumption,'simulationStartDate', simulationStartDate,'assetReturnFrequency', assetReturnFrequency,'ESGModelType',ESGModelType);


            %scenarioMarketSimulationParameters = marketdatasimulationclasses.SimulationParameters(scenarioLengthYears, 'simulationStartDate', simulationStartDate,'assetReturnFrequency', assetReturnFrequency);
            
            projectionTerm = scenario.calculateSimulationProjectionTerm(simulationStartDate,scenario.AssetReturnFrequency);

            scenarioMarketSimulationParameters.SimulationProjectionTerm = projectionTerm;
            scenarioMarketSimulationParameters.TradingStrategy = scenario.Person.AssetPortfolio.TradingStrategy;
            scenarioMarketSimulationParameters.Country = scenario.Person.getPersonCountry;
            scenarioMarketSimulationParameters.RateScenarios = scenario.getRateScenarios;
            scenarioMarketSimulationParameters.AssetReturnFrequencyPerYear = assetReturnFrequencyPerYear ;
            
            


            if utilities.DateUtilities.isCalendarDurationGreaterThanTolerance(projectionTerm)

                %Create a ScenarioSpecificMarketData object
                simulationIdentifier ='testsimulation need to define an identifier scheme see scenario class';
                
                
                %tempScenarioMarketData.SimulationIdentifier = simulationIdentifier;

                %tempScenarioMarketData = marketdata.ScenarioSpecificMarketData(simulationIdentifier,marketDataSubSet);  % COSNTRUCT THE OBJECT MOVE THIS A SEPARATE BUILDER
                marketDataAssetNames = scenario.ScenarioMarketData.ScenarioHistoricalMarketData.MarketIndexPrices.Properties.VariableNames;
                simulationStartValues = scenario.ScenarioMarketData.getMarketPrices(simulationStartDate); % make we return tickers as headers
                scenarioMarketSimulationParameters.SimulationStartValues = simulationStartValues;

                % initialise the Simulation Parameter object with default risk premiums.
                disp("initialise the Simulation Parameter object with default risk premiums.")

                scenarioMarketSimulationParameters.SimulationIdentifier = simulationIdentifier;
                scenarioMarketSimulationParameters.AssetReturnStartDates = tempStartDate(tempStartDate >= simulationStartDate);
                tempAssetReturnStartDate = scenarioMarketSimulationParameters.AssetReturnStartDates(1);
                scenarioMarketSimulationParameters.AssetReturnEndDates = tempEndDate(tempEndDate > tempAssetReturnStartDate);

                assetReturnStartDates = scenarioMarketSimulationParameters.AssetReturnStartDates;
                assetReturnEndDates = scenarioMarketSimulationParameters.AssetReturnEndDates;

                % reset the Simulation Parameter object with scenario risk premiums.
                disp("reset the Simulation Parameter object with scenario risk premiums.")
                scenarioMarketSimulationParameters.RiskPremiums = scenario.RiskPremiumCalculator.calculateRiskPremiums(simulationStartDate, assetReturnStartDates, assetReturnFrequencyPerYear, marketDataAssetNames);             

                [scenarioMarketSimulationParameters.ForwardRates,scenarioMarketSimulationParameters.ForwardRatesTT] = scenario.ScenarioMarketData.getScenarioForwardRates(simulationStartDate,assetReturnStartDates,assetReturnEndDates,scenarioMarketSimulationParameters.Country,scenarioMarketSimulationParameters.RateScenarios);

            else
                simulationIdentifier ='No simulation required as scenario end date is before simulation start date';
                
                %tempScenarioMarketData.SimulationIdentifier = simulationIdentifier;
                %tempScenarioMarketData = marketdata.ScenarioSpecificMarketData(simulationIdentifier,marketDataSubSet);% CONSTRUCT THE OBJECT MOVE THIS A SEPARATE BUILDER
                scenarioMarketSimulationParameters.SimulationIdentifier = simulationIdentifier;
            end

            scenarioOutput = scenario;
            %scenarioOutput.ScenarioMarketData = tempScenarioMarketData;% CONSTRUCT THE OBJECT MOVE IN A SEPARATE BUILDER DO NOT CHANGE HERE
            scenarioOutput.ScenarioMarketSimulationParameters = scenarioMarketSimulationParameters;

        end


    end
end
