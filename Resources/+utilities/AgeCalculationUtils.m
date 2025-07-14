% File: +utilities/AgeCalculationUtils.m
classdef AgeCalculationUtils
    %AGECALCULATIONUTILS Provides a static helper method for calculating age
    %   at a future date, using the application's standard formula.

    methods (Static)
        function ageAtDate = getAgeAtDate(person, valuationDate)
            % Calculates a person's age at a future valuation date based on
            % their starting age and the duration from their start date,
            % using the system's established calculateYearDiff utility.
            
            % Get the reference start date and age from the base person object.
            personStartDate = person.CashflowStrategy.StartDate;
            personStartAge = person.Age;
            
            % Use the application's authoritative function to calculate the duration.
            % The 'years()' function robustly converts the calendarDuration
            % output of your utility into a numeric value for calculation.
            durationInYears = calyears(utilities.DateUtilities.calculateYearDiff(personStartDate, valuationDate));
            
            % The age at the valuation date is the start age plus the number of
            % completed years that have passed.
            ageAtDate = personStartAge + floor(durationInYears);
        end
    end
end