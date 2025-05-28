classdef AssetPortfolio
    %UNTITLED3 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        PortfolioCountry (1,:) string 
        StartDate datetime
        InitialValue double = 100000;
        AssetValues
        BenchmarkReturns timetable% Use a timetable for date-indexed returns
        AllowablePortfolioHoldings  cell 
        PortfolioMarketData marketdata.ScenarioSpecificMarketData %MarketData relevant to the portfolio
        PortfolioHoldings  % container to hold asset objects eg a bank account and an annuity
        CurrentPortfolioValue
        TradingStrategy %TradingStrategy = TradingSTrategyFactory% definition of the trading strategy used by the portfolio  eg'BuyAndHold'
        CashflowsInputData   % Structure with annualised amount, frequency, inflation adjustments
        Cashflows
        PortfolioTimeTable 
    end

    methods
       
        function obj = AssetPortfolio(tradingStrategyType, startDate, varargin)
            %ASSETPORTFOLIO Construct an instance of this class

            % Use inputParser to handle optional arguments
            p = inputParser;

             % Validation function for strategyTypes
            validStrategyTypes = enumeration('TradingStrategyType'); % Get all enum values
            isValidStrategyType = @(x) iscell(x) && all(cellfun(@(s) ismember(s, validStrategyTypes), x)); ; 
            addRequired(p, 'tradingStrategyType', isValidStrategyType);
            
            addRequired(p, 'startDate', @isdatetime);
            addParameter(p, 'portfolioCountry', "AU", ...
                @(x) utilities.ValidationUtils.validateCountry(x));

            % mustBeMember is not supported as an attribute.
            % %addParameter(p, 'portfolioCountry', "AU", ...
            %     @(x) validateattributes(x, {'string'}, ...
            %     {'mustBeMember', ["AU","US","UK","NZ","GB"], ...
            %     'scalartext', ...  % Ensures it's a scalar char vector
            %     'maxLength', 3}));  % Max length of 3

            addParameter(p, 'initialValue', 1e6, @isnumeric);
            addParameter(p, 'benchmarkReturns', timetable.empty, @istimetable);
            addParameter(p, 'cashflowsInputData', struct.empty, @(x) isstruct(x) || isempty(x));
            addParameter(p, 'targetPortfolioWeights', PortfolioWeights(), @(x) isa(x, 'PortfolioWeights')); % Add parameters for the strategy
            addParameter(p, 'marketIndexAcctParameters', struct.empty, @(x) isstruct(x) || isequal(x, struct.empty));
            addParameter(p, 'allowablePortfolioHoldings', {}, @(x) iscell(x));

            parse(p, tradingStrategyType, startDate, varargin{:});

            % Access parsed values
            % Create the TradingStrategy object

            targetPortfolioWeightsTable = p.Results.targetPortfolioWeights.WeightsTable; % access the table of weights


            if isfield(p.Results.cashflowsInputData,'AnnuityType')
           
                    annuityType = p.Results.cashflowsInputData.AnnuityType;

                    tradingStrategies = TradingStrategyFactory.createTradingStrategy(tradingStrategyType, 'TargetPortfolioWeights', targetPortfolioWeightsTable, ...
                        'MarketIndexAcctParameters',  p.Results.marketIndexAcctParameters,'AnnuityType',annuityType);
            else
                    tradingStrategies = TradingStrategyFactory.createTradingStrategy(tradingStrategyType, 'TargetPortfolioWeights', targetPortfolioWeightsTable, ...
                        'MarketIndexAcctParameters',  p.Results.marketIndexAcctParameters);

            end
            
            obj.TradingStrategy  = CompositeTradingStrategy(tradingStrategies,targetPortfolioWeightsTable);
            obj.StartDate = p.Results.startDate;
            obj.PortfolioCountry = p.Results.portfolioCountry;
            obj.InitialValue = p.Results.initialValue;
            obj.BenchmarkReturns = p.Results.benchmarkReturns;
            obj.AssetValues = p.Results.initialValue;
            obj.CashflowsInputData = p.Results.cashflowsInputData;
            obj.AllowablePortfolioHoldings = p.Results.allowablePortfolioHoldings;

            obj.PortfolioHoldings = {};

            % Create and add a BankAccount object with initial value
            bankAccount = BankAccountFactory.createInstrument('Portfolio Cash', obj.InitialValue, obj.StartDate);
            disp('adding bank account to newly created portfolio')
            obj = obj.addInstrument(bankAccount);
        end
        function obj = update_value(obj, owner,startPeriodDates, endPeriodDates,paymentDates,scenarioData)
            %UPDATE_VALUE Calculate asset values at each period end.
            %
            %   OBJ = UPDATE_VALUE(OBJ, STARTDATES, ENDDATES) updates the AssetValues
            %   property of the AssetPortfolio object OBJ. It calculates the asset
            %   value at the end of each period defined by STARTDATES and ENDDATES
            %   using the formula A(t+1) = A(t) * Return(t to t+1) + Cashflow(t+1),
            %   where:
            %       - A(t) is the asset value at the beginning of the period.
            %       - Return(t to t+1) is the return over the period.
            %       - Cashflow(t+1) is the cashflow received at the end of the period.
            %
            %   Inputs:
            %       OBJ: The AssetPortfolio object.
            %       STARTDATES: A vector of datetime objects representing the start dates of each period.
            %       ENDDATES: A vector of datetime objects representing the end dates of each period.
            %
            %   Output:
            %       OBJ: The updated AssetPortfolio object with the calculated AssetValues property.

            scenarioStartDate = scenarioData.ScenarioStartDate;
            frequency = string(obj.BenchmarkReturns.Frequency{1});
            initialBenchmarkReturn = 0;
            varNames = obj.BenchmarkReturns.Properties.VariableNames;
            Time = startPeriodDates(1);
            newRowTT = timetable(Time,frequency,initialBenchmarkReturn,'VariableNames',varNames);
            benchmarkReturns = sortrows([obj.BenchmarkReturns;newRowTT],'Time');
            tradeInstructions =struct.empty;
            
            
            numPeriods = length(startPeriodDates);
            assetValues = zeros(1, numPeriods);  % Preallocate for efficiency
            netCashflows = zeros(1,numPeriods);

            rateScenarios = scenarioData.getRateScenarios();

            portfolio = obj;
            marketData = portfolio.PortfolioMarketData;
            portfolioCountry = portfolio.PortfolioCountry;
            currentPortfolioValue = zeros(1,numPeriods);
            
            % Initialize with the initial value so we don't recalculate the
            % value or  store additional history
            currentPortfolioValue(1)= portfolio.InitialValue;
            assetValues(1) = portfolio.InitialValue; 
            
            
            %accessing info about the annuitants cashflows from the
            %asset portfolio associated with the annuitant of the portfolio but
            %what i don't want to the annuitant tp have an asset portfolio.
            
            owner.AssetPortfolio.Cashflows = paymentDates;
            annuitant = owner;

            for i = 1:numPeriods
                

                startPeriod=startPeriodDates(i);
                endPeriod=endPeriodDates(i);
                portfolioRebalanceDate = startPeriodDates(i);
                valuationDate = endPeriodDates(i);
                %valuationDate = datetime(valuationDate, 'Format','dd-MM-yyyy' );
                
                %purchase instruments  using money from the bank account
                fprintf("Rebalancing portfolio holdings: %s\n", datestr(portfolioRebalanceDate, 'ddmmyyyy'));
                fprintf("Date %d of %d: %s\n", i, numPeriods, datestr(portfolioRebalanceDate, 'ddmmyyyy'));
                
                [tradeInstructions,portfolio] = portfolio.TradingStrategy.determineTrade(portfolio,annuitant, portfolioRebalanceDate,marketData,scenarioData);
                portfolio  = portfolio.TradingStrategy.executeTrade(portfolio,tradeInstructions);
               
                fprintf("Valuing benchmark portfolio value: %s\n", datestr(valuationDate, 'ddmmyyyy'));
                fprintf("Date %d of %d: %s\n", i, numPeriods, datestr(valuationDate, 'ddmmyyyy'));


                % Get the return for this period (from AssetReturns)
                periodPortfolioReturn = getReturnForPeriod(portfolio, startPeriod, endPeriod);
                adjBenchmarkReturns(i) = periodPortfolioReturn;

                % Get the cashflow for this period (from Cashflows, ignore purchased annuity cashflows)
                netCashflows(i) = getCashflowForPeriod(portfolio,scenarioStartDate,startPeriod,endPeriod,paymentDates);

                % Calculate asset value at the end of the period using
                % the benchmark asset returns.
                % test value for comparison with detailed trading strategy
                % below.
                assetValues(i + 1) = assetValues(i) * (1 + periodPortfolioReturn) + netCashflows(i); % assumes cashflows occur at end of period

                %Process cashflows for the period through the bank accounts
                [bankAccount,bankAccountIndex] = portfolio.getBankAccount();
                annuityTradingType =  portfolio.TradingStrategy.getStrategyByType(TradingStrategyType.BuyAndHoldAnnuity);
                annuityType = annuityTradingType.AnnuityType;
                %[portfolioAnnuity,portfolioAnnuityIndex] = portfolio.getInstrument('FixedAnnuity');
                [portfolioAnnuity,portfolioAnnuityIndex] = portfolio.getInstrument(AnnuityType.getAlias(annuityType));
                bankAccount = portfolioAnnuity.payAnnuityToBank(startPeriod,endPeriod,bankAccount); %need to check if annuity exists
                bankAccount = bankAccount.deposit(netCashflows(i));

                portfolio.PortfolioHoldings{bankAccountIndex} = bankAccount;


                [currentPortfolioValue(i+1),portfolio] = portfolio.calculatePortfolioValue(valuationDate,marketData,scenarioData);
                
                %UPDATE BANK ACCOUNT VALUE WITH INTEREST
            end
            obj = portfolio;

            obj.AssetValues = assetValues(1:end);  % Store the updated asset values (excluding the initial value)
            obj.Cashflows = [0,netCashflows(1:end)];
            obj.CurrentPortfolioValue = currentPortfolioValue(1:end);

            initialBenchmarkReturn = 0;
            frequency = scenarioData.AssetReturnFrequency;
            varNames = obj.BenchmarkReturns.Properties.VariableNames;

            % Create the initial timetable with Benchmark_Returns
            adjBenchmarkReturnsTT = timetable(endPeriodDates', ...
                adjBenchmarkReturns', ...
                'VariableNames', {'Benchmark_Returns'});

            % Replicate the frequency value to match the number of rows
            frequencyColumn = repmat(frequency, size(adjBenchmarkReturnsTT, 1), 1);

            % Add the frequency column to the timetable
            adjBenchmarkReturnsTT = addvars(adjBenchmarkReturnsTT, frequencyColumn, 'NewVariableNames', {'Frequency'});

            % Create the new row timetable with Time, Frequency, and Benchmark_Returns
            Time = startPeriodDates(1);
            newRowTT = timetable(Time, initialBenchmarkReturn,frequency, 'VariableNames', {'Benchmark_Returns','Frequency'});

            % Concatenate the timetables and sort by Time
            benchmarkReturnsTT = sortrows([adjBenchmarkReturnsTT; newRowTT], 'Time');

            obj.PortfolioTimeTable =addvars(benchmarkReturnsTT,obj.AssetValues',obj.Cashflows','NewVariableNames',{'Portfolio Value -single asset strategy','Portfolio Net Cashflow'});
        end
        function obj = addInstrument(obj, instrument)
            % Method to add an instrument object to the portfolio
            obj.PortfolioHoldings{end+1} = instrument; 
            name = instrument.Name;
            disp("Instrument " + name + " addeded to the portfolio.")
            % obj.PortfolioHoldings = obj.PortfolioHoldings; % Crucial for updating the object when using cell array
        end
        function removeInstrument(obj, instrumentName)
            % Method to remove an asset by name from the portfolio
            index = find(strcmp({obj.PortfolioHoldings.Name}, instrumentName));
            if ~isempty(index)
                obj.PortfolioHoldings(index) = [];
            else
                error('Asset not found in the portfolio.');
            end
        end

        function [portfolioValue,obj] = calculatePortfolioValue(obj, valuationDate,marketDataProvider,scenarioDataProvider)
            % Calculate total portfolio value at valuationDate
            portfolioValue = 0;
            portfolioHoldings = obj.PortfolioHoldings;
            for i = 1:length(portfolioHoldings)
                currentValue = portfolioHoldings{i}.getCurrentValue(valuationDate,marketDataProvider,scenarioDataProvider);
                portfolioValue = portfolioValue + currentValue;

                % update historicaValues for each instrument

                portfolioHoldings{i} = portfolioHoldings{i}.updateHistoricalValues(valuationDate,currentValue);
                
                obj.PortfolioHoldings{i} = portfolioHoldings{i};
            end
        end
        function assetValues = getAssetValues(obj)
            assetValues = obj.AssetValues;
        end
        
        function periodReturn = getReturnForPeriod(obj,startDate,endDate)
            %GETRETURNFORPERIOD Calculate the total return for a specified period.
            %
            %   PERIODRETURN = GETRETURNFORPERIOD(OBJ, STARTDATE, ENDDATE) calculates the
            %   cumulative return of the asset portfolio represented by the AssetPortfolio
            %   object OBJ over the time period defined by STARTDATE and ENDDATE.
            %
            %   The function assumes that the 'AssetReturns' property of OBJ is a timetable
            %   containing returns for each day (or other appropriate time unit) within
            %   the specified period. The returns are assumed to be simple returns (not log returns).
            %
            %   Inputs:
            %       OBJ: The AssetPortfolio object.
            %       STARTDATE: A datetime object representing the beginning of the period.
            %       ENDDATE: A datetime object representing the end of the period.
            %
            %   Outputs:
            %       PERIODRETURN: The total return (as a decimal) achieved over the period.
            %
            %   Example:
            %       myPortfolio = AssetPortfolio(...);  % Create your AssetPortfolio object
            %       startDate = datetime('2023-01-01');
            %       endDate = datetime('2023-12-31');
            %       periodReturn = getReturnForPeriod(myPortfolio, startDate, endDate);

            % Detailed Explanation:
            %   1. Input Validation: The function first checks if the specified period
            %      (STARTDATE to ENDDATE) is at least as long as the return frequency present
            %      in the AssetReturns timetable. It also ensures that the period is not too
            %      short (less than one day).
            %   2. Return Filtering: It then filters the 'AssetReturns' timetable to include
            %      only the returns within the specified period.
            %   3. Total Return Calculation: Finally, it calculates the total return by
            %      compounding the individual returns over the period using the geometric mean.

            % Input validation for period length

            portfolioAssetReturns = obj.PortfolioMarketData.AssetReturns;
            % timePerPeriod = obj.PortfolioMarketData.AssetReturns.Time;
            % medianTimePerPeriod = median(diff(timePerPeriod)); % Typical duration between returns
            minPeriod = days(1); % Minimum allowed period

            % if medianTimePerPeriod > endDate - startDate
            %     error('The specified period is shorter than the return frequency.');
            % end

            if endDate - startDate < minPeriod
                error('The specified period is too short.');
            end

            % Filter AssetReturns to the relevant period
            % periodReturns = obj.AssetReturns(startDate:endDate, 'Return');
            portfolioPerSubPeriodReturns = portfolioAssetReturns((portfolioAssetReturns.Time>startDate & portfolioAssetReturns.Time<=endDate), 'Benchmark_Return');
            % Check if any returns are available for the period
            
            if isempty(portfolioPerSubPeriodReturns)
                portfolioPerSubPeriodReturns.Benchmark_Return = 0;
                disp('No returns are available for the specified period.',startDate,'  to  ', endDate);
            end

            
            % Calculate total return using geometric mean
            periodReturn = prod(1 + portfolioPerSubPeriodReturns.Benchmark_Return) - 1;
        end


        function cashflow = getCashflowForPeriod(obj,scenarioStartDate,lastValuationDate, valuationDate,paymentDates)
            %GETCASHFLOWFORPERIOD Calculate the net cashflow for a given period.
            %
            %   CASHFLOW = GETCASHFLOWFORPERIOD(OBJ, ENDDATE) calculates the net cashflow
            %   (inflows minus outflows) for the asset portfolio represented by the
            %   AssetPortfolio object OBJ at the specified ENDDATE.
            %
            %   The function assumes that the 'Cashflows' property of OBJ is a structure
            %   containing information about the annual cashflow amount, payment frequency,
            %   and inflation adjustments. It calculates the cashflow for the period ending
            %   on ENDDATE, taking into account the payment frequency and inflation.
            %
            %   Inputs:
            %       OBJ: The AssetPortfolio object.
            %       ENDDATE: A datetime object representing the end of the period for which
            %                to calculate the cashflow.
            %
            %   Outputs:
            %       CASHFLOW: The net cashflow (as a decimal) for the specified period.

            % Detailed Explanation:
            %   1. Cashflow Information Extraction: The function retrieves the relevant
            %      cashflow information (annual amount, frequency, inflation adjustments)
            %      from the 'Cashflows' property of the AssetPortfolio object OBJ.
            %   2. Cashflow Calculation: It then determines whether a cashflow payment occurs
            %      at the specified ENDDATE based on the payment frequency. If a payment
            %      occurs, it calculates the cashflow amount, adjusted for inflation. If no
            %      payment occurs, the cashflow is zero.
            %   3. This version of the code is hard wired to exclude purchased annuity cashflows
            %      becasue the function is only used with a simple asset
            %      portfooio strategy.  TODO  The  method need to be updated to
            %      allow for context within the portfolio object to
            %      determine which cashlows to include and output all the
            %      cashflows in a structure rather than summariseing them.
            %   4. Output: The function returns the calculated CASHFLOW value Inflated from the scenariostartdate to the end date of the period by years..


            % Extract cashflow information (assumes Cashflows is a struct)
            annualContribution = obj.CashflowsInputData.Contribution;
            contributionFrequency = obj.CashflowsInputData.ContributionFrequency;
            annualGuaranteedPayment = obj.CashflowsInputData.GuaranteedPayment;
            guaranteedPaymentFrequency = obj.CashflowsInputData.GuaranteedPaymentFrequency;
            annualPortfolioPayment = obj.CashflowsInputData.PortfolioPayment;
            portfolioPaymentFrequency = obj.CashflowsInputData.PortfolioPaymentFrequency;
            inflationRate = obj.CashflowsInputData.InflationRateAssumption;

            cashflow = obj.CashflowsInputData.DefaultCashFlow; % Initialize net cashflow

            % Contribution cashflow
            if obj.isCashFlowDate(lastValuationDate, valuationDate,paymentDates,'contributionEndDates')
                cashflow = cashflow + utilities.CashFlowUtils.adjustForInflation(annualContribution / utilities.CashFlowUtils.getPaymentsPerYear(contributionFrequency), inflationRate, years(valuationDate - scenarioStartDate));
            end


            % % Guaranteed payment cashflow
            % if obj.isCashFlowDate(lastValuationDate, valuationDate, paymentDates,'annuityPaymentEndDates')
            %     % GuaranteedPaymentStartDate = obj.CashflowsData.annuityPaymentEndDates(1);
            % 
            %     cashflow = cashflow + utilities.CashFlowUtils.adjustForInflation(annualGuaranteedPayment / utilities.CashFlowUtils.getPaymentsPerYear(guaranteedPaymentFrequency), inflationRate, years(valuationDate - scenarioStartDate));
            % end

            % Portfolio owner payment cashflow (outflow, hence subtracted)
            if obj.isCashFlowDate(lastValuationDate, valuationDate, paymentDates,'ownerPaymentEndDates')
                
                cashflow = cashflow - utilities.CashFlowUtils.adjustForInflation(annualPortfolioPayment / utilities.CashFlowUtils.getPaymentsPerYear(portfolioPaymentFrequency), inflationRate, years(valuationDate - scenarioStartDate));
            end
        end

        function adjustedAmount = adjustForInflation(obj,amount, inflationRate, years)
            %ADJUSTFORINFLATION Adjust a cash flow amount for inflation.
            %
            %   ADJUSTEDAMOUNT = ADJUSTFORINFLATION(AMOUNT, INFLATIONRATE, YEARS)
            %   adjusts the AMOUNT for inflation over the specified number of YEARS,
            %   using the given annual INFLATIONRATE.
            %
            %   Inputs:
            %       AMOUNT: The original cash flow amount.
            %       INFLATIONRATE: The annual inflation rate (as a decimal).
            %       YEARS: The number of years over which to apply inflation.
            %
            %   Outputs:
            %       ADJUSTEDAMOUNT: The cash flow amount adjusted for inflation.

            % Simple inflation adjustment (compound interest formula)
            adjustedAmount = amount * (1 + inflationRate)^years;
        end
                
        function isCashflow = isCashFlowDate(obj,lastValuationDate,valuationDate, paymentDatesAllTypes, cashflowType)
            %ISCASHFLOWDATE Check if a date is a cashflow date of a specific type.
            %
            %   ISCASHFLOW = ISCASHFLOWDATE(ENDDATE, PAYMENTDATES, CASHFLOWTYPE) checks if
            %   the ENDDATE falls on a cashflow date of the type specified by CASHFLOWTYPE.
            %
            %   Inputs:
            %       ENDDATE: A datetime object representing the date to check.
            %       PAYMENTDATES: A structure array containing fields for different cashflow types,
            %                     where each field is an array of datetime objects representing the
            %                     payment dates for that cashflow type.
            %       CASHFLOWTYPE: A string indicating the type of cashflow ('ownerPaymentEndDates',
            %                     'contributionDates', 'guaranteedPaymentDates', etc.).
            %
            %   Outputs:
            %       ISCASHFLOW: A logical value (true or false) indicating whether ENDDATE is a
            %                   cashflow date of the specified CASHFLOWTYPE.

            % Check if the cashflow type is valid
            if ~isfield(paymentDatesAllTypes, cashflowType)
                error('Invalid cashflow type: %s', cashflowType);
            end

            % Check if endDate is in the specified payment dates
            paymentDates = paymentDatesAllTypes.(cashflowType);


           isCashflow = utilities.CashFlowUtils.hasPaymentOccurredBetweenValuationDates(lastValuationDate, valuationDate, paymentDates); 
           
            
            
           % ismember(endDate, paymentDatesAllTypes.(cashflowType));
        end
        function [bankAccount,bankAccountIndex] = getBankAccount(obj)
            %GETBANKACCOUNT Retrieve the BankAccount object from the portfolio.
            %
            %   BANKACCOUNT = GETBANKACCOUNT(OBJ) searches the PortfolioHoldings cell array
            %   of the AssetPortfolio object OBJ and returns the first BankAccount object
            %   it finds. If no BankAccount is present, it throws an error.
            %
            %   Example:
            %       myPortfolio = AssetPortfolio(...);
            %       myBankAccount = myPortfolio.getBankAccount();

            for i = 1:numel(obj.PortfolioHoldings)
                if isa(obj.PortfolioHoldings{i}, 'BankAccount')
                    bankAccount = obj.PortfolioHoldings{i};
                    bankAccountIndex = i;
                    return;
                end
            end
            error('Bank account not found in the portfolio.');
        end
        function [instrument,instrumentIndex,found] = getInstrument(obj,type)
            %GETBANKACCOUNT Retrieve the BankAccount object from the portfolio.
            %
            %   BANKACCOUNT = GETBANKACCOUNT(OBJ) searches the PortfolioHoldings cell array
            %   of the AssetPortfolio object OBJ and returns the first BankAccount object
            %   it finds. If no BankAccount is present, it throws an error.
            %
            %   Example:
            %       myPortfolio = AssetPortfolio(...);
            %       myBankAccount = myPortfolio.getBankAccount();

            for i = 1:numel(obj.PortfolioHoldings)
                if isa(obj.PortfolioHoldings{i}, type)
                    instrument = obj.PortfolioHoldings{i};
                    instrumentIndex = i;
                    found = true;
                    return;
                end
            end
            
            instrument =[];
            instrumentIndex = 0;
            found = false;
            disp("Instrument " + type + " not found in the portfolio.");
        end

    end
end