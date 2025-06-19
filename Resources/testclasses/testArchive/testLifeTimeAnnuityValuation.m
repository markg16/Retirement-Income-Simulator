function presentValue = testLifeTimeAnnuityValuation()
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

addpath('annuityclasses');
addpath('lifeandothercontingencyclasses\'); 
addpath('portfolioclasses');
addpath('instrumentclasses\'); 
addpath('tradingstrategyclasses\'); 
addpath('+utilities\');
addpath('+marketdata\');
addpath('testclasses\');
tableFilePath = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat';
improvementFactorsFile = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Improvement_factors_2015-17.xlsx';
gender = 'F';
startAge = 75 ;
frequency = utilities.FrequencyType.Annually;



% workflow


% set up person with appropriate mortalitytable
cashflowStrategy = CashflowStrategy(1000, datetime("today"), frequency, 0, [])
person = Person('F',75,"AU",100000,1000,0,1000,frequency,cashflowStrategy);

% set up annuity with person 

lifeAnnuity = SingleLifeTimeAnnuity(person, 1000, 0, datetime("today"), 0, 40, frequency); % Age 50, male, $1000 annual payment
disp(lifeAnnuity)

% set up marketdata and scenario data required to get value
% 
% % calculate annuity value at a valuation date
% 
% 
presentValue = lifeAnnuity.getCurrentValue(datetime('19/07/2016'),[],[]);

valuationDates = [datetime('31/03/2016'),datetime('19/07/2039')];
inflationRateAssumption =0;
futureMortalityTable = lifeAnnuity.Annuitant.FutureMortalityTable;


%Default rateCUrve .
                type = 'Discount';
                settle = valuationDates(2);
                dates = lifeAnnuity.AnnuityPaymentDates;
                compounding = -1;
                basis = 0;
                rates = ones(1,length(dates));
               
                rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);

lifeAnnuity.present_value(futureMortalityTable,rateCurve,inflationRateAssumption,valuationDates)
% 
% disp(presentValue)


end