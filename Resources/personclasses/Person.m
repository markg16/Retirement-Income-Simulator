classdef Person < handle
    %UNTITLED9 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Gender
        Age
        Country
        InitialValue
        TargetIncome
        ActualIncome
        IncomeDeferement
        Contribution
        ContributionFrequency
        ContributionPeriod
        ImprovementStrategy 
        ImprovementFactorFile char
        CashflowStrategy
        AssetPortfolio % Reference to the AssetPortfolio object
        Annuity % Reference to an Annuity object that represents payments to the owner of the portfolio
        PortfolioTimeTable
        FutureMortalityTable 
    end

    methods
        function obj = Person(varargin)
            %UNTITLED9 Construct an instance of this class
            %   Detailed explanation goes here

            % Default values
            defaultGender = 'Male';
            defaultAge = 60;
            defaultCountry = "AU"; 
            defaultInitialValue = 100000;
            defaultTargetIncome = 50000;
            defaultDeferment = 10;
            defaultContributionPeriod = defaultDeferment;
            defaultTargetContribution = 10000;
            defaultContributionFrequency = utilities.FrequencyType.Monthly; % Monthly
            defaultImprovementStrategy = ConstantImprovementFactorStrategy(0); 
            defaultImprovementFile = ''; % Default to no file
            defaultCashflowStrategy = CashflowStrategy.createWithDefaultAGATable('AnnualAmount',defaultTargetIncome); % Example strategy

            % Define parser
            p = inputParser;
            addParameter(p, 'Gender', defaultGender, @(x) ismember(x, {'Male', 'Female'}));
            addParameter(p, 'Age', defaultAge, @(x) isnumeric(x) && x > 0);
            addParameter(p, 'Country', defaultCountry, @(x) isstring(x));
            addParameter(p, 'InitialValue', defaultInitialValue, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'TargetIncome', defaultTargetIncome, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'IncomeDeferement', defaultDeferment, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'Contribution', defaultTargetContribution, @(x) isnumeric(x) && x >= 0);
            addParameter(p, 'ContributionPeriod' ,defaultContributionPeriod,@(x) isnumeric(x) && x >= 0);
            addParameter(p, 'ContributionFrequency', defaultContributionFrequency, @(x) utilities.ValidationUtils.validateWithParser(@utilities.ValidationUtils.validateContributionFrequency, x, p));
            addParameter(p, 'ImprovementStrategy', defaultImprovementStrategy, @(x) isa(x, 'ImprovementFactorStrategy'));
            addParameter(p, 'ImprovementFactorFile', defaultImprovementFile, @ischar);
            addParameter(p, 'CashflowStrategy', defaultCashflowStrategy, @(x) isa(x, 'CashflowInterface'));

            % Parse input
            parse(p, varargin{:});

            % Assign properties
            obj.Gender = p.Results.Gender;
            obj.Age = p.Results.Age;
            obj.Country = p.Results.Country;
            obj.InitialValue = p.Results.InitialValue;
            obj.TargetIncome = p.Results.TargetIncome;
            obj.IncomeDeferement = p.Results.IncomeDeferement;
            obj.Contribution = p.Results.Contribution;
            obj.ContributionPeriod = p.Results.ContributionPeriod;
            obj.ContributionFrequency = p.Results.ContributionFrequency;
            obj.ImprovementStrategy = p.Results.ImprovementStrategy;
            obj.ImprovementFactorFile = p.Results.ImprovementFactorFile;
            obj.CashflowStrategy = p.Results.CashflowStrategy;
            obj.setFutureMortalityTable();

            %obj.FutureMortalityTable = obj.setFutureMortalityTable();
        end

        function cashflows = generateCashflows(obj, startDate, endDate, paymentDates, inflationRate)
            cashflows = obj.CashflowStrategy.generateCashflows(startDate, endDate, paymentDates, inflationRate);
        end

        function presentValue = valueCashflows(obj, rateCurve, cashflows)
            presentValue = obj.CashflowStrategy.valueCashflows(rateCurve, cashflows);
        end

        function setFutureMortalityTable(obj)
            
