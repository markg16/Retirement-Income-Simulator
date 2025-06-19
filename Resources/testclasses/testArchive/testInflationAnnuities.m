function  [inflatedCashFlows,inflatedPayment,presentValue] = testInflationAnnuities()
referenceTime = utilities.DefaultSimulationParameters.defaultReferenceTime;
frequencies = enumeration('utilities.FrequencyType');
valuationDates = [datetime("today"),datetime('31/03/2026'),datetime('19/07/2039')];
valuationDates.TimeZone = 'Australia/Sydney';
valuationDates = valuationDates+ referenceTime;



person = Person();
levelInterestRate = 0.03;
annuityTypes = enumeration('AnnuityType');
annuityIncome= 100000;
annuityIncomeGtdIncrease = 0.00;
inflationRate = annuityIncomeGtdIncrease;
annuityStartDate = valuationDates(1);
annuityStartDate = annuityStartDate;
annuityStartDate.TimeZone = 'Australia/Sydney';
annuityIncomeDeferment = 0;
maxPaymentsConst = 40;
term = maxPaymentsConst;
annuityPaymentFrequency= utilities.FrequencyType.Annually;

dateLastAnnuityPayment = annuityStartDate + calyears(term);
annuityPaymentDates = utilities.generateDateArrays(annuityStartDate, dateLastAnnuityPayment,annuityPaymentFrequency);

%create an annuity
annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(AnnuityType.FixedAnnuity);
annuity = annuityFactory.createInstrument(person, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityIncomeDeferment,term,annuityPaymentFrequency,annuityPaymentDates);

%create interest rate curve 
type = 'zero';
settle = valuationDates(1);
dates = calyears([1,3,5,10,20,40]);
compounding = -1;
basis = 0;
rates = ones(1,length(dates))*levelInterestRate;
rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);

%create inflation rate curve DONE INSIDE THE ANNUITY CREATION

currentDate = annuityStartDate;

%generate inflated annuity cashflows
inflatedCashFlows = annuity.generateCashFlows(annuityPaymentDates, 'valuationDate',currentDate);

%get current Annuity oayment

inflatedPayment = annuity.getAnnuityPaymentAmount(annuityStartDate,currentDate +years(10));

%get current annuity value

%currentValue = annuity.getCurrentValue(obj,currentDate, marketData, scenarioData);

% calculate present Value
defaultInflationRate = 0;
presentValue = annuity.presentValue(rateCurve,defaultInflationRate,currentDate);

end