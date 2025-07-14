% File: +utilities/AgeCalculationUtils.m
classdef AgeCalculationUtils
    %AGECALCULATIONUTILS Provides static helper methods for age-related calculations.

    methods (Static)
        function ageAtDate = getAgeAtDate(person, valuationDate)
             % Calculates a person's age at a future valuation date based on
            % their starting age and the duration from their start date,
            % using the system's established calculateYearDiff utility.
            
            % Get the reference start date and age from the base person object.
            personStartDate = person.CashflowStrategy.StartDate;
            personStartAge = person.Age;
            
            % --- THIS IS YOUR CORRECT, CENTRALIZED FORMULA ---
            % Calculate the number of full years that have passed.
            % The 'years()' function robustly converts the calendarDuration
            % output of your utility into a numeric value for calculation.
            durationInYears = years(utilities.DateUtilities.calculateYearDiff(personStartDate, valuationDate));
            
            % The age at the valuation date is the start age plus the completed years.
            ageAtDate = personStartAge + floor(durationInYears);


        end
    end
end