% This method now uses the configured ImprovementStrategy and FactorFile
            % properties to create the decorator.
            
            % The strategy to use is already stored as a property
            improvementFactorCalulationAlgo = obj.ImprovementStrategy;
            
            % Handle cases where the strategy requires a file
            if isa(improvementFactorCalulationAlgo, 'MeanImprovementFactorStrategy')
                if isempty(obj.ImprovementFactorFile)
                    error('Person:MissingFile', 'MeanImprovementFactorStrategy requires a valid ImprovementFactorFile to be provided.');
                elseif ~isfile(obj.ImprovementFactorFile)
                     error('Person:FileNotFound', 'The specified ImprovementFactorFile was not found: %s', obj.ImprovementFactorFile);
                end
                 improvementFactorsFile = obj.ImprovementFactorFile;
            else
                % For other strategies like Constant, the file might not be needed,
                % so we pass a dummy value that loadImprovementFactors can ignore.
                improvementFactorsFile = 'dummy.txt'; % Or handle more elegantly in the strategy itself
            end
            
            % Get the base table and cache manager from the cashflow strategy
            baseTable = obj.CashflowStrategy.BaseLifeTable;
            cacheManager = obj.CashflowStrategy.MortalityDataSource.getCacheManager();
            
            % Create the decorator with the injected dependencies
            obj.FutureMortalityTable = CachedImprovementFactorDecorator(...
                baseTable, ...
                improvementFactorsFile, ...
                improvementFactorCalulationAlgo, ...
                obj.Age, ...
                cacheManager);


            % cashflowStrategy = obj.CashflowStrategy;
            % defaultImprovementFactor = 0.05;
            % gender = obj.Gender;
            % startAge = obj.Age;
            % country = obj.Country;
            % 
            % %TODO set tablefilepath and improvementfactros file using
            % %country as key
            % try
            %     if country == "AU"
            %         % tableFilePath = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat';
            % 
            %         improvementFactorsFile = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Improvement_factors_2015-17.xlsx';
            %     else
            %         error('setting up person with country outside Australia')
            %     end
            % catch ME
            %     disp(ME.message)
            % end
            % 
            % % workflow
            % % read in mortality tables from a file 
            % 
            % baseTable = cashflowStrategy.BaseLifeTable;
            % cacheManager = cashflowStrategy.MortalityDataSource.getCacheManager();
            % 
            % % set the algorithm  to calculate the improvement factors from
            % % source files
            % improvementFactorCalulationAlgo = MeanImprovementFactorStrategy(); 
            % 
            % %set up the decorator to convert the base table to the improved
            % %table
            % futureMortalityTableDecorator = CachedImprovementFactorDecorator(baseTable,improvementFactorsFile, improvementFactorCalulationAlgo,startAge,cacheManager);
        end

        function set.FutureMortalityTable(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'FutureMortalityTable' property.

            % We allow setting the property to an empty value (e.g., during initialization).
            % But if a non-empty value is provided, we validate its class.
            if ~isempty(value)
                mustBeA(value, 'MortalityTable');
            end

            % Assign the validated value to the property.
            obj.FutureMortalityTable = value;
        end
        function set.ImprovementStrategy(obj, value)
            % This 'set' method is automatically called whenever a value
            % is assigned to the 'FutureMortalityTable' property.

            % We allow setting the property to an empty value (e.g., during initialization).
            % But if a non-empty value is provided, we validate its class.
            if ~isempty(value)
                mustBeA(value, 'ImprovementFactorStrategy');
            end

            % Assign the validated value to the property.
            obj.ImprovementStrategy = value;
        end

        function personCountry = getPersonCountry(obj)

            personCountry = obj.Country;

        end

        function portfolioCountry = getPortfolioCountry(obj)

            portfolioCountry = obj.AssetPortfolio.Country;
        end
    end
end