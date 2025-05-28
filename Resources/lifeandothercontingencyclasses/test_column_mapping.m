function test_column_mapping()
    % Test script to verify column mapping works correctly
    fprintf('Testing column mapping...\n');
    
    % Get the mapping
    map = column_mapping();
    
    % Use the TableNames enum
    tables = [TableNames.ALT_Table2020_22, TableNames.ALT_Table2015_17, TableNames.ALT_Table2010_12, TableNames.ALT_Table2005_07];
    for i = 1:length(tables)
        key = char(tables(i));
        fprintf('\nTesting table %s:\n', key);
        if isfield(map, key)
            col = map.(key);
            fprintf('  Age column: %d\n', col.Age);
            fprintf('  qx column: %d\n', col.qx);
            fprintf('  lx column: %d\n', col.lx);
        else
            fprintf('  ERROR: No mapping found for table %s\n', key);
        end
    end
    
    fprintf('\nColumn mapping test completed.\n');
end 