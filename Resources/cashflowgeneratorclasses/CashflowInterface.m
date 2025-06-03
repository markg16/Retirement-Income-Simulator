classdef (Abstract) CashflowInterface < handle
    methods (Abstract)
        cashflows = generateCashflows(obj, startDate, endDate, paymentDates, inflationRate);
        %presentValue = valueCashflows(obj, rateCurve, cashflows); 
    end
end