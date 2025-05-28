classdef SimulationParameters
    %SIMULATIONPARAMETERS Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        SimulationIdentifier
        AssetReturnStartDates
        AssetReturnEndDates
        Country
        RateScenarios
        SimulationStartValues timetable
        SimulationStartDate
        AssetReturnFrequency
        AssetReturnFrequencyPerYear
        ForwardRates
        ForwardRatesTT timetable
        RiskPremiums table
        TradingStrategy 
        SimulationProjectionTerm
        ESGModelType

    end
    
    methods
        function obj = SimulationParameters(scenarioLengthYears,riskPremiumAssumptions,varargin)
            %SIMULATIONPARAMETERS Construct an instance of this class
            %   Set Default parameters (trying to make it easy to test functionality)

            p = inputParser;

            defaultSimulationStartTime = utilities.DateUtilities.setDefaultSimulationStartDate();
            defaultSimulationStartTime.TimeZone = utilities.DefaultSimulationParameters.defaultTimeZone;
            defaultSimulationStartValues = timetable(1,'RowTimes',defaultSimulationStartTime,'VariableNames' , {'DefaultTicker'});
            defaultESGModelType = utilities.EconomicScenarioGeneratorType.Deterministic;

            
            addRequired(p, 'scenarioLengthYears',@iscalendarduration);
            addRequired(p, 'riskPremiumAssumptions',@istable);
            addParameter(p, 'assetReturnFrequency',utilities.FrequencyType.Annually, @(x) isa(x,'utilities.FrequencyType'));
            addParameter(p, 'simulationAssetStartValues',defaultSimulationStartValues,@istimetable);
            addParameter(p, 'simulationStartDate', defaultSimulationStartTime, @isdatetime );
            addParameter(p, 'ESGModelType', defaultESGModelType, @(x) isa(x,'utilities.EconomicScenarioGeneratorType') );
            

            parse(p,scenarioLengthYears, riskPremiumAssumptions,varargin{:});


            obj.SimulationStartValues = p.Results.simulationAssetStartValues;
            obj.SimulationStartDate = p.Results.simulationStartDate;
            obj.AssetReturnFrequency = p.Results.assetReturnFrequency;
            %riskPremiumAssumptions = p.Results.riskPremiumAssumptions;


            obj.SimulationProjectionTerm = p.Results.scenarioLengthYears;
            simulationStartDate = obj.SimulationStartDate;
            assetReturnFrequency = obj.AssetReturnFrequency;



            %default scenario parameters set up to initialse a local Scenario
            tradingStrategyLabel = {TradingStrategyType.BuyAndHoldReferencePortfolio};
            person = Person();
            portfolio = AssetPortfolio(tradingStrategyLabel,simulationStartDate);
            person.AssetPortfolio = portfolio;
            % paymentDates = [];
            % annuityValuationDates =[];
            % scenarioInflationAssumptions=[];
            % annuityStartDate=[];
            assetReturnFrequencyPerYear = utilities.DateUtilities.getFrequencyPerYear(assetReturnFrequency);
            obj.AssetReturnFrequencyPerYear = assetReturnFrequencyPerYear;
            obj.Country = person.AssetPortfolio.PortfolioCountry; % should default to 'AU';
            obj.TradingStrategy = person.AssetPortfolio.TradingStrategy;
            obj.ESGModelType = p.Results.ESGModelType;

            if utilities.DateUtilities.isCalendarDurationGreaterThanTolerance(scenarioLengthYears)
                endDateScenario = simulationStartDate+scenarioLengthYears;

                [assetReturnStartDates, assetReturnEndDates] = utilities.generateDateArrays(simulationStartDate, endDateScenario, assetReturnFrequency);
                obj.AssetReturnStartDates = assetReturnStartDates;
                % tempStartDate.TimeZone = '';
                obj.AssetReturnEndDates  = assetReturnEndDates;
                % tempEndDate.TimeZone = '';
                
                
               

                obj.SimulationIdentifier ="testdefault";
                rateScenarios = "default level yield curve";
                obj.RateScenarios =rateScenarios;
                defaultRateCurve = marketdata.setDefaultRateCurve();         
                [obj.ForwardRates,obj.ForwardRatesTT] = defaultRateCurve.getForwardRates(assetReturnStartDates,assetReturnEndDates);


                % % set default Scenario REMOVED TO AVOID CIRCULAR
                % DEPENDENCIES
                % defaultScenario = scenarios.Scenario(person,rateScenarios,'assetReturnStartDates',assetReturnStartDates,'assetReturnEndDates',assetReturnEndDates, ...
                %     'assetReturnFrequency',assetReturnFrequency);

                % set default Risk Premiums
                marketDataAssetNames = obj.SimulationStartValues.Properties.VariableNames;
                riskPremiumCalculator = marketdatasimulationclasses.DefaultRiskPremiumCalculator(riskPremiumAssumptions);
                riskPremiums = riskPremiumCalculator.calculateRiskPremiums(simulationStartDate,assetReturnStartDates,assetReturnFrequencyPerYear,marketDataAssetNames);
                obj.RiskPremiums = riskPremiums;
            else

                obj.AssetReturnStartDates = [];
                obj.AssetReturnEndDates= [];
                obj.RateScenarios= [];
                obj.ForwardRates= [];
                obj.RiskPremiums= [];
            end


        end


    end
end

