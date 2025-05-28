classdef FrequencyType
    enumeration
        Daily 
        Weekly
        Monthly
        Quarterly
        Annually
        Hourly    % do not use this for simulated projections until you work out how to calculate number of periods between dates
        Minutely  % do not use this for simulated projections until you work out how to calculate number of periods between dates
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
    end
end