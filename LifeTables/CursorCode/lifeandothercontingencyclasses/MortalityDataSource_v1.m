classdef MortalityDataSource_v1 < handle
    %MORTALITYDATASOURCE Base class for mortality data sources
    %   Abstract base class for mortality data sources
    %   Provides common functionality for:
    %   - Data caching
    %   - Error handling
    %   - Logging
    %   - Data validation
    
    properties (Access = public)
        % Public properties
        SourceName = '';  % Name of the data source
        SourceURL = '';   % URL of the data source
        LastUpdated = ''; % Last update timestamp
        DataCache = containers.Map('KeyType', 'char', 'ValueType', 'any');  % Cache for mortality data
        WebOptions = weboptions();  % Web options for data fetching
    end
    
    properties (Access = protected)
        % Protected properties
        CacheDir = 'cache';  % Directory for cached data
        LogFile = 'mortality_source.log';  % Log file path
    end
    
    methods (Access = public)
        function obj = MortalityDataSource_v1()
            % Constructor
            %   Initializes the data source with default settings
            obj.initializeCache();
            obj.initializeLogging();
        end
        
        function data = getMortalityTable(obj, tableEnum)
            %GETMORTALITYTABLE Get mortality table data
            %   Inputs:
            %       tableEnum - TableNames enum value
            %   Returns:
            %       data - Struct containing table data
            try
                % Check cache first
                cacheKey = char(tableEnum);
                if obj.DataCache.isKey(cacheKey)
                    obj.log('Retrieved table %s from cache', cacheKey);
                    data = obj.DataCache(cacheKey);
                    return;
                end
                
                % Fetch raw data
                rawData = obj.fetchRawData(tableEnum);
                
                % Parse raw data
                data = obj.parseRawData(rawData, tableEnum);
                
                % Cache the data
                obj.DataCache(cacheKey) = data;
                obj.log('Cached table %s', cacheKey);
                
            catch ME
                error('MATLAB:invalidType', 'Failed to get mortality table: %s', ME.message);
            end
        end
        
        function isAvailable = checkAvailability(obj)
            %CHECKAVAILABILITY Check if data source is available
            %   Returns:
            %       isAvailable - Boolean indicating if source is accessible
            try
                % Try to access the source URL
                webread(obj.SourceURL, obj.WebOptions);
                isAvailable = true;
            catch
                isAvailable = false;
            end
        end
        
        function log(obj, message, varargin)
            %LOG Log a message
            %   Inputs:
            %       message - Message to log
            %       varargin - Format arguments for message
            try
                % Format message
                formattedMessage = sprintf(message, varargin{:});
                
                % Add timestamp
                timestamp = datestr(now, 'yyyy-mm-dd HH:MM:SS');
                logMessage = sprintf('[%s] %s\n', timestamp, formattedMessage);
                
                % Write to log file
                fid = fopen(obj.LogFile, 'a');
                if fid ~= -1
                    fprintf(fid, logMessage);
                    fclose(fid);
                end
                
            catch ME
                warning('Failed to log message: %s', ME.message);
            end
        end
        
        function updateLastUpdated(obj)
            %UPDATELASTUPDATED Update last updated timestamp
            obj.LastUpdated = datestr(now, 'yyyy-mm-dd HH:MM:SS');
        end
    end
    
    methods (Access = protected)
        function initializeCache(obj)
            %INITIALIZECACHE Initialize data cache
            %   Creates cache directory if it doesn't exist
            if ~exist(obj.CacheDir, 'dir')
                mkdir(obj.CacheDir);
            end
        end
        
        function initializeLogging(obj)
            %INITIALIZELOGGING Initialize logging
            %   Creates log file if it doesn't exist
            if ~exist(obj.LogFile, 'file')
                fid = fopen(obj.LogFile, 'w');
                if fid ~= -1
                    fclose(fid);
                end
            end
        end
    end
    
    methods (Abstract, Access = protected)
        rawData = fetchRawData(obj, tableEnum)
        %FETCHRAWDATA Fetch raw data from source
        %   Inputs:
        %       tableEnum - TableNames enum value
        %   Returns:
        %       rawData - Struct containing raw table data
        
        parsedData = parseRawData(obj, rawData, tableEnum)
        %PARSERAWDATA Parse raw data into standard format
        %   Inputs:
        %       rawData - Struct containing raw table data
        %       tableEnum - TableNames enum value
        %   Returns:
        %       parsedData - Struct containing parsed table data
    end
end 