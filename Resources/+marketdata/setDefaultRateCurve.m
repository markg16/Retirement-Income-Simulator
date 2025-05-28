function defaultRateCurve = setDefaultRateCurve(varargin)

p = inputParser;

addParameter(p, 'startDate',utilities.DefaultScenarioParameters.defaultStartDate,@isdatetime);
addParameter(p, 'levelRate',utilities.DefaultScenarioParameters.defaultLevelRate,@double);

parse(p,varargin{:})


levelRate = p.Results.levelRate;
startDate = p.Results.startDate;

dates = [calyears([1,2,3,4,5,10,20,30])];
rates = repelem(levelRate,8);
defaultRateCurve = marketdata.RateCurveKaparra('zero',startDate,dates,rates);



end