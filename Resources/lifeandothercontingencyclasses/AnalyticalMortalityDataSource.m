% File: AnalyticalMortalityDataSource.m
classdef AnalyticalMortalityDataSource < MortalityDataSource
    %ANALYTICALMORTALITYDATASOURCE A data source for generating mortality tables from analytical models.
    %   Instead of fetching data from an external source, this class generates
    %   mortality tables on-the-fly based on specified model parameters (e.g., for
    %   Gompertz, Lee-Carter, etc.). It uses caching to store and retrieve
    %   these generated tables for efficiency.

    methods
        function obj = AnalyticalMortalityDataSource()
            % Constructor for the analytical data source.
            obj@MortalityDataSource(); % Call superclass constructor
            obj.SourceName = 'Analytical Models';
            obj.SourceURL = 'internal://formulae';
        end

        function table = getMortalityTable(obj, modelSpecification)
            % Overrides the parent method to handle model specifications instead of enums.
            % Input:
            %   modelSpecification: A struct defining the model and its parameters.
            %                       Example: struct('Model', 'Gompertz', 'B', 0.0002, 'c', 1.09, 'maxAge', 120)
            
            % 1. Validate the input specification
            if ~isstruct(modelSpecification) || ~isfield(modelSpecification, 'Model')
                error('AnalyticalMortalityDataSource:InvalidSpec', ...
                      'Input must be a struct with a "Model" field.');
            end

            % 2. Generate a unique cache key from the model specification
            cacheKey = obj.generateCacheKeyFromSpec(modelSpecification);

            % 3. Check the cache first
            [cachedTable, isCached] = obj.CacheManager.getTable(cacheKey);

            if isCached && isa(cachedTable, 'MortalityTable')
                obj.log('Table for model "%s" retrieved from cache.', modelSpecification.Model);
                table = cachedTable;
                return;
            end
            
            obj.log('Table for model "%s" not in cache, generating from formula...', modelSpecification.Model);
            
            % 4. If not in cache, generate the table using a factory pattern
            switch modelSpecification.Model
                case MortalityModelNames.Gompertz   %'gompertz'
                    % Ensure required parameters for Gompertz exist
                    if ~isfield(modelSpecification, 'B') || ~isfield(modelSpecification, 'c')
                        error('AnalyticalMortalityDataSource:MissingParams', 'Gompertz model requires "B" and "c" parameters.');
                    end
                    
                    %TODO think about how to allow for a more dynamic max age
                    maxAge = 120; % Default max age
                    if isfield(modelSpecification, 'maxAge')
                        maxAge = modelSpecification.maxAge;
                    end
                    
                    % Create the GompertzMortalityTable object
                    table = GompertzMortalityTable(modelSpecification.B, modelSpecification.c, maxAge);
                    
                case MortalityModelNames.LeeCarter %'lee-carter'
                    % --- Placeholder for future Lee-Carter implementation ---
                    % Here you would:
                    % 1. Check for Lee-Carter specific parameters in the struct (ax, bx, kt, etc.).
                    % 2. Create a LeeCarterMortalityTable object.
                    error('AnalyticalMortalityDataSource:NotImplemented', 'Lee-Carter model is not yet implemented.');
                    
                % --- Add cases for other stochastic models here ---
                
                otherwise
                    error('AnalyticalMortalityDataSource:UnknownModel', 'Analytical model "%s" is not recognized.', modelSpecification.Model);
            end
            
            % 5. Cache the newly generated table object for future use
            obj.CacheManager.cacheTable(cacheKey, table);
            obj.log('Generated and cached table for model "%s".', modelSpecification.Model);
        end

        function tables = getAvailableTables(obj)
            % For this analytical source, the concept of a static "TableName" enum does not apply.
            % This overridden method returns the raw cache keys of the tables that have been generated.
            % These are the dynamic keys like 'Gompertz_B_0_0002_c_1_09...'.
            % For a more user-friendly list, use getCachedTableObjects().
            
            obj.log('Getting available table keys for analytical source.');
            tables = obj.CacheManager.getCachedTables(); % Returns a cell array of strings
        end
        function tableObjects = getCachedTableObjects(obj)
            % Returns a cell array of the actual MortalityTable objects
            % currently in the cache for this data source. This is useful for
            % inspection or populating a UI with descriptive table names.
            
            cachedKeys = obj.getAvailableTables(); % Get the raw keys
            tableObjects = {};
            
            for i = 1:length(cachedKeys)
                key = cachedKeys{i};
                [table, isCached] = obj.CacheManager.getTable(key);
                if isCached && isa(table, 'MortalityTable')
                    tableObjects{end+1} = table;
                end
            end
        end
    end
    
    methods (Access = protected)
        function cacheKey = generateCacheKeyFromSpec(obj, modelSpec)
            % Creates a consistent, unique string key from the model specification struct.
            keyStr = modelSpec.Model;
            
            % Sort fieldnames (excluding 'Model') to ensure consistent key order
            fields = sort(fieldnames(rmfield(modelSpec, 'Model')));
            
            for i = 1:length(fields)
                fieldName = fields{i};
                fieldValue = modelSpec.(fieldName);
                if isnumeric(fieldValue)
                    % Format numbers consistently to avoid floating point issues in keys
                    keyStr = sprintf('%s_%s_%.8f', keyStr, fieldName, fieldValue);
                else
                    keyStr = sprintf('%s_%s_%s', keyStr, fieldName, char(fieldValue));
                end
            end
            
            % Sanitize the key to be a valid variable/field name if needed
            cacheKey = matlab.lang.makeValidName(keyStr);
        end

        % --- Abstract method implementations (not directly used) ---
        function rawData = fetchRawData(obj, modelSpecification)
            % This data source generates data, it doesn't fetch raw data.
            % We must implement it to satisfy the abstract class contract, but it can be minimal.
            obj.log('fetchRawData called on AnalyticalMortalityDataSource (generates data, does not fetch).');
            rawData = struct('modelSpec', modelSpecification); % Return the spec as "raw data"
        end

        function parsedData = parseRawData(obj, rawData, modelSpecification)
            % Parsing is also not needed in the traditional sense, as the getMortalityTable
            % method directly creates the final table object.
            obj.log('parseRawData called on AnalyticalMortalityDataSource (generates data, does not parse).');
            parsedData = rawData; % Pass through
        end
    end
end
