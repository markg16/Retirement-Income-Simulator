function improvedRate = testMortalityTables()
%UNTITLED8 Summary of this function goes here
%   Detailed explanation goes here

addpath('annuityclasses');
addpath('lifeandothercontingencyclasses\'); 
addpath('portfolioclasses');
addpath('instrumentclasses\'); 
addpath('tradingstrategyclasses\'); 
addpath('+utilities\');
addpath('+marketdata\');
addpath('testclasses');
tableFilePath = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat';
improvementFactorsFile = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Improvement_factors_2015-17.xlsx';
gender = 'F';
startAge = 50 
% workflow
% read in mortality tables from a file

baseTable = utilities.LifeTableUtilities.loadOrCreateBaseTable(tableFilePath);
genders = fieldnames(baseTable.MortalityRates);

%TOD readin table of improvement factors (see oexisting funcitons.) 
factor = 0.05; % 5% improvement

improvementFactorCalulationAlgo = MeanImprovementFactorStrategy();

%apply improvement factors to get an improved mortality table

improvedTable = CachedImprovementFactorDecorator(baseTable, factor,improvementFactorsFile, improvementFactorCalulationAlgo);

% Now you can repeatedly call improvedTable.getRate(age)


%improvedRate = improvedTable.getRate(gender,50,50); % TODO maybe add getRates() for all ages from 50.
improvedRate = improvedTable.getRate(gender,80,50)
disp(improvedRate)

newTable = improvedTable.createImprovedTable(startAge);
newTable.MortalityRates.('M')
newTable.MortalityRates.('F')
newTable.saveToMAT(); % Save the new table

% 
 improvedTable.saveCache(); % Save cache after calculations

end