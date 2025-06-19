function simulatedValues = testESG()

addpath('G:\My Drive\Kaparra Software\Rates Analysis\Resources\+scenarios\marketdatasimulationclasses\')

parameters = [0.1,10];
startValues =1;
simulator = DeterministicScenarioGenerator(parameters);
simulatedValues = simulator.simulateValues(startValues)
end