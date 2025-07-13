% File: MortalityTableForTestingAnnuityValuesSource.m
classdef MortalityTableForTestingAnnuityValuesSource < MortalityDataSource
    %MortalityTableForTestingAnnuityValues A data source that reads a local Excel
    %   file containing mortality and annuity values for testing purposes.

    properties (SetAccess = private)
        % The full path to the directory containing the test table files.
        TestTableDirectory char
    end

    methods
        function obj = MortalityTableForTestingAnnuityValuesSource(varargin)
            % Constructor for the test data source.
            % 1. Pre-scan varargin for arguments intended for the parent constructor.
            %    In this case, we are only looking for 'cacheManagerInstance'.
            parentArgs = {};
            childVarargin = varargin; % Make a copy to pass to the child's parser

            for i = 1:2:length(varargin)
                if strcmpi(varargin{i}, 'cacheManagerInstance')
                    % Found the argument for the parent.
                    parentArgs = {'cacheManagerInstance', varargin{i+1}};
                    % Remove it from the list that the child will parse.
                    childVarargin([i, i+1]) = [];
                    break; % Assume it only appears once
                end
            end

            % 2. Call the parent constructor FIRST, passing any found arguments.
            %    This correctly initializes the CacheManager.
            obj@MortalityDataSource(parentArgs{:});

            % 3. Now, configure the child-specific properties using its own parser.
                        
            p = inputParser;
            defaultDirectory = fullfile('G:', 'My Drive', 'Kaparra Software', 'Rates Analysis', 'LifeTables', 'Tables For Testing');
            addParameter(p, 'TestTableDirectory', defaultDirectory, @ischar);
            addParameter(p, 'OverwriteExisting', false, @islogical);

            parse(p, childVarargin{:});
            %obj.OverwriteExisting = p.Results.OverwriteExisting;
                                 
            obj.TestTableDirectory = p.Results.TestTableDirectory;
            if ~isfolder(obj.TestTableDirectory)
                error('MortalityTableForTestingAnnuityValues:DirectoryNotFound', 'The specified test table directory does not exist: %s', obj.TestTableDirectory);
            end
            
            % Set descriptive properties for this source.
            obj.SourceName = 'Local Annuity Value Test Tables';
            obj.SourceURL = ['file:///' obj.TestTableDirectory];
        end
    end
    
    methods (Access = protected)
        function rawData = fetchRawData(obj, tableIdentifier)
            % For this local file source, "fetching" means finding the file path.
            tableKey = char(TableNames.getAlias(tableIdentifier));
            fileName = char([tableKey '.xlsx']); % Assumes identifier is a tablename enum
            filePath = fullfile(obj.TestTableDirectory, fileName);
             % Get table key from enum
            
            
            % Initialize files array
            files = {};

            % Verify the  file is a valid Excel file
            try
                [~, sheets] = xlsfinfo(filePath);
                if isempty(sheets) || ischar(sheets) && contains(sheets, 'Unreadable Excel file')
                    obj.log('Warning: Downloaded file is not a valid Excel file: %s', filePath);
                    delete(filePath);  % Clean up invalid file
                    % continue;
                end
            catch e
                obj.log('Warning: Failed to validate Excel file %s: %s', filePath, e.message);
                if exist(filePath, 'file')
                    delete(filePath);  % Clean up invalid file
                end
                %continue;
            end

            % Create file data structure
            fileData = struct('filename', filePath, ...
                'data', [], ...
                'type', [], ...
                'tableEnum', tableIdentifier); % chaneg to pass in an enum for identifier

            % % Add to files array
             files{end+1} = fileData;

                            
            rawData = struct('files', {files});
            obj.log('Found local test table file: %s', filePath);
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
            
            
           
            % Track if we've found both male and female data
            foundMale = false;
            foundFemale = false;

            % Process matching files
            for i = 1:length(matchingFiles)
                fileData = matchingFiles{i};

                %TODO refactor column mapping in AA and this source to bring
                %inrelevant map based on MortalityIdentifier

                mapping = obj.getColumnMapping(fileData.tableEnum);
               
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
                        startCell = 'A3'; 

                        % Read male data if not already found
                        if ~foundMale
                            maleData = readmatrix(fileData.filename, 'Sheet', maleSheet, 'FileType', 'spreadsheet','Range',startCell);
                            if size(maleData, 2) < max([mapping.Age, mapping.lx, mapping.qx,mapping.ax])
                                obj.log('Warning: Male data has insufficient columns in file: %s', fileData.filename);
                                % continue;
                            end
                            parsedData.Male = struct('Age', maleData(:,mapping.Age), ...
                                'lx', maleData(:,mapping.lx), ...
                                'qx', maleData(:,mapping.qx) ,...
                                'ax', maleData(:,mapping.ax));
                            foundMale = true;
                        end

                        % Read female data if not already found
                        if ~foundFemale
                            femaleData = readmatrix(fileData.filename, 'Sheet', femaleSheet, 'FileType', 'spreadsheet','Range',startCell);
                            if size(femaleData, 2) < max([mapping.Age, mapping.lx, mapping.qx,mapping.ax])
                                obj.log('Warning: Female data has insufficient columns in file: %s', fileData.filename);
                                % continue;
                            end
                            parsedData.Female = struct('Age', femaleData(:,mapping.Age), ...
                                'lx', femaleData(:,mapping.lx) ,...
                                'qx', femaleData(:,mapping.qx),...
                                'ax', femaleData(:,mapping.ax));
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
                        axData = cell2mat(raw(:, mapping.ax));

                        % Create data structure
                        data = struct('Age', ageData, 'lx', lxData, 'qx', qxData, 'ax', axData);

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
        function columnMap = getColumnMapping(obj,tableIdentifier)
            % Provides a mapping from expected Excel header names to the desired
            % struct field names. This makes the code robust to changes in
            % header naming (e.g., 'qx' vs 'MortalityRate').
            % In this case, the names are the same.
                        
            map = column_mapping();


            %columnMap = map.(char(TableNames.fromAlias(tableIdentifier)));
            columnMap = map.(char(tableIdentifier));
        end
    end
end

