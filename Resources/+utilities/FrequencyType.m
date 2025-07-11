classdef FrequencyType <double
    enumeration
        
        Weekly (52)
        Monthly (12)
        Quarterly (4)
        Annually (1)
        Daily (365)
        Hourly   (8760) % do not use this for simulated projections until you work out how to calculate number of periods between dates
        Minutely  (525600) % do not use this for simulated projections until you work out how to calculate number of periods between dates
    end
     methods (Static) % Define a static method for the alias lookup
        function alias = getAlias(frequency)
            switch frequency
                case utilities.FrequencyType.Daily
                    alias = 'Daily';
                case utilities.FrequencyType.Weekly
                    alias = 'Weekly';
                case utilities.FrequencyType.Monthly
                    alias = 'Monthly';
                case utilities.FrequencyType.Quarterly
                    alias = 'Quarterly';
                case utilities.FrequencyType.Annually
                    alias = 'Yearly';
                otherwise
                    error('Unsupported frequency type');
            end
        end
        function alias = getPeriod(frequency)
            switch frequency
                case utilities.FrequencyType.Daily
                    alias = 'Days';
                case utilities.FrequencyType.Weekly
                    alias = 'Weeks';
                case utilities.FrequencyType.Monthly
                    alias = 'Months';
                case utilities.FrequencyType.Quarterly
                    alias = 'Quarters';
                case utilities.FrequencyType.Annually
                    alias = 'Years';
                otherwise
                    error('Unsupported frequency type');
            end
        end
        function frequency = fromAlias(alias)
            switch alias
                case 'Daily'
                    frequency = utilities.FrequencyType.Daily;
                case 'Weekly'
                    frequency = utilities.FrequencyType.Weekly;
                case 'Monthly'
                    frequency = utilities.FrequencyType.Monthly;
                case 'Quarterly'
                    frequency = utilities.FrequencyType.Quarterly;
                case 'Yearly'
                    frequency = utilities.FrequencyType.Annually;
                otherwise
                    error('Unsupported frequency alias');
            end
        end
        function numericValue = getNumericValue(frequency)
            % Returns the underlying numeric value of the enum member,
            % representing the number of payments per year.
            switch frequency
                case utilities.FrequencyType.Daily
                    numericValue = 365;
                case utilities.FrequencyType.Weekly
                    numericValue =52;
                case utilities.FrequencyType.Monthly
                    numericValue=12;
                case utilities.FrequencyType.Quarterly
                    numericValue =4;
                case utilities.FrequencyType.Annually
                    numericValue =1;
                otherwise
                    error('Unsupported frequency alias');
            end
            
        end
    end
end