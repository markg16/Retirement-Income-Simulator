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
        function obj = Annuity(annuitant, guaranteedPayment,guaranteedPaymentIncreaseRate, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency) %Annuity(annuitant,startDate)
            
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
           % The Annuity object now calls a private helper method to generate its
           % own payment dates, ensuring the logic is always applied consistently.
           obj.AnnuityPaymentDates = obj.generatePaymentDates();
           % % Optionally, set annuity payment dates
           % if nargin == 8   % Check if annuityPaymentDates were provided
           %     obj.AnnuityPaymentDates = annuityPaymentDates;
           % else
           %     % If not provided, generate them based on frequency and start date
           %     dateLastAnnuityPayment = annuityStartDate + years(maxNumPayments);
           %     dateFirstAnnuityPayment = annuityStartDate + years(incomeDeferment);
           % 
           % 
           %     obj.AnnuityPaymentDates = utilitiies.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment,paymentFrequency);
           % 
           % end
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

        function result = value(obj, request)
            % Main valuation method that takes a request object and delegates
            % to the appropriate private calculation method.

            mustBeA(request, 'InstrumentValuationRequest');

            % Use the class of the request to determine which analysis to run
            switch class(request)
                case 'AnnuitySensitivityRequest'
                    result = obj.valueSensitivity(request);

                case 'AnnuityProjectionRequest'
                    result = obj.valueProjection(request);

                otherwise
                    error('Annuity:UnknownRequest', 'The provided request type is not supported.');
            end
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
           
            % % get base inflated value from obj.HistoricalGuaranteedPaymentLevel
            payment = obj.GuaranteedPayment;

           

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
            % ... (input parser remains the same) ...
            p = inputParser;
            addParameter(p, 'valuationDate', datetime('now'), @isdatetime);

            % Set a default mortality table. If the annuity is 'Fixed', this will be ignored later.
            defaultMortalityTable = [];
            if obj.AnnuityType ~= "Fixed"
                defaultMortalityTable = obj.Annuitant.FutureMortalityTable;
            end
            addParameter(p, 'MortalityTable', defaultMortalityTable, @(x) isa(x, 'MortalityTable'));

            % 2. The parse function should ONLY be given 'varargin'.
            parse(p, varargin{:});

            % 3. The required arguments 'obj' and 'cashFlowDates' are used directly.
            %    The optional arguments are now correctly retrieved from p.Results.

            valuationDate = p.Results.valuationDate;
            futureMortalityTable = p.Results.MortalityTable;
            paymentsPerYear = double(obj.PaymentFrequency);
            cashFlows = obj.GuaranteedPayment / paymentsPerYear * ones(size(cashFlowDates));

            if obj.AnnuityType ~= "Fixed"
                if ~isempty(p.Results.MortalityTable)
                    futureMortalityTable = p.Results.MortalityTable;

                    % --- THIS IS THE KEY CHANGE ---
                    % Make a single, clean call to the new utility.
                    ageAtValuation = utilities.AgeCalculationUtils.getAgeAtDate(obj.Annuitant, valuationDate);
                    survivalProbsTT = utilities.LifeTableUtilities.calculateSurvivalProbabilitiesTT(...
                        futureMortalityTable, ...
                        obj.Annuitant.Gender, ...
                        ageAtValuation, ...
                        valuationDate,...
                        cashFlowDates);

                    % Apply the survival probabilities to the cash flows.
                    cashFlows = cashFlows .* survivalProbsTT.SurvivalProbability';
                end
            end

            % Adjust for Inflation
            inflatedCashFlows = obj.CashFlowInflationRules.adjustValue(cashFlows, cashFlowDates, valuationDate);
        end

        

        function cashFlowDates = generateCashFlowDates(obj,valuationDate)
           cashFlowDates= obj.AnnuityPaymentDates(obj.AnnuityPaymentDates >= valuationDate);

        end

        function [indexationDates,effectiveInflationDates] = generateInflationDates(obj,startDate,indexationFrequency,indexationMonthDay,effectiveInflationLag)
            
            oneIndexationPeriod = utilities.DateUtilities.convertFrequencyToDuration(indexationFrequency);
            maxIndexations = obj.MaxNumPayments+obj.IncomeDeferment;

           [firstIndexationDate, firstEffectiveInflationDate] = utilities.DateUtilities.calculateNextIndexationDate(startDate, indexationMonthDay, effectiveInflationLag);
           dateLastIndexation = utilities.DateUtilities.dateShiftKaparra(firstIndexationDate ,+ years(maxIndexations),'end','month');
           dateLastEffectiveInflation = utilities.DateUtilities.dateShiftKaparra(firstEffectiveInflationDate, + years(maxIndexations), 'end', 'month');

         
           while dateLastIndexation > obj.AnnuityPaymentDates(end) 

               dateLastIndexation = utilities.DateUtilities.dateShiftKaparra(dateLastIndexation, - oneIndexationPeriod,'end','month');
               dateLastEffectiveInflation = utilities.DateUtilities.dateShiftKaparra(dateLastEffectiveInflation, - oneIndexationPeriod, 'end', 'month');

               
           end
          
           % adding oneindexation period as the generateDateArrays function treats the date as the end of the period of last indexation
           indexationDates = utilities.DateUtilities.generateDateArrays(firstIndexationDate, utilities.DateUtilities.dateShiftKaparra(dateLastIndexation, oneIndexationPeriod,'end','month'),indexationFrequency); 
          
           effectiveInflationDates = utilities.DateUtilities.generateDateArrays(firstEffectiveInflationDate, utilities.DateUtilities.dateShiftKaparra(dateLastEffectiveInflation, oneIndexationPeriod, 'end', 'month'),indexationFrequency);

        end

        function discountFactors = calculateDiscountFactors(obj,rateCurve, futureCashFlowDates, valuationDate)

            numPaymentsMade = sum(futureCashFlowDates < valuationDate);
            discountFactors = rateCurve.getDiscountFactors(futureCashFlowDates((numPaymentsMade+1):end));
            discountFactorToValuationDate = rateCurve.getDiscountFactors(valuationDate);
            discountFactors = discountFactors/discountFactorToValuationDate; % getDiscountFactors provides discounts relative to settle date. Need to bring forward from settle date to valuation date

        end

        function presentValue = presentValue(obj,rateCurve,inflationRates,valuationDate)
            % TODO work out how to bring in actual inflation rates for CPI
            % linked annuities
            %TODO need to allow a MortalityTable to be passed that is not
            %specific to the annuitant to allow product provider mortality
            %vs annuitant perspective

            % 1. Generate Cash Flow Dates
            futureCashFlowDates = generateCashFlowDates(obj,valuationDate); % assumes next payment is on the valuation date
            
            % 2. Generate Cash Flows (including survivorship if applicable)
            %cashFlows = generateCashFlows(obj,futureCashFlowDates,'valuationDate',valuationDate);
            cashFlows = generateCashFlows(obj,futureCashFlowDates,'valuationDate',valuationDate);
            % 3. Calculate Discount Factors
            discountFactors = calculateDiscountFactors(obj,rateCurve, futureCashFlowDates, valuationDate);

            

            % 5. Calculate Present Value
            presentValue = sum(cashFlows .* discountFactors);


        end


        function presentValues = present_value(obj, futureMortalityTable,rateCurve, ...
                inflationRate, valuationDates)

            %TODO this function is deprecated by the annuity
            %valuationrequest interface

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


    methods (Access = private)
        function paymentDates = generatePaymentDates(obj)
            % This private helper encapsulates the logic for creating the payment date vector.

            % 1. Determine the first payment date by shifting the start date by the deferment period.
            dateFirstAnnuityPayment = obj.StartDate + years(obj.IncomeDeferment);

            % 2. Determine the last payment date based on the number of payments and frequency.
            freqValue = double(obj.PaymentFrequency);
            numMonths = (obj.MaxNumPayments - 1) * (12 / freqValue);
            dateLastAnnuityPayment = dateFirstAnnuityPayment + calmonths(numMonths);

            % 3. Call the central utility to generate the date array.
            paymentDates = utilities.DateUtilities.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment, obj.PaymentFrequency);
        end
        function resultsTable = valueSensitivity(obj, request)
            % This private method contains the logic from your AnnuityValuationEngine.
            % It runs a 2D sensitivity analysis.

            engine = AnnuityValuationEngine(obj.Person, obj.AnnuityType, request.RateCurveProvider);
            resultsTable = engine.runAnnuitySensitivityAnalysis(request.XAxisEnum, request.LineVarEnum);
        end

        function resultsTable = valueProjection(obj, request)
            % This private method contains the logic from your AnnuityValuationEngine.
            % It runs a 2D sensitivity analysis.

            resultsTable = 'Valuation Projectio not yet implemented. see roll forward service';
        end

        function stochasticResults = valueStochastic(obj, request)
            % --- FUTURE IMPLEMENTATION ---
            % This is where your Monte Carlo logic would go.

            % scenarioGenerator = request.ScenarioGenerator;
            % numPaths = request.NumPaths;
            % results = zeros(numPaths, 1);
            % for i = 1:numPaths
            %     rateCurvePath = scenarioGenerator.getNewPath();
            %     results(i) = obj.presentValue(rateCurvePath, ...);
            % end
            % stochasticResults.Mean = mean(results);
            % stochasticResults.StdDev = std(results);
            % stochasticResults.Distribution = results;
            stochasticResults = 'Stochastic valuation not yet implemented.';
        end
    end
end
        

   