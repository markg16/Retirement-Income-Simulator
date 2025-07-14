classdef CashflowStrategy < CashflowInterface & handle
    %CASHFLOWSTRATEGY Strategy for generating cashflows.
    %   Use the static factory methods like createWithDefaultAGATable()
    %   to easily construct common configurations.

    properties (Access = public)
        AnnualAmount
        StartDate
        Frequency
        InflationRate
        MaxNumPayments
        MortalityDataSource % Holds an instance of any MortalityDataSource subclass
        MortalityIdentifier % Generic property to hold the identifier for the mortality table
        BaseLifeTable       % The resulting MortalityTable object
    end
    
    properties (Access = private)
        DEFAULT_TABLE_PATH = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat'
    end
    
    methods (Static)
        % --- STATIC FACTORY METHOD for a default AGA table ---
        function strategy = createWithDefaultAGATable(varargin)
            % Creates a CashflowStrategy using the default Australian Government Actuary table.
            % Optional inputs (varargin) are passed to the main constructor (e.g., 'AnnualAmount').
            
            % 1. Create the specific data source and identifier for this default case.
            defaultDataSource = AustralianGovernmentActuarySource();
            defaultIdentifier = TableNames.ALT_Table2015_17; % A sensible default table
            
            % 2. Call the main constructor, providing the source and identifier.
            %    We also pass along any other user-provided arguments.
            strategy = CashflowStrategy(...
                defaultIdentifier, ...
                defaultDataSource, ...
                varargin{:});
        end
        
        % --- STATIC FACTORY METHOD for an analytical table ---
        function strategy = createWithAnalyticalTable(modelSpec, varargin)
            % Creates a CashflowStrategy using a specified analytical model.
            % Inputs:
            %   modelSpec: A struct defining the analytical model (e.g., Gompertz).
            %   varargin: Optional inputs for the CashflowStrategy constructor.

            if nargin < 1 || ~isstruct(modelSpec)
                error('createWithAnalyticalTable requires a modelSpecification struct as the first argument.');
            end

            % 1. Create the analytical data source.
            analyticalSource = AnalyticalMortalityDataSource();

            % 2. Call the main constructor with the analytical source and its specific identifier.
            strategy = CashflowStrategy(...
                defaultIdentifier, ...
                defaultDataSource, ...
                varargin{:});
        end
    end
    
    methods (Access = public)
        % The main constructor is now simpler. It expects a valid source and identifier.
        function obj = CashflowStrategy(varargin)
            defaultStartDate = utilities.DateUtilities.createDateTime(); %datetime('now');
            
            p = inputParser;
            % It now requires a DataSource and an Identifier. No defaults here.
            addRequired(p, 'MortalityIdentifier', @(x) ~isempty(x));

            addRequired(p, 'MortalityDataSource', @(x) isa(x, 'MortalityDataSource'));

            addParameter(p, 'AnnualAmount', 50000, @isnumeric);
            addParameter(p, 'StartDate', defaultStartDate, @(x) isdatetime(x));
            addParameter(p, 'Frequency', utilities.FrequencyType.Annually, @(x) isa(x,'utilities.FrequencyType'));
            addParameter(p, 'InflationRate', 0.00, @isnumeric);
            addParameter(p, 'MaxNumPayments', 45, @isnumeric);
            
           
            
            % Use keepUnmatched to allow varargin in the static methods to pass through.
            %p.KeepUnmatched = true; 

            parse(p, varargin{:});

            obj.AnnualAmount = p.Results.AnnualAmount;
            obj.StartDate = p.Results.StartDate;


            obj.Frequency = p.Results.Frequency;
            obj.InflationRate = p.Results.InflationRate;
            obj.MaxNumPayments = p.Results.MaxNumPayments;

            obj.MortalityDataSource = p.Results.MortalityDataSource;
            obj.MortalityIdentifier = p.Results.MortalityIdentifier;
            
            if isempty(obj.MortalityDataSource) || isempty(obj.MortalityIdentifier)
                error('CashflowStrategy:MissingInputs', ...
                      'A valid MortalityDataSource and MortalityIdentifier must be provided. Use a static factory method like createWithDefaultAGATable() for convenience.');
            end

            obj.loadBaseTableUsingSource();
        end
        
        % --- REVISED and primary method for loading ---
        function loadBaseTableUsingSource(obj)
            % Loads the base life table using the configured MortalityDataSource
            % and the generic MortalityIdentifier. This is fully polymorphic.
            try
                % The getMortalityTable method in the specific data source will know
                % how to handle the identifier it is given (enum, struct, etc.).
                % This single line works for ANY data source.
                tableObject = obj.MortalityDataSource.getMortalityTable(obj.MortalityIdentifier);
                
                % Ensure a valid handle object was returned
                if isa(tableObject, 'MortalityTable')
                    obj.BaseLifeTable = tableObject;
                else
                    % This might happen if a source incorrectly returns a struct
                    error('CashflowStrategy:InvalidTableType', 'The data source returned a value that was not a valid MortalityTable object.');
                end

            catch ME
                warning('CashflowStrategy:SourceLoadFailed', ...
                        'Failed to load table from configured source: %s. Falling back to legacy file.', ME.message);
                obj.loadOrCreateBaseTableLegacy(); % Fallback
            end
        end
        
        function loadOrCreateBaseTableLegacy(obj)
            % Legacy method to load base life table from a hardcoded path if source fetch fails
            if exist(obj.DEFAULT_TABLE_PATH, 'file')
                data = load(obj.DEFAULT_TABLE_PATH); % Expects 'mortalityRates'
                
                % Ensure data is wrapped in a BasicMortalityTable object
                if isfield(data, 'mortalityTable') && isa(data.mortalityTable, 'MortalityTable')
                    obj.BaseLifeTable = data.mortalityTable;
                elseif isfield(data, 'mortalityRates') && isstruct(data.mortalityRates)
                     obj.BaseLifeTable = BasicMortalityTable(obj.DEFAULT_TABLE_PATH, data.mortalityRates);
                else
                     error('MATLAB:invalidType', 'Default mortality table file has an unexpected format.');
                end
            else
                error('MATLAB:invalidType', 'Default mortality table file not found: %s', obj.DEFAULT_TABLE_PATH);
            end
        end
    
        function cashflows = generateCashflows(obj, startDate, endDate, paymentDates, inflationRate)
            %GENERATECASHFLOWS Generate cashflows
            %   Generates cashflows based on payment dates and filters by mortality
            %   Inputs:
            %       startDate - Start date for cashflows
            %       endDate - End date for cashflows
            %       paymentDates - Array of payment dates
            %       inflationRate - Annual inflation rate
            %   Returns:
            %       cashflows - Array of cashflow amounts

            % Generate basic cashflows
            cashflows = obj.generateBasicCashflows(paymentDates, inflationRate);

            % Apply mortality if table exists
            if ~isempty(obj.BaseLifeTable)
                cashflows = obj.applyMortalityToCashflows(cashflows, paymentDates);
            end
        end
    end
    
    methods (Access = protected)
        
        
        function cashflows = generateBasicCashflows(obj, paymentDates, inflationRate)
            %GENERATEBASICCASHFLOWS Generate basic cashflows without mortality
            %   Inputs:
            %       paymentDates - Array of payment dates
            %       inflationRate - Annual inflation rate
            %   Returns:
            %       cashflows - Array of cashflow amounts
            
            % Calculate payment amount
            paymentAmount = obj.AnnualAmount / obj.Frequency;
            
            % Generate cashflows with inflation
            numPayments = length(paymentDates);
            cashflows = zeros(numPayments, 1);
            
            for i = 1:numPayments
                yearsFromStart = years(paymentDates(i) - obj.StartDate);
                cashflows(i) = paymentAmount * (1 + inflationRate)^yearsFromStart;
            end
        end
        
        function cashflows = applyMortalityToCashflows(obj, cashflows, paymentDates)
            %APPLYMORTALITYTOCASHFLOWS Apply mortality to cashflows
            %   Inputs:
            %       cashflows - Array of cashflow amounts
            %       paymentDates - Array of payment dates
            %   Returns:
            %       cashflows - Array of mortality-adjusted cashflow amounts
            
            % Get mortality probabilities
            mortalityProbs = obj.calculateMortalityData(paymentDates);
            
            % Apply mortality to cashflows
            cashflows = cashflows .* mortalityProbs;
        end
        
        function mortalityProbs = calculateMortalityData(obj, paymentDates)
            %CALCULATEMORTALITYDATA Calculate mortality probabilities
            %   Inputs:
            %       paymentDates - Array of payment dates
            %   Returns:
            %       mortalityProbs - Array of survival probabilities
            
            % Get number of payments
            numPayments = length(paymentDates);
            mortalityProbs = ones(numPayments, 1);
            
            % Calculate survival probabilities
            for i = 1:numPayments
                yearsFromStart = years(paymentDates(i) - obj.StartDate);
                age = obj.BaseLifeTable.Age + yearsFromStart;
                mortalityProbs(i) = obj.BaseLifeTable.getSurvivalProbability(age);
            end
        end
    end
end