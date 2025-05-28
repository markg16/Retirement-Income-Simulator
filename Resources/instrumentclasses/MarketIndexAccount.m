classdef MarketIndexAccount <Instrument %< KaparraMarketDataManipulationInterFace
    properties
        Tickers
        TickerQuantities  timetable% TODO this should be a time series of quantities
        TargetWeights
        ActualWeights
        AccountCurrency
        AccumulationIndicator  % true means dividends are accumulated in the Account
        TradingStrategy
        IndexMarketData  % a MarketIndexAcctDataDecorator object
        % ... (other equity index-specific properties)
    end

    methods
        % ... (constructor, getCurrentValue, other equity index-specific methods)

        function obj = MarketIndexAccount(marketIndexAcctParameters,inputScenario,inputMarketData)
            tickers = marketIndexAcctParameters.tickers;
            startDate = marketIndexAcctParameters.startDate;
            allowableTickers = marketIndexAcctParameters.tickers;
            obj.Name = marketIndexAcctParameters.name;
            obj.StartDate = startDate;
            obj.Tickers = allowableTickers; % account will have n units of underlying index
            obj.TargetWeights = marketIndexAcctParameters.targetWeights;

            tickerTable = array2table(zeros(1,length(marketIndexAcctParameters.tickers)),'VariableNames',tickers);
            obj.TickerQuantities = table2timetable(tickerTable,'RowTimes',startDate);
            
            
            marketIndexAcctMarketData = marketdata.MarketIndexAcctDataDecorator(startDate,allowableTickers,inputMarketData,inputScenario);

            % marketIndexAcctMarketData must be a MarketIndexAcctDataDecorator so it has the correct methods available.
                            
            obj.IndexMarketData = marketIndexAcctMarketData;
            obj.TradingStrategy = MarketIndexAcctTradingStrategy(marketIndexAcctParameters);
            obj = obj.updateHistoricalValues(startDate,0);
        end

        function obj = deposit(obj,amount,depositDate)
            
            if ~isdatetime(depositDate)
                depositDate = datetime(depositDate);                
            end
            depositDate.TimeZone = 'Australia/Sydney';
            
            tickerQuantities = obj.getLatestQuantities(depositDate);

            tempMarketData = obj.IndexMarketData;
            tempTickers = obj.Tickers;
            tickerPrices = tempMarketData.getTickerPrices(depositDate);
            

            % tickerPrices = obj.IndexMarketData.getTickerPrices(obj.Tickers,depositDate);
            obj.TickerQuantities = tickerQuantities + amount*obj.TargetWeights./tickerPrices;

        end
        function tickerValues  = getCurrentValues(obj,valuationDate)
            %tempMarketData = obj.IndexMarketData;
            if ~isdatetime(valuationDate)
                valuationDate = datetime(valuationDate);                
            end
            valuationDate.TimeZone = 'Australia/Sydney';
            
            tickerQuantities = obj.getLatestQuantities(valuationDate);

            tickerPrices = obj.IndexMarketData.getTickerPrices(valuationDate);
            tickerValues = tickerQuantities .* tickerPrices;
        end

        function currentAccountValue = getCurrentValue(obj,valuationDate,varargin)
            % added vargin to allow for this method to be called on all
            % instruments. Some instruments require additional parameters.

            currentValues = obj.getCurrentValues(valuationDate);
            % TODO should all getValues return a timetbale or an array?
            % updateAssetValue assumes all array 

            currentValuesTable = timetable2table(currentValues);
            currentValuesArray = table2array(currentValuesTable(1,2:end));
            % Sum the values in each row of the array
            currentAccountValue = sum(currentValuesArray, 2); % Sum across columns (2nd dimension)
            
            %currentAccountValue = table2array(rowfun(@plus,currentValues,"OutputVariableNames",'MarketIndexAcctCurrentValue'));

        end

        function tickerQuantities  = getLatestQuantities(obj,valuationDate)

            tickerQuantitiesRetimed = retime(obj.TickerQuantities,valuationDate,'previous');
            
            % Convert the timetable to a table for easier access
            tickerQuantitiesRetimedTable = timetable2table(tickerQuantitiesRetimed);

            % Find the row index corresponding to the target date (or the latest date before it)
            rowIndex = tickerQuantitiesRetimedTable.Time == tickerQuantitiesRetimed.Time(end);

            % Extract the value of the specified variable at that row
            tickerQuantitiesTable = tickerQuantitiesRetimedTable(rowIndex,:);

            % Convert Back to a timetable
            tickerQuantities=table2timetable(tickerQuantitiesTable);
        end



        function obj = withdraw(obj,amount,withdrawalDate)
            %tempMarketData = obj.IndexMarketData;
            
            if ~isdatetime(withdrawalDate)
                withdrawalDate = datetime(withdrawalDate);                
            end
            withdrawalDate.TimeZone = 'Australia/Sydney';
            tempTickers = obj.Tickers;
            tickerPrices = obj.IndexMarketData.getTickerPrices(withdrawalDate);
            tickerQuantities = obj.getLatestQuantities(withdrawalDate);
            currentValues = obj.getCurrentValues(withdrawalDate);
            currentAccountValue = obj.getCurrentValue(withdrawalDate);
            % Convert the timetable to a numeric array

            % currentValuesTable = timetable2table(currentValues);
            % currentValuesArray = table2array(currentValuesTable(1,2:end));
            % % Sum the values in each row of the array
            % rowSums = sum(currentValuesArray, 2); % Sum across columns (2nd dimension)

            if amount <= currentAccountValue  % TODO address possible short positions assumes withdrawals are done using target weights which may lead to short positions.

                obj.TickerQuantities = tickerQuantities - amount*obj.TargetWeights./tickerPrices;

            else

                disp('Insufficient funds in the Market Index account No withdrawal made. Failed Trade  ');

            end

            % currentValue = rowfun(@sum,currentValues,"OutputVariableNames",'MarketIndexAcctValue');
            
            % if amount <= currentValue.MarketIndexAcctValue  % TODO address possible short positions assumes withdrawals are done using target weights which may lead to short positions.
            % 
            %     obj.TickerQuantities = tickerQuantities - amount*obj.TargetWeights./tickerPrices;
            % 
            % else
            % 
            %     disp('Insufficient funds in the Market Index account No withdrawal made. Failed Trade  ');
            % 
            % end
        end


        function obj = rebalance(obj,rebalanceDate)
            
            portfolio =  obj;
            %marketData = obj.IndexMarketData;
            person = [];
            scenarioData =[];

            %     %determine rebalances required
  
            instructions = obj.TradingStrategy.determineTrade(portfolio,person,rebalanceDate, portfolio, scenarioData);
         
            %     %execute the  rebalance
            portfolio = obj.TradingStrategy.executeTrade(portfolio,instructions);
            obj = portfolio;
            %
        end


    end
end