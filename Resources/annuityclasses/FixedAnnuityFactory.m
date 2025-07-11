classdef FixedAnnuityFactory < AnnuityFactory
    methods %(Static)
        function annuity = createInstrument(obj,person,annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,maxNumAnnuityPayments,annuityPaymentFrequency,annuityPaymentDates)
                                 
            if nargin ==9
            annuity = FixedAnnuity(person, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,maxNumAnnuityPayments,annuityPaymentFrequency,annuityPaymentDates);
            else
                annuity = FixedAnnuity(person, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,maxNumAnnuityPayments,annuityPaymentFrequency);
            end
        end
    end
end

