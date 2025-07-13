% File: DataSourceMapping.m
classdef DataSourceMapping
    %DATASOURCEMAPPING Provides a static, validated mapping from a TableName 
    %   to its responsible MortalityDataSourceName.

    methods (Static)
        function map = getTableToSourceMap()
            % Returns a containers.Map linking each TableName enum member
            % to the corresponding MortalityDataSourceName enum member.
            % This method includes validation to ensure all enums are mapped.
            
            % --- Define the mapping here ---
            keys = [ ... 
                TableNames.ALT_Table2020_22; ...
                TableNames.ALT_Table2015_17; ...
                TableNames.ALT_Table2010_12; ...
                TableNames.ALT_Table2005_07; ...
                TableNames.Mock_Table; ...
                TableNames.UK_a55_Ult ...
            ];
        
            values = [ ...
                MortalityDataSourceNames.AustralianGovernmentActuarySource; ...
                MortalityDataSourceNames.AustralianGovernmentActuarySource; ...
                MortalityDataSourceNames.AustralianGovernmentActuarySource; ...
                MortalityDataSourceNames.AustralianGovernmentActuarySource; ...
                MortalityDataSourceNames.MockMortalityDataSource; ...
                MortalityDataSourceNames.MortalityTableForTestingAnnuityValuesSource ...
            ];
            
            % Create a dictionary. It natively supports enum keys.
            map = dictionary(keys, values);
            
            % --- START of Robustness Check ---
            
            % 1. Get all possible TableName enum members that exist in the code.
            allDefinedTables = enumeration('TableNames');
            
            % 2. Get all TableName members that we have just mapped.
            allMappedTables = map.keys;
            
            % 3. Find the difference.
            %    setdiff requires both inputs to be the same type.
            %    We convert the cell array of keys back to an enum array.
            % mappedEnumArray = [allMappedTables{:}];
            unmappedTables = setdiff(allDefinedTables, allMappedTables);
            
            % 4. If any tables are unmapped, throw a specific error.
            if ~isempty(unmappedTables)
                % Create a comma-separated list of the missing table names.
                missingNames = arrayfun(@char, unmappedTables, 'UniformOutput', false);
                missingListStr = strjoin(missingNames, ', ');
                
                error('DataSourceMapping:UnmappedTables', ...
                    ['The following tables are defined in TableNames.m but have no mapping in DataSourceMapping.m. Please update the mapping. Missing: %s'], ...
                    missingListStr);
            end
            % --- END of Robustness Check ---
        end
    end
end
