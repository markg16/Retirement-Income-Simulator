classdef MortalityCacheManager < handle
    %MORTALITYCACHEMANAGER Manages caching of mortality data
    %   Handles caching, retrieval, and invalidation of mortality tables
    %   Provides methods for cache statistics and management
    
    properties (Access = protected)
        CacheDir      % Directory for cache files
        CacheFile     % Path to main cache file
        Cache         % Map containing cached data
        LastUpdated   % Timestamp of last cache update
        CacheStats    % Statistics about cache usage
    end
    
    properties (Constant)
        DEFAULT_CACHE_DIR = 'cache'  % Default cache directory name
        DEFAULT_TABLE_CACHE_FILE = 'mortality_table_cache.mat'  % Default cache file name
    end
    
    methods (Access = public)
        function obj = MortalityCacheManager(varargin)
            %MORTALITYCACHEMANAGER Constructor
            %   Initializes cache manager and loads existing cache
            %   Optional inputs:
            %       cacheDir - Custom cache directory path
            %       cacheFile - Custom cache file name
            
            % Parse optional inputs
            p = inputParser;
            addParameter(p, 'cacheDir', '', @ischar);
            addParameter(p, 'cacheFile', '', @ischar);
            parse(p, varargin{:});
            
            % Set cache directory
            if ~isempty(p.Results.cacheDir)
                obj.CacheDir = p.Results.cacheDir;
            else
                % Use default location relative to class file
                baseDir = fileparts(mfilename('fullpath'));
                obj.CacheDir = fullfile(baseDir, obj.DEFAULT_CACHE_DIR);
            end
            
            % Set cache file
            if ~isempty(p.Results.cacheFile)
                obj.CacheFile = fullfile(obj.CacheDir, p.Results.cacheFile);
            else
                obj.CacheFile = fullfile(obj.CacheDir, obj.DEFAULT_TABLE_CACHE_FILE);
            end
            
            % Initialize cache
            try
                obj.initializeCache();
            catch e
                warning('Failed to initialize cache: %s', e.message);
                obj.resetCache();
            end
        end
        
        function initializeCache(obj)
            %INITIALIZECACHE Initialize cache directory and load existing cache
            %   Creates cache directory if it doesn't exist and loads cache file
            
            % Create cache directory if it doesn't exist
            if ~exist(obj.CacheDir, 'dir')
                try
                    mkdir(obj.CacheDir);
                catch e
                    error('Failed to create cache directory: %s', e.message);
                end
            end
            
            % Initialize cache
            if exist(obj.CacheFile, 'file')
                try
                    cache = load(obj.CacheFile);
                    obj.Cache = cache.cache;
                    obj.LastUpdated = cache.lastUpdated;
                    obj.CacheStats = cache.cacheStats;
                catch e
                    warning('Failed to load cache file: %s. Resetting cache.', e.message);
                    obj.resetCache();
                end
            else
                obj.resetCache();
            end
        end
        
        function resetCache(obj)
            %RESETCACHE Reset cache to initial state
            obj.Cache = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.LastUpdated = datetime('now');
            obj.CacheStats = struct('hits', 0, 'misses', 0, 'updates', 0);
            obj.saveCache();
        end
        
        function saveCache(obj)
            %SAVECACHE Save cache to file
            cache = obj.Cache;
            lastUpdated = obj.LastUpdated;
            cacheStats = obj.CacheStats;
            save(obj.CacheFile, 'cache', 'lastUpdated', 'cacheStats');
        end
        
        function [data, isCached] = getTable(obj, tableKey)
            %GETTABLE Get table from cache
            %   Inputs:
            %       tableKey - String key for table
            %   Returns:
            %       data - Cached table data
            %       isCached - Boolean indicating if data was in cache
            if obj.Cache.isKey(tableKey)
                data = obj.Cache(tableKey);
                isCached = true;
                obj.CacheStats.hits = obj.CacheStats.hits + 1;
            else
                data = [];
                isCached = false;
                obj.CacheStats.misses = obj.CacheStats.misses + 1;
            end
        end
        
        function cacheTable(obj, tableKey, data)
            %CACHETABLE Cache table data
            %   Inputs:
            %       tableKey - String key for table
            %       data - Table data to cache
            obj.Cache(tableKey) = data;
            obj.LastUpdated = datetime('now');
            obj.CacheStats.updates = obj.CacheStats.updates + 1;
            obj.saveCache();
        end
        
        function invalidateTable(obj, tableKey)
            %INVALIDATETABLE Remove table from cache
            %   Inputs:
            %       tableKey - String key for table
            if obj.Cache.isKey(tableKey)
                remove(obj.Cache, tableKey);
                obj.saveCache();
            end
        end
        
        function stats = getCacheStats(obj)
            %GETCACHESTATS Get cache statistics
            %   Returns:
            %       stats - Struct containing cache statistics
            stats = obj.CacheStats;
            stats.totalRequests = stats.hits + stats.misses;
            if stats.totalRequests > 0
                stats.hitRate = stats.hits / stats.totalRequests;
            else
                stats.hitRate = 0;
            end
        end
        
        function tables = getCachedTables(obj)
            %GETCACHEDTABLES Get list of cached tables
            %   Returns:
            %       tables - Cell array of cached table keys
            tables = keys(obj.Cache);
        end
        
        function clearCache(obj)
            %CLEARCACHE Clear entire cache
            obj.resetCache();
        end
        
        % Getter methods for protected properties
        function dir = getCacheDir(obj)
            %GETCACHEDIR Get cache directory path
            dir = obj.CacheDir;
        end
        
        function file = getCacheFile(obj)
            %GETCACHEFILE Get cache file path
            file = obj.CacheFile;
        end
        
        function cache = getCache(obj)
            %GETCACHE Get cache map
            cache = obj.Cache;
        end
        
        function time = getLastUpdated(obj)
            %GETLASTUPDATED Get last update timestamp
            time = obj.LastUpdated;
        end
    end
end 