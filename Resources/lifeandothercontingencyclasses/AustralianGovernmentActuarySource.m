classdef AustralianGovernmentActuarySource < MortalityDataSource
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
        %CacheManager % Property to hold the cache manager
    end
    
    methods (Access = public)
        function obj = AustralianGovernmentActuarySource(varargin)
            % Constructor with optional parameters
            % Usage: obj = AustralianGovernmentActuarySource('OverwriteExisting', true)
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

            % % initilaise mortality cachemanager
            % obj.CacheManager = CacheManagerFactory.createCacheManager(CacheManagerType.Mortality);
            % % obj.CacheManager = MortalityCacheManager();
        end
         function initializeSourceDirectory(obj)
            %INITIALIZESOURCEDIRECTORY Initialize source directory
            %   Creates directory for source files if it doesn't exist
            sourceDir = fullfile(obj.CacheDir, '..', obj.SourceDir); %TODO need to use LifeTables under Resources folder
            if ~exist(sourceDir, 'dir')
                mkdir(sourceDir);
            end
        end
        function initializeUrlCache(obj)
            % Initialize URL cache from file if it exists
            obj.UrlCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
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
         %   obj.updateUrlCache(); 
         %TODO consider if we use save or update and what is best approach
            obj.saveUrlCache()
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
               %data = obj.getMortalityTable(TableNames.ALT_Table2020_22);
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
                    %TODO print first three rows of table to logfile
                    %include identifying table names
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
        
        function isAvailable = checkAvailability(obj)
            %CHECKAVAILABILITY Check if AGA website is available
            %   Tests connection to AGA website
            %
            %   Returns:
            %       isAvailable - Boolean indicating if website is accessible
            try
                webread([obj.BaseURL 'publications/life-tables'], obj.WebOptions);
                isAvailable = true;
            catch
                isAvailable = false;
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
                tempData = obj.getMortalityTable(tableEnum);
                if ~isempty(tempData) && isfield(tempData, 'Male') && isfield(tempData, 'Female')
                    data = tempData;
                    success = true;
                end

            catch e
                obj.log(sprintf('Error fetching table %s: %s', char(tableEnum), e.message));
                data = [];
                success = false;
            end
        end
        
        

        function testUrlPatterns(obj)
            %TESTURLPATTERNS Test URL patterns
            %   Tests all known URL patterns for each table
            tables = obj.getAvailableTables();
            for i = 1:length(tables)
                tableEnum = tables(i);
                tableName = obj.enumToTableString(tableEnum);
                obj.log(sprintf('\nTesting patterns for table %s:', tableName));
                currentDate = datetime('now');
                yearMonth = datestr(currentDate, 'yyyy-mm');
                patterns = obj.generateUrlPatterns(tableName, yearMonth);
                for j = 1:length(patterns)
                    try
                        obj.log(sprintf('  Testing pattern %d: %s', j, patterns{j}));

                        response = webread(patterns{j}, obj.WebOptions);
                        if isempty(response)
                            obj.log('Warning: Empty response from URL: %s', urlsprintf('  FAILED: Pattern %d works for table %s', patterns{j}, tableName));
                            continue;
                        end

                        
                        % %[~, status] = urlread(patterns{j}, 'Timeout', 5);
                        % if status == 200
                        %     obj.log(sprintf('  SUCCESS: Pattern %d works for table %s', j, tableName));
                        %     obj.updateUrlCache(tableEnum, patterns{j});
                        % else
                        %     obj.log(sprintf('  FAILED: Pattern %d returned status %d', j, status));
                        % end
                    catch e
                        obj.log(sprintf('  ERROR: Pattern %d failed with error: %s', j, e.message));
                    end
                end
            end
        end
        
        function saveUrlCache(obj)
            %SAVEURLCACHE Save URL cache to file
            urlCache = obj.UrlCache;
            %TODO make sure we save this in the appropriate folder
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
                    obj.log('Not enough rows in data');
                    isValid = false;
                    return;
                end
                
                % Validate age values
                if any(isnan(raw.Age)) || any(raw.Age < 0) || any(raw.Age > 150)
                    obj.log('Invalid age values found');
                    isValid = false;
                    return;
                end
                
                % Validate qx values (should be between 0 and 1)
                if any(isnan(raw.qx)) || any(raw.qx < 0) || any(raw.qx > 1)
                    obj.log('Invalid qx values found');
                    isValid = false;
                    return;
                end
                
                % Validate lx values (should be positive)
                if any(isnan(raw.lx)) || any(raw.lx <= 0)
                    obj.log('Invalid lx values found');
                    isValid = false;
                    return;
                end
                
                % Check if arrays have same length
                if ~isequal(length(raw.Age), length(raw.qx), length(raw.lx))
                    obj.log('Arrays have different lengths');
                    isValid = false;
                    return;
                end
                
                isValid = true;
            catch e
                obj.log(['Validation error: ' e.message]);
                isValid = false;
            end
        end
                
        function filename = downloadFile(obj, url)
            %DOWNLOADFILE Download file from URL
            %   Downloads file and returns local filename
            %   Inputs:
            %       url - String URL to download
            %   Returns:
            %       filename - String path to downloaded file
            [~, name, ext] = fileparts(url);
            filename = fullfile(obj.DownloadDir, [name ext]);
            if ~exist(filename, 'file') || obj.OverwriteExisting
                obj.log(sprintf('Downloading: %s', url));
                websave(filename, url, obj.WebOptions);
            end
        end
        
        function clearCache(obj)
            %CLEARCACHE Clear all caches
            %   Clears both data cache and URL cache
            try
                % Clear data cache
                obj.DataCache = containers.Map();
                % 1. Call the parent's clearCache to handle the main data cache.
                clearCache@MortalityDataSource(obj);
                
                % Clear URL cache
                obj.UrlCache = containers.Map('KeyType', 'char', 'ValueType', 'any');
               
                %TODO delete cachefiles should be a separate method
                %TODO either store an empty cachefile or ensure we always
                %TODO initialise

                if exist(obj.UrlCacheFile, 'file')
                    delete(obj.UrlCacheFile);
                    obj.log('URL cache file deleted.');
                else
                    obj.log('URL cache file (%s) not found, no deletion needed.', obj.UrlCacheFile); % Or just skip logging if not found
                end
                
               % TODO add savecache method
                % % Save empty cache to file
                %work out how to saveCache
                % obj.saveCache();
                
                obj.log('Data cache and URL cache cleared');
            catch ME
                error('MATLAB:invalidType', 'Failed to clear cache: %s', ME.message);
            end
        end
    end
    
    methods (Access = protected)
        function updateLastUpdated(obj)
            %UPDATELASTUPDATED Update last updated timestamp
            %   Updates both the object's LastUpdated property and the cache's timestamp
            
            % Call superclass method first
            updateLastUpdated@MortalityDataSource(obj);
            
            % Additional AGA-specific updates if needed
            if obj.DataCache.isKey('metadata')
                metadata = obj.DataCache('metadata');
                metadata.Source = 'Australian Government Actuary';
                obj.DataCache('metadata') = metadata;
            end
        end
         function urls = getTableUrlsFromUrlCache(obj)
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

        function urls = getDownloadUrlsFromUrlCache(obj)
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

        % function tableEnum = tableStringToEnum(obj, tableName)
        %     %TABLESTRINGTOENUM Convert string table name to enum
        %     %   Inputs:
        %     %       tableName - String table name
        %     %   Returns:
        %     %       tableEnum - TableNames enumeration value
        %     try
        %         % Convert string to enum
        %         tableEnum = TableNames.(tableName);
        %     catch e
        %         error('MATLAB:invalidType', 'Invalid table name: %s', tableName);
        %     end
        % end
    end
       
        
        
      methods(Access = protected)  
        function rawData = fetchRawData(obj, tableName)
            %FETCHRAWDATA Fetch raw data for a specific table
            %   Downloads and parses the Excel file for the specified table
            %   Inputs:
            %       tableName - TableNames enumeration value
            %   Returns:
            %       rawData - Struct containing raw data with fields:
            %           files - Cell array of structs, each with:
            %               filename - String path to file
            %               data - Matrix of numeric data
            %               type - GenderType enum value (Male or Female)
            %               tableEnum - TableNames enum value this file belongs to
            
            % Get table key from enum
            tableKey = char(tableName);
            
            % Initialize files array
            files = {};
            
            % Get publication page URL
            if ~obj.TableURLs.isKey(tableKey)
                error('MATLAB:invalidType', 'Unknown table: %s', tableKey);
            end
            
            % Fetch publication page
            try
                pageContent = webread(obj.TableURLs(tableKey), obj.WebOptions);
            catch e
                error('MATLAB:invalidType', 'Failed to fetch publication page: %s', e.message);
            end
            
            % Extract download URLs
            downloadURLs = obj.getDownloadUrls(pageContent, tableKey);
            if isempty(downloadURLs)
                error('MATLAB:invalidType', 'No download URLs found for table: %s', tableKey);
            end
            
            % Try each URL
            for i = 1:length(downloadURLs)
                try
                    url = downloadURLs{i};
                    obj.log('Testing URL: %s', url);
                    
                    % First verify the URL is accessible
                    response = webread(url, obj.WebOptions);
                    if isempty(response)
                        obj.log('Warning: Empty response from URL: %s', url);
                        continue;
                    end
                    
                    % Download the file
                    obj.log('Downloading: %s', url);
                    [~, filename,extension] = fileparts(url);
                    %filepath = fullfile(obj.DownloadDir, [filename '.xlsx']);     
                    filepath = fullfile(obj.DownloadDir, [filename extension]);

                    
                    % Use websave with additional options for better reliability
                    options = weboptions('Timeout', 60, ...
                                       'HeaderFields', {'User-Agent', 'Mozilla/5.0'}, ...
                                       'ContentType', 'binary');
                    websave(filepath, url, options);
                    
                    % Verify the downloaded file is a valid Excel file
                    try
                        [~, sheets] = xlsfinfo(filepath);
                        if isempty(sheets) || ischar(sheets) && contains(sheets, 'Unreadable Excel file')
                            obj.log('Warning: Downloaded file is not a valid Excel file: %s', filepath);
                            delete(filepath);  % Clean up invalid file
                            continue;
                        end
                    catch e
                        obj.log('Warning: Failed to validate Excel file %s: %s', filepath, e.message);
                        if exist(filepath, 'file')
                            delete(filepath);  % Clean up invalid file
                        end
                        continue;
                    end
                    
                    % Create file data structure
                    fileData = struct('filename', filepath, ...
                                    'data', [], ...
                                    'type', [], ...
                                    'tableEnum', tableName);
                    
                    % Add to files array
                    files{end+1} = fileData;
                    
                    % Update URL cache
                    obj.updateUrlCache(tableName, url);
                    
                catch e
                    obj.log('Warning: Failed to download file from URL %s: %s', url, e.message);
                    if exist('filepath', 'var') && exist(filepath, 'file')
                        delete(filepath);  % Clean up any partially downloaded file
                    end
                    continue;
                end
            end
            
            if isempty(files)
                error('MATLAB:invalidType', 'Failed to download any valid files for table: %s', tableKey);
            end
            
            % Return the raw data
            rawData = struct('files', {files});
        end
        
        function parsedData = parseRawData(obj, rawData, tableEnum)
            %PARSERAWDATA Parse raw data into standard format
            %   Transforms raw Excel data into standard mortality table format
            %   Inputs:
            %       rawData - Struct containing raw data with fields:
            %           files - Cell array of structs, each with:
            %               filename - String path to file
            %               data - Matrix of numeric data
            %               type - GenderType enum value (Male or Female)
            %               tableEnum - TableNames enum value this file belongs to
            %       tableEnum - TableNames enumeration value
            %   Returns:
            %       parsedData - Struct with Male and Female mortality data
            
            % % Get column mapping
            % mapping = obj.column_mapping();
            
            % Initialize the structure with empty arrays
            parsedData = struct();
            parsedData.Male = struct('Age', [], 'qx', [], 'lx', []);
            parsedData.Female = struct('Age', [], 'qx', [], 'lx', []);
                                  
            % Filter files to only those matching the table enum
            matchingFiles = {};
            for i = 1:length(rawData.files)
                fileData = rawData.files{i};
                if ~isfield(fileData, 'filename') || isempty(fileData.filename)
                    continue;
                end
                if isequal(fileData.tableEnum, tableEnum)
                    matchingFiles{end+1} = fileData;
                end
            end

            if isempty(matchingFiles)
                error('MATLAB:invalidType', 'No files found matching table %s', char(tableEnum));
            end

            % % Process matching files
            % use parseExcelData(fileData,mapping,parsedData)
            parsedData = parseExcelData(obj, matchingFiles,parsedData);
                                 
            % Add table metadata
            parsedData.TableName = char(tableEnum);
            parsedData.Source = obj.SourceName;
            parsedData.LastUpdated = obj.LastUpdated;
        end
        
        function parsedData = parseExcelData(obj, matchingFiles,inputParsedData)
            %PARSEEXCELDATA Parse Excel data into struct
            %   Converts Excel data into structured format
            %
            %   Inputs:
            %       matchingFiles - Cell array from xlsread
            %   Returns:
            % % Get spreadsheet column mapping
            mapping = obj.column_mapping();

            % Track if we've found both male and female data
            foundMale = false;
            foundFemale = false;

            % Process matching files
            for i = 1:length(matchingFiles)
                fileData = matchingFiles{i};

                try%       s

                    [~, sheets] = xlsfinfo(fileData.filename);
                    if length(sheets) > 1
                        % Combined file with separate sheets
                        % Find male and female sheets

                        maleSheet = sheets{contains(lower(sheets), 'male')};
                        femaleSheet = sheets{contains(lower(sheets), 'female')};

                        if isempty(maleSheet) || isempty(femaleSheet)
                            obj.log('Warning: Could not find both male and female sheets in file: %s', fileData.filename);
                            % continue;
                        end

                        % Read male data if not already found
                        if ~foundMale
                            maleData = readmatrix(fileData.filename, 'Sheet', maleSheet, 'FileType', 'spreadsheet');
                            if size(maleData, 2) < max([mapping.Age, mapping.lx, mapping.qx])
                                obj.log('Warning: Male data has insufficient columns in file: %s', fileData.filename);
                                % continue;
                            end
                            parsedData.Male = struct('Age', maleData(:,mapping.Age), ...
                                'lx', maleData(:,mapping.lx), ...
                                'qx', maleData(:,mapping.qx));
                            foundMale = true;
                        end

                        % Read female data if not already found
                        if ~foundFemale
                            femaleData = readmatrix(fileData.filename, 'Sheet', femaleSheet, 'FileType', 'spreadsheet');
                            if size(femaleData, 2) < max([mapping.Age, mapping.lx, mapping.qx])
                                obj.log('Warning: Female data has insufficient columns in file: %s', fileData.filename);
                                % continue;
                            end
                            parsedData.Female = struct('Age', femaleData(:,mapping.Age), ...
                                'lx', femaleData(:,mapping.lx), ...
                                'qx', femaleData(:,mapping.qx));
                            foundFemale = true;
                        end
                    else
                        % Single sheet file
                        [~, ~, raw] = xlsread(fileData.filename);
                        if isempty(raw)
                            obj.log('Warning: Empty data in file: %s', fileData.filename);
                            % continue;
                        end

                        % Find start of data
                        startRow = obj.findDataStart(raw);
                        if startRow == 0
                            obj.log('Warning: Could not find start of data in file: %s', fileData.filename);
                            % continue;
                        end

                        % Extract data
                        raw = raw(startRow:end, :);

                        % Validate data
                        if size(raw, 1) < 2
                            obj.log('Warning: Not enough rows in data in file: %s', fileData.filename);
                            % continue;
                        end

                        % Extract columns by position
                        ageData = cell2mat(raw(:, mapping.Age));
                        lxData = cell2mat(raw(:, mapping.lx));
                        qxData = cell2mat(raw(:, mapping.qx));

                        % Create data structure
                        data = struct('Age', ageData, 'lx', lxData, 'qx', qxData);

                        % Determine gender type based on filename
                        if contains(lower(fileData.filename), 'male') && ~foundMale
                            parsedData.Male = data;
                            foundMale = true;
                        elseif contains(lower(fileData.filename), 'female') && ~foundFemale
                            parsedData.Female = data;
                            foundFemale = true;
                        end
                    end

                    % Break if we've found both male and female data if
                    if foundMale && foundFemale
                        break;
                    end

                catch e
                    obj.log('Warning: Failed to parse xls file %s: %s', fileData.filename, e.message);
                    % continue;
                end
            end

        end
        
        function loadUrlPatterns(obj)
            %LOADURLPATTERNS Load URL patterns from resource file
            try
                % Get the directory where this class file is located
                classDir = fileparts(mfilename('fullpath'));
                % Construct path to JSON file in +runtimeclasses directory
                patternFile = fullfile(classDir, '..', '+runtimeclasses', 'aga_url_patterns.json');
                
                if ~exist(patternFile, 'file')
                    error('MATLAB:invalidType', 'URL patterns file not found: %s', patternFile);
                end
                
                % Read and parse JSON file
                fid = fopen(patternFile, 'r');
                raw = fread(fid, inf);
                str = char(raw');
                fclose(fid);
                obj.UrlPatterns = jsondecode(str);
                
                obj.log('Successfully loaded URL patterns from resource file');
            catch e
                error('MATLAB:invalidType', 'Failed to load URL patterns: %s', e.message);
            end
        end
      end

    
    methods (Access = private)
        function mapping = column_mapping(obj)
            %COLUMN_MAPPING Get column mapping for data extraction
            %   Returns a struct with column indices for age, lx, and qx
            %   Uses the mapping table defined in column_mapping()
            map = column_mapping();
            mapping = map.ALT_Table2020_22;  % Use latest table mapping as default
        end
        
        function downloadURLs = getDownloadUrls(obj, pageContent, tableKey)
            %GETDOWNLOADURLS Get download URLs
            %   Extracts download URLs from page content
            %
            %   Inputs:
            %       pageContent - String containing page HTML
            %       tableKey - String table identifier
            %   Returns:
            %       downloadURLs - Cell array of download URLs
            %TODO examine the reason for this method
            downloadURLs = {};
            
            % First try cached download URL
            if isKey(obj.UrlCache, tableKey) && ~isempty(obj.UrlCache(tableKey).downloadUrl)
                obj.log(['Trying cached download URL for ' tableKey ': ' obj.UrlCache(tableKey).downloadUrl]);
                downloadURLs{end+1} = obj.UrlCache(tableKey).downloadUrl;
                return;
            end
            
            % Get URLs from patterns
            if isfield(obj.UrlPatterns, 'table_patterns')
                % Get all field names in table_patterns
                patternFields = fieldnames(obj.UrlPatterns.table_patterns);
                
                % Try to find matching pattern
                pattern = [];
                for i = 1:length(patternFields)
                    field = patternFields{i};
                    % Remove 'x' prefix if it exists
                    cleanField = regexprep(field, '^x', '');
                    if strcmp(cleanField, tableKey)
                        pattern = obj.UrlPatterns.table_patterns.(field);
                        break;
                    end
                end
                
                if isempty(pattern)
                    obj.log(sprintf('No URL patterns found for table: %s', tableKey));
                    return;
                end
                
                baseUrl = obj.UrlPatterns.base_url;
                
                if strcmp(pattern.type, 'combined')
                    downloadURLs{end+1} = [baseUrl pattern.url];
                else
                    downloadURLs{end+1} = [baseUrl pattern.urls.male];
                    downloadURLs{end+1} = [baseUrl pattern.urls.female];
                end
            else
                obj.log(sprintf('No table patterns found in URL patterns'));
            end
            
            obj.log(sprintf('Found download URLs for table %s:', tableKey));
            for i = 1:length(downloadURLs)
                obj.log(sprintf('  %s', downloadURLs{i}));
            end
        end
        
        function patterns = generateUrlPatterns(obj, tableName, yearMonth)
            %GENERATEURLPATTERNS Generate URL patterns
            %   Creates URL patterns for different table formats to test
            %   alternates to what is in JSON file
            %
            %   Inputs:
            %       tableName - String table identifier
            %       yearMonth - String in format 'yyyy-mm'
            %   Returns:
            %       patterns - Cell array of URL patterns
            tableYear = str2double(tableName(1:4));
            currentYear = year(datetime('now'));
            %TODO base the patterns off teh url pattern JSON file 
            if tableYear < currentYear
                if tableYear >= 2015
                    patterns = {
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s-all-tables.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s-all-tables_2.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/Australian_Life_Tables_%s_Males.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/Australian_Life_Tables_%s_Females.xlsx', yearMonth, tableName)
                    };
                elseif tableYear >= 2010
                    patterns = {
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s-all-tables.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/Males_Australian_Life_Tables_%s.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/Females_Australian_Life_Tables_%s.xlsx', yearMonth, tableName)
                    };
                else
                    patterns = {
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s-all-tables.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/males_%s.xlsx', yearMonth, tableName),
                        sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/females_%s.xlsx', yearMonth, tableName)
                    };
                end
            else
                patterns = {
                    sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s-all-tables.xlsx', yearMonth, tableName),
                    sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s-all-tables_2.xlsx', yearMonth, tableName),
                    sprintf('https://aga.gov.au/sites/aga.gov.au/files/%s/australian-life-tables-%s.xlsx', yearMonth, tableName)
                };
            end
        end
        
        function updateUrlCache(obj, tableEnum, url)
            %UPDATEURLCACHE Update URL cache
            %   Stores working URL in cache
            %
            %   Inputs:
            %       tableEnum - TableNames enumeration value
            %       url - String URL to cache
           
            
            key = char(tableEnum);
            if ~isKey(obj.UrlCache, key)
                obj.UrlCache(key) = struct('pubUrl', obj.TableURLs(key), 'downloadUrl', '');
            end
            
            % Get the current struct, modify it, and put it back
            cacheEntry = obj.UrlCache(key);
            cacheEntry.downloadUrl = url;
            obj.UrlCache(key) = cacheEntry;
            
            obj.saveUrlCache();
            obj.log('Updated URL cache for %s: %s', key, url);
        end
        
        function str = enumToTableString(~, tableEnum)
            %ENUMTOTABLESTRING Convert enum to string
            %   Converts TableNames enum to string identifier
            %   Inputs:
            %       tableEnum - TableNames enumeration value or string
            %   Returns:
            %       str - String table identifier
            if ischar(tableEnum) || isstring(tableEnum)
                str = tableEnum;
                return;
            end
            
            % Convert enum to string and remove 'ALT_Table' prefix
            str = char(tableEnum);
            str = strrep(str, 'ALT_Table', '');
        end
        
        function str = tableStringToEnum(~, tableStr)
            %TABLESTRINGTOENUM Convert string to enum
            %   Converts string table identifier to TableNames enum
            %   Inputs:
            %       tableStr - String table identifier
            %   Returns:
            %       str - TableNames enumeration value
            if isa(tableStr, 'TableNames')
                str = tableStr;
                return;
            end
            
            % Add 'ALT_Table' prefix and convert to enum
            enumStr = ['ALT_Table' tableStr];
            str = TableNames.(enumStr);
        end
        
        function startRow = findDataStart(~, raw)
            %FINDDATASTART Find the starting row of data in the Excel file
            %   Looks for the row containing age data in first 10 rows

            maxRows = min(10, size(raw, 1));
            for i = 1:maxRows
                row = raw(i, :);
                if ~isempty(row) && isnumeric(row{1}) && row{1} == 0
                    startRow = i;
                    return;
                end
            end
            error('MATLAB:invalidType', 'Could not find data start in first %d rows', maxRows);
        end
    end

end