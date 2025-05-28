classdef Scenario <scenarios.ScenarioDataProvider
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %Annuity
        Person 
        RateScenarios
        RiskPremiumAssumptions table = array2table([0.03],"VariableNames","DefaultTicker")
        RiskPremiumCalculator 
        ScenarioStartDate
        AnnuityStartDate
        ScenarioEndDate
        AssetReturnStartDates % series of date reflecting start of period for the asset return
        AssetReturnEndDates % series of date reflecting end of period for the asset return
        AssetReturnFrequency
        AnnuityValuationDates
        PaymentDates
        ScenarioMarketData  marketdata.ScenarioSpecificMarketData %MarketData  % market & simulated data relevant to the scenario. each portfolio will use this data source to create data relevant to it.
        ScenarioInflationAsumptions
        ScenarioMarketSimulationParameters
       % RateCurveCollection HAVE NOT USED THIS YET% store rate curves for each annuity valuation date (assumes only have rate curves for these dates
        %AssetPortfolio
    end

    methods
        function obj = Scenario(person,rateScenarios,annuityStartDate, startDate, endDate,assetReturnStartDates,assetReturnEndDates,assetReturnFrequency,paymentDates, annuityValuationDates,scenarioInflationAsumptions)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            %obj.Annuity = annuity;
            obj.Person = person; %this person is intended to be the owner of the portfolio
            obj.RateScenarios = rateScenarios;
            obj.AnnuityStartDate = annuityStartDate;
            obj.ScenarioStartDate = startDate;
            obj.ScenarioEndDate = endDate;
            obj.AssetReturnStartDates=assetReturnStartDates;
            obj.AssetReturnEndDates=assetReturnEndDates;
            obj.AssetReturnFrequency = assetReturnFrequency;
            obj.AnnuityValuationDates = annuityValuationDates;
            %obj.AssetPortfolio = assetPortfolio;
            obj.PaymentDates = paymentDates;
            obj.ScenarioInflationAsumptions=scenarioInflationAsumptions;
        end
        
        

        function results = run_simulation(obj,baseLifeTableFolder)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here


            startDate = obj.ScenarioStartDate;
            scenarioData =obj;
            scenarioMarketData = obj.ScenarioMarketData;
            %want to use a generate Portfolio Market scenario method here TODO.
            inflationRateAssumption = obj.ScenarioInflationAsumptions;

            % rateCurve = scenarioMarketData.getRateCurveForScenario(startDate, obj.Person.Country, obj.RateScenarios);
            % rateCurveName  = scenarioMarketData.determineCurveName(startDate, obj.Person.Country, obj.RateScenarios);

            % passing through scenarioMarketDat which is a MarketData object.
            % should have a create PortoflioMarketData method.  to isolate all the code
            % to create only relevant market data for the portfolio.

            disp("About to create the portfolio market data from scenario data")
            obj.Person.AssetPortfolio.PortfolioMarketData = scenarioMarketData;
            disp("updating assets values for each valuation date")

            obj.Person.AssetPortfolio = obj.Person.AssetPortfolio.update_value(obj.Person,obj.AssetReturnStartDates,  obj.AssetReturnEndDates,obj.PaymentDates,scenarioData);
            results.AssetPortfolio  = obj.Person.AssetPortfolio;
            assetValuesTimetable = obj.Person.AssetPortfolio.PortfolioTimeTable;
            disp("Finished updating portfolio values (simple and complex)")

            % need to define valuation dates between start and end of
            % scenario . THis code should calcualte annuity value at each
            % date/ will need the ratecurves dictionary to have curves for
            % each date relevant to Person

            %loop through valuation dates and generate a collection of
            %AnnuityValuationSets for the owner paymentgs from the owners
            %portfolio
            % Valuations for all future times at each valaution is
            % performed here. Presentation layer looks after extracting teh
            % required data for users.


            scenarioName ="TEST Calculating person income payment value";
            valuationDates = obj.AnnuityValuationDates;

            for i = 1: length(valuationDates)
                valuationDate = valuationDates(i);
                valuationDateDeTZ = valuationDate;
                valuationDateDeTZ.TimeZone = '';
                if valuationDateDeTZ < obj.ScenarioMarketData.RatesMetaData.EndDateRates(end)
                    fprintf("Valuing owner payments at date: %s\n", datestr(valuationDates(i), 'ddmmyyyy'));

                    rateCurve = scenarioMarketData.getRateCurveForScenario(valuationDate, obj.Person.Country, obj.RateScenarios);
                    rateCurveName  = scenarioMarketData.determineCurveName(valuationDate, obj.Person.Country, obj.RateScenarios);


                    % obj.Person.AssetPortfolio.PortfolioMarketData.RateCurves = rateCurve;
                    % obj.Person.AssetPortfolio.PortfolioMarketData.RateCurveName = rateCurveName;

                    % create a set of dates for only remaining valuation dates

                    futureMortalityTable = obj.Person.FutureMortalityTable;

                    personIncomeStreamPV = obj.Person.Annuity.present_value(futureMortalityTable,rateCurve,inflationRateAssumption,valuationDates);


                    annuityValuationsTimetable = timetable(valuationDates(i:end)',personIncomeStreamPV(i:end)','VariableNames',{'PV of Portfolio Owner Payments'});
                    annuityValuationsTimetableRetimed= retime(annuityValuationsTimetable, assetValuesTimetable.Time, 'previous');

                    %construct AnnuityValuationSets object
                    annuityValuationSet = AnnuityValuationSet(annuityValuationsTimetableRetimed, rateCurveName);

                    if i == 1
                        %instantiate annuityValuationCollection
                        annuityValuationTT = timetable(valuationDate', {annuityValuationSet}, 'VariableNames', {'AnnuityValuationSets'});
                        annuityValuationCollection = AnnuityValuationCollection(annuityValuationTT,scenarioName);
                    else
                        annuityValuationCollection=annuityValuationCollection.addAnnuityValuationSet(annuityValuationSet,valuationDate);
                    end

                else
                    disp("Annuity Valuation dates exceed the available input rate curves. Check out your input data Valuations will typically using a stale yield curve throughout the remaining scenario")
                    break;
                end
            end %for valuation dates loop

            disp("finished owner payment valuations")

            %results.Timetable = addvars(obj.Person.AssetPortfolio.PortfolioTimeTable,pv','NewVariableNames',{'Target Income Value'});
            %results.Timetable =  [assetValuesTimetable,annuityValuationsTimetableRetimed];
            results.AnnuityValuations =  annuityValuationCollection;
            AnnuityValuationsTTRetimed = retime(annuityValuationCollection.AnnuityValuationsTT,assetValuesTimetable.Time,"previous");

            results.Timetable =  [assetValuesTimetable,AnnuityValuationsTTRetimed];

        end
        function obj = setRiskPremiumCalculator(obj,inputCalculator)
            if ~isa(inputCalculator, 'RiskPremiumCalculator')
                error('Invalid assignment. RiskPremiumCalculator must be an object of type RiskPremiumCalculator or its subclasses.');
            end
            tempScenario = obj;
            tempScenario.RiskPremiumCalculator = inputCalculator; 
            obj = tempScenario;
        end
        function rateScenarios =  getRateScenarios(obj)
            rateScenarios = obj.RateScenarios;
        end
        function inflationRateAssumptions = getInflationAssumption(obj)
            inflationRateAssumptions = obj.ScenarioInflationAsumptions;
        end
        function annuityValuationDates = getAnnuityValuationDates(obj)
            annuityValuationDates = obj.AnnuityValuationDates;
        end
         function assetReturnFrequencyPerYear = getAssetReturnFrequencyPerYear(obj)
            
            assetReturnFrequencyPerYear = utilities.DateUtilities.getFrequencyPerYear(obj.AssetReturnFrequency);
         end
         function scenarioProjectionTerm = calculateSimulationProjectionTerm(obj,simulationStartDate,frequency) 
            disp('Calculating scenario projection term')

            %scenarioStartDate = obj.ScenarioStartDate;

            scenarioEndDate = obj.ScenarioEndDate;
            %scenarioEndDate.TimeZone = '';
            scenarioProjectionTerm = utilities.DateUtilities.calculateNumPeriodsBetweeenTwoDates(simulationStartDate, scenarioEndDate,frequency);
        end

      function dateLastPrices = getDateLastPrices(obj)
            disp('need to build function to get last historical prices')
            dateLastPrices = 'need to build function to get last historical prices';
        end
        
        function obj = generateScenarioMarketData(obj,marketData)
            %GENERATESCENARIOMARKETDATA Selects historical from market data store the required data and simulates future data.
            %The market data is stored in the Scenario object as a containers map with the valuation date
            % as the key and the rate curve object as the value.
            % The scenarioMarketData object will contain only data for
            % period between scenario start and end date.

            % INPUTS

            %pre initialised scenario object , market data object and the typr of simulation to use for future market data.

            % OUTPUT 
            % output is a scenariomarketdata object with data relevant to the scenario


            % check market data includes all past data required . If not
            % output an error message to say the start date commences
            % before the available historical market data.


            % extract required historical market data from the market data object
           

            scenarioStartDate = obj.ScenarioStartDate;
            scenarioEndDate = obj.ScenarioEndDate;
            
            % marketDataSubSet = marketData.ExtractMarketDataBetweenTwoDates(scenarioStartDate,scenarioEndDate);
            %  %Create a ScenarioSpecificMarketData object
            % simulationIdentifier ='testsimulation need to define an identifier scheme see scenario class';
            % % rateCurvesCollection = marketDataSubSet.RateCurvesCollection;
            % % mapCountryToCurveName = marketDataSubSet.MapCountryToCurveName;
            % % ratesMetaData = marketDataSubSet.RatesMetaData;
            % tempScenarioMarketData = marketdata.ScenarioSpecificMarketData(simulationIdentifier,marketDataSubSet);
            % 

            %Create simulation parameters

            % get teh start date for simulating returns, interest rates and
            % market price indexes. Should be possible to provide a user
            % input as well as base it off the available historical prices,
            % returns and rates. SO present a list of these to use and
            % allow a choice.

            simulationStartDate = marketDataSubSet.getDateLastHistoricalPrices();
            simulationStartDate = datetime('10/27/2023','InputFormat','MM/dd/uuuu');
            simulationStartDate.TimeZone = 'Australia/Sydney';
            simulationStartDate = simulationStartDate+ hours(17);
            
            
            
            % create a market data simulation engine % add a factory to
            % convert simulationType to a generator dynamically
            
            % simulationParameters = [0.1,10];

            tempScenario = obj.generateScenarioMarketSimulationParameters(scenarioStartDate,simulationStartDate,scenarioEndDate,marketData);
            simulationParameters = tempScenario.ScenarioMarketSimulationParameters;
            % scenarioMarketSimulationParameters.forwardRates = tempScenarioMarketData.getScenarioForwardRates(simulationStartDate);
            % scenarioMarketSimulationParameters.riskPremiums = tempScenarioMarketData.getScenarioRiskPremiums(simulationStartDate);
            % scenarioMarketSimulationParameters.assetReturnFrequencyPerYear = tempScenarioMarketData.getScenarioAssetReturnFrequencyPerYear() ;
            % scenarioMarketSimulationParameters.scenarioProjectionTerm = tempScenarioMarketData.calculateScenarioProjectionTerm(simulationStartDate,scenarioEndDate,scenarioMarketSimulationParameters.assetReturnFrequencyPerYear) ;

            %Create Simulation Generator
            simulator = DeterministicScenarioGenerator(simulationParameters);
            
            % simulate future market data
            simulatedMarketData = simulator.generateSimulatedScenarioMarketData();
            %simulatedMarketData = simulator.simulateValues(simulationStartValues); % first cut of this is to return aAssetReturns timetable.
            tempScenarioMarketData = tempScenario.ScenarioMarketData;       
            % append simulatedMarketData to scenarioMarketData
            obj.ScenarioMarketData = tempScenarioMarketData.combineExistingAndSimulatedMarketData(simulatedMarketData,simulationStartDate);
            
            obj.ScenarioMarketSimulationParameters = simulationParameters;
            % obj.ScenarioMarketSimulationParameters = scenarioMarketSimulationParameters;

        end

        

        function obj = generateScenarioMarketSimulationParameters(obj,scenarioStartDate,simulationStartDate,scenarioEndDate,marketData)
            
            %Summary converts market data to ScenarioSpecificMarketData object and initialises SimulationParamters object.
            %Both objects are returned with the input scenario object.
            
            scenarioLengthYears = between(scenarioStartDate,scenarioEndDate,'years')+calyears(1);
            tempStartDate = obj.AssetReturnStartDates;
            % tempStartDate.TimeZone = '';
            tempEndDate = obj.AssetReturnEndDates;
            % tempEndDate.TimeZone = '';
            assetReturnFrequencyPerYear = obj.getAssetReturnFrequencyPerYear();
            assetReturnFrequency = obj.AssetReturnFrequency;
            
            
            marketDataSubSet = marketData.ExtractMarketDataBetweenTwoDates(scenarioStartDate,scenarioEndDate);
             %Create a ScenarioSpecificMarketData object
            simulationIdentifier ='testsimulation need to define an identifier scheme see scenario class';
            % rateCurvesCollection = marketDataSubSet.RateCurvesCollection;
            % mapCountryToCurveName = marketDataSubSet.MapCountryToCurveName;
            % ratesMetaData = marketDataSubSet.RatesMetaData;
            
            tempScenarioMarketData = marketdata.ScenarioSpecificMarketData(simulationIdentifier,marketDataSubSet);
            marketDataAssetNames = tempScenarioMarketData.ScenarioHistoricalMarketData.MarketIndexPrices.Properties.VariableNames;

            simulationStartValues = tempScenarioMarketData.getMarketPrices(simulationStartDate); % make we return tickers as headers


            scenarioMarketSimulationParameters = SimulationParameters(simulationStartValues,simulationStartDate,assetReturnFrequency,scenarioLengthYears);
           

            
            scenarioMarketSimulationParameters.SimulationIdentifier = simulationIdentifier;
            scenarioMarketSimulationParameters.AssetReturnStartDates = tempStartDate(tempStartDate >= simulationStartDate);
            tempAssetReturnStartDate = scenarioMarketSimulationParameters.AssetReturnStartDates(1);
            scenarioMarketSimulationParameters.AssetReturnEndDates = tempEndDate(tempEndDate > tempAssetReturnStartDate);

            assetReturnStartDates = scenarioMarketSimulationParameters.AssetReturnStartDates;
            assetReturnEndDates = scenarioMarketSimulationParameters.AssetReturnEndDates;
            scenarioMarketSimulationParameters.RiskPremiums = obj.RiskPremiumCalculator.calculateRiskPremiums(simulationStartDate, assetReturnStartDates, assetReturnFrequencyPerYear, marketDataAssetNames);

            scenarioMarketSimulationParameters.Country = obj.Person.getPersonCountry;
            scenarioMarketSimulationParameters.RateScenarios = obj.getRateScenarios;
            
    
            scenarioMarketSimulationParameters.ForwardRates = tempScenarioMarketData.getScenarioForwardRates(simulationStartDate,assetReturnStartDates,assetReturnEndDates,scenarioMarketSimulationParameters.Country,scenarioMarketSimulationParameters.RateScenarios);
            
            scenarioMarketSimulationParameters.AssetReturnFrequencyPerYear = assetReturnFrequencyPerYear ;
            scenarioMarketSimulationParameters.SimulationProjectionTerm = obj.calculateSimulationProjectionTerm(simulationStartDate,obj.AssetReturnFrequency) ;
            scenarioMarketSimulationParameters.TradingStrategy = obj.Person.AssetPortfolio.TradingStrategy;
            
            obj.ScenarioMarketData = tempScenarioMarketData;
            obj.ScenarioMarketSimulationParameters = scenarioMarketSimulationParameters;
            

        end
        
    end
end