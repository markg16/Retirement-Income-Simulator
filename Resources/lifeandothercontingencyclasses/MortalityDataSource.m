classdef MortalityDataSource < handle
    %MORTALITYDATASOURCE Abstract base class for mortality data sources
    %   Defines the interface and common functionality for mortality data sources.
    %   This class implements the Template Method pattern where:
    %   - fetch* methods get data from external sources
    %   - get* methods retrieve data from cache/local storage
    %   - parse* methods transform data between formats
    %   - cache* methods store data in local storage
    %
    %   Subclasses must implement:
    %   - fetchRawData: Get data from external source
    %   - parseRawData: Transform raw data into standard format
    
    properties (Access = public)
        SourceName    % Name of the data source
        SourceURL     % URL of the data source
        LastUpdated   % Last update date of the data
        WebOptions    % Web request options
        DataCache     % Cache for downloaded data
        DownloadDir   % Directory for downloaded files
        LogFile       % File handle for logging
        CacheFile     % File path for the data cache
        CacheDir      % Directory for cache files
    end
    
    properties (Access = protected)
       % The DataCache is now replaced by a dedicated CacheManager object
        CacheManager % Handles all caching operations
    end
    
    methods (Abstract, Access = protected)
        % These methods must be implemented by each data source
        rawData = fetchRawData(obj, tableEnum)  % Fetch raw data from external source
        parsedData = parseRawData(obj, rawData, tableEnum)  % Parse raw data into standard format
    end
    
    methods

% In MortalityDataSource.m constructor (conceptual modification)
function obj = MortalityDataSource(varargin)
    p = inputParser;
    addParameter(p, 'cacheManagerInstance', [], @(x) isempty(x) || isa(x, 'MortalityCacheManager'));
    % ... other parameters like cacheFileName, cacheDirName if you want to configure file directly
    parse(p, varargin{:});
    %   Initializes common properties and directories

    obj.initializeDirectories();
    obj.DataCache = containers.Map();
    
    if ~isempty(p.Results.cacheManagerInstance)
        obj.CacheManager = p.Results.cacheManagerInstance;
    else
         % Create a new CacheManager; its own constructor will handle loading its cache file
        className = class(obj);
        % The CacheManagerFactory or MortalityCacheManager constructor will use this file name
        % to initialize its internal cache (e.g., load from this .mat file).
        uniqueCacheFile = sprintf('%s_cache.mat', className); 
        obj.CacheManager = utilities.CacheManagerFactory.createCacheManager(...
            utilities.CacheManagerType.Mortality, 'cacheFile', uniqueCacheFile);
       
     end
   
end


% function obj = MortalityDataSource()
%     %MORTALITYDATASOURCE Constructor
%     % Constructor now creates the CacheManager via the factory
%     obj.CacheManager = utilities.CacheManagerFactory.createCacheManager(utilities.CacheManagerType.Mortality);
%     %   Initializes common properties and directories
% 
%     obj.initializeDirectories();
% 
%     obj.DataCache = containers.Map();
%     obj.initializeDataCache();  % Initialize the data cache
% end

function delete(obj)
    %DELETE Destructor
    %   Closes log file when object is destroyed
    if ~isempty(obj.LogFile) && obj.LogFile ~= -1
        fclose(obj.LogFile);
    end
end
function cm = getCacheManager(obj)
    % Public getter for the CacheManager instance
    cm = obj.CacheManager;
end

function tableObject = getMortalityTable(obj, tableEnum)
    %GETMORTALITYTABLE Get mortality table data
    %   Returns mortality table data for the specified table.
    %   If data is not in cache, fetches from source and caches it.
    %
    %   Inputs:
    %       tableEnum - TableNames enumeration value
    %   Returns:
    %       table - Struct containing mortality data


    % This method now delegates directly to the CacheManager.
    % It implements the "read-through" cache pattern.
    tableKey = char(tableEnum);
    [tableObject, isCached] = obj.CacheManager.getTable(tableKey);


    if ~isCached
        obj.log(sprintf('Table %s not in cache, fetching from source...', char(tableEnum)));
        try
            rawData = obj.fetchRawData(tableEnum);
            parsedDataStruct = obj.parseRawData(rawData, tableEnum);
            
            % 2. Convert the data struct into a concrete BasicMortalityTable object
            %    We create a descriptive "path" for the constructor.
            descriptivePath = sprintf('%s:%s', obj.SourceName, char(tableEnum));
            tableObject = BasicMortalityTable(descriptivePath, parsedDataStruct);
            tableObject.TableName = char(tableEnum); % Ensure TableName is set

            % 3. Cache the newly fetched and parsed data
            obj.CacheManager.cacheTable(tableKey, tableObject);


        catch e
            error('MATLAB:invalidType', 'Failed to fetch table %s: %s', char(tableEnum), e.message);
        end
    else
        % Step 2b: If it was in the cache, 'table' (from Step 1) already holds the data.
        % This 'else' block was primarily for logging the cache hit.
        obj.log(sprintf('Table %s retrieved from cache.', tableKey));
    end
