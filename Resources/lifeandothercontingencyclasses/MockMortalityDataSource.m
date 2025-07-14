% --- MockMortalityDataSource Definition ---
classdef MockMortalityDataSource < MortalityDataSource
    properties
        MockTableName = TableNames.ALT_Table2020_22; % Default mock table, can be changed
        ReturnEmptyData = false; % Flag to simulate data not found
        CustomRates = []; % Property to hold custom rates for mocking
    end

    methods
        function obj = MockMortalityDataSource(varargin)
            % --- REFACTORED CONSTRUCTOR with argument forwarding ---

            % 1. Pre-scan varargin for arguments intended for the parent constructor.
            parentArgs = {};
            childVarargin = varargin; 
            
            % We look for 'cacheManagerInstance' and also for arguments that
            % this mock class's parser will handle, to separate them.
            for i = 1:2:length(varargin)
                if strcmpi(varargin{i}, 'cacheManagerInstance')
                    parentArgs = {'cacheManagerInstance', varargin{i+1}};
                    childVarargin([i, i+1]) = [];
                    break; 
                end
            end

            % 2. Call the parent constructor FIRST, forwarding the found arguments.
            obj@MortalityDataSource(parentArgs{:});
            
            % 3. Now, configure the child-specific properties using its own parser.
            p = inputParser;
            addParameter(p, 'TableName', obj.MockTableName, @(x) isa(x, 'TableNames'));
            addParameter(p, 'CustomRates', [], @isstruct);
            parse(p, childVarargin{:});
            
            obj.MockTableName = p.Results.TableName;
            obj.CustomRates = p.Results.CustomRates;
            
            % 4. Set other properties for this source.
            obj.SourceName = 'MockDataSource';
            obj.SourceURL = 'local://mock';
            
            % Ensure the cache is clean for this instance, which is good practice for a mock.
            if ~isempty(obj.getCacheManager())
                obj.getCacheManager().clearCache();
            end
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