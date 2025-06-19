function annuityValues = testAnnuities2()
inputArgs = runtimeclasses.initialiseInputArguments();
app.projectBasePath = 'G:\My Drive\Kaparra Software\Rates Analysis';
disp(app.projectBasePath);
format = 'bank';
annuityValues = struct('interest_rate', [], 'annuity_term', [], 'value', []);
% Get all annuity types
annuityTypes = enumeration('AnnuityType');
% Create a structure to hold values for all annuity types
allAnnuityValues = struct();

referenceTime = utilities.DefaultSimulationParameters.defaultReferenceTime;
%run('config.m');


frequencies = enumeration('utilities.FrequencyType');
valuationDates = [datetime("today"),datetime('31/03/2026'),datetime('19/07/2039')];
valuationDates.TimeZone = 'Australia/Sydney';
valuationDates = valuationDates+ referenceTime;

%cashflowStrategy = CashflowStrategy(1000, valuationDates(1), frequency, 0, []);
%person = Person('F',75,"AU",100000,1000,0,1000,frequency,cashflowStrategy);
person = Person();

annuityIncome= 100000;
annuityIncomeGtdIncrease = 0.03;
inflationRate = annuityIncomeGtdIncrease;
annuityStartDate = valuationDates(1);
annuityStartDate = annuityStartDate;
annuityStartDate.TimeZone = 'Australia/Sydney';
annuityIncomeDeferment = 0;

maxPaymentsConst = 40;
%annuityValues = ones(10,maxPaymentsConst);

levelRates =-0.02:0.01:0.10;
for l = 5:5
    frequency = frequencies(l);
    for k = 1:length(annuityTypes)
        annuityType = annuityTypes(k);

        for j = 1:length(levelRates)
            levelRate = levelRates(j);
            %set up a ratecurve object
            type = 'zero';
            settle = valuationDates(1);
            dates = calyears([1,3,5,10,20,40]);
            compounding = -1;
            basis = 0;
            rates = ones(1,length(dates))*levelRate;
            rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);

            for i = 5:1:maxPaymentsConst+10

                term = i;
                annuityPaymentFrequency= frequency;
                dateLastAnnuityPayment = annuityStartDate + calyears(term);
                annuityPaymentDates = utilities.generateDateArrays(annuityStartDate, dateLastAnnuityPayment,annuityPaymentFrequency);

                annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);
                annuity = annuityFactory.createInstrument(person, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,term,annuityPaymentFrequency,annuityPaymentDates);

                annuityValue = annuity.presentValue(rateCurve,inflationRate, valuationDates(1));

                annuityValues(j, term).interest_rate = levelRate;
                annuityValues(j, term).annuity_term = term;
                annuityValues(j, term).value = annuityValue;

            end
        end
        % Store the annuityValues for the current type in the main structure
        allAnnuityValues.([char(annuityType),char(frequency)]) = annuityValues;
    end
end


% Define colors for each interest rate (optional)
colors = ['r', 'g', 'b', 'k'];

for l = 5:5
    frequency = frequencies(l);
    for k = 1:length(annuityTypes)
        annuityType = annuityTypes(k);
        annuityValues = allAnnuityValues.([char(annuityType),char(frequency)]);
        figure; % Create a new figure window
        hold on; % Allow multiple plots on the same axes

        % Loop through each interest rate
        for j = 1:length(levelRates)
            % Extract the annuity terms and values for the current interest rate
            terms = [annuityValues(j, :).annuity_term];
            values = [annuityValues(j, :).value];

            % Plot the data
            plot(terms, values, colors(mod(j-1,length(colors))+1), 'DisplayName', sprintf('%.2f%%', levelRates(j)*100));
        end

        hold off; % Stop allowing multiple plots

        % Add labels and legend
        xlabel('Annuity Term');
        ylabel('Annuity Value');
        title(sprintf('Annuity Value vs. Term for %s', char([char(annuityType),char(frequency)])));
        legend('show'); % Display the legend

        grid on; % Add gridlines (optional)

    end
end

end