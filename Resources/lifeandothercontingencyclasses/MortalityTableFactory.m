% NEW FILE: MortalityTableFactory.m
% Factory class for creating and managing mortality tables
classdef MortalityTableFactory
    methods (Static)
        function table = createTable(sourceType, sourceIdentifier, tableName)
            % Creates a new mortality table instance based on source type
            % Inputs:
            %   sourceType - 'File' or 'Web' or 'mortalitytablecache'
            %   sourcePath - Path to file or URL
            %   tableName - Name of the mortality table
            % Returns:
            %   table - Instance of BasicMortalityTable
            
            switch lower(sourceType)
                case 'file'
                    if ~isfile(sourceIdentifier)
                        error('MortalityTableFactory:FileNotFound', ...
                            'File not found: %s', sourceIdentifier);
                    end
                    data = load(sourceIdentifier); % Assumes .mat file has 'mortalityRates' struct
                    % with .Male and .Female fields.
                    % Ensure consistency: if file has .M and .F, convert to .Male and .Female
                    if isfield(data.mortalityRates, 'M') && isfield(data.mortalityRates, 'F')
                        actualRates.Male = data.mortalityRates.M;
                        actualRates.Female = data.mortalityRates.F;
                    else
                        actualRates = data.mortalityRates; % Assume it's already Male/Female
                    end

                    table = BasicMortalityTable(sourceIdentifier, actualRates);
                    table.TableName = tableName; % Can be a string if from file
                    table.SourcePath = sourceIdentifier;

                case 'mortalitytablecache'
                    if ~isa(sourceIdentifier, 'MortalityDataSource')
                        error('MortalityTableFactory:InvalidInput', ...
                            'For sourceType "CachedSource", sourceIdentifier must be a MortalityDataSource object.');
                    end
                    if ~isa(tableName, 'TableNames')
                        error('MortalityTableFactory:InvalidInput', ...
                            'For sourceType "CachedSource", tableNameEnum must be a TableNames enum member.');
                    end

                    dataSource = sourceIdentifier;

                    % This getMortalityTable uses the cache internally
                    mortalityDataStruct = dataSource.getMortalityTable(tableNameEnum);

                    % We need to wrap this struct in a BasicMortalityTable object
                    % The 'sourcePath' for BasicMortalityTable isn't strictly a file path here,
                    % so we can use a descriptive string.
                    table = BasicMortalityTable(sprintf('Cached: %s', char(tableNameEnum)), mortalityDataStruct);
                    table.TableName = char(tableName);
                    table.SourcePath = dataSource.SourceName; % Or something more specific


                case 'web'
                    error('MortalityTableFactory:NotImplemented', ...
                        'Web source not yet implemented');
                    
                otherwise
                    error('MortalityTableFactory:InvalidSourceType', ...
                        'Invalid source type: %s', sourceType);
            end
            
            % Set common properties
           
            table.SourceType = sourceType;
            table.LastUpdated = datetime('now');
            
            % Validate the table
            %TODO add error handling
            table.validate(); % should be using teh validate() method of the MortalityTable class
            table.validateTableData(table.MortalityRates); % should be validating using the factory table validation
        end
        
        function tableList = getAvailableTables(tableDir)
            % TODO Legacy Code canbe deleted once mortalitytable cache is good
            % Scans directory for available mortality tables
            % Inputs:
            %   tableDir - Directory to scan for tables
            % Returns:
            %   tableList - Structure array with table information
            
            if nargin < 1
                tableDir = pwd;
            end
            
            % Get all .mat files in directory
            files = dir(fullfile(tableDir, '*.mat'));
            
            tableList = struct('Name', {}, 'Path', {}, 'LastModified', {});
            
            for i = 1:length(files)
                file = files(i);
                [~, name] = fileparts(file.name);
                
                % Skip if not a mortality table file
                if ~contains(lower(name), 'mortality')
                    continue;
                end
                
                % Add to list
                tableList(end+1) = struct(...
                    'Name', name, ...
                    'Path', fullfile(file.folder, file.name), ...
                    'LastModified', datetime(file.datenum, 'ConvertFrom', 'datenum'));
            end
        end
        
        function validateTableData(data)
            % Validates mortality table data structure
            % Inputs:
            %   data - Structure containing mortality table data
            
            requiredFields = {'Male', 'Female'};
            requiredSubFields = {'Age', 'lx', 'qx'};
            if ~isstruct(data)
                 error('MortalityTableFactory:InvalidData', ...
                        'Input data must be a struct.');
            end

            
            % Check main structure
            for i = 1:length(requiredFields)
                if ~isfield(data, requiredFields{i})
                    error('MortalityTableFactory:InvalidData', ...
                        'Missing required field: %s', requiredFields{i});
                end
            end
            
            % Check sub-fields for each gender
            for i = 1:length(requiredFields)
                gender = requiredFields{i};
                if ~isstruct(data.(gender))
                     error('MortalityTableFactory:InvalidData', ...
                        'Field %s must be a struct.', gender);
                end

                for j = 1:length(requiredSubFields)
                    if ~isfield(data.(gender), requiredSubFields{j})
                        error('MortalityTableFactory:InvalidData', ...
                            'Missing required field: %s.%s', gender, requiredSubFields{j});
                    end
                end
            end
        end
    end
end 