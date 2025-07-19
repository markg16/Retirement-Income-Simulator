% File: CachedImprovementFactorDecorator.m
classdef CachedImprovementFactorDecorator < MortalityTable
   %CACHEDIMPROVEMENTFACTORDECORATOR Decorates a base mortality table with improvement factors.
    %   Delegates the calculation of improvement factors to a provided strategy object.
    %   Uses a CacheManager to store and retrieve pre-calculated improved tables.

    properties (SetAccess = private) % Properties specific to the decorator's function
        BaseTable                   % The underlying MortalityTable being decorated
        ImprovementFactorStrategy   % Strategy object for calculating improvement factors
        ImprovementFactors          % The calculated improvement factors struct
        StartAgeForImprovement      % The age from which improvements are applied for this instance
        CacheManager                % Instance of MortalityCacheManager
    end

    % --- Properties that fulfill the abstract requirements from MortalityTable ---
    properties
        TableName
        SourceType
        SourcePath
        LastUpdated
    end

    % --- Property to hold the actual improved mortality data ---
    properties (SetAccess = private)
        CacheKeyForOwnImprovedTable % Stores the unique cache key for this decorator's data
        MortalityRates % Struct with .Male and .Female, each having .Age, .lx, .qx
                       % This stores the *improved* rates for this decorator instance.
    end

    methods
        function obj = CachedImprovementFactorDecorator(baseTable, improvementFactorsFile, improvementFactorStrategy, startAgeForImprovement, cacheManager)
            
             % --- REVISED CONSTRUCTOR ---
            % It is now much simpler. It validates inputs and delegates the complex
            % factor calculation to the strategy object.
 
            % Inputs:
            %   baseTable:                  Instance of a class implementing MortalityTable
            %   improvementFactorsFile:     Path to file containing raw improvement factors
            %   improvementFactorStrategy:  Instance of a strategy to process raw factors
            %   startAgeForImprovement:     The age from which to apply improvements
            %   cacheManager:               Instance of MortalityCacheManager

            obj@MortalityTable(); % Call superclass constructor

            % Validate inputs
            if ~isa(baseTable, 'MortalityTable')
                error('CachedImprovementFactorDecorator:InvalidInput', 'baseTable must be a MortalityTable object.');
            end
            if ~(isobject(improvementFactorStrategy) && ismethod(improvementFactorStrategy, 'calculateFactors')) % Basic check
                error('CachedImprovementFactorDecorator:InvalidInput', 'improvementFactorStrategy is not a valid strategy object or lacks calculateAverageFactors method.');
            end
            if ~isa(cacheManager, 'utilities.MortalityCacheManager')
                error('CachedImprovementFactorDecorator:InvalidInput', 'cacheManager must be a MortalityCacheManager object.');
            end
            if ~isnumeric(startAgeForImprovement) || ~isscalar(startAgeForImprovement) || startAgeForImprovement < 0
                error('CachedImprovementFactorDecorator:InvalidInput', 'startAgeForImprovement must be a non-negative scalar number.');
            end
            % 2. Assign core properties
            obj.BaseTable = baseTable;
            obj.ImprovementFactorStrategy = improvementFactorStrategy;
            obj.StartAgeForImprovement = startAgeForImprovement;
            obj.CacheManager = cacheManager;
            % 3. Delegate responsibility for calculating factors to the strategy.

            %    The strategy itself will handle whether it needs the file path or the base table.
            try
                obj.ImprovementFactors = obj.ImprovementFactorStrategy.calculateFactors(improvementFactorsFile, obj.BaseTable);

                % Validate the structure returned by the strategy to ensure it's usable
                if ~isstruct(obj.ImprovementFactors) || ~isfield(obj.ImprovementFactors, 'Age') || ...
                        ~isfield(obj.ImprovementFactors, 'Male') || ~isfield(obj.ImprovementFactors, 'Female')
                    error('CachedImprovementFactorDecorator:InvalidIFStructure', 'The provided improvement strategy returned an invalid factors structure.');
                end
            catch ME
                % Catch errors from the strategy (e.g., file not found in Mean strategy) and re-throw
                error('CachedImprovementFactorDecorator:IFStrategyError', 'The improvement factor strategy failed: %s', ME.message);
            end


            
            % 4. Set descriptive and abstract properties
            % Set inherited properties that were abstract in the superclass
            obj.TableName = sprintf('%s_ImpFrom%d_%s', obj.BaseTable.TableName, obj.StartAgeForImprovement, class(obj.ImprovementFactorStrategy));
            obj.SourceType = 'Decorator';
            obj.SourcePath = obj.BaseTable.TableName; % Origin is the base table's name
            obj.LastUpdated = datetime('now');
           
            % 5. Set the unique cache key for this decorator's instance
            obj.CacheKeyForOwnImprovedTable = obj.generateCacheKeyInternal();

            % 6. Generate or load the improved mortality rates from cache
            obj.MortalityRates = obj.getOrGenerateImprovedRatesStruct();
            
            % 7. Validate the final, generated rates structure
            MortalityTableFactory.validateTableData(obj.MortalityRates);
        end

        % --- Implementation of abstract methods from MortalityTable ---
        function rate = getRate(obj, gender, age)
            % Retrieves the pre-calculated improved mortality rate (qx).
            if ~isfield(obj.MortalityRates, gender)
                error('CachedImprovementFactorDecorator:InvalidGender', 'Gender "%s" not found in improved table for table %s.', gender, obj.TableName);
            end
            
            ageIndex = find(obj.MortalityRates.(gender).Age == age, 1);
            if isempty(ageIndex)
                error('CachedImprovementFactorDecorator:AgeNotFound', 'Age %d not found in improved table for gender %s, table %s.', age, gender, obj.TableName);
            end
            rate = obj.MortalityRates.(gender).qx(ageIndex);
        end

        function [lxVal, success, errorMessage] = getLx(obj, gender, age)
            % Retrieves the pre-calculated improved number of lives (lx).
            % Returns a success flag and an error message if the lookup fails.

            % 1. Set default return values for the failure case.
            lxVal = NaN;
            success = false;
            errorMessage = '';

            % 2. Validate that the gender field exists.
            if ~isfield(obj.MortalityRates, gender)
                errorMessage = sprintf('Gender "%s" not found in improved table for table %s.', gender, obj.TableName);
                return; % Exit the function early
            end

            % 3. Find the index for the requested age.
            try
                ageIndex = find(obj.MortalityRates.(gender).Age == age, 1);
            catch
                % This handles cases where .Age might not exist or is not numeric
                errorMessage = sprintf('Could not search for age in table for gender %s.', gender);
                return;
            end

            % 4. Validate that the age was found.
            if isempty(ageIndex)
                errorMessage = sprintf('Age %d not found in improved table for gender %s, table %s.', age, gender, obj.TableName);
                return; % Exit the function early
            end

            % --- Success Case ---
            % If all checks passed, we can get the value and set success to true.
            lxVal = obj.MortalityRates.(gender).lx(ageIndex);
            success = true;
            % No error message is needed on success.
        end
        

        function survivorshipProbabilities = getSurvivorshipProbabilities(obj, gender, currentAge, finalAge)
            % Delegates the calculation to the static utility function.
            % The utility will use this decorator's overridden getLx and getRate methods.
            survivorshipProbabilities = utilities.LifeTableUtilities.getSurvivorship(obj, gender, currentAge, finalAge);
        end
        

        % --- Helper methods specific to this decorator ---
        function factor = getImprovementFactor(obj, gender, age)
            % Retrieves the specific improvement factor for a given gender and age.
            if ~isfield(obj.ImprovementFactors, gender)
                error('CachedImprovementFactorDecorator:InvalidGenderForIF', 'Improvement factors for gender "%s" not found.', gender);
            end
            agesIF = obj.ImprovementFactors.Age;
            factorsIF = obj.ImprovementFactors.(gender);
            binIndex = find(agesIF <= age, 1, 'last');
            if isempty(binIndex)
                factor = 0; % Default if age is below the first band
            else
                factor = factorsIF(binIndex) / 100; % Assuming factors are in percentage points (e.g., 2 for 2%)
            end
        end
        function cacheKey = getCacheKeyForImprovedTable(obj)
           % Returns the cache key used by this decorator instance for its improved rates struct.
            cacheKey = obj.CacheKeyForOwnImprovedTable;
        end

        % --- NEW METHOD to get all keys from the shared CacheManager ---
        function allKeys = getAllKeysInSharedCacheManager(obj)
            % Returns all keys currently present in the CacheManager instance
            % that this decorator is using.
            if ~isempty(obj.CacheManager) && isa(obj.CacheManager, 'MortalityCacheManager') && ismethod(obj.CacheManager, 'getCachedTables')
                allKeys = obj.CacheManager.getCachedTables();
            else
                warning('CachedImprovementFactorDecorator:NoCacheManager', 'CacheManager not available or does not support getCachedTables.');
                allKeys = {};
            end

        end
    end

    methods (Access = private)
        function key = generateCacheKeyInternal(obj)
            % Generates the unique cache key for this decorator's improved table.
            % This is called once by the constructor.
            baseTableNameForCache = regexprep(obj.BaseTable.TableName, '[^a-zA-Z0-9_]', '_');
            key = sprintf('ImprovedRates_%s_Start%d_%s', ...
                               baseTableNameForCache, ...
                               obj.StartAgeForImprovement, ...
                               class(obj.ImprovementFactorStrategy));
        end

        function improvedRatesStruct = getOrGenerateImprovedRatesStruct(obj)
            % Generates the full improved mortality rates struct (Male & Female with Age, qx, lx)
            % or loads it from the CacheManager.
            
            cacheKey = obj.CacheKeyForOwnImprovedTable;

            [cachedStruct, isCached] = obj.CacheManager.getTable(cacheKey);

            if isCached && isstruct(cachedStruct) && isfield(cachedStruct, 'Male') && isfield(cachedStruct, 'Female')
                improvedRatesStruct = cachedStruct;
                %fprintf('INFO: Loaded improved rates from cache for key: %s\n', cacheKey); % Optional: for debugging
            else
                %fprintf('INFO: Generating improved rates (not found or invalid in cache) for key: %s\n', cacheKey); % Optional: for debugging
                newRates = struct();
                
                if isempty(obj.BaseTable.MortalityRates)
                     error('CachedImprovementFactorDecorator:BaseTableNotLoaded', ...
                           'BaseTable.MortalityRates is empty. Ensure the base table data is loaded before decorating.');
                end
                % First, copy all non-gender (metadata) fields from the base table's rates
                % to the new improved rates struct to preserve them.
                allBaseFields = fieldnames(obj.BaseTable.MortalityRates);
                for k_meta = 1:length(allBaseFields)
                    fieldName = allBaseFields{k_meta};
                    if ~strcmpi(fieldName, 'Male') && ~strcmpi(fieldName, 'Female')
                        newRates.(fieldName) = obj.BaseTable.MortalityRates.(fieldName);
                    end
                end

                % Explicitly define the genders to process to avoid iterating over metadata fields
                gendersToProcess = {'Male', 'Female'};
                
                for i = 1:length(gendersToProcess)
                    gender = gendersToProcess{i};

                    % Check if this gender exists in the base table's mortality rates
                    if ~isfield(obj.BaseTable.MortalityRates, gender)
                        warning('CachedImprovementFactorDecorator:MissingBaseGender', ...
                            'Gender "%s" not found in BaseTable.MortalityRates. Skipping improvement for this gender.', gender);
                        continue; % Skip to the next gender if this one isn't in the base table
                    end

                    baseGenderRates = obj.BaseTable.MortalityRates.(gender);
                    
                    baseAges = baseGenderRates.Age(:);
                    maxAgeInTable = baseAges(end);
                    startAgeForImprovement = obj.StartAgeForImprovement;

                    if startAgeForImprovement <=maxAgeInTable
                        try

                            idxStartInBase = find(baseAges == startAgeForImprovement, 1);
                            if isempty(idxStartInBase)
                                errmsg = sprintf('CachedImprovementFactorDecorator:StartAgeNotFound',...
                                    'Age %d not found in improved table for gender %s, table %s.', startAgeForImprovement, gender, obj.TableName);
                                
                            end

                            numImprovedAges = length(baseAges) - idxStartInBase + 1;
                            improvedAges = baseAges(idxStartInBase:end);

                            temp_qx = zeros(numImprovedAges, 1);
                            temp_lx = zeros(numImprovedAges, 1);

                            temp_lx(1) = obj.BaseTable.getLx(gender, startAgeForImprovement);

                            for k = 1:numImprovedAges
                                currentActualAge = improvedAges(k);
                                base_qx_val = obj.BaseTable.getRate(gender, currentActualAge);
                                duration = max(0, currentActualAge - startAgeForImprovement);
                                improvementF = obj.getImprovementFactor(gender, currentActualAge);

                                calculated_qx = base_qx_val * (1 + improvementF)^duration;  % improvement factors are assumed to be negative for a reducing mortality
                                temp_qx(k) = max(0, min(1, calculated_qx)); % Ensure qx is bounded [0,1]

                                if k > 1
                                    temp_lx(k) = temp_lx(k-1) * (1 - temp_qx(k-1));
                                end

                                newRates.(gender) = struct('Age', improvedAges, 'lx', temp_lx, 'qx', temp_qx);
                            end
                        catch ME
                            warning('getImprovedRate:FailedLookup', 'Could not retrieve starting qx value. Reason: %s , revert to existing table', errMsg);
                            newRates.(gender) = obj.BaseTable.MortalityRates;

                        end
                    else
                        errMsg = sprintf('CachedImprovementFactorDecorator:StartAgeGreater than max table age %d not found in improved table for gender %s, table %s.',...
                            startAgeForImprovement, gender, obj.TableName);
                        warning('getImprovedRate:FailedLookup', 'Could not retrieve starting qx value. Reason: %s , revert to existing table',errMsg );
                        %TODO work out how to 
                            newRates.(gender) = obj.BaseTable.MortalityRates.(gender);
                    end
                    
                    improvedRatesStruct = newRates;
                    obj.CacheManager.cacheTable(cacheKey, improvedRatesStruct);
                end
        end
    end
    end
end
