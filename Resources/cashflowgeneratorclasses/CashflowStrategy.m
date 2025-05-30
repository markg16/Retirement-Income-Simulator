classdef CashflowStrategy < CashflowInterface & handle
    %CASHFLOWSTRATEGY Strategy for generating cashflows
    %   Implements cashflow generation strategy with mortality table integration
    
    properties (Access = public)
        AnnualAmount      % Annual payment amount
        StartDate         % Start date for payments
        Frequency         % Payment frequency
        InflationRate     % Annual inflation rate
        BaseLifeTable     % Base mortality table
        MaxNumPayments    % Maximum number of payments
        TableName         % TableNames enum for mortality table
        MortalityDataSource      % MortalityDataSource instance
    end
    
    properties (Access = private)
        DEFAULT_TABLE = TableNames.ALT_Table2015_17  % Default table to use
        DEFAULT_TABLE_PATH = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\Australian_Life_Tables_2015-17.mat'  % Default table path
    end
    
    methods (Access = public)
        function obj = CashflowStrategy(varargin)
            %CASHFLOWSTRATEGY Constructor
            %   Initializes cashflow strategy with optional parameters
            p = inputParser;
            addParameter(p, 'AnnualAmount', 1000, @isnumeric);
            addParameter(p, 'StartDate', datetime('now'), @(x) isdatetime(x));
            addParameter(p, 'Frequency', 12, @isnumeric);
            addParameter(p, 'InflationRate', 0.02, @isnumeric);
            addParameter(p, 'BaseLifeTable', [], @(x) isempty(x) || isa(x, 'BaseLifeTable'));
            addParameter(p, 'MaxNumPayments', 1200, @isnumeric);
            addParameter(p, 'TableName', obj.DEFAULT_TABLE, @(x) isa(x, 'TableNames'));
            addParameter(p, 'MortalityDataSource', AustralianGovernmentActuarySource(), @(x) isa(x, 'MortalityDataSource'));
            parse(p, varargin{:});
            
            obj.AnnualAmount = p.Results.AnnualAmount;
            obj.StartDate = p.Results.StartDate;
            obj.Frequency = p.Results.Frequency;
            obj.InflationRate = p.Results.InflationRate;
            obj.BaseLifeTable = p.Results.BaseLifeTable;
            obj.MaxNumPayments = p.Results.MaxNumPayments;
            obj.TableName = p.Results.TableName;
            obj.MortalityDataSource = p.Results.MortalityDataSource; % Store the data source
            
             % Load the table upon construction or lazily
            if isempty(p.Results.BaseLifeTable)
                obj.loadBaseTableUsingSource(); % New primary method
            else
                obj.BaseLifeTable = p.Results.BaseLifeTable;
            end

            % % Initialize cache manager
            % obj.CacheManager = MortalityCacheManager();
        end
        function loadBaseTableUsingSource(obj)
            % Loads the base life table using the configured MortalityDataSource
            try
                % The getMortalityTable method in AustralianGovernmentActuarySource
                % already uses the cache internally.
                mortalityDataStruct = obj.MortalityDataSource.getMortalityTable(obj.TableName);

                % Now, wrap this struct in a BasicMortalityTable object
                % The 'tableFilePath' for BasicMortalityTable can be descriptive
                obj.BaseLifeTable = BasicMortalityTable( ...
                    sprintf('%s - %s', obj.MortalityDataSource.SourceName, char(obj.TableName)), ...
                    mortalityDataStruct ...
                    );
                obj.BaseLifeTable.TableName = char(obj.TableName);
            catch ME
                warning('CashflowStrategy:SourceLoadFailed', ...
                    'Failed to load table from configured source: %s. Falling back to legacy file.', ME.message);
                obj.loadOrCreateBaseTableLegacy(); % Your existing fallback
            end
        end

               
        function loadOrCreateBaseTableLegacy(obj)
            %LOADORCREATEBASETABLELEGACY Legacy method to load base life table
            %   Loads table from default path if source fetch fails
            if isempty(obj.BaseLifeTable)
                if exist(obj.DEFAULT_TABLE_PATH, 'file')
                    load(obj.DEFAULT_TABLE_PATH);
                    obj.BaseLifeTable = mortalityTable;
                else
                    error('MATLAB:invalidType', 'Default mortality table file not found: %s', obj.DEFAULT_TABLE_PATH);
                end
                endif isempty(obj.BaseLifeTable)
                if exist(obj.DEFAULT_TABLE_PATH, 'file')
                    % Load data from file
                    data = load(obj.DEFAULT_TABLE_PATH); % Expects 'mortalityRates' with Male/Female

                    % Ensure consistency if file has M/F
                    if isfield(data.mortalityRates, 'M') && isfield(data.mortalityRates, 'F')
                        actualRates.Male = data.mortalityRates.M;
                        actualRates.Female = data.mortalityRates.F;
                    else
                        actualRates = data.mortalityRates;
                    end
                    obj.BaseLifeTable = BasicMortalityTable(obj.DEFAULT_TABLE_PATH, actualRates);
                    obj.BaseLifeTable.TableName = char(obj.DEFAULT_TABLE);
                else
                    error('MATLAB:invalidType', 'Default mortality table file not found: %s', obj.DEFAULT_TABLE_PATH);
                end
            end
        end
        
        % function cacheKey = generateCacheKey(obj)
        %     %GENERATECACHEKEY Generate cache key for current table
        %     %   Returns:
        %     %       cacheKey - String key for cache lookup
        %     cacheKey = sprintf('%s_%s', class(obj.MortalitySource), char(obj.TableName));
        % end
        
        % function clearCache(obj)
        %     %CLEARCACHE Clear the cache
        %     obj.CacheManager.clearCache();
        % end
        % 
        % function stats = getCacheStats(obj)
        %     %GETCACHESTATS Get cache statistics
        %     %   Returns:
        %     %       stats - Struct containing cache statistics
        %     stats = obj.CacheManager.getCacheStats();
        % end
    
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