end

function tables = getAvailableTables(obj)
    %GETAVAILABLETABLES Get list of available tables from the cache.
    %   Queries the CacheManager to find all table keys currently stored
    %   and returns them as an array of TableNames enumerations.
    %
    %   Returns:
    %       tables - Array of TableNames enumeration values found in the cache.

    % 1. Get the list of all table keys (as strings) from the CacheManager.
    %    This is the only line needed to query the cache's contents.
    cachedTableKeys = obj.CacheManager.getCachedTables();

    % 2. Convert the string keys back into TableNames enumeration members.
    %    This ensures the method returns data in the expected format.
    availableTables = TableNames.empty; % Initialize an empty array of the correct enum type

    for i = 1:length(cachedTableKeys)
        key = cachedTableKeys{i};
        try
            % Convert the string key to its corresponding enum member
            tableEnum = TableNames.(key);
            availableTables(end+1) = tableEnum;
        catch
            % This key from the cache file is not a valid TableNames member.
            % This could happen if the cache contains old or non-table data.
            % We can log this for debugging purposes and safely skip it.
            obj.log('Warning: Found key "%s" in cache that is not a valid TableNames member. Skipping.', key);
        end
    end

    tables = availableTables;
end

function clearCache(obj)
    %CLEARCACHE Clear the data cache
    %   Removes all cached data and resets cache state
    try


        obj.log('Clearing data cache...');
        obj.CacheManager.clearCache();
        obj.log('Data cache cleared.');
        % Clear the cache
        obj.DataCache = containers.Map();

        % Reinitialize the cache structure
        obj.initializeDataCache();

        obj.log('Data cache cleared and reinitialized');
    catch ME
        error('MATLAB:invalidType', 'Failed to clear cache: %s', ME.message);
    end
end

function log(obj, message, varargin)

    timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
    if nargin > 2
        fullMessage = sprintf('[%s] %s\n', timestamp, sprintf(message, varargin{:}));
    else
        fullMessage = sprintf('[%s] %s\n', timestamp, message);
    end
    fprintf('%s', fullMessage); % Always print to console
    if ~isempty(obj.LogFile) && obj.LogFile ~= -1
        try
            fprintf(obj.LogFile, '%s', fullMessage);
        catch ME
            warning('MortalityDataSource:LogWriteError', ...
                'Failed to write to log file: %s', ME.message);
            % Optionally, try to close and reopen, or disable file logging
        end
    end
end

function logMortalityTableSample(obj, mortalityDataStruct, titleString)
    %LOGMORTALITYTABLESAMPLE Logs a formatted sample of mortality data.
    %   Inputs:
    %       mortalityDataStruct - The struct containing .Male and .Female fields.
    %       titleString         - A title for this sample log.

    if nargin < 3 || isempty(titleString)
        titleString = '--- Mortality Data Sample ---';
    end

    obj.log(titleString); % Uses the existing log method

    if ~isstruct(mortalityDataStruct) || ~isfield(mortalityDataStruct, 'Male') || ~isfield(mortalityDataStruct, 'Female')
        obj.log('ERROR: Invalid or incomplete mortality data struct provided for sampling. Cannot display sample.');
        obj.log('--- End of Sample ---');
        return;
    end

    % Further check for subfields to prevent errors
    if ~isfield(mortalityDataStruct.Male, 'Age') || ~isfield(mortalityDataStruct.Male, 'qx') || ...
            ~isfield(mortalityDataStruct.Female, 'Age') || ~isfield(mortalityDataStruct.Female, 'qx')
        obj.log('ERROR: Male or Female data is missing Age or qx fields. Cannot display sample.');
        obj.log('--- End of Sample ---');
        return;
    end

    sampleAges = [0, 21, 45, 65, 85, 100];
    results = table('Size', [length(sampleAges), 3], ...
        'VariableTypes', {'double', 'double', 'double'}, ...
        'VariableNames', {'Age', 'Male_qx', 'Female_qx'}, ...
        'RowNames', string(sampleAges));

    for j = 1:length(sampleAges)
        age = sampleAges(j);
        results.Age(j) = age;

        % Male data
        if ~isempty(mortalityDataStruct.Male.Age)
            maleIdx = find(mortalityDataStruct.Male.Age == age, 1);
            if ~isempty(maleIdx)
                results.Male_qx(j) = mortalityDataStruct.Male.qx(maleIdx);
            else
                results.Male_qx(j) = NaN;
            end
        else
            results.Male_qx(j) = NaN;
        end

        % Female data
        if ~isempty(mortalityDataStruct.Female.Age)
            femaleIdx = find(mortalityDataStruct.Female.Age == age, 1);
            if ~isempty(femaleIdx)
                results.Female_qx(j) = mortalityDataStruct.Female.qx(femaleIdx);
            else
                results.Female_qx(j) = NaN;
            end
        else
            results.Female_qx(j) = NaN;
        end
    end

    % Display to console (via the log method for timestamping)
    % Convert table to string array for multiline logging
    tableLines = splitlines(evalc('disp(results)'));
    for k = 1:length(tableLines)
        if ~isempty(strtrim(tableLines{k})) % Avoid logging empty lines
            obj.log(strtrim(tableLines{k}));
        end
    end

    % The log method already handles writing to the log file.
    obj.log('--- End of Sample ---');
