classdef DefaultRiskPremiumCalculator < marketdatasimulationclasses.RiskPremiumCalculator
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        RiskPremiumAssumptions
        CalculationMethod
    end

    methods


        function obj = DefaultRiskPremiumCalculator(riskPremiumAssumptions)
                                              
            % if nargin() == 0
            %     scenarioObject = scenarios.Scenario(); % need implement
            %     vargin for Scenario default constructor.
            % end 
            
            if isa(riskPremiumAssumptions,"table")
            % obj.RiskPremiumAssumptions = scenarioObject.RiskPremiumAssumptions;
            obj.RiskPremiumAssumptions = riskPremiumAssumptions;
            elseif isa(riskPremiumAssumptions,"timetable")
                obj.RiskPremiumAssumptions = riskPremiumAssumptions;
            
            else
                disp("Invalid risk premium assumption data type passed to risk premium calculator constructor. Needs to be a table or a timetable not a scenario object")

            end
            % else
            % error('invalid input arguments for DefaultRiskPremium Calculator')
        end

        
        function riskPremiums = calculateRiskPremiums(obj,simulationStartDate,assetReturnStartDates,assetReturnFrequencyPerYear,marketDataAssetNames)

            % Notes:   made this method one for the subclass
            % SceanraioSpecificMarketData. Design choice to locate all
            % simulations within a scenario so they can be defined as aprt
            % of the scenario. May be inefficient if you could reuse across
            % all scanarios or subsets of scenarios.
            % INPUT ScenarioSpecificMarketData object and simulationStartDate
            % output will be an array of length N . each element represents
            % the risk premium (annulaized) for the period defined by
            % assetReturnStart and end dates.


            defaultRiskPremium = 0.03;
            numberOfPeriods = length(assetReturnStartDates);
            %numPeriodsPerYear = assetReturnFrequencyPerYear; %obj.getNumberofFuturePeriods;
            allowedAssetNames = marketDataAssetNames;
            numAssets = length(allowedAssetNames);
            
            

            if ~isprop(obj,'RiskPremiumAssumptions')
                % riskPremiumInputParameter =  repelem(defaultRiskPremium,numAssets,calyears(numOfYearsInSimulation)) ;
                
                riskPremiumInputParameter =  repelem(defaultRiskPremium,numAssets,numberOfPeriods) ;
            elseif isprop(obj,'RiskPremiumAssumptions')
                riskPremiumInputParameter = obj.RiskPremiumAssumptions;
                
                isValidAssetName = utilities.ValidationUtils.validateTableVariableNames(riskPremiumInputParameter, allowedAssetNames);
            end
            
           
            if isempty(riskPremiumInputParameter) || ~isValidAssetName
                %riskPremiumInputParameter =  repelem(defaultRiskPremium,numAssets,calyears(numOfYearsInSimulation)) ;
                riskPremiums=  repelem(defaultRiskPremium,numAssets,numberOfPeriods) ;
                riskPremiums = array2table(riskPremiums');
                riskPremiums.Properties.VariableNames = allowedAssetNames;
                disp('using default risk premium as allowed asset names does not match names supplied for risk premiums')
            else
                names = riskPremiumInputParameter.Properties.VariableNames;
                % numAssets = length(names);
                riskPremiumInputParameter = table2array(riskPremiumInputParameter);
                riskPremiumInputParameter = riskPremiumInputParameter(:,1:end);

                riskPremiums = repelem(riskPremiumInputParameter',1,numberOfPeriods); % assumes riskPremiums has one element for each asset. number of columns = number of assets

                riskPremiums = array2table(riskPremiums');
                riskPremiums.Properties.VariableNames = names; 
            end
           
        end
    end
end