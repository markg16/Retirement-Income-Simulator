classdef BankAccount < Instrument
    properties
        InterestRate
        MaturityDate
        PendingTrade  
        % ... (other bank account-specific properties)
    end

   methods
       function obj = BankAccount(name, initialBalance,startDate)
           obj.Name = name;
           obj.Quantity = 1;  % Only one bank account
           obj.StartDate = startDate;
           obj.InitialPrice = initialBalance;
           obj.CurrentPrice = initialBalance; % Initial balance is the current value
           obj.PendingTrade = 0;
           obj = obj.updateHistoricalValues(startDate,initialBalance);
           
       end

        function value = getCurrentValue(obj, varargin)  % valuationDate not needed for bank account
            value = obj.CurrentPrice + obj.PendingTrade; 
        end
        function obj = deposit(obj,amount)
             obj.CurrentPrice = obj.CurrentPrice + amount;
             obj.PendingTrade = obj.PendingTrade -amount;
        end
        function obj = withdraw(obj,amount)
            if obj.CurrentPrice >= amount
                obj.CurrentPrice = obj.CurrentPrice - amount;
                obj.PendingTrade = obj.PendingTrade + amount;
            else
                disp('Insufficient funds in the bank account.');
                obj.CurrentPrice = obj.CurrentPrice - amount;
            end
        end

        function obj = applyPendingTrade(obj,tradeAmount)
            obj.PendingTrade = obj.PendingTrade + tradeAmount;

        end
        function obj = calculateAndAllocateInterest()
            disp('build function');

        end
    end
end
