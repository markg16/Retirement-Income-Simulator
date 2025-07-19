classdef FixedAnnuityFactory < AnnuityFactory
    methods %(Static)
        % --- NEW, PREFERRED METHOD ---
        function annuity = createInstrumentFromParams(obj, person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency)
            % This method calls the new, clean FixedAnnuity constructor that
            % calculates its own payment dates.
            annuity = FixedAnnuity(person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency);
        end

        % --- LEGACY METHOD (DEPRECATED) ---
        function annuity = createInstrument(obj, person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency, ~)
            % This method is kept for backward compatibility.
            % The '~' in the signature indicates that the 'paymentDates' argument is intentionally ignored.
            
            % 1. Warn the developer that they are using an outdated method.
            warning('AnnuityFactory:DeprecatedMethod', ...
                ['The createInstrument method is deprecated and the provided paymentDates were ignored. ' ...
                 'Please refactor your code to use createInstrumentFromParams.']);
            
            % 2. Forward the call to the new, robust method.
            annuity = obj.createInstrumentFromParams(person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency);
        end
    end
end

