classdef AnnuityValuationCollection
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        AnnuityValuationsTT  timetable % a timetable of AnnuityValuationSet objects
        ScenarioName
    end

    methods
        function obj = AnnuityValuationCollection(annuityValuationsTT,scenarioName)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.AnnuityValuationsTT = annuityValuationsTT;  % intended to be a timetable of annuity valuation set objects
            obj.ScenarioName = scenarioName;


        end

        function annuityValue = getAnnuityValuationForADate(obj,valuationDate)
            %getAnnuityValuationForADate Is intened to return the AnnuityValuationSet for a specified date
            %   assumes that AnnuityValuationsTT has a Time and
            %   AnnuityValuations variable.  
            dateIndex = find(obj.AnnuityValuationsTT.Time==valuationDate);
             if isempty(dateIndex)
                error('No Annuity Valuations found for the specified date: %s', valuationDate);
            end
            
            annuityValue = obj.AnnuityValuationsTT.AnnuityValuationSets{dateIndex};
        end

        function scenarioName = getAnnuityValuationScenarioName(obj)

            scenarioName = obj.ScenarioName;

        end
        function obj = addAnnuityValuationSet(obj,annuityValuationSet,valuationDate)
            newEntry = timetable(valuationDate', {annuityValuationSet}, 'VariableNames', { 'AnnuityValuationSets'});
            obj.AnnuityValuationsTT = [obj.AnnuityValuationsTT;newEntry];
            %obj = obj.AnnuityValuationsTT;
            
        end

    end
end