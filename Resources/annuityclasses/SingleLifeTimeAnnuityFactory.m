classdef SingleLifeTimeAnnuityFactory < AnnuityFactory
    methods %(Static)
         % --- NEW, PREFERRED METHOD ---
        function annuity = createInstrumentFromParams(obj, person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency)
            % This method calls the new, clean SingleLifeTimeAnnuity constructor.
            annuity = SingleLifeTimeAnnuity(person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency);
        end

        % --- LEGACY METHOD (DEPRECATED) ---
        function annuity = createInstrument(obj, person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency, ~)
            % This method is kept for backward compatibility.
            
            warning('AnnuityFactory:DeprecatedMethod', ...
                ['The createInstrument method is deprecated and the provided paymentDates were ignored. ' ...
                 'Please refactor your code to use createInstrumentFromParams.']);
            
            % Forward the call to the new, robust method.
            annuity = obj.createInstrumentFromParams(person, annuityIncome, increaseRate, startDate, deferment, maxPayments, frequency);
        end
    end
end

