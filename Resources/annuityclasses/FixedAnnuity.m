
classdef FixedAnnuity < Annuity
    properties
        AnnuityType  = "Fixed"
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
        function obj = FixedAnnuity(person, guaranteedPayment, guaranteedPaymentIncreaseRate, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency, annuityPaymentDates)
     % Constructor for FixedAnnuity
           % Constructor for FixedAnnuity
           if nargin == 7
                % If not provided, generate them based on frequency and start date
                dateLastAnnuityPayment = annuityStartDate + years(maxNumPayments);


                annuityPaymentDates = utilities.generateDateArrays(annuityStartDate, dateLastAnnuityPayment,paymentFrequency);
           end
           obj@Annuity(person, guaranteedPayment, guaranteedPaymentIncreaseRate, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency, annuityPaymentDates);  % Call the Annuity superclass constructor
          % obj@Annuity(person, guaranteedPayment, annuityStartDate, incomeDeferment, maxNumPayments, paymentFrequency, annuityPaymentDates);  % Call the Annuity superclass constructor
             obj.Name = "FixedAnnuity"; 
          % Set FixedAnnuity specific properties
           % obj.AnnuityCountry = person.Country;
           % obj.GuaranteedPayment = guaranteedPayment;
           % obj.GuaranteedPaymentIncreaseRate = guaranteedPaymentIncreaseRate;
           % obj.IncomeDeferment = incomeDeferment;
           % obj.MaxNumPayments = maxNumPayments;
           % obj.PaymentFrequency = paymentFrequency;
           % % Optionally, set annuity payment dates
           % if nargin == 8   % Check if annuityPaymentDates were provided
           %     obj.AnnuityPaymentDates = annuityPaymentDates;
           % else
           %     % If not provided, generate them based on frequency and start date
           %     dateLastAnnuityPayment = annuityStartDate + years(maxNumPayments);
           %     obj.AnnuityPaymentDates = generateDateArrays(annuityStartDate, dateLastAnnuityPayment,paymentFrequency);
           % end

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
            %       MARKETDATAPROVIDER: A MarketData object for accessing rate curves.
            %       SCENARIODATAPROVIDER: A Scenario object for accessing scenario-specific data (e.g., inflation rate).
            %
            %   Outputs:
            %       CURRENTVALUE: The present value of the fixed annuity at VALUATIONDATE.

            %Get rateCurve for valuation date.  
            country = obj.getAnnuityCountry();
            rateCurve = marketDataProvider.extractRateCurve(valuationDate,country, scenarioDataProvider);

            % Get inflation rate from the scenario data provider
            
            inflationRate = scenarioDataProvider.getInflationAssumption();

            % get folder for the mortality tables

            if obj.AnnuityType == "Fixed"
                baseLifeTableFolder = "Fixed Annuity No Mortality Table Required: see FixedAnnuity class";
            else
                disp("Fixed Annuity object being set up with incorrect type")
                error("Fixed Annuity object being set up with incorrect type");
            end

            % Calculate present value (delegate to the existing present_value method)
            %currentValue = obj.present_value(baseLifeTableFolder,rateCurve, inflationRate,valuationDate );
            currentValue = obj.presentValue(rateCurve,inflationRate,valuationDate);
        end
        
        % function presentValues = present_value(obj, baseLifeTableFolder,rateCurve,inflationRate, valuationDates)
        % 
        %     %   PRESENTVALUES = PRESENT_VALUE(OBJ, BASELIFETABLEFOLDER, RATECURVES, CURVENAME, INFLATIONRATE, VALUATIONDATES)
        %     %   computes the present value of the annuity represented by the Annuity object OBJ
        %     %   at each date specified in VALUATIONDATES. The calculation uses the discount
        %     %   factors from the RATECURVES dictionary, the inflation rate INFLATIONRATE,
        %     %   and optionally, mortality data from the BASELIFETABLEFOLDER (not implemented in this example).
        %     %
        %     %   Inputs:
        %     %       OBJ: The Annuity object.
        %     %       BASELIFETABLEFOLDER: Path to the folder containing base life tables (optional, not used in this example).
        %     %       RATECURVES: A dictionary of RateCurveKaparra objects, where keys are curve names and values are RateCurveKaparra objects.
        %     %       CURVENAME: The name of the curve to use from RATECURVES.
        %     %       INFLATIONRATE: The assumed inflation rate for future payments.
        %     %       VALUATIONDATES: A vector of datetime objects representing the dates at which to calculate present values.
        %     %
        %     %   Outputs:
        %     %       PRESENTVALUES: A timetable  of present values corresponding to each date in VALUATIONDATES.
        % 
        %     % Detailed Explanation:
        %     %   1. Input Validation: Attempts to get discount factors from the specified
        %     %       rate curve. If the input is not a RateCurveKaparra object, it throws an error.
        %     %   2. Calculation Loop: Iterates over each valuationDate in VALUATIONDATES.
        %     %   3. Present Value Calculation: For each date, it retrieves the relevant discount
        %     %       factor from the RateCurveKaparra object and performs a simplified present
        %     %       value calculation based on a default payment amount (GuaranteedPayment)
        %     %       and number of payments (40).
        %     %   4. Result Storage: Stores the calculated present value for each date in the
        %     %       PRESENTVALUES array.
        %     %   5. Have encapsulated toolbox dependency on ratecurves to the class RateCurveKaparra provides methods like getDiscountFactors
        %     % Input Validation (check if rateCurve is valid)
        %     if ~isa(rateCurve, 'marketdata.RateCurveKaparra')
        %         error('Input must be a RateCurveKaparra object');
        %     end
        % 
        %     numPayments = numel(obj.AnnuityPaymentDates);
        %     numValuationDates = numel(valuationDates);
        %     presentValues = zeros(1, numValuationDates);% Preallocate for efficiency
        %     paymentsPerYear = utilities.CashFlowUtils.getPaymentsPerYear(obj.PaymentFrequency);
        % 
        % 
        %     for i = 1:numValuationDates
        %         valuationDate = valuationDates(i);
        % 
        %         % Get payment dates to value (after the valuation date)
        % 
        %         %%TODO adjust payments for guaranteed increases 
        %         paymentDatesToValue = obj.AnnuityPaymentDates(obj.AnnuityPaymentDates > valuationDate);
        %         paymentAmounts = ones(1, numel(paymentDatesToValue))*obj.GuaranteedPayment/paymentsPerYear;
        % 
        % 
        %        % cashflow = cashflow - utilities.CashFlowUtils.adjustForInflation(annualPortfolioPayment / utilities.CashFlowUtils.getPaymentsPerYear(portfolioPaymentFrequency), inflationRate, years(valuationDate - scenarioStartDate));
        % 
        %         % Calculate the number of payments remaining from the annuity
        %         numPaymentsMade = sum(paymentDatesToValue < valuationDates(i));
        %         numPaymentsRemaining = sum(paymentDatesToValue > valuationDates(i));
        % 
        %         % If there are no payments remaining set the present value to zero
        %         if numPaymentsRemaining == 0
        %             presentValue = 0;
        %         else
        % 
        %          % Get discount factors for the payment dates
        %             discountFactors = rateCurve.getDiscountFactors(paymentDatesToValue((numPaymentsMade+1):end));
        %             discountFactors = discountFactors(:)'; % Ensure it's a column vector
        % 
        %             % Calculate present value of each payment
        %             presentValue = sum(paymentAmounts((numPaymentsMade+1):end).*discountFactors); % Element-wise multiplication of payments and discount factors
        % 
        %         end
        %         presentValues(i) = presentValue;
        %     end
        % 
        %     %test code with no discounting
        % 
        %     for i = 1:numValuationDates
        %          try
        %              % Attempt to use rateCurves as a RateCurve array
        %              discountFactors = rateCurve.getDiscountFactors(valuationDates(i)); % Example
        %              % ... rest of your code ...
        %          catch ME
        %              if strcmp(ME.identifier, 'MATLAB:nonExistentField') || strcmp(ME.identifier, 'MATLAB:badsubscript')
        %                  error('run_simulation: Invalid input. rateCurves must be a vector of RateCurve objects.');
        %              else
        %                  rethrow(ME);  % Re-throw other errors
        %              end
        %          end
        %          if (valuationDates(i) - obj.AnnuityPaymentDates(1)) >0
        % 
        %             presentValueTest = obj.GuaranteedPayment/paymentsPerYear*(numPayments- (i-1)); %simple default value for code testing
        % 
        %          else
        %              presentValueTest = obj.GuaranteedPayment/paymentsPerYear*(numPayments);
        %          end
        %          presentValuesTest(i) = presentValueTest;
        %          %presentValuesTT = timetable(obj.AnnuityValuationDates',pv','VariableNames',{'Present Value'});
        %      end
             


             
             
             %%future calc for life time annuity
             % if isfield(obj.AnnuityCashflowStrategy,'MortalityTable') && ~isempty(obj.AnnuityCashflowStrategy.MortalityTable)
             %     % Adjust the present value if mortality is included
             %     presentValue = presentValue * obj.AnnuityCashflowStrategy.MortalityTable.getSurvivalProbability(obj.Person.Age);
             % end
             
        % end

    end

end