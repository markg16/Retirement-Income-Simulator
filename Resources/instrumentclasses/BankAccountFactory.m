classdef BankAccountFactory < InstrumentFactory
    methods(Static)
        function instrument = createInstrument(name, initialValue,startDate)
            instrument = BankAccount(name, initialValue,startDate);
        end
    end
end