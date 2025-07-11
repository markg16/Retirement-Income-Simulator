classdef InvestmentReturnUtilities
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Property1
    end
    
    methods (Static)
        function obj = readPriceDataFromFile(inputFolder,inputFile)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here

            %read file 

            
            %standardise datastructure


            
            obj.Property1 = inputArg1 + inputArg2;
        end
        
        function returnsTT = convertPriceDataToReturnsTT(priceDataTT)
            %convertPriceDataToReturnsTT Converts a price timetable to a return timetable
            %
            %   returnsTT = convertPriceDataToReturnsTT(priceDataTT) calculates the
            %   returns between each date in the input priceDataTT timetable for
            %   multiple price series (each in a separate column). The function
            %   accounts for the time between entries in the timetable.
            %
            %   Inputs:
            %       priceDataTT: A timetable with multiple price variables (each in
            %                    a separate column). The row times of the timetable
            %                    should include both date and time of
            %                    day.The timetable must be synchronise(ie
            %                    all times have a price for each variable)
            %
            %   Outputs:
            %       returnsTT: A timetable containing the calculated returns for each
            %                  price series.

            % Get variable names (index names)
            varNames = priceDataTT.Properties.VariableNames;

            % Initialize an empty timetable for returns
            returnsTT = timetable();

            % Loop through each index (variable)
            for i = 1:width(priceDataTT)
                % Extract price data for the current index
                prices = priceDataTT.(varNames{i});

                % Calculate price differences
                priceDiffs = diff(prices);

                % Get the time differences between rows in days
                timeDiffs = days(diff(priceDataTT.Time));

                % Calculate returns % per day (adjusting for time differences)
                returns = priceDiffs ./ prices(1:end-1) ./ timeDiffs./100;

                % Add returns to the returns timetable
                returnsTT = addvars(returnsTT, returns, ...
                    'NewVariableNames', [varNames{i}],... % '_Returns'], ...
                    'Before', 1); % Add at the beginning
            end

            % Set the time for the returns timetable
            returnsTT.Time = priceDataTT.Time(2:end);


            % --- Determine frequency ---

            % Calculate the mode of the time differences in days
            timeDiffs = days(diff(priceDataTT.Time));
            modalDiff = mode(timeDiffs);

            % Determine frequency based on the modal time difference
            if modalDiff == 1
                frequency = "daily";
            elseif modalDiff >= 7 && modalDiff <= 9 % Account for some variation
                frequency = "weekly";
            elseif modalDiff >= 28 && modalDiff <= 31
                frequency = "monthly";
            else
                frequency = "unknown"; % Or handle the unexpected frequency appropriately
                display('historical price data frequency is too irregular to determine a frequency when setting up scenariomarketdata')
            end

            % Add frequency variable to the returns timetable
            returnsTT = addvars(returnsTT, repmat(frequency, size(returnsTT, 1), 1), ...
                'NewVariableNames', 'Frequency'); % Add at the eend
        end
       

        function perPeriodWtdReturnsTT = calculatePortfolioWtdReturns(assetClassReturnsTT,portfolioWeightsTT)
            %UNTITLED Construct an instance of this class
            %   Detailed explanation goes here

            %read file
            availableTickers = assetClassReturnsTT.Properties.VariableNames(1:end-1); % last variable is frequency for simulated returns 
            benchmarkTickers = portfolioWeightsTT.Properties.VariableNames(1:end);
            tempAssetClassReturnsTT =  assetClassReturnsTT(:,benchmarkTickers);

            %convert from timetables

            portfolioWeights = table2array(portfolioWeightsTT);
            perPeriodReturns = table2array(tempAssetClassReturnsTT);                            
            
            %calculate benchmark portfolio return
           
            [numTimePeriods,numAssets]= size(perPeriodReturns);
            portfolioWeights = repmat(portfolioWeights,numTimePeriods,1); % assumes weights are constant

            perPeriodWtdReturns = perPeriodReturns.*portfolioWeights; % assumes 1*M array
            perPeriodWtdReturns = sum(perPeriodWtdReturns,2);
            
            % convert to a timetable based on existing one with only variable

            perPeriodWtdReturnsTT = removevars(assetClassReturnsTT,availableTickers);
            perPeriodWtdReturnsTT = addvars(perPeriodWtdReturnsTT,perPeriodWtdReturns,'NewVariableNames','Benchmark_Return');

            
        end
        
        function assetReturnsTimetable = createAssetReturnsTimetable(assetReturns, assetReturnStartDates, assetReturnEndDates, frequency,tickers)
            %CREATEASSETRETURNSTIMETABLE Create a timetable of asset returns with metadata.
            %
            %   ASSETRETURNSTIMETABLE = CREATEASSETRETURNSTIMETABLE(ASSETRETURNS, ASSETRETURNSTARTDATES, ASSETRETURNENDDATES, FREQUENCY)
            %   takes the following inputs:
            %       ASSETRETURNS: A numeric matrix containing asset returns, where each row represents an asset and each column a period.
            %       ASSETRETURNSTARTDATES: A vector of datetime objects representing the start dates of each period.
            %       ASSETRETURNENDDATES: A vector of datetime objects representing the end dates of each period.
            %       FREQUENCY: A string indicating the frequency of the returns ('daily', 'weekly', 'monthly', etc.).
            %
            %   It returns a timetable ASSETRETURNSTIMETABLE with the following variables:
            %       Time: The end dates of each period.
            %       Return: The corresponding asset returns for each period.
            %       Frequency: The specified frequency as a categorical variable.

           
            [numAssets, numPeriods] = size(assetReturns);
            % Validate input lengths
            if ~isequal(numPeriods, length(assetReturnStartDates), length(assetReturnEndDates))
                error('Input arrays must have the same length.');
            end
            if numAssets ~= numel(tickers)
                error('Number of rows in ASSETRETURNS must match the number of TICKERS.');
            end

            % Create the timetable
            %assetReturnsTimetable = timetable(assetReturnEndDates', assetReturns', 'VariableNames', {'Return'});
            assetReturnsTimetable = array2timetable(assetReturns', 'RowTimes', assetReturnEndDates, 'VariableNames', tickers);

            % Add frequency information
            if isempty(assetReturns)
                assetReturnsTimetable.Frequency = strings(0, 1); % Empty string array if no returns
            else
                assetReturnsTimetable.Frequency = repmat(string(frequency), size(assetReturnsTimetable, 1), 1);
            end
        end
        function annualizedReturnsTT = annualizeReturns(returnsTT)
            %annualizeReturns Annualizes returns based on frequency
            %
            %   annualizedReturnsTT = annualizeReturns(returnsTT) takes a timetable
            %   of returns with a 'Frequency' variable and calculates annualized
            %   returns.
            %
            %   Inputs:
            %       returnsTT: A timetable with return variables and a 'Frequency'
            %                  variable indicating the frequency of the returns
            %                  (e.g., 'daily', 'weekly', 'monthly').
            %
            %   Outputs:
            %       annualizedReturnsTT: A timetable containing the annualized
            %                            returns.

            % Get variable names (return variable names)
            varNames = returnsTT.Properties.VariableNames;
            varNames = varNames(2:end); % Exclude 'Frequency'

            % Initialize an empty timetable for annualized returns
            annualizedReturnsTT = timetable();
            % Convert 'Frequency' to categorical
            %returnsTT.Frequency = categorical(returnsTT.Frequency);


            % Loop through each return variable
            for i = 1:length(varNames)
                % % Extract returns for the current variable
                % returns = returnsTT.(varNames{i});

                % % Get the frequency
                % frequency = returnsTT.Frequency(1); % Assuming frequency is the same for all rows

                % Calculate annualized returns using an anonymous function
                annualizedReturnsTT = rowfun(@(r, f) utilities.InvestmentReturnUtilities.annualizeReturn(r, f), ...
                    returnsTT, 'InputVariables', {varNames{i}, 'Frequency'}, ...
                    'OutputVariableNames', [varNames{i} '_Annualized']);

                % Add annualized returns to the timetable

                annualizedReturnsTT = addvars(annualizedReturnsTT,returnsTT.Frequency,'NewVariableNames','Frequency','Before', 1);
                % %annualizedReturnsTT = addvars(annualizedReturnsTT, annualizedReturns.([varNames{i} '_Annualized']), ...
                %     'NewVariableNames', [varNames{i} '_Annualized'], ...
                %     'Before', 1); % Add at the beginning
            end

            % % Set the time for the annualized returns timetable
            % annualizedReturnsTT.Time = returnsTT.Time;
            % annualizedReturnsTT.Frequency = returnsTT.Frequency;
        end

        function annualizedReturn = annualizeReturn(returnVal, frequency)
            % Calculate annualization factor based on frequency
            switch frequency
                case "daily"
                    annualizationFactor = 220;
                case "Weekly"
                    annualizationFactor = 52;
                case "Monthly"
                    annualizationFactor = 12;
                case "Quarterly"
                    annualizationFactor = 1;
                case "Annually"
                    annualizationFactor = 1;
                otherwise
                    error("Unknown frequency: %s", frequency);
            end

            % Calculate annualized return
            annualizedReturn = (1 + returnVal)^annualizationFactor - 1;
        end
    end
end

