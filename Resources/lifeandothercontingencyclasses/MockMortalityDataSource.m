% --- MockMortalityDataSource Definition ---
classdef MockMortalityDataSource < MortalityDataSource
    properties
        MockTableName = TableNames.ALT_Table2020_22; % Default mock table, can be changed
        ReturnEmptyData = false; % Flag to simulate data not found
        CustomRates = []; % Property to hold custom rates for mocking
    end

    methods
        function obj = MockMortalityDataSource(tableName, customRates)
            obj@MortalityDataSource(); % Call superclass constructor
            if nargin > 0 && ~isempty(tableName)
                obj.MockTableName = tableName;
            end
            if nargin > 1 && ~isempty(customRates)
                obj.CustomRates = customRates;
            end
            obj.SourceName = 'MockDataSource';
            obj.SourceURL = 'local://mock';
            % The superclass constructor already creates obj.CacheManager
            % using a unique filename like 'MockMortalityDataSource_cache.mat'
            % if ~isempty(obj.CacheManager) % Ensure it was created
            %     obj.CacheManager.clearCache(); % Start clean for each instance
            % end
        end

        function clearSpecificCache(obj)
            % Helper to clear only this mock source's cache
            if ~isempty(obj.CacheManager)
                obj.CacheManager.clearCache();
            end
        end
    end

    methods (Access = protected)
        function rawData = fetchRawData(obj, tableEnum)
            if obj.ReturnEmptyData || (~isempty(obj.MockTableName) && tableEnum ~= obj.MockTableName)
                error('MockMortalityDataSource:DataNotFound', 'Mock data not found for %s', char(tableEnum));
            end
            rawData = struct('source', 'mock', 'tableName', char(tableEnum));
        end

        function parsedData = parseRawData(obj, rawDataInput, tableEnum)
            if obj.ReturnEmptyData || (~isempty(obj.MockTableName) && tableEnum ~= obj.MockTableName)
                 error('MockMortalityDataSource:ParsingFailed', 'Mock parsing failed for %s', char(tableEnum));
            end

            if ~isempty(obj.CustomRates)
                parsedData = obj.CustomRates; % Use custom rates if provided
            else
                % Default simple mock data
                parsedData = struct();
                ages = (0:10)'; % Short table for testing
                
                parsedData.Male.Age = ages;
                parsedData.Male.qx = linspace(0.001, 0.1, length(ages))';
                parsedData.Male.lx = round(100000 * cumprod([1; (1-parsedData.Male.qx(1:end-1))]));
                
                parsedData.Female.Age = ages;
                parsedData.Female.qx = linspace(0.0008, 0.08, length(ages))';
                parsedData.Female.lx = round(100000 * cumprod([1; (1-parsedData.Female.qx(1:end-1))]));
            end
            
            % Ensure essential metadata is present
            parsedData.TableName = char(tableEnum);
            parsedData.Source = obj.SourceName;
            parsedData.LastUpdated = datetime('now');
        end
    end
end
% --- End of MockMortalityDataSource Definition ---