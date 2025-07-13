% File: AnnuityValuationEngine.m
classdef AnnuityValuationEngine < handle
    properties
        Person Person
        AnnuityFactory
        RateCurveProvider %marketdata.RateCurveProviderBase
    end

    methods
        function obj = AnnuityValuationEngine(person, annuityType, rateCurveProvider)
            obj.Person = person;
            obj.AnnuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);
            obj.RateCurveProvider = rateCurveProvider;
        end
        function set.RateCurveProvider(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'RateCurveProvider' property.

            % We allow setting it to empty, but if a value is provided,
            % we validate that it is the correct type of handle object.
            if ~isempty(value)
                % mustBeA checks if 'value' is an instance of the class
                % or any of its subclasses. This is perfect for your abstract class.
                mustBeA(value, 'marketdata.RateCurveProviderBase');
            end

            % If validation passes, assign the value to the property.
            obj.RateCurveProvider = value;
        end

        function resultsTable = runAnnuitySensitivityAnalysis(obj, xAxisVarEnum, lineVarEnum)
            % Runs a 2D sensitivity analysis and returns the results in a table.
            % xAxisVarEnum: The AnnuityInputType enum member for the x-axis.
            % lineVarEnum:  The AnnuityInputType enum member for the different lines.
            
            % Use a config struct for clarity
            config.xAxis.enum = xAxisVarEnum;
            config.xAxis.name = char(xAxisVarEnum);
            config.lineVar.enum = lineVarEnum;
            config.lineVar.name = char(lineVarEnum);
            config.xAxis.values = obj.getValuesForParam(config.xAxis.enum);
            config.lineVar.values = obj.getValuesForParam(config.lineVar.enum);
            
            % Pre-allocate results array of structs for speed
            numRows = length(config.xAxis.values) * length(config.lineVar.values);

            if numRows == 0
                resultsTable = table();
                warning('AnnuityValuationEngine:NoScenarios', 'No scenarios to run based on the provided looping variable ranges.');
                return;
            end

            %Gather the BASE parameters from the initial Person object ---
            % We will use these as the starting point for each iteration.
            baseParams.Gender = obj.Person.Gender;
            baseParams.Country = obj.Person.Country;
            baseParams.InitialValue = obj.Person.InitialValue;
            baseParams.TargetIncome = obj.Person.TargetIncome;
            baseParams.Contribution = obj.Person.Contribution;
            baseParams.ContributionPeriod = obj.Person.ContributionPeriod;
            baseParams.ContributionFrequency = obj.Person.ContributionFrequency;
            baseParams.ImprovementStrategy = obj.Person.ImprovementStrategy;
            baseParams.ImprovementFactorFile = obj.Person.ImprovementFactorFile;

            % Base parameters that might be varied by the loops
            baseParams.Age = obj.Person.Age;
            baseParams.IncomeDeferement = obj.Person.IncomeDeferement;

            % Base CashflowStrategy parameters
            baseParams.AnnualAmount = obj.Person.CashflowStrategy.AnnualAmount;
            baseParams.StartDate = obj.Person.CashflowStrategy.StartDate;
            baseParams.Frequency = obj.Person.CashflowStrategy.Frequency;
            baseParams.InflationRate = obj.Person.CashflowStrategy.InflationRate;
            baseParams.MaxNumPayments = obj.Person.CashflowStrategy.MaxNumPayments;
            baseParams.MortalityDataSource = obj.Person.CashflowStrategy.MortalityDataSource;
            baseParams.MortalityIdentifier = obj.Person.CashflowStrategy.MortalityIdentifier;




            results(numRows) = struct(config.xAxis.name, [], config.lineVar.name, [], 'AnnuityValue', []);

            rowCounter = 1;

            % Determine if either axis is rate-based to simplify logic inside the loop
            isXAxisRateBased = (config.xAxis.enum == AnnuityInputType.InterestRate || config.xAxis.enum == AnnuityInputType.ValuationDate);
            isLineVarRateBased = (config.lineVar.enum == AnnuityInputType.InterestRate || config.lineVar.enum == AnnuityInputType.ValuationDate);

            for lineVal = config.lineVar.values
                for xVal = config.xAxis.values


                    % --- 2. Create a temporary struct of parameters for THIS iteration ---
                    currentParams = baseParams;

                    % Overwrite base parameters with the current loop variables
                    currentParams = obj.updateParamsForLoop(currentParams, config.xAxis.enum, xVal);
                    currentParams = obj.updateParamsForLoop(currentParams, config.lineVar.enum, lineVal);

                    % --- 3. Reconstruct the objects for THIS iteration ---
                    % This ensures all dependent properties are correctly calculated.

                    % Create a temporary cashflow strategy for the person
                    tempCashflowStrategy = CashflowStrategy(currentParams.MortalityIdentifier, currentParams.MortalityDataSource, ...
                        'AnnualAmount', currentParams.AnnualAmount, 'StartDate', currentParams.StartDate, ...
                        'MaxNumPayments', currentParams.MaxNumPayments, 'Frequency', currentParams.Frequency, ...
                        'InflationRate', currentParams.InflationRate);

                    % Create the Person object from scratch using the current iteration's parameters
                    localPerson = Person('Gender', currentParams.Gender, 'Age', currentParams.Age, 'Country', currentParams.Country, ...
                        'TargetIncome', currentParams.TargetIncome, 'IncomeDeferement', currentParams.IncomeDeferement, ...
                        'ImprovementStrategy', currentParams.ImprovementStrategy, 'ImprovementFactorFile', currentParams.ImprovementFactorFile, ...
                        'CashflowStrategy', tempCashflowStrategy);

                    % 4. Get the correct rate curve for this iteration
                    rateCurve = obj.getRateCurveForIteration(isXAxisRateBased, isLineVarRateBased, xVal, lineVal);


                    % 5. Calculate the specific payment dates for this iteration.
                    %    This logic is now correctly placed within the loop.


                    annuityIncome             = localPerson.CashflowStrategy.AnnualAmount;
                    annuityIncomeGtdIncrease  = localPerson.CashflowStrategy.InflationRate/100;
                    annuityStartDate          = localPerson.CashflowStrategy.StartDate;
                    defermentPeriod           = localPerson.IncomeDeferement;
                    maxNumPmts                = localPerson.CashflowStrategy.MaxNumPayments;
                    annuityPaymentFrequency   = localPerson.CashflowStrategy.Frequency;
                    dateFirstAnnuityPayment = annuityStartDate + years(defermentPeriod);
                    dateLastAnnuityPayment = dateFirstAnnuityPayment + ...
                        calmonths( (maxNumPmts-1) * (12 /  double(annuityPaymentFrequency)) );

                    annuityPaymentDates = utilities.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment, annuityPaymentFrequency);
                    % 6. Create and value the annuity instrument
                    annuity = obj.AnnuityFactory.createInstrument(localPerson,...
                        annuityIncome,annuityIncomeGtdIncrease,...
                        annuityStartDate,defermentPeriod,maxNumPmts,...
                        annuityPaymentFrequency,annuityPaymentDates);
                    annuityValue = annuity.presentValue(rateCurve, ...
                        annuityIncomeGtdIncrease, annuityStartDate);

                    %     annuityIncomeGtdIncrease, annuityStartDate);

                    %7. Store results
                    results(rowCounter).(config.xAxis.name) = xVal;
                    results(rowCounter).(config.lineVar.name) = lineVal;
                    results(rowCounter).AnnuityValue = annuityValue;
                    rowCounter = rowCounter + 1;
                end
            end
            resultsTable = struct2table(results);
        end
    end
    
    methods (Access = private)
        function values = getValuesForParam(obj, paramEnum)
            % This method replaces the old valueMap
            baseInflationRate = obj.Person.CashflowStrategy.InflationRate;
            switch paramEnum
                case AnnuityInputType.InterestRate
                    values = obj.RateCurveProvider.getAvailableIdentifiers();
                case AnnuityInputType.ValuationDate
                    values = obj.RateCurveProvider.getAvailableIdentifiers();
                case AnnuityInputType.AnnuityTerm
                    values = 5:1:(obj.Person.CashflowStrategy.MaxNumPayments + 10);
                case AnnuityInputType.Age
                    values = obj.Person.Age:1:(obj.Person.Age + 20);
                case AnnuityInputType.DefermentPeriod
                    values = 0:5:(obj.Person.IncomeDeferement + 5);
                case AnnuityInputType.AnnuityIncomeGtdIncrease
                    values = 0:0.01:(baseInflationRate + 0.02);
                otherwise
                    values = [];
            end
        end
        function params = updateParamsForLoop(~, params, paramEnum, value)
            switch paramEnum
                case AnnuityInputType.Age
                    params.Age = value;
                case AnnuityInputType.DefermentPeriod
                    params.IncomeDeferement = value;
                case AnnuityInputType.AnnuityTerm
                    params.MaxNumPayments = value;
                case AnnuityInputType.AnnuityIncomeGtdIncrease
                    params.InflationRate = value;
            end
        end

        function rateCurve = getRateCurveForIteration(obj, isXAxisRateBased, isLineVarRateBased, xVal, lineVal)
             if isXAxisRateBased
                rateCurveIdentifier = xVal;
            elseif isLineVarRateBased
                rateCurveIdentifier = lineVal;
            else
                defaultIdentifiers = obj.RateCurveProvider.getAvailableIdentifiers();
                if isempty(defaultIdentifiers)
                     error('AnnuityValuationEngine:NoDefaultIdentifier', 'The RateCurveProvider has no available identifiers to create a default curve.');
                end
                rateCurveIdentifier = defaultIdentifiers(1);
            end
            rateCurve = obj.RateCurveProvider.getCurve(rateCurveIdentifier);
        end

        function person = setParameter(obj, person, paramEnum, value)
            % Helper to set the correct property on the person/strategy object
            switch paramEnum
                case AnnuityInputType.Age
                    person.Age = value;
                case AnnuityInputType.DefermentPeriod
                    person.IncomeDeferement = value;
                case AnnuityInputType.AnnuityTerm
                    person.CashflowStrategy.MaxNumPayments = value;
                case AnnuityInputType.AnnuityIncomeGtdIncrease
                    person.CashflowStrategy.InflationRate = value;
                % These cases don't need to doanything because they are handled by the RateCurveProvider,
                % but including them prevents any potential "unhandled enum" errors
                % and makes the code's intent clear.
                case {AnnuityInputType.InterestRate, AnnuityInputType.ValuationDate}
                    % No action needed. These parameters are used to select a rate curve,
                    % not to modify the Person object's properties.
            end
        end
        
    end
end