classdef TableNames < uint32
   
    enumeration
       
        ALT_Table2020_22  (1)
        ALT_Table2015_17  (2)
        ALT_Table2010_12  (3)
        ALT_Table2005_07  (4)
        Mock_Table        (5)
        UK_a55_Ult    (6)
    end

    methods (Static) % Define a static method for the alias lookup
        function alias = getAlias(tableNames)
            switch tableNames
                case TableNames.ALT_Table2020_22
                    alias = 'ALT_Table2020_22';
                case TableNames.ALT_Table2015_17
                    alias = 'ALT Table2015_17';
                case TableNames.ALT_Table2010_12
                    alias = 'ALT Table 2010-12';
                case TableNames.ALT_Table2005_07
                    alias = 'ALT_Table2005_07';
                case TableNames.Mock_Table
                    alias = 'Mock Table';
                case TableNames.UK_a55_Ult
                    alias = 'UK-annuity-tables-a(55)';
                otherwise
                    error('Unsupported Table Name');
            end
        end
        function tableName = fromAlias(alias)
            switch alias
                case 'ALT_Table2020_22'
                    tableName = TableNames.ALT_Table2020_22;
                case 'ALT Table2015_17'
                    tableName = TableNames.ALT_Table2015_17;
                case 'ALT Table 2010-12'
                    tableName = TableNames.ALT_Table2010_12;
                case 'ALT_Table2005_07'
                    tableName = TableNames.ALT_Table2005_07;
                case 'Mock Table'
                    tableName = TableNames.Mock_Table;
                 case 'UK-annuity-tables-a(55)'
                    tableName = TableNames.UK_a55_Ult;
                otherwise
                    error('Unsupported Table Name');
            end
        end
    end
end

