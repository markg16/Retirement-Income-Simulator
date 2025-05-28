classdef (Abstract) Instrument
    properties
        Name
        StartDate datetime
        Quantity 
        InitialPrice
        CurrentPrice
        HistoricalValues
    end

    
    methods (Abstract)
        value = getCurrentValue(obj, valuationDate,marketData,scenarioData);
    end
   
   

    methods % concrete implementation of an instrument.
            function obj = Instrument()
                % Initialize properties with default values if needed
                obj.Name = '';
                obj.Quantity = 0;
                obj.InitialPrice = 0;
                obj.CurrentPrice = 0;
                % create an empty timetable with the instruments prices
                Time = datetime.empty(0, 1); % Empty datetime array
                Time.TimeZone = 'Australia/Sydney'; % poison pill one day this needs to be set dynamically
                InstrumentPrice = [];        % Empty numeric array
                TT = timetable(Time, InstrumentPrice, 'VariableNames', {'Instrument Value'});
                obj.HistoricalValues = TT;
            end
            
            function obj = updateHistoricalValues(obj,currentDate,currentValue)
                valueHeader = 'Instrument Value';
                historicalValues = obj.HistoricalValues;
                newTimeTable = timetable(currentDate, currentValue, 'VariableNames', {valueHeader});
                historicalValues = [historicalValues ; newTimeTable];
                obj.HistoricalValues  = historicalValues;
            end
    end
end