function [results,updatedScenario] = runSimulation(scenario,baseLifeTableFolder)

arguments
    scenario  scenarios.Scenario
    baseLifeTableFolder

end


disp("running simulation")
tic
% # Run simulation
try
    [results,updatedScenario] = scenario.run_simulation(baseLifeTableFolder);
catch ME
    % Handle errors (log, display message, etc.)
    rethrow(ME);  % Or handle the error differently
end

try
    results = reorganiseResults(results);
catch ME
    % Handle errors (log, display message, etc.)
    rethrow(ME);  % Or handle the error differently
end

end
