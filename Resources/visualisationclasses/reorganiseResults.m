function results = reorganiseResults(results)
Y1 = results.AssetPortfolio.AssetValues;
%Y2 = results.LiabilityValue;
tempTimetable = results.Timetable;

disp("organising timetable of outputs for plotting")



oldVariableNames = {'PV of Portfolio Owner Payments'} ;%, 'Annuity Value Current Date Rate Curve'};
newVariableNames = {'PV of Portfolio Owner Payments StartDate Rate Curve'} ;%, 'Annuity Value Current Date Rate Curve'};
annuityValuationsStartDateRateCurve= results.Timetable.AnnuityValuationSets{1}.ValuationTimeTable;

valuationDates = results.Timetable.Time;
numValuations = length(valuationDates);


for i = 1: numValuations
    currentDate = valuationDates(i);
    dateIndex = find(results.Timetable.AnnuityValuationSets{i}.ValuationTimeTable.Time == currentDate);
    if ~isempty(dateIndex)
        if i ==1
            newTimetable = results.Timetable.AnnuityValuationSets{i}.ValuationTimeTable(dateIndex, :);
        else
            newEntry = results.Timetable.AnnuityValuationSets{i}.ValuationTimeTable(dateIndex, :);
            newTimetable =[newTimetable;newEntry];
        end
    else
        error('The specified date was not found in the timetable.');
    end

end
%newTimetable = timetable(valuationDates', annuityValueCurrentRateCurve, 'VariableNames', {'Annuity Value Current Date Rate Curve'});
newTimetable = renamevars(newTimetable,'PV of Portfolio Owner Payments','PV of Portfolio Owner Payments Current Rate Curve');


tempTimetable = [tempTimetable,annuityValuationsStartDateRateCurve];
tempTimetable = [tempTimetable,newTimetable];
tempTimetable = removevars(tempTimetable, 'AnnuityValuationSets');
tempTimetable = renamevars(tempTimetable,oldVariableNames,newVariableNames);

numInstruments = length(results.AssetPortfolio.PortfolioHoldings); %need to reassign to an updated scenario .Person.AssetPortfolio post simulation run.

for i = 1: numInstruments
    tempTimetable = [tempTimetable,results.AssetPortfolio.PortfolioHoldings{i}.HistoricalValues];
    instrumentName = results.AssetPortfolio.PortfolioHoldings{i}.Name;
    tempTimetable = renamevars(tempTimetable,'Instrument Value', instrumentName);
    % Y6 = [Y5,results.AssetPortfolio.PortfolioHoldings{1}.HistoricalValues(1:end,:)];
    % Y6 = renamevars(Y6,'Instrument Value', 'Bank Account');
    % Y7 = [Y6,results.AssetPortfolio.PortfolioHoldings{2}.HistoricalValues];
    % Y7 = renamevars(Y7,'Instrument Value', 'Market Index Acct');
    % results.TimeTable = Y6;
    % results.TimeTable = Y7;
end
results.Timetable = tempTimetable;

end