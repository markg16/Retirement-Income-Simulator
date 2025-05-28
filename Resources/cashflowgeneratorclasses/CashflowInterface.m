classdef (Abstract) CashflowInterface
    methods (Abstract)
        cashflows = generateCashflows(obj, startDate, endDate, paymentDates, inflationRate);
        presentValue = valueCashflows(obj, rateCurve, cashflows); 
    end
end