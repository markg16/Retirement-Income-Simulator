function allSampleValues = calculateSampleAnnuityValuesTest(person)
% loopVariableIndexes is expected to be a 1*3 array of doubles. The first
% two positions represent variabels that will be shown on the the x and y axis 
% and the third position% represents the variable to show by seperate line plots on same graph.  


format = 'bank';
% Pre-allocate annuityValues as an empty struct with the desired fields
%annuityValues = struct('sampleAge',[],'levelRate',[],'annuityIncomeGtdIncrease',[],'defermentPeriod',[],'annuityValue',[]);
%annuityValues = struct();
% Get all annuity types
annuityTypes = enumeration('AnnuityType');



% Create a structure to hold values for all annuity types

%sampleValues = struct();
%allSampleValues = struct();
%referenceTime = utilities.DefaultSimulationParameters.defaultReferenceTime;
localPerson = person;
%run('config.m');

frequency = localPerson.CashflowStrategy.Frequency; %utilities.FrequencyType.Annually;
annuityIncome= localPerson.TargetIncome; %100000;
annuityIncomeGtdIncrease = localPerson.CashflowStrategy.InflationRate; %0.03;
inflationRate = annuityIncomeGtdIncrease;
annuityStartDate  = localPerson.CashflowStrategy.StartDate;


defermentPeriod = localPerson.IncomeDeferement;

maxNumPmts = localPerson.CashflowStrategy.MaxNumPayments ;

baseLevelRate = 0.03;
sampleAge = localPerson.Age;
defermentPeriods = [0 5 10];
sampleAges = [person.Age, person.Age + 5];
annuityTypes = enumeration('AnnuityType'); % Assuming you have this enumeration

% Pre-allocate the main data structure as a struct array
allSampleValues = struct('AnnuityType',[], 'Data',[]); 
allSampleValues = repmat(allSampleValues, length(annuityTypes), 1); % create a struct array with length(annuityTypes0 as number of rows. I column. Each struct will have fields AnnuityType and Data)

for k = 1:length(annuityTypes)
    annuityType = annuityTypes(k);
    
   
    % Define the header names dynamically based on the parameters varied
    outputHeaderNames = {'SampleAge', 'LevelRate', 'AnnuityIncomeGtdIncrease', 'DefermentPeriod', 'AnnuityValue'};
    %sampleValues.Properties.VariableNames = headerNames;
    % Pre-allocate the inner data structure as a table
    variableCount = length(outputHeaderNames);
    tableSize = [length(sampleAges)*length(defermentPeriods) variableCount]; 
    variableTypes = {'double','double','double','double','double'};
    sampleValues = table('Size',tableSize,'VariableTypes', variableTypes,'VariableNames',outputHeaderNames);
    rowCounter =1;

    for j = 1:length(sampleAges)
        levelRate = baseLevelRate;
        sampleAge = sampleAges(j);
        localPerson.Age = sampleAge;
        %set up a ratecurve object
        type = 'zero';
        settle = annuityStartDate; %valuationDates(1);
        dates = calyears([1,3,5,10,20,40]);
        compounding = -1;
        basis = 0;
        rates = ones(1,length(dates))*levelRate;
        rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);

        for i = 1:length(defermentPeriods)


            %... (your existing code to calculate annuityValue)...
            defermentPeriod = defermentPeriods(i);
            annuityPaymentFrequency= frequency; %utilities.FrequencyType.Annually;
            dateLastAnnuityPayment = annuityStartDate + calyears(defermentPeriod+maxNumPmts);

            dateFirstAnnuityPayment = annuityStartDate + years(defermentPeriod);
            annuityPaymentDates = utilities.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment,annuityPaymentFrequency);

            annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);

            annuity = annuityFactory.createInstrument(localPerson, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,defermentPeriod,maxNumPmts,annuityPaymentFrequency,annuityPaymentDates);

            annuityValue = annuity.presentValue(rateCurve,inflationRate, annuityStartDate);
       

            % Append a new row to the table
        
            sampleValues(rowCounter,:) = {sampleAge, levelRate, annuityIncomeGtdIncrease, defermentPeriod, annuityValue};

            rowCounter = rowCounter +1;
        end

       
    end

    % Store the annuityValues table in the main structure
    allSampleValues(k).AnnuityType = char(annuityType);
    allSampleValues(k).Data = sampleValues;
end

