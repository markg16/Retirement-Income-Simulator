classdef ScenarioBuilder < handle
    methods (Abstract)
        person = buildPerson(obj, personParameters);
        person = addAnnuity(obj,person,annuityParameters);
        portfolio = buildPortfolio(obj, portfolioParameters);
        scenario = buildScenario(obj, person,  scenarioParameters); 
    end
end