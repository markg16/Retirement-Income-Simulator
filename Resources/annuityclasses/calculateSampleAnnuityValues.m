function allAnnuityValues = calculateSampleAnnuityValues(person,loopVariableIndexes)
% loopVariableIndexes is expected to be a 1*3 array of doubles. The first
% two positions represent variabels that will be shown on the the x and y axis
% and the third position% represents the variable to show by seperate line plots on same graph.


format = 'bank';
% Pre-allocate annuityValues as an empty struct with the desired fields
%annuityValues = struct('sampleAge',[],'levelRate',[],'annuityIncomeGtdIncrease',[],'defermentPeriod',[],'annuityValue',[]);
annuityValues = struct();
% Get all annuity types
annuityTypes = enumeration('AnnuityType');

% valid annuity input variable names
[annuityInputType,annuityInputTypeNames] = enumeration('AnnuityInputType');


% Create a structure to hold values for all annuity types
allAnnuityValues = struct();
sampleValues = struct();
allSampleValues = struct();
referenceTime = utilities.DefaultSimulationParameters.defaultReferenceTime;



localPerson = person;
frequency = localPerson.CashflowStrategy.Frequency; %utilities.FrequencyType.Annually;
annuityIncome= localPerson.TargetIncome; %100000;
annuityIncomeGtdIncrease = localPerson.CashflowStrategy.InflationRate; %0.03;
baseInflationRate = annuityIncomeGtdIncrease;
annuityStartDate  = localPerson.CashflowStrategy.StartDate;
sampleAge = localPerson.Age;
defermentPeriod = localPerson.IncomeDeferement;
maxNumPmts = localPerson.CashflowStrategy.MaxNumPayments ;



baseLevelInterestRate = 0.03;
levelRate = baseLevelInterestRate;



% Define the mapping for loop variable values using AnnuityInputType enumeration
% valueMap = containers.Map(...
%     {char(AnnuityInputType.InterestRate), char(AnnuityInputType.AnnuityTerm),...
%      char(AnnuityInputType.Age), char(AnnuityInputType.DefermentPeriod)},...
%      char(AnnuityInputType.AnnuityIncomeGtdIncrease)},...
%     {@() (-0.02:0.01:baseLevelRate + 0.07),...
%      @() (5:1:maxNumPmts + 10),...
%      @() (sampleAge:1:sampleAge + 20),...
%      @() [0 5 10]},...
%      @() (0:0.01:inflationRate + 0.02)});

valueMap = containers.Map({char(AnnuityInputType.InterestRate), char(AnnuityInputType.AnnuityTerm), char(AnnuityInputType.Age), char(AnnuityInputType.DefermentPeriod), char(AnnuityInputType.AnnuityIncomeGtdIncrease)}, ...
    {@() (-0.02:0.01:baseLevelInterestRate + 0.07), @() (5:1:maxNumPmts + 10), @() (sampleAge:1:sampleAge + 20), @() (0:5:defermentPeriod+5), @() (0:0.01:baseInflationRate + 0.02)});

% Get the keys from the valueMap (AnnuityInputType names)
keys = valueMap.keys();

% Initialize the loopVariables struct array
loopVariables(length(keys)).name = ''; % Preallocate
for i = 1:length(keys)
    loopVariables(i).name = keys{i}; %keys are in alphabetcial orfder
    loopVariablesRangeFunction = valueMap(keys{i});
    loopVariables(i).values = loopVariablesRangeFunction(); % Execute the anonymous function to get the values
end



