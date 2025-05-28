classdef EconomicScenarioGeneratorFactory
    %ECONOMICScenarioGENERATORFACTORY Summary of this class goes here
    %   Detailed explanation goes here

    methods (Static)
        function obj = create(generatorType, simulationParameters)
            %CREATE Factory method to create EconomicScenarioGenerator objects
            %   generatorType: EconomicScenarioGeneratorType enum value
            %   simulationParameters: marketdatasimulationclasses.SimulationParameters object

            switch generatorType
                case utilities.EconomicScenarioGeneratorType.Deterministic
                    obj = marketdatasimulationclasses.DeterministicScenarioGenerator(simulationParameters);
                case  utilities.EconomicScenarioGeneratorType.BrownianMotion
                    % Assuming you have a BrownianMotionScenarioGenerator class:
                    obj = marketdatasimulationclasses.BrownianMotionScenarioGenerator(simulationParameters); 
                otherwise
                    error('Invalid EconomicScenarioGeneratorType');
            end
        end
    end
end