end
    end

    methods (Access = protected)
        function initializeDirectories(obj)
            %INITIALIZEDIRECTORIES Initialize directories
            %   Creates download and log directories if they don't exist
            obj.DownloadDir = fullfile(fileparts(mfilename('fullpath')), 'downloads');
            if ~exist(obj.DownloadDir, 'dir')
                mkdir(obj.DownloadDir);
            end

            logDir = fullfile(fileparts(mfilename('fullpath')), 'logs');
            if ~exist(logDir, 'dir')
                mkdir(logDir);
            end
            logFile = fullfile(logDir, sprintf('mortality_source_%s.log', datestr(now, 'yyyymmdd_HHMMSS')));
            obj.LogFile = fopen(logFile, 'a');
        end

        function initializeDataCache(obj)
            %INITIALIZEDATACACHE Initialize data cache
            %   Creates a new data cache in the LifeTables directory
            %   Cache location: LifeTables/cache/

            % Get cache directory
            obj.CacheDir = fullfile(fileparts(mfilename('fullpath')), '..', 'LifeTables', 'cache');
            if ~exist(obj.CacheDir, 'dir')
                mkdir(obj.CacheDir);
            end

            % Set cache file path
            obj.CacheFile = fullfile(obj.CacheDir, 'cache.mat');

            % Initialize cache
            if exist(obj.CacheFile, 'file')
                try
                    cache = load(obj.CacheFile);
                    obj.DataCache = cache.dataCache;
                catch
                    obj.DataCache = containers.Map();
                end
            else
                obj.DataCache = containers.Map();
            end
        end

        function cacheTableData(obj, tableEnum, parsedData)
            %CACHETABLEDATA Cache table data
            %   Stores parsed table data in cache
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %       parsedData - Struct containing parsed table data
            key = char(tableEnum);
            obj.DataCache(key) = parsedData;
            obj.updateLastUpdated();

            % Save cache to file
            dataCache = obj.DataCache;
            save(obj.CacheFile, 'dataCache');
        end

        function table = getTableFromCache(obj, tableEnum)
            %GETTABLEFROMCACHE Get table from cache
            %   Retrieves table data from cache
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       table - Struct containing table data
            key = char(tableEnum);
            if ~obj.DataCache.isKey(key)
                error('MATLAB:invalidType', 'Table %s not found in cache', key);
            end
            table = obj.DataCache(key);
        end

        function isCached = isTableInCache(obj, tableEnum)
            %ISTABLEINCACHE Check if table is in cache
            %   Verifies if table exists in cache and has valid data
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       isCached - Boolean indicating if table is cached
            key = char(tableEnum);
            isCached = obj.DataCache.isKey(key) && ...
                isfield(obj.DataCache(key), 'Male') && ...
                isfield(obj.DataCache(key).Male, 'Age') && ...
                ~isempty(obj.DataCache(key).Male.Age);
        end

        function updateLastUpdated(obj)
            %UPDATELASTUPDATED Update last updated timestamp
            %   Updates both the object's LastUpdated property and the cache's timestamp

            % Update object property
            obj.LastUpdated = datetime('now');
            % 2. Delegate the responsibility of saving to the CacheManager.
            %    The CacheManager's own saveCache method will handle its internal
            %    timestamp and writing to its file.
            if ~isempty(obj.CacheManager) && isvalid(obj.CacheManager)
                % This is the crucial change:
                obj.CacheManager.saveCache();
                obj.log('Persisted cache state via CacheManager.');
            end
            
        end
    end
end 