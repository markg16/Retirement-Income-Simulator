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
        % These properties are inherited from the base class
    end
    
    methods (Abstract, Access = protected)
        % These methods must be implemented by each data source
        rawData = fetchRawData(obj, tableEnum)  % Fetch raw data from external source
        parsedData = parseRawData(obj, rawData, tableEnum)  % Parse raw data into standard format
    end
    
    methods
        function obj = MortalityDataSource()
            %MORTALITYDATASOURCE Constructor
            %   Initializes common properties and directories
            obj.DataCache = containers.Map();
            obj.initializeDirectories();
            obj.initializeDataCache();  % Initialize the data cache
        end
        
        function delete(obj)
            %DELETE Destructor
            %   Closes log file when object is destroyed
            if ~isempty(obj.LogFile) && obj.LogFile ~= -1
                fclose(obj.LogFile);
            end
        end
        
        function table = getMortalityTable(obj, tableEnum)
            %GETMORTALITYTABLE Get mortality table data
            %   Returns mortality table data for the specified table.
            %   If data is not in cache, fetches from source and caches it.
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       table - Struct containing mortality data
            if ~obj.isTableInCache(tableEnum)
                obj.log(sprintf('Table %s not in cache, fetching from source...', char(tableEnum)));
                try
                    rawData = obj.fetchRawData(tableEnum);
                    parsedData = obj.parseRawData(rawData, tableEnum);
                    obj.cacheTableData(tableEnum, parsedData);
                catch e
                    error('MATLAB:invalidType', 'Failed to fetch table %s: %s', char(tableEnum), e.message);
                end
            end
            table = obj.getTableFromCache(tableEnum);
        end
        
        function tables = getAvailableTables(obj, forceRefresh)
            %GETAVAILABLETABLES Get list of available tables
            %   Returns list of tables that have data in cache.
            %   Optionally forces refresh of available tables list.
            %
            %   Inputs:
            %       forceRefresh - Optional boolean to force refresh
            %   Returns:
            %       tables - Array of TableNames enumeration values
            if nargin < 2
                forceRefresh = false;
            end
            
            if forceRefresh || ~obj.DataCache.isKey('tables')
                if ~obj.DataCache.isKey('initialized')
                    obj.initializeDataCache();
                end
                
                allTables = enumeration('TableNames');
                availableTables = [];
                
                for i = 1:length(allTables)
                    if obj.isTableInCache(allTables(i))
                        availableTables = [availableTables, allTables(i)];
                    end
                end
                
                obj.DataCache('tables') = availableTables;
                
                fprintf('Available tables:\n');
                for i = 1:length(availableTables)
                    fprintf('  %s\n', char(availableTables(i)));
                end
            else
                tables = obj.DataCache('tables');
            end
            
            if ~exist('tables', 'var')
                tables = [];
            end
        end
        
        function clearCache(obj)
            %CLEARCACHE Clear the data cache
            %   Removes all cached data and resets cache state
            try
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
            %LOG Log a message
            %   Writes message to both console and log file
            %
            %   Inputs:
            %       message - String message to log (can include sprintf format specifiers)
            %       varargin - Optional arguments for sprintf formatting
            timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
            if nargin > 2
                fullMessage = sprintf('[%s] %s\n', timestamp, sprintf(message, varargin{:}));
            else
                fullMessage = sprintf('[%s] %s\n', timestamp, message);
            end
            fprintf('%s', fullMessage);
            if ~isempty(obj.LogFile) && obj.LogFile ~= -1
                fprintf(obj.LogFile, '%s', fullMessage);
            end
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
            
            % Update cache timestamp
            obj.DataCache('lastUpdated') = obj.LastUpdated;
            
            % Save cache to file
            dataCache = obj.DataCache;
            save(obj.CacheFile, 'dataCache');
        end
    end
end 