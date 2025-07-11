classdef Scenario <scenarios.ScenarioDataProvider
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        %Annuity
        Person 
        RateScenarios
        RiskPremiumAssumptions table = array2table(utilities.DefaultSimulationParameters.defaultRiskPremium,"VariableNames","DefaultTicker")
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
        function obj = Scenario(person,rateScenarios,varargin)
            %UNTITLED2 Construct an instance of this class
            %   Defaults to a one year scenario valuaiton frequency 1 year
            %   and default person
            %obj.Annuity = annuity;
            
            defaultStartDate = utilities.DefaultScenarioParameters.defaultStartDate;
            defaultEndDate = utilities.DefaultScenarioParameters.defaultEndDate;
            
            defaultStartDate.TimeZone = utilities.DefaultScenarioParameters.defaultTimeZone;
            defaultEndDate.TimeZone = utilities.DefaultScenarioParameters.defaultTimeZone;
            defaultReferenceTime =  utilities.DefaultScenarioParameters.defaultReferenceTime;
            defaultFrequency = utilities.FrequencyType.Annually;
            [defaultAssetReturnStartDates, defaultAssetReturnEndDates] = utilities.generateDateArrays(defaultStartDate, defaultEndDate, defaultFrequency,defaultReferenceTime);
            [defaultStartDates, paymentDates.defaultEndDates]=utilities.generateDateArrays(defaultStartDate,  defaultEndDate, defaultFrequency,defaultReferenceTime);
            defaultAnnuityValuationDates = utilities.generateDateArrays( defaultStartDate, defaultEndDate, defaultFrequency ,defaultReferenceTime);
            
            defaultRateScenarios = utilities.DefaultScenarioParameters.defaultRateScenarios;

            p = inputParser;
            addRequired(p,'person',@(x) isa(x, 'Person'));
            addRequired(p,'rateScenarios');
            addParameter(p,'startDate',defaultStartDate,@isdatetime);
            addParameter(p,'endDate', defaultEndDate,@isdatetime)
            addParameter(p,'assetReturnStartDates',defaultAssetReturnStartDates,@isdatetime);
            addParameter(p,'assetReturnEndDates',defaultAssetReturnEndDates,@isdatetime);
            addParameter(p,'assetReturnFrequency',defaultFrequency,@(x) isa(x,'utilities.FrequencyType'));
            addParameter(p,'paymentDates',paymentDates,@isstruct);
            addParameter(p,'annuityStartDate',defaultStartDate,@isdatetime);
            addParameter(p,'annuityValuationDates',[defaultStartDate,defaultEndDate],@isdatetime);
            addParameter(p,'scenarioInflationAssumptions',[0.0],@(x) isa(x,'double'));
            
            parse(p,person,rateScenarios,varargin{:});


            obj.Person = p.Results.person; %this person is intended to be the owner of the portfolio
            obj.RateScenarios =  p.Results.rateScenarios;
            obj.ScenarioStartDate =  p.Results.startDate;
            obj.ScenarioEndDate =  p.Results.endDate;
            obj.AssetReturnStartDates= p.Results.assetReturnStartDates;
            obj.AssetReturnEndDates= p.Results.assetReturnEndDates;
            obj.AssetReturnFrequency =  p.Results.assetReturnFrequency;
            obj.PaymentDates =  p.Results.paymentDates;
            obj.AnnuityStartDate =  p.Results.annuityStartDate;
            obj.AnnuityValuationDates =  p.Results.annuityValuationDates;
            obj.ScenarioInflationAsumptions= p.Results.scenarioInflationAssumptions;
            
        end
        
        

        function [results,updatedScenario] = run_simulation(obj)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here


            startDate = obj.ScenarioStartDate;
            
            scenarioMarketData = obj.ScenarioMarketData;
            %want to use a generate Portfolio Market scenario method here TODO.
            inflationRateAssumption = obj.ScenarioInflationAsumptions;

            % rateCurve = scenarioMarketData.getRateCurveForScenario(startDate, obj.Person.Country, obj.RateScenarios);
            % rateCurveName  = scenarioMarketData.determineCurveName(startDate, obj.Person.Country, obj.RateScenarios);

            % passing through scenarioMarketDat which is a MarketData object.
            % should have a create PortoflioMarketData method.  to isolate all the code
            % to create only relevant market data for the portfolio.

            disp("About to create the portfolio market data from scenario market data")
            obj.Person.AssetPortfolio.PortfolioMarketData = scenarioMarketData;
            % create a portfolio benchmark return time series from scenario
            % specific market data

            %% assume that benchmark returns for the assetportfolio = the market reference portfolio returns

            obj.Person.AssetPortfolio.BenchmarkReturns = obj.Person.AssetPortfolio.PortfolioMarketData.AssetReturns;

       

            disp("updating assets values for each valuation date")
            
            scenarioData =obj;

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
            updatedScenario = obj;

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
        
        function obj = generateScenarioMarketData(obj)
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
            

            tempScenario = obj;
            scenarioStartDate = obj.ScenarioStartDate;
            scenarioEndDate = obj.ScenarioEndDate;

            scenarioMarketData =obj.ScenarioMarketData;
            
            if isempty(tempScenario.ScenarioMarketSimulationParameters)
            tempScenario = obj.generateScenarioMarketSimulationParameters(scenarioStartDate,scenarioEndDate,scenarioMarketData);
            end
            simulationParameters = tempScenario.ScenarioMarketSimulationParameters;
            simulationStartDate = simulationParameters.SimulationStartDate;
           
            %Create Simulation Generator

            simulationModelType = tempScenario.ScenarioMarketSimulationParameters.ESGModelType;
            simulator = marketdatasimulationclasses.EconomicScenarioGeneratorFactory.create(simulationModelType, simulationParameters);
            

            
            % simulate future market data
            simulatedMarketData = simulator.generateSimulatedScenarioMarketData();

            tempScenarioMarketData = tempScenario.ScenarioMarketData;       
            % append simulatedMarketData to scenarioMarketData
            
            obj.ScenarioMarketData = tempScenarioMarketData.combineExistingAndSimulatedMarketData(simulatedMarketData,simulationStartDate);  
            
           

        end

        

        function scenarioOutput = generateScenarioMarketSimulationParameters(obj,scenarioMarketData,varargin)
             % Use inputParser to handle optional arguments
            
             
            p = inputParser;
            
            
            % addRequired(p, 'scenarioStartDate', @isdatetime);
            % addRequired(p, 'scenarioEndDate', @isdatetime);
            addRequired(p, 'marketData', @(x) isa(x, 'marketdata.MarketData'));
           
            addParameter(p, 'simulationStartDate',datetime('now'), @isdatetime);
            
            parse(p, scenarioMarketData,varargin{:});

            scenarioOutput = initialiseScenarioMarketSimulationParameters(obj,marketData,varargin);
                      

        end
        
    end
end