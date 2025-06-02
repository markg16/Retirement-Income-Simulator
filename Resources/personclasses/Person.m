classdef Person
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
        CashflowStrategy
        AssetPortfolio % Reference to the AssetPortfolio object
        Annuity % Reference to an Annuity object that represents payments to the owner of the portfolio
        PortfolioTimeTable
        FutureMortalityTable BasicMortalityTable

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
            defaultCashflowStrategy = CashflowStrategy('AnnualAmount',defaultTargetIncome); % Example strategy

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
            obj.CashflowStrategy = p.Results.CashflowStrategy;

            obj.FutureMortalityTable = obj.setFutureMortalityTable();
        end

        function cashflows = generateCashflows(obj, startDate, endDate, paymentDates, inflationRate)
            cashflows = obj.CashflowStrategy.generateCashflows(startDate, endDate, paymentDates, inflationRate);
        end

        function presentValue = valueCashflows(obj, rateCurve, cashflows)
            presentValue = obj.CashflowStrategy.valueCashflows(rateCurve, cashflows);
        end

        function futureMortalityTable =setFutureMortalityTable(obj)
            
            cashflowStrategy = obj.CashflowStrategy;
            defaultImprovementFactor = 0.05;
            gender = obj.Gender;
            startAge = obj.Age;
            country = obj.Country;

            %TODO set tablefilepath and improvementfactros file using
            %country as key
            try
                if country == "AU"
                    % tableFilePath = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat';
                    
                    improvementFactorsFile = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Improvement_factors_2015-17.xlsx';
                else
                    error('setting up person with country outside Australia')
                end
            catch ME
                disp(ME.message)
            end

            
            
            % workflow
            % read in mortality tables from a file 

            %baseTable = utilities.LifeTableUtilities.loadOrCreateBaseTable(tableFilePath);
            baseTable = cashflowStrategy.BaseLifeTable;

            % TODO introduce a test to ensure appropriate structure for standard methods
            %genders = fieldnames(baseTable.MortalityRates); 
            
            
            % set the algorithm  to calculate the improvement factors from
            % source files
            improvementFactorCalulationAlgo = MeanImprovementFactorStrategy(); 

            %set up the decorator to convert the base table to the improved
            %table

            futureMortalityTableDecorator = CachedImprovementFactorDecorator(baseTable, defaultImprovementFactor,improvementFactorsFile, improvementFactorCalulationAlgo);

            futureMortalityTable = futureMortalityTableDecorator.createImprovedTable(startAge);
          %   futureMortalityTable = futureMortalityTables.MortalityRates.(gender);


        end
        function personCountry = getPersonCountry(obj)

            personCountry = obj.Country;

        end
        function portfolioCountry = getPortfolioCountry(obj)

            portfolioCountry = obj.AssetPortfolio.Country;

        end

       

    end
end