function marketReferenceParameters = buildMarketReferencePortfolioScenarioParameters(inputArgs)

referencePortfolioParameters = inputArgs.referencePortfolioParameters;
referencePortfolioParameters.startDate= inputArgs.Dates.startDateScenario;
referencePortfolioParameters.country = inputArgs.person.country;
referencePortfolioParameters.endDate = inputArgs.Dates.endDateScenario;
referencePortfolioParameters.assetReturnFrequency = inputArgs.runtime.assetReturnFrequency;

referencePortfolioSimulationStartDate = referencePortfolioParameters.startDate;
referencePortfolioSimulationStartDate.TimeZone = 'Australia/Sydney';

marketReferenceParameters.portfolio = referencePortfolioParameters;
marketReferenceParameters.scenario.rateScenarios =  inputArgs.RateFile.rateScenarios;
marketReferenceParameters.scenario.startDateScenario = inputArgs.Dates.startDateScenario;
marketReferenceParameters.scenario.endDateScenario = inputArgs.Dates.endDateScenario;
marketReferenceParameters.scenario.referenceTime = inputArgs.Dates.referenceTime;
marketReferenceParameters.scenario.AssetReturnFrequency = inputArgs.runtime.assetReturnFrequency;
marketReferenceParameters.scenario.RiskPremiums = inputArgs.marketUniverse.riskPremiums;
marketReferenceParameters.scenario.RiskPremiumTickers=inputArgs.marketUniverse.riskPremiumTickers;

end

