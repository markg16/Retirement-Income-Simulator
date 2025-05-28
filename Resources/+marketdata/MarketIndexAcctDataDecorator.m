classdef MarketIndexAcctDataDecorator < marketdata.ScenarioSpecificMarketData 
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        IndexMarketDataTimeTable
    end

    methods (Static)
       % function obj = MarketIndexAcctDataDecorator(scenarioSpecificMarketData,startDateAcct,allowableTickers)
       function obj = MarketIndexAcctDataDecorator(startDateAcct,allowableTickers,scenarioSpecificMarketData,scenario)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            
            simulationIdentifier = "testmarketIndexAcct";
            obj@marketdata.ScenarioSpecificMarketData(simulationIdentifier,scenario,scenarioSpecificMarketData);
         

            obj.AssetReturns = scenarioSpecificMarketData.AssetReturns;
            obj.MarketIndexPrices = scenarioSpecificMarketData.MarketIndexPrices;

            obj.MarketIndexPrices = obj.extractIndexPricesData(startDateAcct, allowableTickers); 

            % % Call the parent constructor
            % %obj@marketdata.ScenarioSpecificMarketData(simulationIdentifier,localScenario,scenarioSpecificMarketData);
            % obj.IndexMarketDataTimeTable = indexMarketDataTimeTable;
            % obj.MarketIndexPrices = scenarioSpecificMarketData.ScenarioHistoricalMarketData.MarketIndexPrices;
            % 
            % marketIndexAcctPrices = obj.extractIndexPricesData(startDateAcct,allowableTickers);
            % obj.MarketIndexPrices = marketIndexAcctPrices;
        end
    end

    methods

        function marketIndexAcctPrices = extractIndexPricesData(obj,startDateAcct,allowableTickers)
            % Get data from the wrapped ScenarioData object
            lastDateAvailable = getLastDatePriceAvailable(obj);
            endDate = lastDateAvailable;
            subsetMarketData  = obj.ExtractMarketDataBetweenTwoDates(startDateAcct,endDate);
            extracted_tt = subsetMarketData.MarketIndexPrices(:,allowableTickers);
            indexMarketData = extracted_tt;
            marketIndexAcctPrices = indexMarketData;
        end

        function tickerPrices = getTickerPrices(obj,valuationDate)
            %METHOD1 Summary of this method goes here
            %   Detailed explanation goes here
            
            tickerPrices = obj.MarketIndexPrices(valuationDate,:);
        end

        function lastDateAvailable = getLastDatePriceAvailable(obj)

            priceTT = obj.MarketIndexPrices;
            lastDateAvailable = tail(priceTT,1).Time;
        end
    end
end