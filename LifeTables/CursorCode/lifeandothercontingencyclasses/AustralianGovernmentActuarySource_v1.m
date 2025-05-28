classdef AustralianGovernmentActuarySource_v1 < MortalityDataSource
    %AUSTRALIANGOVERNMENTACTUARYSOURCE Australian Government Actuary data source
    %   Implements data fetching from the Australian Government Actuary website.
    %   This class handles:
    %   - Fetching data from AGA website
    %   - Parsing Excel files into standard format
    %   - Caching downloaded data
    %   - Managing URL patterns and updates
    
    properties (Access = public)
        % Public properties for AGA source
        TableURLs = containers.Map('KeyType', 'char', 'ValueType', 'any');  % Map of table names to their publication URLs
        UrlCacheFile = 'aga_url_cache.mat';  % Path to MAT-file for URL cache
        UrlCache = containers.Map('KeyType', 'char', 'ValueType', 'any');  % Cache of working URLs with structure: {tableKey: {pubUrl: url, downloadUrl: url}}
    end
    
    properties (Access = protected)
        % Protected properties specific to AGA source
        BaseURL = 'https://aga.gov.au/';  % Base URL for AGA website
        OverwriteExisting = false;  % Whether to overwrite existing files
        UrlPatterns = struct();  % URL patterns loaded from resource file
        SourceDir = 'source';  % Directory for source files
    end
    
    methods (Access = public)
        function obj = AustralianGovernmentActuarySource_v1(varargin)
            % Constructor with optional parameters
            % Usage: obj = AustralianGovernmentActuarySource_v1('OverwriteExisting', true)
            obj@MortalityDataSource();
            
            % Set source properties
            obj.SourceName = 'Australian Government Actuary';
            obj.SourceURL = 'https://aga.gov.au/publications/life-tables';
            
            % Configure web options
            obj.WebOptions = weboptions('Timeout', 30, ...
                                      'HeaderFields', {'User-Agent', 'Mozilla/5.0'}, ...
                                      'ContentType', 'text', ...
                                      'CharacterEncoding', 'UTF-8');
            
            % Parse optional parameters
            p = inputParser;
            addParameter(p, 'OverwriteExisting', false, @islogical);
            parse(p, varargin{:});
            obj.OverwriteExisting = p.Results.OverwriteExisting;
            
            % Initialize directories
            obj.initializeSourceDirectory();
            
            % Load URL patterns
            obj.loadUrlPatterns();
            
            % Initialize table URLs before URL cache
            obj.initializeTableURLs();
            obj.initializeUrlCache();
        end
        
        function initializeSourceDirectory(obj)
            %INITIALIZESOURCEDIRECTORY Initialize source directory
            %   Creates directory for source files if it doesn't exist
            sourceDir = fullfile(obj.CacheDir, '..', obj.SourceDir);
            if ~exist(sourceDir, 'dir')
                mkdir(sourceDir);
            end
        end
        
        function initializeUrlCache(obj)
            % Initialize URL cache from file if it exists
            obj.UrlCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            % Set URL cache file path
            obj.UrlCacheFile = fullfile(obj.CacheDir, 'aga_url_cache.mat');
            
            if exist(obj.UrlCacheFile, 'file')
                try
                    cache = load(obj.UrlCacheFile);
                    obj.UrlCache = cache.urlCache;
                catch
                    % If loading fails, keep empty cache
                    obj.UrlCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
                end
            end
            
            % Ensure all tables have an entry in the cache
            obj.populateUrlCache();
            
            % Update download URLs in cache
            obj.updateUrlCache();
        end
        
        function populateUrlCache(obj)
            %POPULATEURLCACHE Populate URL cache with all known tables
            %   Ensures all tables in TableURLs have an entry in the cache
            try
                % Get all table keys
                tableKeys = keys(obj.TableURLs);
                
                % Add each table to cache if not present
                for i = 1:length(tableKeys)
                    key = tableKeys{i};
                    if ~isKey(obj.UrlCache, key)
                        obj.UrlCache(key) = struct('pubUrl', obj.TableURLs(key), 'downloadUrl', '');
                    end
                end
                
                % Save updated cache
                obj.saveUrlCache();
                obj.log('URL cache populated with %d tables', length(tableKeys));
            catch ME
                error('MATLAB:invalidType', 'Failed to populate URL cache: %s', ME.message);
            end
        end
        
        function initializeTableURLs(obj)
            %INITIALIZETABLEURLS Initialize table URLs with publication page URLs
            obj.TableURLs = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.TableURLs('ALT_Table2020_22') = [obj.BaseURL 'publications/life-tables/australian-life-tables-2020-22'];
            obj.TableURLs('ALT_Table2015_17') = [obj.BaseURL 'publications/life-tables/australian-life-tables-2015-17'];
            obj.TableURLs('ALT_Table2010_12') = [obj.BaseURL 'publications/life-tables/australian-life-tables-2010-12'];
            obj.TableURLs('ALT_Table2005_07') = [obj.BaseURL 'publications/life-tables/australian-life-tables-2005-07'];
        end
        
        function data = fetchLatestData(obj)
            %FETCHLATESTDATA Fetch latest mortality data
            %   Gets the most recent mortality table (2020-22)
            %
            %   Returns:
            %       data - Struct containing latest mortality data
            try
                % Get all available tables
                allPossibleTables = enumeration('TableNames');

                % Find the most recent table by extracting year from enum name
                latestYear = 0;
                latestTable = [];

                for i = 1:length(allPossibleTables)
                    tableName = char(allPossibleTables(i));
                    yearStr = regexp(tableName, '\d{4}', 'match');
                    if ~isempty(yearStr)
                        year = str2double(yearStr{1});
                        if year > latestYear
                            latestYear = year;
                            latestTable = allPossibleTables(i);
                        end
                    end
                end

                if isempty(latestTable)
                    error('MATLAB:invalidType', 'No valid tables found');
                end
                data = obj.getMortalityTable(latestTable);
                obj.updateLastUpdated();
                obj.DataCache('latest') = data;
            catch e
                error('MATLAB:invalidType', 'Failed to fetch data from AGA: %s', e.message);
            end
        end
        
        function fetchAllTables(obj)
            %FETCHALLTABLES Fetch all available tables
            %   Attempts to fetch and cache all known mortality tables
            obj.log('Fetching all available tables...');
            
            % Get all available tables
            allTables = enumeration('TableNames');
            successfulTables = [];
            
            for i = 1:length(allTables)
                try
                    tableEnum = allTables(i);
                    obj.log(sprintf('Fetching table %s...', obj.enumToTableString(tableEnum)));
                    data = obj.getMortalityTable(tableEnum);
                    % Only add to successful tables if we got valid data
                    if ~isempty(data) && isfield(data, 'Male') && isfield(data, 'Female')
                        successfulTables = [successfulTables, tableEnum];
                    end
                catch e
                    obj.log(sprintf('Error fetching table %s: %s', obj.enumToTableString(allTables(i)), e.message));
                end
            end
            
            % Update available tables in cache
            obj.DataCache('tables') = successfulTables;
            obj.log(sprintf('Successfully fetched %d tables', length(successfulTables)));
        end

        function [data, success] = fetchTable(obj, tableEnum)
            %FETCHTABLE Fetch a specific table from AGA source
            %   Inputs:
            %       tableEnum - TableNames enum value
            %   Returns:
            %       data - Struct containing table data
            %       success - Boolean indicating if fetch was successful
            try
                % Validate input is a TableNames enum
                if ~isa(tableEnum, 'TableNames')
                    error('MATLAB:invalidType', 'Input must be a TableNames enum value');
                end
                
                % Fetch the table
                data = obj.getMortalityTable(tableEnum);
                success = true;
                
            catch e
                obj.log(sprintf('Error fetching table %s: %s', char(tableEnum), e.message));
                data = [];
                success = false;
            end
        end
        
        function isAvailable = isWebsiteAvailable(obj)
            %ISWEBSITEAVAILABLE Check if AGA website is available
            %   Tests connection to AGA website
            %
            %   Returns:
            %       isAvailable - Boolean indicating if website is accessible
            try
                isAvailable = obj.checkAvailability();
            catch
                isAvailable = false;
            end
        end
        
        function saveUrlCache(obj)
            %SAVEURLCACHE Save URL cache to file
            urlCache = obj.UrlCache;
            save(obj.UrlCacheFile, 'urlCache');
        end
        
        function isValid = validateTableData(obj, raw)
            %VALIDATETABLEDATA Validate table data
            %   Checks if raw data has expected structure
            %   Inputs:
            %       raw - struct with three fields Age, qx, lx
            %   Returns:
            %       isValid - Boolean indicating if data is valid
            try
                % Check if raw is a struct with required fields
                if ~isstruct(raw) || ~isfield(raw, 'Age') || ~isfield(raw, 'qx') || ~isfield(raw, 'lx')
                    obj.log('Data is not a struct with required fields (Age, qx, lx)');
                    isValid = false;
                    return;
                end
                
                % Check if arrays have sufficient length
                if length(raw.Age) < 10
                    obj.log('Data arrays are too short');
                    isValid = false;
                    return;
                end
                
                % Check if arrays have matching lengths
                if ~isequal(length(raw.Age), length(raw.qx), length(raw.lx))
                    obj.log('Data arrays have mismatched lengths');
                    isValid = false;
                    return;
                end
                
                % Check if values are within expected ranges
                if any(raw.Age < 0) || any(raw.qx < 0) || any(raw.qx > 1) || any(raw.lx < 0)
                    obj.log('Data contains values outside expected ranges');
                    isValid = false;
                    return;
                end
                
                isValid = true;
            catch ME
                obj.log('Error validating table data: %s', ME.message);
                isValid = false;
            end
        end

        function urls = getTableUrls(obj)
            %GETTABLEURLS Get all available table URLs
            %   Returns a map of table names to their publication URLs
            %
            %   Returns:
            %       urls - containers.Map with table names as keys and URLs as values
            try
                % Ensure URL cache is initialized
                if isempty(obj.UrlCache)
                    obj.initializeUrlCache();
                end
                
                % Return the table URLs map
                urls = obj.TableURLs;
                
                % If no URLs are available, try to update the cache
                if isempty(urls)
                    obj.updateUrlCache();
                    urls = obj.TableURLs;
                end
                
                obj.log('Retrieved %d table URLs', length(urls));
            catch e
                error('MATLAB:invalidType', 'Failed to get table URLs: %s', e.message);
            end
        end

        function urls = getDownloadUrls(obj)
            %GETDOWNLOADURLS Get download URLs for all tables
            %   Returns a map of table names to their download URLs
            %
            %   Returns:
            %       urls - containers.Map with table names as keys and download URLs as values
            try
                % Ensure URL cache is initialized
                if isempty(obj.UrlCache)
                    obj.initializeUrlCache();
                end
                
                % Create map for download URLs
                urls = containers.Map('KeyType', 'char', 'ValueType', 'any');
                
                % Get all table keys
                tableKeys = keys(obj.UrlCache);
                
                % Extract download URLs
                for i = 1:length(tableKeys)
                    key = tableKeys{i};
                    if isfield(obj.UrlCache(key), 'downloadUrl')
                        urls(key) = obj.UrlCache(key).downloadUrl;
                    end
                end
                
                obj.log('Retrieved %d download URLs', length(urls));
            catch e
                error('MATLAB:invalidType', 'Failed to get download URLs: %s', e.message);
            end
        end

        function tableEnum = tableStringToEnum(obj, tableName)
            %TABLESTRINGTOENUM Convert string table name to enum
            %   Inputs:
            %       tableName - String table name
            %   Returns:
            %       tableEnum - TableNames enumeration value
            try
                % Convert string to enum
                tableEnum = TableNames.(tableName);
            catch e
                error('MATLAB:invalidType', 'Invalid table name: %s', tableName);
            end
        end
    end
    
    methods (Access = protected)
        function rawData = fetchRawData(obj, tableEnum)
            %FETCHRAWDATA Fetch raw data from AGA website
            %   Downloads and reads Excel files from AGA website
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       rawData - Struct containing raw table data
            try
                % Get table name and URL
                tableName = obj.enumToTableString(tableEnum);
                if ~obj.UrlCache.isKey(tableName)
                    error('MATLAB:invalidType', 'Table %s not found in URL cache', tableName);
                end
                
                % Get download URL
                downloadUrl = obj.UrlCache(tableName).downloadUrl;
                if isempty(downloadUrl)
                    error('MATLAB:invalidType', 'No download URL found for table %s', tableName);
                end
                
                % Download file
                sourceDir = fullfile(obj.CacheDir, '..', obj.SourceDir);
                fileName = sprintf('%s.xlsx', tableName);
                filePath = fullfile(sourceDir, fileName);
                
                if ~exist(filePath, 'file') || obj.OverwriteExisting
                    obj.log('Downloading %s...', fileName);
                    websave(filePath, downloadUrl, obj.WebOptions);
                end
                
                % Read Excel file
                obj.log('Reading %s...', fileName);
                [~, ~, raw] = xlsread(filePath);
                
                % Convert to struct
                rawData = obj.parseExcelData(raw);
                
            catch ME
                error('MATLAB:invalidType', 'Failed to fetch raw data: %s', ME.message);
            end
        end
        
        function parsedData = parseRawData(obj, rawData, tableEnum)
            %PARSERAWDATA Parse raw data into standard format
            %   Transforms raw data into standard mortality table format
            %
            %   Inputs:
            %       rawData - Struct containing raw table data
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       parsedData - Struct containing parsed table data
            try
                % Validate raw data
                if ~obj.validateTableData(rawData)
                    error('MATLAB:invalidType', 'Invalid raw data structure');
                end
                
                % Create standard format
                parsedData = struct();
                parsedData.Male = rawData;
                parsedData.Female = rawData;  % TODO: Handle gender-specific data
                parsedData.TableName = char(tableEnum);
                parsedData.Source = obj.SourceName;
                parsedData.LastUpdated = obj.LastUpdated;
                
            catch ME
                error('MATLAB:invalidType', 'Failed to parse raw data: %s', ME.message);
            end
        end
        
        function data = parseExcelData(obj, raw)
            %PARSEEXCELDATA Parse Excel data into struct
            %   Converts Excel data into structured format
            %
            %   Inputs:
            %       raw - Cell array from xlsread
            %   Returns:
            %       data - Struct with Age, qx, lx fields
            try
                % Find data rows (skip headers)
                dataStart = 1;
                while dataStart <= size(raw, 1) && ~isnumeric(raw{dataStart, 1})
                    dataStart = dataStart + 1;
                end
                
                % Extract data
                data = struct();
                data.Age = cell2mat(raw(dataStart:end, 1));
                data.qx = cell2mat(raw(dataStart:end, 2));
                data.lx = cell2mat(raw(dataStart:end, 3));
                
            catch ME
                error('MATLAB:invalidType', 'Failed to parse Excel data: %s', ME.message);
            end
        end
        
        function tableName = enumToTableString(obj, tableEnum)
            %ENUMTOTABLESTRING Convert enum to table name string
            %   Converts TableNames enum to string format
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       tableName - String table name
            tableName = char(tableEnum);
        end
        
        function loadUrlPatterns(obj)
            %LOADURLPATTERNS Load URL patterns from resource file
            %   Loads patterns for matching publication and download URLs
            try
                % Define URL patterns for AGA website
                obj.UrlPatterns = struct();
                
                % Pattern for publication pages
                obj.UrlPatterns.pubPattern = 'https://aga\.gov\.au/publications/life-tables/[a-z-]+';
                
                % Pattern for Excel file downloads - more flexible to match files in any location
                obj.UrlPatterns.downloadPattern = 'https://aga\.gov\.au/[^"\s]*\.xlsx';
                
                % Pattern for table names in URLs
                obj.UrlPatterns.tableNamePattern = '(?:australian-life-tables|alt)-(\d{4}-\d{2})';
                
                obj.log('URL patterns loaded successfully');
            catch e
                error('MATLAB:invalidType', 'Failed to load URL patterns: %s', e.message);
            end
        end

        function [matches, tokens] = matchUrlPattern(obj, url, patternType)
            %MATCHURLPATTERN Match URL against pattern
            %   Inputs:
            %       url - URL to match
            %       patternType - Type of pattern to use ('pub', 'download', or 'tableName')
            %   Returns:
            %       matches - Cell array of matched strings
            %       tokens - Cell array of captured tokens
            try
                switch patternType
                    case 'pub'
                        pattern = obj.UrlPatterns.pubPattern;
                    case 'download'
                        pattern = obj.UrlPatterns.downloadPattern;
                    case 'tableName'
                        pattern = obj.UrlPatterns.tableNamePattern;
                    otherwise
                        error('MATLAB:invalidType', 'Invalid pattern type: %s', patternType);
                end
                
                [matches, tokens] = regexp(url, pattern, 'match', 'tokens');
            catch e
                error('MATLAB:invalidType', 'Failed to match URL pattern: %s', e.message);
            end
        end

        function downloadUrl = extractDownloadUrl(obj, pubUrl)
            %EXTRACTDOWNLOADURL Extract download URL from publication page
            %   Inputs:
            %       pubUrl - Publication page URL
            %   Returns:
            %       downloadUrl - URL for Excel file download
            try
                % Read publication page
                html = webread(pubUrl, obj.WebOptions);
                
                % Find all URLs matching download pattern
                [matches, ~] = obj.matchUrlPattern(html, 'download');
                
                if isempty(matches)
                    error('MATLAB:invalidType', 'No download URL found on page: %s', pubUrl);
                end
                
                % Use first matching URL
                downloadUrl = matches{1};
                
            catch e
                error('MATLAB:invalidType', 'Failed to extract download URL: %s', e.message);
            end
        end

        function tableName = extractTableName(obj, url)
            %EXTRACTTABLENAME Extract table name from URL
            %   Inputs:
            %       url - URL containing table name
            %   Returns:
            %       tableName - Extracted table name
            try
                [~, tokens] = obj.matchUrlPattern(url, 'tableName');
                
                if isempty(tokens)
                    error('MATLAB:invalidType', 'No table name found in URL: %s', url);
                end
                
                % Extract year range from tokens
                yearRange = tokens{1}{1};
                
                % Convert to table name format
                tableName = sprintf('ALT_Table%s', strrep(yearRange, '-', '_'));
                
            catch e
                error('MATLAB:invalidType', 'Failed to extract table name: %s', e.message);
            end
        end

        function updateUrlCache(obj)
            %UPDATEURLCACHE Update URL cache with latest URLs
            %   Scans publication pages for download URLs and updates cache
            try
                % Get all table keys
                tableKeys = keys(obj.TableURLs);
                
                for i = 1:length(tableKeys)
                    key = tableKeys{i};
                    pubUrl = obj.TableURLs(key);
                    
                    try
                        % Extract download URL
                        downloadUrl = obj.extractDownloadUrl(pubUrl);
                        
                        % Update cache
                        obj.UrlCache(key) = struct('pubUrl', pubUrl, 'downloadUrl', downloadUrl);
                        obj.log('Updated URL cache for table %s', key);
                    catch e
                        obj.log('Failed to update URL cache for table %s: %s', key, e.message);
                    end
                end
                
                % Save updated cache
                obj.saveUrlCache();
                
            catch e
                error('MATLAB:invalidType', 'Failed to update URL cache: %s', e.message);
            end
        end
    end
end 