
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


            if obj.AnnuityType == "SingleLifeTime"
                futureMortalityTable = obj.Annuitant.FutureMortalityTable;
            else
                disp("SingleLifeTime Annuity object being set up with incorrect type")
                error("SingleLifeTime Annuity object being set up with incorrect type");
            end

            % Calculate present value (delegate to the existing present_value method)
        
            currentValue = obj.presentValue(rateCurve,inflationRate,valuationDate);
        end

     

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


     end

end