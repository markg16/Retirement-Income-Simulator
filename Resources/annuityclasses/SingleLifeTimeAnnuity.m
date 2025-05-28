
classdef SingleLifeTimeAnnuity < Annuity
    properties
        AnnuityType  = "SingleLifeTime"
        % GuaranteedPayment      % Annual guaranteed payment amount
        % AnnuityStartDate       % Date when annuity payments start
        % IncomeDeferment        % Deferment period in years (if any)
        % MaxNumPayments         % Maximum number of annuity payments
        % PaymentFrequency       % Frequency of annuity payments (e.g., 'monthly', 'annually')
        % AnnuityPaymentDates    % Array of datetime objects for payment dates (optional)% ... (properties and methods for FixedAnnuity)
        % AnnuityCashflowStrategy
        % PurchasePrice
        % AnnuityValuations

    
    end

    methods
        function obj = SingleLifeTimeAnnuity(person, guaranteedPayment, guaranteedPaymentIncreaseRate, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency, annuityPaymentDates)
            % Constructor for Single Life TIme Annuity

            if nargin == 7
                % If not provided, generate them based on frequency and start date
                dateLastAnnuityPayment = annuityStartDate + years(maxNumPayments);


                annuityPaymentDates = utilities.generateDateArrays(annuityStartDate, dateLastAnnuityPayment,paymentFrequency);
            end


            obj@Annuity(person, guaranteedPayment, guaranteedPaymentIncreaseRate, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency, annuityPaymentDates);  % Call the Annuity superclass constructor

            obj.Name = "SingleLifeTimeAnnuity";
           
        end

        function currentValue = getCurrentValue(obj, valuationDate, marketDataProvider, scenarioDataProvider)
            %GETCURRENTVALUE Computes the current value of the fixed annuity.
            %
            %   CURRENTVALUE = GETCURRENTVALUE(OBJ, VALUATIONDATE, MARKETDATAPROVIDER, SCENARIODATAPROVIDER)
            %   computes the present value of the fixed annuity (OBJ) at the specified
            %   VALUATIONDATE, using the discount factors from the MARKETDATAPROVIDER,
            %   inflation rate from SCENARIODATAPROVIDER, and optional mortality data
            %   (not implemented in this example).
            %
            %   Inputs:
            %       OBJ: The FixedAnnuity object.
            %       VALUATIONDATE: A datetime object representing the date at which to
            %                      calculate the present value.
            %       MARKETDATAPROVIDER: A MarketDataProvider object for accessing rate curves.
            %       SCENARIODATAPROVIDER: A ScenarioDataProvider object for accessing scenario-specific data (e.g., inflation rate).
            %
            %   Outputs:
            %       CURRENTVALUE: The present value of the fixed annuity at VALUATIONDATE.

            
            country = obj.getAnnuityCountry();
             %Get rateCurve for valuation date.  
            if ~isempty(marketDataProvider)
                 %Get rateCurve from marketdataprovidere.  
                
                rateCurve = marketDataProvider.extractRateCurve(valuationDate,country, scenarioDataProvider);
            else
               
                %Default rateCUrve .
                type = 'Discount';
                settle = valuationDate;
                dates = obj.AnnuityPaymentDates;
                compounding = -1;
                basis = 0;
                rates = ones(1,length(dates));
               
                rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);
            end
            if ~isempty(scenarioDataProvider)
                 % Get inflation rate from the scenario data provider
                 inflationRate = scenarioDataProvider.getInflationAssumption();

            else

                inflationRate = 0;
            end

           
            % get folder for the mortality tables
            %TODO set up reference to cachefolder or lifetable folder.
            %SHould be a reference to person object

            if obj.AnnuityType == "SingleLifeTime"
                futureMortalityTable = obj.Annuitant.FutureMortalityTable;
            else
                disp("SingleLifeTime Annuity object being set up with incorrect type")
                error("SingleLifeTime Annuity object being set up with incorrect type");
            end

            % Calculate present value (delegate to the existing present_value method)
            %currentValue = obj.present_value(futureMortalityTable,rateCurve, inflationRate,valuationDate );
            currentValue = obj.presentValue(rateCurve,inflationRate,valuationDate);
        end


        % function cashFlows = generateCashFlows(obj, futureMortalityTable,valuationDate)
        %     % 1. Generate basic cash flows (from superclass)
        %     cashFlows = generateCashFlows@Annuity(obj, valuationDate);
        % 
        %     % 2. Incorporate Survivorship Probabilities
        %     survivalProbabilities = calculateSurvivalProbabilities(obj,futureMortalityTable, valuationDate);
        %     cashFlows = cashFlows .* survivalProbabilities; 
        % end

        function survivalProbabilities = calculateSurvivalProbabilities(obj,futureMortalityTable, valuationDate)

            annuityStartDate = obj.StartDate;
            gender = obj.Annuitant.Gender;
            startAge = obj.Annuitant.Age;  % assumes the person object only stores the start age.
            ageFinalAnnuityPayment = startAge + calyears(utilities.DateUtilities.calculateYearDiff(annuityStartDate,obj.AnnuityPaymentDates(end)));
            valuationAge = startAge + calyears(utilities.DateUtilities.calculateYearDiff(annuityStartDate,valuationDate));
            paymentsPerYear = utilities.CashFlowUtils.getPaymentsPerYear(obj.PaymentFrequency);
           
            paymentDatesToValue = obj.AnnuityPaymentDates(obj.AnnuityPaymentDates > valuationDate);
            
            survivorshipProbabilitiesFull = futureMortalityTable.getSurvivorshipProbabilities(gender,valuationAge,ageFinalAnnuityPayment+1); % returns a vector of probabilities for all future ages
            survivalProbabilities = futureMortalityTable.getSurvivorshipProbabilitiesForEachPaymentDate(survivorshipProbabilitiesFull,paymentDatesToValue,paymentsPerYear);

        end


    %     function presentValues = present_value(obj, futureMortalityTable,rateCurve, ...
    %             inflationRate, valuationDates)
    % 
    %         %   PRESENTVALUES = PRESENT_VALUE(OBJ, BASELIFETABLEFOLDER, RATECURVES, CURVENAME, INFLATIONRATE, VALUATIONDATES)
    %         %   computes the present value of the annuity represented by the Annuity object OBJ
    %         %   at each date specified in VALUATIONDATES. The calculation uses the discount
    %         %   factors from the RATECURVES dictionary, the inflation rate INFLATIONRATE,
    %         %   and optionally, mortality data from the BASELIFETABLEFOLDER (not implemented in this example).
    %         %
    %         %   Inputs:
    %         %       OBJ: The Annuity object.
    %         %       BASELIFETABLEFOLDER: Path to the folder containing base life tables (optional, not used in this example).
    %         %       RATECURVES: A dictionary of RateCurveKaparra objects, where keys are curve names and values are RateCurveKaparra objects.
    %         %       CURVENAME: The name of the curve to use from RATECURVES.
    %         %       INFLATIONRATE: The assumed inflation rate for future payments.
    %         %       VALUATIONDATES: A vector of datetime objects representing the dates at which to calculate present values.
    %         %
    %         %   Outputs:
    %         %       PRESENTVALUES: A timetable  of present values corresponding to each date in VALUATIONDATES.
    % 
    %         % Detailed Explanation:
    %         %   1. Input Validation: Attempts to get discount factors from the specified
    %         %       rate curve. If the input is not a RateCurveKaparra object, it throws an error.
    %         %   2. Calculation Loop: Iterates over each valuationDate in VALUATIONDATES.
    %         %   3. Present Value Calculation: For each date, it retrieves the relevant discount
    %         %       factor from the RateCurveKaparra object and performs a simplified present
    %         %       value calculation based on a default payment amount (GuaranteedPayment)
    %         %       and number of payments (40).
    %         %   4. Result Storage: Stores the calculated present value for each date in the
    %         %       PRESENTVALUES array.
    %         %   5. Have encapsulated toolbox dependency on ratecurves to the class RateCurveKaparra provides methods like getDiscountFactors
    %         % Input Validation (check if rateCurve is valid)
    %         if ~isa(rateCurve, 'marketdata.RateCurveKaparra')
    %             error('Input must be a RateCurveKaparra object');
    %         end
    % 
    %         numPayments = numel(obj.AnnuityPaymentDates);
    %         numValuationDates = numel(valuationDates);
    %         presentValues = zeros(1, numValuationDates);% Preallocate for efficiency
    %         paymentsPerYear = utilities.CashFlowUtils.getPaymentsPerYear(obj.PaymentFrequency);
    %         annuityStartDate = obj.StartDate;
    %         gender = obj.Annuitant.Gender;
    %         startAge = obj.Annuitant.Age;  % assumes the person object only stores the start age.
    %         ageFinalAnnuityPayment = startAge + calyears(utilities.DateUtilities.calculateYearDiff(annuityStartDate,obj.AnnuityPaymentDates(end)));
    % 
    % 
    %         for i = 1:numValuationDates
    %             valuationDate = valuationDates(i);
    %             valuationAge = startAge + calyears(utilities.DateUtilities.calculateYearDiff(annuityStartDate,valuationDate)); % assumes age is exact on the startScenarioDate
    % 
    %             % Get payment dates to value (after the valuation date)
    % 
    %             %%TODO adjust payments for guaranteed increases 
    %             %%TODO allow for paymnet frequencies other than annual with
    %             %%TODO survivorship probabilities
    %             %TODO encapsulate present value function for survivorship
    %             %eg one formula for all annuities.%% inherit PV from the
    %             %annuity class and then overload with survivorship
    % 
    % 
    %             paymentDatesToValue = obj.AnnuityPaymentDates(obj.AnnuityPaymentDates > valuationDate);
    %             survivorshipProbabilitiesFull = futureMortalityTable.getSurvivorshipProbabilities(gender,valuationAge,ageFinalAnnuityPayment); % returns a vector of probabilities for all future ages
    % 
    %             survivorshipProbabilities = futureMortalityTable.getSurvivorshipProbabilitiesForEachPaymentDate(survivorshipProbabilitiesFull,paymentDatesToValue,paymentsPerYear);
    % 
    %             try
    %             paymentAmounts = ones(1, numel(paymentDatesToValue))*obj.GuaranteedPayment/paymentsPerYear.*survivorshipProbabilities;
    %             catch ME
    %                 %disp(i,numel(paymentDatesToValue),survivorshipProbabilities);
    %             end
    %             % Calculate the number of payments remaining from the annuity
    %             numPaymentsMade = sum(paymentDatesToValue < valuationDates(i));
    %             numPaymentsRemaining = sum(paymentDatesToValue > valuationDates(i));
    % 
    %             % If there are no payments remaining set the present value to zero
    %             if numPaymentsRemaining == 0
    %                 presentValue = 0;
    %             else
    % 
    %              % Get discount factors for the payment dates
    %                 discountFactors = rateCurve.getDiscountFactors(paymentDatesToValue((numPaymentsMade+1):end));
    %                 discountFactors = discountFactors(:)'; % Ensure it's a column vector
    % 
    %                 % Calculate present value of each payment
    %                 presentValue = sum(paymentAmounts((numPaymentsMade+1):end).*discountFactors); % Element-wise multiplication of payments and discount factors
    % 
    %             end
    %             presentValues(i) = presentValue;
    % 
    %         end
    %         disp("Revalued annuity for " + numValuationDates +  " valuation dates")
    %         %test code with no discounting and no mortality
    % 
    %         for i = 1:numValuationDates
    %              try
    %                  % Attempt to use rateCurves as a RateCurve array
    %                  discountFactors = rateCurve.getDiscountFactors(valuationDates(i)); % Example
    %                  % ... rest of your code ...
    %              catch ME
    %                  if strcmp(ME.identifier, 'MATLAB:nonExistentField') || strcmp(ME.identifier, 'MATLAB:badsubscript')
    %                      error('run_simulation: Invalid input. rateCurves must be a vector of RateCurve objects.');
    %                  else
    %                      rethrow(ME);  % Re-throw other errors
    %                  end
    %              end
    %              if (valuationDates(i) - obj.AnnuityPaymentDates(1)) >0
    % 
    %                 presentValueTest = obj.GuaranteedPayment/paymentsPerYear*(numPayments- (i-1)); %simple default value for code testing
    % 
    %              else
    %                  presentValueTest = obj.GuaranteedPayment/paymentsPerYear*(numPayments);
    %              end
    %              presentValuesTest(i) = presentValueTest;
    %              %presentValuesTT = timetable(obj.AnnuityValuationDates',pv','VariableNames',{'Present Value'});
    %          end
    % 
    % 
    %     end
    % 
     end

end