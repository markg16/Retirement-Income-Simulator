% NEW FILE: MortalityTableFactory.m
% Factory class for creating and managing mortality tables
classdef MortalityTableFactory
    methods (Static)
        function table = createTable(sourceType, sourcePath, tableName)
            % Creates a new mortality table instance based on source type
            % Inputs:
            %   sourceType - 'File' or 'Web'
            %   sourcePath - Path to file or URL
            %   tableName - Name of the mortality table
            % Returns:
            %   table - Instance of BasicMortalityTable
            
            switch lower(sourceType)
                case 'file'
                    if ~isfile(sourcePath)
                        error('MortalityTableFactory:FileNotFound', ...
                            'File not found: %s', sourcePath);
                    end
                    
                    % Load data from file
                    data = load(sourcePath);
                    table = BasicMortalityTable(sourcePath, data.mortalityRates);
                    
                case 'web'
                    error('MortalityTableFactory:NotImplemented', ...
                        'Web source not yet implemented');
                    
                otherwise
                    error('MortalityTableFactory:InvalidSourceType', ...
                        'Invalid source type: %s', sourceType);
            end
            
            % Set common properties
            table.TableName = tableName;
            table.SourceType = sourceType;
            table.SourcePath = sourcePath;
            table.LastUpdated = datetime('now');
            
            % Validate the table
            table.validate();
        end
        
        function tableList = getAvailableTables(tableDir)
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
            
            requiredFields = {'M', 'F'};
            requiredSubFields = {'Age', 'lx', 'qx'};
            
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