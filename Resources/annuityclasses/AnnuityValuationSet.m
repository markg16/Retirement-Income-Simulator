classdef AnnuityValuationSet
   %AnnuityValuationSet This class represents the set of annuity valuations between
   %two dates using the initial rate curve. The timetables are intended to be produced by 
   %the Annuity method present_value(obj, baseLifeTableFolder,rateCurve,inflationRate, valuationDates)
    %   Detailed explanation goes here
    
    properties
        ValuationTimeTable timetable   % Valuation dates (datetime array)(variable Names( AnnuityValuations and Time
        % FutureValuationDates
        % PresentValue double  % Present value of the annuity (double array)
        % InitialPresentValue double % Present value at each valuation date using the initial rate curve (double array)
        RateCurveName
    end

    methods
        function obj = AnnuityValuationSet(valuationTimeTable, rateCurveName)
            obj.ValuationTimeTable = valuationTimeTable;
            obj.RateCurveName = rateCurveName;
        end

        function annuityValue = getAnnuityValuationForADate(obj,valuationDate)
            
            dateIndex = find(obj.ValuationTimeTable.Time==valuationDate);
             if isempty(dateIndex)
                error('No Annuity Valuations found for the specified date: %s', valuationDate);
            end
            
            annuityValue = obj.ValuationTimeTable.AnnuityValuations{dateIndex};
        end
        function rateCurveName=getAnnuityValuationRateCurveName(obj)

            rateCurveName =obj.RateCurveName;

        end


    end
end
