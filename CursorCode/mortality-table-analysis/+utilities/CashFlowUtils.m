classdef CashFlowUtils
    %UNTITLED8 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods(Static)
        function paymentsPerYear = getPaymentsPerYear(frequency)
            %GETPAYMENTSPERYEAR Get the number of payments per year based on frequency.
            %
            %   PAYMENTSPERYEAR = GETPAYMENTSPERYEAR(FREQUENCY) returns the number of
            %   payments per year corresponding to the specified FREQUENCY.
            %
            %   Inputs:
            %       FREQUENCY: A string indicating the frequency of payments ('Monthly',
            %                  'Quarterly', 'Annually', etc.).
            %
            %   Outputs:
            %       PAYMENTSPERYEAR: The number of payments per year.

            
            paymentsPerYear = utilities.DateUtilities.getFrequencyPerYear(frequency);
            
        end

        function hasPaymentOccurred = hasPaymentOccurredBetweenValuationDates(lastValuationDate, valuationDate, paymentDates)
            %HASPAYMENTOCCURREDBETWEENVALUATIONDATES Checks if a payment occurred between two valuation dates.
            %
            %   hasPaymentOccurred = hasPaymentOccurredBetweenValuationDates(valuationDate, lastValuationDate, paymentDates)
            %   returns a logical value indicating whether any dates in the `paymentDates`
            %   array fall within the period defined by `lastValuationDate` (exclusive) and `valuationDate` (inclusive).
            %   If `lastValuationDate` is empty, it is treated as if it were the same as `valuationDate`, meaning only payments
            %   occurring exactly on the `valuationDate` are considered.
            %
            %   Inputs:
            %       valuationDate - datetime: The current valuation date.
            %       lastValuationDate   - datetime: The previous valuation date. Can be empty for the first valuation.
            %       paymentDates        - datetime array: An array of payment dates in ascending order.
            %
            %   Outputs:
            %       hasPaymentOccurred   - logical: True if a payment occurred between the
            %                                       valuation dates, False otherwise.
            %
            %   Example:
            %       paymentDates = [datetime('2024-04-30'), datetime('2024-05-31'), datetime('2024-06-30')];
            %       currentValuationDate = datetime('2024-06-15');
            %       lastValuationDate = datetime('2024-05-10');
            %       hasPaymentOccurred = hasPaymentOccurredBetweenValuationDates(currentValuationDate, lastValuationDate, paymentDates);
            %       disp(hasPaymentOccurred);  % Output: 1 (True) - Payment on May 31st
            %
            %       currentValuationDate = datetime('2024-04-30'); % First valuation (lastValuationDate is empty)
            %       lastValuationDate = [];
            %       hasPaymentOccurred = hasPaymentOccurredBetweenValuationDates(currentValuationDate, lastValuationDate, paymentDates);
            %       disp(hasPaymentOccurred);  % Output: 1 (True) - Payment on April 30th

            % Handle the case where lastValuationDate is empty (first valuation)
            if isempty(lastValuationDate)
                lastValuationDate = valuationDate; % Treat as if the previous valuation was on the same date
            end

            % Ensure the valuation dates are in the correct order
            if valuationDate < lastValuationDate
                error('currentValuationDate must be after lastValuationDate.');
            end

            % Check if any payment dates are between the last (exclusive) and current (inclusive) valuation dates
            hasPaymentOccurred = any(paymentDates > lastValuationDate & paymentDates <= valuationDate);
        end
        
        function isCashFlow= isCashFlowDate(inputStartDate, inputEndDate, cashflowDates)
            %ISCASHFLOWDATE Checks if any cash flow dates fall within a given period.
            %
            %   test = isCashFlowDate(inputStartDate, inputEndDate, cashflowDates)
            %   returns a logical value indicating whether any dates in the `cashflowDates`
            %   array fall within the period defined by `inputStartDate` and `inputEndDate`.
            %
            %   Inputs:
            %       inputStartDate - datetime: The start date of the period.
            %       inputEndDate   - datetime: The end date of the period.
            %       cashflowDates  - datetime array: An array of potential cash flow dates.
            %
            %   Outputs:
            %       test           - logical: True if any cash flow dates fall within the
            %                                period, False otherwise.
            %
            %   Example:
            %       cashflowDates = [datetime('2024-01-15'), datetime('2024-03-30'), datetime('2024-06-10')];
            %       periodStart = datetime('2024-02-01');
            %       periodEnd = datetime('2024-05-31');
            %
            %       test = isCashFlowDate(periodStart, periodEnd, cashflowDates);
            %       disp(test);  % Output: 1 (True)


            % Check if any cash flow dates are between the start and end dates
            isCashFlow = any(cashflowDates >= inputStartDate & cashflowDates <= inputEndDate);
        end

        function adjustedAmount = adjustForInflation(amount, inflationRate, years)
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
        function inflationFactors = getInflationFactors(paymentDates,inflationRate,indexationDates)

            numberOfPayments = length(paymentDates);
            inflationFactors = zeros(1,numberOfPayments);
            inflationFactors(1) = 1;
            for id = 2:numberOfPayments
                nextIndexationDate = indexationDates(lastIndexationDateIndex+1);
                isAnIndexationTime = (nextIndexationDate <= paymentDates(id) & nextIndexationDate> paymentdates(id-1)) ;

                if isAnIndexationTime
                    inflationFactors(id) = (1+inflationRate)*inflationFactors(id-1);
                    lastIndexationDate = indexationDates(indexationDates<paymentDates(id));

                else
                    inflationFactors(id) = inflationFactors(id-1);

                end

            end

        end
        function cashflowsData = createCashFlowDataStruct(inputArgs)
            cashflowsData.DefaultCashFlow = inputArgs.runtime.defaultCashflows; % will be a combination of annuity planned payments and actual payments with real inflation
            cashflowsData.Contribution = inputArgs.person.contribution;
            cashflowsData.ContributionFrequency = inputArgs.person.contributionFrequency;
            cashflowsData.GuaranteedPayment = inputArgs.hedgeAnnuity.guaranteedPayment;
            cashflowsData.GuaranteedPaymentFrequency = inputArgs.hedgeAnnuity.guaranteedPaymentFrequency;
            cashflowsData.GuaranteedPaymentIncreaseRate = inputArgs.hedgeAnnuity.GuaranteedPaymentIncreaseRate;
            cashflowsData.PortfolioPayment = inputArgs.person.ownerPayment;
            cashflowsData.PortfolioPaymentFrequency =inputArgs.person.ownerPaymentFrequency;
            cashflowsData.InflationRateAssumption = inputArgs.person.inflationRateAssumption;
            cashflowsData.GuaranteedIncomeDeferement = inputArgs.hedgeAnnuity.GuaranteedIncomeDeferement;
            cashflowsData.GuaranteedIncomeMaxNumPmts = inputArgs.hedgeAnnuity.maxNumPayments;
            cashflowsData.AnnuityType = inputArgs.hedgeAnnuity.annuityType;
            cashflowsData.HedgeAnnuityStartDate=inputArgs.hedgeAnnuity.annuityStartDate;
        end
    end
end