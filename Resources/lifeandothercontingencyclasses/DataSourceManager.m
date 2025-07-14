% File: DataSourceManager.m
classdef DataSourceManager < handle
    %DATASOURCEMANAGER A singleton service locator for managing and providing
    %   data source instances. This version is configurable to allow for
    %   dependency injection of shared CacheManager objects.
    %TODO add ability for user to pass a custom map into getDataSOurceTable

    properties (Access = private)
        DataSourcePool containers.Map % Stores the singleton instances of data sources
        
        % --- NEW PROPERTY ---
        % This map will store a pre-configured CacheManager for a specific DataSource type.
        % Key = char(MortalityDataSourceNames), Value = CacheManager object
        CacheManagerRegistry containers.Map 
    end
    % --- THIS IS THE MAIN CHANGE ---
    % The constructor is now public, allowing the main app to create an instance.
    methods (Access = public)
        function obj = DataSourceManager()
            % Public constructor.
            obj.DataSourcePool = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.CacheManagerRegistry = containers.Map('KeyType', 'char', 'ValueType', 'any');
            disp('DataSourceManager instance created.');
        end
    end

    % --- The static getInstance() method is REMOVED ---
    % methods (Static)
    %     function singleObj = getInstance() ...
    % end
    % methods (Access = private)
    %     % The constructor is private to enforce the singleton pattern.
    %     function obj = DataSourceManager()
    %         obj.DataSourcePool = containers.Map('KeyType', 'char', 'ValueType', 'any');
    %         obj.CacheManagerRegistry = containers.Map('KeyType', 'char', 'ValueType', 'any');
    %     end
    % end
    % 
    % methods (Static)
    %     function singleObj = getInstance()
    %         % Provides global access to the single instance of this manager.
    %         persistent uniqueInstance
    %         if isempty(uniqueInstance) || ~isvalid(uniqueInstance)
    %             uniqueInstance = DataSourceManager();
    %         end
    %         singleObj = uniqueInstance;
    %     end
    % end

    methods
        % --- NEW PUBLIC METHOD for configuration ---
        function registerCacheManager(obj, dataSourceEnum, cacheManagerInstance)
            % Registers a specific CacheManager instance to be used when creating
            % a specific type of DataSource.
            if ~isa(dataSourceEnum, 'MortalityDataSourceNames')
                error('DataSourceManager:InvalidInput', 'dataSourceEnum must be a valid MortalityDataSourceNames enum member.');
            end
            if ~isa(cacheManagerInstance, 'utilities.MortalityCacheManager')
                error('DataSourceManager:InvalidInput', 'cacheManagerInstance must be a valid MortalityCacheManager object.');
            end
            
            sourceNameStr = char(dataSourceEnum);
            obj.CacheManagerRegistry(sourceNameStr) = cacheManagerInstance;
            fprintf('DataSourceManager: Registered a custom CacheManager for %s.\n', sourceNameStr);
        end

        function dataSource = getDataSource(obj, dataSourceEnum)
            % Retrieves a data source from the pool, creating it if it doesn't exist.
            sourceNameStr = char(dataSourceEnum);

            if obj.DataSourcePool.isKey(sourceNameStr)
                dataSource = obj.DataSourcePool(sourceNameStr);
            else
                fprintf('DataSourceManager: Creating new singleton instance for %s...\n', sourceNameStr);
                dataSource = obj.createDataSourceInstance(dataSourceEnum);
                obj.DataSourcePool(sourceNameStr) = dataSource;
            end
        end

        function dataSource = getDataSourceForTable(obj, tableNameEnum)
            % This high-level method remains the same for the user.
            %TODO add ability for user to pass a custom map into getDataSOurceTable
            mapping = DataSourceMapping.getTableToSourceMap();
            if ~isKey(mapping, tableNameEnum)
                error('DataSourceManager:MappingNotFound', 'No data source is mapped to the table "%s".', char(tableNameEnum));
            end
            dataSourceNameEnum = mapping(char(tableNameEnum));
            dataSource = obj.getDataSource(dataSourceNameEnum);
        end
        
        function reset(obj)
            % Utility method to clear the pools, useful for testing.
            obj.DataSourcePool = containers.Map('KeyType', 'char', 'ValueType', 'any');
            obj.CacheManagerRegistry = containers.Map('KeyType', 'char', 'ValueType', 'any');
            disp('DataSourceManager pools have been reset.');
        end
    end

    methods (Access = private)
        % --- MODIFIED private creation method ---
        function dataSource = createDataSourceInstance(obj, dataSourceEnum)
            % This method now checks the registry for a pre-configured CacheManager.
            
            sourceNameStr = char(dataSourceEnum);
            constructorArgs = {};

            % Check if a specific CacheManager has been registered for this DataSource type.
            if obj.CacheManagerRegistry.isKey(sourceNameStr)
                % If yes, prepare to pass it to the constructor as a name-value pair.
                registeredCacheManager = obj.CacheManagerRegistry(sourceNameStr);
                constructorArgs = {'cacheManagerInstance', registeredCacheManager};
                fprintf('DataSourceManager: Using registered CacheManager for %s.\n', sourceNameStr);
            end
            
             % Dynamically create the object from its name string.
            try
                % str2func converts the class name string into a function handle
                % that can be used to call the constructor.
                constructorHandle = str2func(sourceNameStr);
                
                % Call the constructor with any registered arguments.
                dataSource = constructorHandle(constructorArgs{:});
            catch ME
                % This catch block will handle errors like the class file not being found.
                error('DataSourceManager:CreationFailed', ...
                    'Failed to create instance of "%s". Ensure the class file "%s.m" exists on the MATLAB path and its constructor is correct. Original error: %s', ...
                    sourceNameStr, sourceNameStr, ME.message);
            end
        end
    end
end