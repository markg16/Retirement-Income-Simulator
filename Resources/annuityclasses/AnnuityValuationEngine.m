% File: AnnuityValuationEngine.m
classdef AnnuityValuationEngine < handle
    properties
        
        Person Person
        AnnuityFactory
        RateCurveProvider %marketdata.RateCurveProviderBase
        MortalityDataSourceManager
    end

    methods
        function obj = AnnuityValuationEngine(person,annuityType,mortalityDataSourceManager)
            % The constructor is now simpler. It doesn't need the RateCurveProvider,
            % as that will be part of the config passed to the run method.

            if ~isa(mortalityDataSourceManager, 'DataSourceManager')
                error('AnnuityValuationEngine:InvalidInput', 'A valid DataSourceManager object must be provided.');
            end

            obj.Person = person;
            obj.AnnuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);
            obj.MortalityDataSourceManager = mortalityDataSourceManager;

        end
        % function set.RateCurveProvider(obj, value)
        %     % This 'set' method is automatically called whenever a value
        %     % is assigned to the 'RateCurveProvider' property.
        % 
        %     % We allow setting it to empty, but if a value is provided,
        %     % we validate that it is the correct type of handle object.
        %     if ~isempty(value)
        %         % mustBeA checks if 'value' is an instance of the class
        %         % or any of its subclasses. This is perfect for your abstract class.
        %         mustBeA(value, 'marketdata.RateCurveProviderBase');
        %     end
        % 
        %     % If validation passes, assign the value to the property.
        %     obj.RateCurveProvider = value;
        % end

        function resultsTable = runAnnuitySensitivityAnalysis(obj,  config )
            % Runs a 2D sensitivity analysis and returns the results in a table.
            % xAxisVarEnum: The AnnuityInputType enum member for the x-axis.
            % lineVarEnum:  The AnnuityInputType enum member for the different lines.
            

            % Get loop values directly from the config object
            xAxisValues = config.XAxisValues;
            lineVarValues = config.LineVarValues;
            xAxisEnum = config.XAxisEnum;
            lineVarEnum = config.LineVarEnum;
           
            %set up ratecurve provider property from config object
            obj.RateCurveProvider = config.RateCurveProvider;           

            % Pre-allocate results array of structs for speed
            %numRows = length(config.xAxis.values) * length(config.lineVar.values);
            numRows = length(xAxisValues) * length(lineVarValues);

            if numRows == 0
                resultsTable = table();
                warning('AnnuityValuationEngine:NoScenarios', 'No scenarios to run based on the provided looping variable ranges.');
                return;
            end
           % results(numRows) = struct(config.xAxis.name, [], config.lineVar.name, [], 'AnnuityValue', []);
            results(numRows) = struct(char(xAxisEnum), [], char(lineVarEnum), [], 'AnnuityValue', []);

            rowCounter = 1;

            % Determine if either axis is rate-based to simplify logic inside the loop
            isXAxisRateBased = (xAxisEnum == AnnuityInputType.InterestRate || xAxisEnum == AnnuityInputType.ValuationDate);
            isLineVarRateBased = (lineVarEnum == AnnuityInputType.InterestRate || lineVarEnum == AnnuityInputType.ValuationDate);

            for lineValCell = lineVarValues
                lineVal = lineValCell{:};
                for xValCell = xAxisValues
                    xVal = xValCell{:};

                    % --- 2. Create a temporary struct of parameters for THIS iteration ---
                    currentParams = obj.getBaseParams();

                    % Overwrite base parameters with the current loop variables
                    currentParams = obj.updateParamsForLoop(currentParams, xAxisEnum, xVal);
                    currentParams = obj.updateParamsForLoop(currentParams, lineVarEnum, lineVal);

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
                    results(rowCounter).(char(config.XAxisEnum)) = xVal;
                    results(rowCounter).(char(config.LineVarEnum)) = lineVal;
                    results(rowCounter).AnnuityValue = annuityValue;
                    rowCounter = rowCounter + 1;
                end
            end
            resultsTable = struct2table(results);
        end
    end
    
    methods (Access = private)
  
        function params = updateParamsForLoop(obj, params, paramEnum, value)
            switch paramEnum
                case AnnuityInputType.Age
                    params.Age = value;
                case AnnuityInputType.DefermentPeriod
                    params.IncomeDeferement = value;
                case AnnuityInputType.AnnuityTerm
                    params.MaxNumPayments = value;
                case AnnuityInputType.AnnuityIncomeGtdIncrease
                    params.InflationRate = value;
                case AnnuityInputType.MortalityIdentifier

                    mortalityDataSourceManager = obj.MortalityDataSourceManager;
                    mortalityDataSource = mortalityDataSourceManager.getDataSourceForTable(value);
                    params.MortalityDataSource = mortalityDataSource;
                    params.MortalityIdentifier = value;

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
        
        function baseParams = getBaseParams(obj)
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

        end

        
        
    end
end