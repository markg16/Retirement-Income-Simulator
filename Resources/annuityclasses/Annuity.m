classdef Annuity < Instrument
    %ANNUITY Represents a financial annuity contract.
    %   This class models an annuity, a contract where a person (the annuitant)
    %   receives regular payments in exchange for an upfront investment. It 
    %   implements the `Instrument` interface, providing functionality for 
    %   calculating the annuity's current value.
    %  Subclasses of annuity  such as LifeTime Joint Fixed will implement
    %  specifics of Annuity contracts. 
    % TODO consider whether all annuity subclasses could inherit the
    % getCurrentValue or some basic PV methods.

    properties
        Annuitant                % Associated Person object this provides the mortality factors eg age gender life tables.
        AnnuityCountry           % country currency in which payments are denominated
        GuaranteedPayment        % Initial annual guaranteed payment amount
        GuaranteedPaymentIncreaseRate   % guaranteed rate of increase if any
        IncomeDeferment          % Deferment period in years (if any)
        MaxNumPayments           % Maximum number of annuity payments
        PaymentFrequency         % Frequency of annuity payments (e.g., 'monthly', 'annually')
        AnnuityPaymentDates      % Array of datetime objects for payment dates (optional)
        IndexationDates
        EffectiveInflationDates
        CashFlowInflationRules
        AnnuityCashflowStrategy
        PurchasePrice
        HistoricalGuaranteedPaymentLevel
        
        
    end
    % ANNUITY Constructor for the Annuity class.
    %   Initializes the Annuity object with basic details.
    methods
        function obj = Annuity(annuitant, guaranteedPayment,guaranteedPaymentIncreaseRate, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency, annuityPaymentDates) %Annuity(annuitant,startDate)
            
            switch annuitant.Gender
                case utilities.GenderType.Male
                    annuitant.Gender = 'Male';
                case utilities.GenderType.Female
                    annuitant.Gender = 'Female';
            end
            obj.Annuitant = annuitant;
            obj.Name = "Annuity";
            obj.StartDate = annuityStartDate;
            obj.Quantity = 1;
            obj.InitialPrice = 0;
            obj.CurrentPrice = 0; % Initial price is current price on initiation of the object
            
           obj.AnnuityCountry = annuitant.Country;
           obj.GuaranteedPayment = guaranteedPayment;
           obj.GuaranteedPaymentIncreaseRate = guaranteedPaymentIncreaseRate;
           obj.IncomeDeferment = incomeDeferment;
           obj.MaxNumPayments = maxNumPayments; % annual payments assumed
           obj.PaymentFrequency = paymentFrequency;
           % Optionally, set annuity payment dates
           if nargin == 8   % Check if annuityPaymentDates were provided
               obj.AnnuityPaymentDates = annuityPaymentDates;
           else
               % If not provided, generate them based on frequency and start date
               dateLastAnnuityPayment = annuityStartDate + years(maxNumPayments);
               dateFirstAnnuityPayment = annuityStartDate + years(incomeDeferment);
            

               obj.AnnuityPaymentDates = utilitiies.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment,paymentFrequency);
               
           end
           %set up cashflowinflation spec for the annuity
           indexationFrequency = utilities.FrequencyType.Annually;
           
           indexationMonthDay = datetime(0,6,30);
           indexationMonthDay.TimeZone = 'Australia/Sydney';
           referenceTime = utilities.DefaultSimulationParameters.defaultReferenceTime;
           indexationMonthDay = indexationMonthDay+referenceTime ;

           InflationPublishingLag = 3 ; %3 months           
           effectiveInflationLag = calmonths(InflationPublishingLag);

           [indexationDates,effectiveInflationDates] = generateInflationDates(obj,annuityStartDate,indexationFrequency,indexationMonthDay,effectiveInflationLag);
           cashFlowInflationType = utilities.CashFlowInflationType.Guaranteed;
           obj.IndexationDates = indexationDates; 
           obj.EffectiveInflationDates = effectiveInflationDates;

           inflationRules = struct;
           inflationRules.indexationDates = obj.IndexationDates;
           inflationRules.effectiveInflationDates = obj.EffectiveInflationDates;  
           
           

           %set up the inflation rate curve
            type = 'zero';
            settle = annuityStartDate;
            dates = calyears([1,3,5,10,20,40]);
            compounding = -1;
            basis = 0;
            rates = ones(1,length(dates))*guaranteedPaymentIncreaseRate;
            inflationRateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);
          
           obj.CashFlowInflationRules = CashFlowInflationSpec(cashFlowInflationType,inflationRateCurve,inflationRules);


           obj = obj.updateHistoricalValues(annuityStartDate,0);
           obj.HistoricalGuaranteedPaymentLevel = obj.updateHistoricalGuaranteedPaymentLevel(annuityStartDate,guaranteedPayment);
        end
        function value = getCurrentValue(obj,valuationDate, marketData, scenarioData)
            %GETCURRENTVALUE Calculates the annuity's value at a specific date.
            %   
            % The method is providced to meet interface definition

            inflationRates = 0;
            country = obj.getannuityCountry();
            rateScenario = scenarioData.getRateScenarios();

            % Extract rate curve and current date
            % tradeDate.TimeZone = '';
            rateCurve = marketData.getRateCurveForScenario(valuationDate, country, rateScenario);
            value = presentValue(obj,rateCurve,inflationRates,valuationDate);

            % value = obj.CurrentPrice; %default value
        end
        function annuityCountry = getAnnuityCountry(obj)
              %GETANNUITYCOUNTRY Returns the country associated with the annuity.
              % this will be needed to determine the mortalit tables ,
              % interest rate curves etc. 
            annuityCountry = obj.AnnuityCountry;
        end

        function bankAccount= payAnnuityToBank(obj,lastValuationDate,valuationDate,bankAccount)

            payment = obj.getAnnuityPaymentAmount(lastValuationDate,valuationDate);
            bankAccount = bankAccount.deposit(payment);

        end

        function payment = getAnnuityPaymentAmount(obj, lastValuationDate,valuationDate)
            %GETANNUITYPAYMENTAMOUNT Calculates the annuity payment due on a given date.
            %
            %   payment = getAnnuityPaymentAmount(obj, valuationDate) returns the annuity
            %   payment amount (if any) due on the specified valuationDate. The payment
            %   is adjusted for inflation based on the guaranteed payment increase rate.
            %
            %   Inputs:
            %       obj           - The Annuity object.
            %       valuationDate - datetime: The date for which the payment amount is calculated.
            %
            %   Outputs:
            %       payment       - double: The annuity payment amount due on the valuationDate.
            %                      Returns 0 if no payment is due.
            %
            %   Note:
            %       - This function assumes that the annuity payment dates have been
            %         pre-calculated and stored in the obj.AnnuityPaymentDates property.
            %       - The payment amount is adjusted for inflation based on the
            %         guaranteed payment increase rate and the time elapsed since the
            %         annuity start date.
            %
            %   Example:
            %       payment = myAnnuity.getAnnuityPaymentAmount(datetime('2025-01-01'));


            % Extract relevant properties from the Annuity object
            annuityStartDate = obj.StartDate;
            paymentDates = obj.AnnuityPaymentDates; 
            cashFlowInflationRules = obj.CashFlowInflationRules;
            %paymentFrequency = obj.PaymentFrequency;
            %gtdPaymentIncreaseRate = obj.GuaranteedPaymentIncreaseRate;
            % % get base inflated value from obj.HistoricalGuaranteedPaymentLevel
            payment = obj.GuaranteedPayment;

            % Calculate payments per year based on frequency
            %paymentPerPeriod = utilities.CashFlowUtils.getPaymentsPerYear(paymentFrequency);

            % Calculate time since annuity start in years
            %timeSinceStart = years(valuationDate - annuityStartDate);

            % Check if the valuationDate is a valid payment date
            %if utilities.CashFlowUtils.isCashFlowDate(valuationDate, paymentDates)

            if utilities.CashFlowUtils.hasPaymentOccurredBetweenValuationDates(lastValuationDate,valuationDate, paymentDates)
                % Adjust payment for inflation

                payment = cashFlowInflationRules.adjustValue(payment,valuationDate,annuityStartDate);
                %payment = utilities.CashFlowUtils.adjustForInflation(payment / paymentPerPeriod, gtdPaymentIncreaseRate, timeSinceStart);
            else
                payment = 0; % No payment on this date
            end           
        end

        function inflatedCashFlows = generateCashFlows(obj, cashFlowDates, varargin)
            % Basic cash flow generation

            % Handle varargin using inputParser
            p = inputParser;

            % Required parameters
            addRequired(p, 'obj', @(x) isa(x, 'Annuity')); % Or your specific annuity class
            addRequired(p, 'cashFlowDates', @isdatetime);
            

            % Optional parameter

            addParameter(p, 'valuationDate', datetime('now'), @isdatetime);
            addParameter(p,'futureInflationRates',0,@isadouble);


            if obj.AnnuityType == "SingleLifeTime"
                defaultMortalityTable = obj.Annuitant.FutureMortalityTable;
                addParameter(p, 'MortalityTable', defaultMortalityTable, @(x) isa(x, 'MortalityTable'));
            else
                addParameter(p, 'MortalityTable', [], @(x) isa(x, 'MortalityTable'));
            end

            parse(p, obj, cashFlowDates, varargin{:});

            annuity = p.Results.obj;
            valuationDate = p.Results.valuationDate;
            cashFlowInflationRules = obj.CashFlowInflationRules;

            % Access parsed inputs (now directly from p.Results)
            paymentsPerYear = utilities.CashFlowUtils.getPaymentsPerYear(annuity.PaymentFrequency);
            cashFlows = p.Results.obj.GuaranteedPayment/paymentsPerYear * ones(size(p.Results.cashFlowDates));
            % get base inflated value from obj.HistoricalGuaranteedPaymentLevel

            if ~isempty(p.Results.MortalityTable)
                futureMortalityTable = p.Results.MortalityTable;
                
                % Incorporate Survivorship Probabilities
                survivalProbabilities = calculateSurvivalProbabilities(annuity, futureMortalityTable, valuationDate);
                cashFlows = cashFlows .* survivalProbabilities;
            end

            %Adjust for Inflation (if applicable)
            %inflatedCashFlows = adjustForInflation(cashFlows, inflationRate, futureCashFlowDates, valuationDate);

            inflatedValues = cashFlowInflationRules.adjustValue(cashFlows,cashFlowDates,valuationDate);
            inflatedCashFlows = inflatedValues;


        end

        function cashFlowDates = generateCashFlowDates(obj,valuationDate)
           cashFlowDates= obj.AnnuityPaymentDates(obj.AnnuityPaymentDates > valuationDate);

        end

        function [indexationDates,effectiveInflationDates] = generateInflationDates(obj,startDate,indexationFrequency,indexationMonthDay,effectiveInflationLag)
            
            oneIndexationPeriod = utilities.DateUtilities.convertFrequencyToDuration(indexationFrequency);
            maxIndexations = obj.MaxNumPayments+obj.IncomeDeferment;

           [firstIndexationDate, firstEffectiveInflationDate] = utilities.DateUtilities.calculateNextIndexationDate(startDate, indexationMonthDay, effectiveInflationLag);
            
           dateLastIndexation = firstIndexationDate + years(maxIndexations);
           dateLastEffectiveInflation = firstEffectiveInflationDate + years(maxIndexations);
           while dateLastIndexation > obj.AnnuityPaymentDates(end) 
               dateLastIndexation = dateshift(dateLastIndexation - oneIndexationPeriod, 'end', 'month');
               dateLastEffectiveInflation = dateshift(dateLastEffectiveInflation - oneIndexationPeriod, 'end', 'month');
           end
           
           indexationDates = utilities.generateDateArrays(firstIndexationDate, dateLastIndexation + oneIndexationPeriod,indexationFrequency); % adding oneindexation period as the generateDateArrays function treats the date as the end of the period of last indexation
           effectiveInflationDates = utilities.generateDateArrays(firstEffectiveInflationDate, dateLastEffectiveInflation + oneIndexationPeriod,indexationFrequency);

        end

        function discountFactors = calculateDiscountFactors(obj,rateCurve, futureCashFlowDates, valuationDate)

            numPaymentsMade = sum(futureCashFlowDates < valuationDate);
            discountFactors = rateCurve.getDiscountFactors(futureCashFlowDates((numPaymentsMade+1):end));

        end

        function presentValue = presentValue(obj,rateCurve,inflationRates,valuationDate)

            % 1. Generate Cash Flow Dates
            futureCashFlowDates = generateCashFlowDates(obj,valuationDate);
            
            % 2. Generate Cash Flows (including survivorship if applicable)
            cashFlows = generateCashFlows(obj,futureCashFlowDates,'valuationDate',valuationDate);            

            % 3. Calculate Discount Factors
            discountFactors = calculateDiscountFactors(obj,rateCurve, futureCashFlowDates, valuationDate);

            

            % 5. Calculate Present Value
            presentValue = sum(cashFlows .* discountFactors);


        end


        function presentValues = present_value(obj, futureMortalityTable,rateCurve, ...
                inflationRate, valuationDates)

           if ~isa(rateCurve, 'marketdata.RateCurveKaparra')
                error('Input must be a RateCurveKaparra object');
           end 

           numValuationDates = numel(valuationDates);
           presentValues = zeros(1, numValuationDates);% Preallocate for efficiency

            for i = 1:numValuationDates

                valuationDate = valuationDates(i);

                presentValue = obj.presentValue(rateCurve,inflationRate,valuationDate);
                presentValues(i) = presentValue;

            end

        end

        function obj = updateHistoricalGuaranteedPaymentLevel(obj,currentDate,updatedGtdPaymentLevel)
            valueHeader = 'Guaranteed Payment Level';
                historicalValues = obj.HistoricalGuaranteedPaymentLevel;
                newTimeTable = timetable(currentDate, updatedGtdPaymentLevel, 'VariableNames', {valueHeader});
                historicalValues = [historicalValues ; newTimeTable];
                obj.HistoricalGuaranteedPaymentLevel  = historicalValues;


        end
       
        
      
    end
end
        

   