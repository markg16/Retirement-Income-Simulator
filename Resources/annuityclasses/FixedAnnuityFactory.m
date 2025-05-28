classdef FixedAnnuityFactory < AnnuityFactory
    methods %(Static)
        function annuity = createInstrument(obj,person,annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,maxNumAnnuityPayments,annuityPaymentFrequency,annuityPaymentDates)
                                 
            annuity = FixedAnnuity(person, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,maxNumAnnuityPayments,annuityPaymentFrequency,annuityPaymentDates);
        
        end
    end
end

