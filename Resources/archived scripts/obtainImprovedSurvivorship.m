function [revisedlx,revisedqx] = obtainImprovedSurvivorship(baseLifeTableFolder,entryAge,gender)
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
% Read Base Life Table (assuming xlsx format)
  maleFile = fullfile(baseLifeTableFolder,"Australian_Life_Tables_2015-17_Males.xlsx");
  femaleFile = fullfile(baseLifeTableFolder,"Australian_Life_Tables_2015-17_Females.xlsx");  
  improvementFactorsFile = fullfile(baseLifeTableFolder,"Improvement_factors_2015-17.xlsx");
  baseLifeTable =  readLifeTables(maleFile, femaleFile);
  baseImprovementFactors = array2table(readImprovementFactors(improvementFactorsFile),'VariableNames',{'Age', 'M', 'F'}) ;
    
  % Input Validation (Optional)
  % Check if lifeTable, rateCurve, age, gender and deferment are valid.

  % Load Mortality Data from lifeTable (assuming it's a structured array)
  qx = baseLifeTable.(gender).qx;  % Get qx for the specified gender
  lx = baseLifeTable.(gender).lx;  % Get lx for the specified gender
  fx = [baseImprovementFactors.Age,baseImprovementFactors.(gender)];

  % Adjust the mortality table based on improvement factors
  [revisedlx,revisedqx] = adjustMortalityTable(qx,lx, fx, entryAge);
end