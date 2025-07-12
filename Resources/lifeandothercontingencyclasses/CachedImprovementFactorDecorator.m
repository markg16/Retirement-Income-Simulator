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
        % function lxVal = getLx(obj, gender, age)
        %     % Retrieves the pre-calculated improved number of lives (lx).
        %     try
        % 
        %         if ~isfield(obj.MortalityRates, gender)
        %             error('CachedImprovementFactorDecorator:InvalidGender', 'Gender "%s" not found in improved table for table %s.', gender, obj.TableName);
        %         end
        %     catch ME
        %     end
        % 
        %     ageIndex = find(obj.MortalityRates.(gender).Age == age, 1);
        %     if isempty(ageIndex)
        %         error('CachedImprovementFactorDecorator:AgeNotFound', 'Age %d not found in improved table for gender %s, table %s.', age, gender, obj.TableName);
        %     end
        %     lxVal = obj.MortalityRates.(gender).lx(ageIndex);
        % end

        function survivorshipProbabilities = getSurvivorshipProbabilities(obj, gender, currentAge, finalAge)
            % Delegates the calculation to the static utility function.
            % The utility will use this decorator's overridden getLx and getRate methods.
            survivorshipProbabilities = utilities.LifeTableUtilities.getSurvivorship(obj, gender, currentAge, finalAge);
        end
        
        function survivorshipProbabilitiesAtPaymentDates = getSurvivorshipProbabilitiesForEachPaymentDate(obj, varargin)
            % Handles two calling signatures:
            % 1. (obj, survivorshipProbabilitiesToCompleteAge, paymentDatesToValue, paymentsPerYear) - Old
            % 2. (obj, gender, ageAtFirstPaymentDate, paymentDatesToValue, paymentsPerYear) - New

            % Parse varargin to determine inputs
            if nargin == 4 % Corresponds to obj + 3 inputs for old signature
                % Old signature: (obj, survivorshipProbabilitiesToCompleteAge, paymentDatesToValue, paymentsPerYear)
                if isnumeric(varargin{1}) && isvector(varargin{1}) && ...
                        isdatetime(varargin{2}) && isvector(varargin{2}) && ...
                        isnumeric(varargin{3}) && isscalar(varargin{3})

                    annualSurvivorshipProbs = varargin{1};
                    paymentDatesToValue = varargin{2};
                    paymentsPerYear = varargin{3};

                    if isempty(paymentDatesToValue)
                        survivorshipProbabilitiesAtPaymentDates = [];
                        return;
                    end
                    if paymentsPerYear <= 0
                        error('CachedImprovementFactorDecorator:InvalidPaymentsPerYear', 'paymentsPerYear must be positive for old signature.');
                    end

                else
                    error('CachedImprovementFactorDecorator:InvalidOldSignature', 'Inputs do not match old signature (numericVector, datetimeVector, numericScalar).');
                end

            elseif nargin == 5 % Corresponds to obj + 4 inputs for new signature
                % New signature: (obj, gender, ageAtFirstPaymentDate, paymentDatesToValue, paymentsPerYear)
                if (ischar(varargin{1}) || isstring(varargin{1})) && ...
                        isnumeric(varargin{2}) && isscalar(varargin{2}) && ...
                        isdatetime(varargin{3}) && isvector(varargin{3}) && ...
                        isnumeric(varargin{4}) && isscalar(varargin{4})

                    gender = char(varargin{1});
                    ageAtFirstPaymentDate = varargin{2};
                    paymentDatesToValue = varargin{3};
                    paymentsPerYear = varargin{4};

                    if isempty(paymentDatesToValue)
                        survivorshipProbabilitiesAtPaymentDates = [];
                        return;
                    end
                    if paymentsPerYear <= 0
                        error('CachedImprovementFactorDecorator:InvalidPaymentsPerYear', 'paymentsPerYear must be positive for new signature.');
                    end
                    if ageAtFirstPaymentDate < 0
                        error('CachedImprovementFactorDecorator:InvalidAge', 'ageAtFirstPaymentDate must be non-negative.');
                    end

                    % Calculate annual survivorship probabilities internally
                    durationInYearsExact = years(paymentDatesToValue(end) - paymentDatesToValue(1) + caldays(1));
                    numberOfFullYears = ceil(durationInYearsExact);

                    if numberOfFullYears < 0
                        error('CachedImprovementFactorDecorator:InvalidPaymentDates', 'Last payment date cannot be before the first payment date.');
                    elseif numberOfFullYears == 0
                        annualSurvivorshipProbs = obj.getSurvivorshipProbabilities(gender, ageAtFirstPaymentDate, ageAtFirstPaymentDate + 1);
                        if isempty(annualSurvivorshipProbs)
                            annualSurvivorshipProbs = 1 - obj.getRate(gender, ageAtFirstPaymentDate);
                        end
                    else
                        annualSurvivorshipProbs = obj.getSurvivorshipProbabilities(gender, ageAtFirstPaymentDate, ageAtFirstPaymentDate + numberOfFullYears);
                    end
                else
                    error('CachedImprovementFactorDecorator:InvalidNewSignature', 'Inputs do not match new signature (char/string, numericScalar, datetimeVector, numericScalar).');
                end
            else
                error('CachedImprovementFactorDecorator:InvalidNumberOfArguments', 'Invalid number of arguments. Expecting 3 or 4 inputs after obj.');
            end

            % --- Common logic for interpolation and slicing ---

            % Use the static helper for the core interpolation.
            if ~exist('utilities.LifeTableUtilities', 'class') || ~ismethod('utilities.LifeTableUtilities', 'interpolateAnnualSurvivorship')
                error('CachedImprovementFactorDecorator:MissingUtility', ...
                    'The utility function utilities.LifeTableUtilities.interpolateAnnualSurvivorship is required.');
            end

            allInterpolatedProbs = utilities.LifeTableUtilities.interpolateAnnualSurvivorship(annualSurvivorshipProbs, paymentsPerYear);

            totalYearsForInterpolation = length(annualSurvivorshipProbs);
            totalNumberFuturePayments = length(paymentDatesToValue);
            numAllInterpolatedPeriods = totalYearsForInterpolation * paymentsPerYear;

            if isempty(allInterpolatedProbs) && totalNumberFuturePayments > 0
                error('CachedImprovementFactorDecorator:InterpolationFailed', 'Interpolated survivorship probabilities are empty or too short.');
            elseif totalNumberFuturePayments == 0
                survivorshipProbabilitiesAtPaymentDates = [];
                return;
            end

            if totalNumberFuturePayments > numAllInterpolatedPeriods
                warning('CachedImprovementFactorDecorator:PaymentCountWarning', ...
                    'Number of future payments (%d) exceeds span of interpolated probabilities (%d). This may lead to unexpected results or errors if not handled by slicing logic.', ...
                    totalNumberFuturePayments, numAllInterpolatedPeriods);
            end

            % Select the probabilities corresponding to paymentDatesToValue.
            % We need the first `totalNumberFuturePayments` from `allInterpolatedProbs`.
            if totalNumberFuturePayments <= length(allInterpolatedProbs)
                slicedProbs = allInterpolatedProbs(1:totalNumberFuturePayments);
            else
                slicedProbs = allInterpolatedProbs; % Take all available if not enough
                warning('CachedImprovementFactorDecorator:SliceTooShort', ...
                    'Requested payment dates extend beyond interpolated probability range. Using all available %d probabilities for %d payments.', ...
                    length(slicedProbs), totalNumberFuturePayments);
            end

            % Normalize based on the first probability in the SLICED array
            if isempty(slicedProbs)
                survivorshipProbabilitiesAtPaymentDates = [];
            else
                if slicedProbs(1) == 0
                    survivorshipProbabilitiesAtPaymentDates = zeros(size(slicedProbs));
                else
                    survivorshipProbabilitiesAtPaymentDates = slicedProbs / slicedProbs(1);
                end
            end

            % Ensure output length matches paymentDatesToValue, if different after slicing/warnings
            if length(survivorshipProbabilitiesAtPaymentDates) ~= totalNumberFuturePayments && ~isempty(survivorshipProbabilitiesAtPaymentDates)
                warning('CachedImprovementFactorDecorator:FinalOutputLengthMismatch', ...
                    'Final output length (%d) for payment date probabilities does not match number of payment dates (%d). Adjusting output.', ...
                    length(survivorshipProbabilitiesAtPaymentDates), totalNumberFuturePayments);
                if length(survivorshipProbabilitiesAtPaymentDates) > totalNumberFuturePayments
                    survivorshipProbabilitiesAtPaymentDates = survivorshipProbabilitiesAtPaymentDates(1:totalNumberFuturePayments);
                else
                    survivorshipProbabilitiesAtPaymentDates = [survivorshipProbabilitiesAtPaymentDates, ...
                        zeros(1, totalNumberFuturePayments - length(survivorshipProbabilitiesAtPaymentDates))];
                end
            end
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
