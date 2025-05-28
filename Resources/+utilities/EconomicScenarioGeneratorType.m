classdef EconomicScenarioGeneratorType
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    enumeration
        Deterministic
        BrownianMotion
    end

    methods (Static)

        function generatorTypes = getEconomicScenarioGeneratorTypes()
            %GETECONOMICScenarioGENERATORTYPES Returns a list of available EconomicScenarioGeneratorType enum values.

            generatorTypes = enumeration('utilities.EconomicScenarioGeneratorType');
        end
       
    end

end