classdef (Abstract) AnnuityFactory <InstrumentFactory
    methods (Abstract)
         % --- NEW, PREFERRED METHOD ---
        % This is the new, robust way to create an annuity. It relies on the
        % annuity object to calculate its own payment dates.
        annuity = createInstrumentFromParams(obj, person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency);

        % --- LEGACY METHOD (DEPRECATED) ---
        % This method is kept for backward compatibility. Concrete classes
        % should implement this by calling the new method and issuing a warning.
        annuity = createInstrument(obj, person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency, paymentDates);
    
    end
end