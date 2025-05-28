classdef (Abstract) AnnuityFactory <InstrumentFactory
    methods (Abstract)
        createInstrument(obj,person,annuityIncome,annuityStartDate,annuityIncomeDeferment,maxNumAnnuityPayments,annuityPaymentFrequency,annuityPaymentDates);
    end
end