for k = 1:length(annuityTypes)
    annuityType = annuityTypes(k);


    % Define the header names dynamically based on the parameters varied
    %headerNames = {'SampleAge', 'LevelRate', 'AnnuityIncomeGtdIncrease', 'DefermentPeriod', 'AnnuityValue'};

    outputHeaderNames = [annuityInputTypeNames' 'AnnuityValue'];
    %sampleValues.Properties.VariableNames = headerNames;
    % Pre-allocate the inner data structure as a table
    variableCount = length(outputHeaderNames);
    tableSize = [length(length(loopVariables(loopVariableIndexes(1)).values))*length(loopVariables(loopVariableIndexes(2)).values) variableCount];
    variableTypes = {'double','double','double','double','double','double'};
    sampleValuesTest = table('Size',tableSize,'VariableTypes', variableTypes,'VariableNames',outputHeaderNames);
    rowCounter =1;

    for j = 1:length(loopVariables(loopVariableIndexes(1)).values)

        for i = 1:length(loopVariables(loopVariableIndexes(2)).values)

            % for l = 1:length(loopVariables(loopVariableIndexes(3)).values)

            % Dynamically assign the parameter values to local variables
            for loopVarIndex = 1:length(loopVariableIndexes) % Loop through the two loop variables
                varName = loopVariables(loopVariableIndexes(loopVarIndex)).name;

                % Use the correct counter for each loop variable
                % currently only need 2

                switch loopVarIndex
                    case 1
                        varValue = loopVariables(loopVariableIndexes(loopVarIndex)).values(j);
                    case 2
                        varValue = loopVariables(loopVariableIndexes(loopVarIndex)).values(i);
                    case 3
                        varValue = loopVariables(loopVariableIndexes(loopVarIndex)).values(l);
                end



                % if loopVarIndex == 1
                %     varValue = loopVariables(loopVariableIndexes(loopVarIndex)).values(j);
                % else
                %     varValue = loopVariables(loopVariableIndexes(loopVarIndex)).values(i);
                % end

                switch varName
                    case outputHeaderNames{1} %'Age'
                        localPerson.Age = varValue;
                        sampleAge = varValue;
                    case outputHeaderNames{4} %'DefermentPeriod'
                        defermentPeriod = varValue;
                    case outputHeaderNames{3} %'AnnuityTerm'
                        maxNumPmts = varValue;
                    case outputHeaderNames{5} %'InterestRate'
                        levelRate = varValue;
                    case outputHeaderNames{2} %'DefermentPeriod'
                        annuityIncomeGtdIncrease = varValue;
                    case outputHeaderNames{6} %'DefermentPeriod'
                        annuityPaymentFrequency = varValue;
                        % Add more cases for other variables as needed
                end
            end


            %set up a ratecurve object
            type = 'zero';
            settle = annuityStartDate; %valuationDates(1);
            dates = calyears([1,3,5,10,20,40]);
            compounding = -1;
            basis = 0;
            rates = ones(1,length(dates))*levelRate;
            rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);


            annuityPaymentFrequency= frequency; %utilities.FrequencyType.Annually;

            dateLastAnnuityPayment = annuityStartDate + calyears(defermentPeriod + maxNumPmts);
            dateFirstAnnuityPayment = annuityStartDate + years(defermentPeriod);

            annuityPaymentDates = utilities.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment,annuityPaymentFrequency);

            annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);
            annuity = annuityFactory.createInstrument(localPerson, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,defermentPeriod,maxNumPmts,annuityPaymentFrequency,annuityPaymentDates);

            annuityValue = annuity.presentValue(rateCurve,baseInflationRate, annuityStartDate);

            if and(j==1,i==1)
                sampleValues = struct(...
                    outputHeaderNames{1}, sampleAge,...
                    outputHeaderNames{5}, levelRate,...
                    outputHeaderNames{2}, annuityIncomeGtdIncrease,...
                    outputHeaderNames{3}, maxNumPmts,...
                    outputHeaderNames{4}, defermentPeriod,...
                    'AnnuityValue', annuityValue...
                    );
            else
                sampleValue = struct(...
                    outputHeaderNames{1}, sampleAge,...
                    outputHeaderNames{5}, levelRate,...
                    outputHeaderNames{3}, maxNumPmts,...
                    outputHeaderNames{2}, annuityIncomeGtdIncrease,...
                    outputHeaderNames{4}, defermentPeriod,...
                    'AnnuityValue', annuityValue...
                    );
                sampleValues = [sampleValues;sampleValue];

                %sampleValues(rowCounter,:) = {sampleAge, levelRate, annuityIncomeGtdIncrease, defermentPeriod, annuityValue};


                rowCounter = rowCounter+1;
            end
            %end
        end
    end
    % Store the annuityValues for the current type in the main structure
    % allAnnuityValues.(char(annuityType)) = annuityValues;
    allAnnuityValues(k).AnnuityType = char(annuityType);
    allAnnuityValues(k).Data = sampleValues;
end




end