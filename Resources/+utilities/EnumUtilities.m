classdef EnumUtilities
    %ENUMUTILITY Utility class for working with enumerations

    methods (Static)
        function enumString = getString(enumValue)
            %GETSTRING Returns the string representation of an enumeration value.
            enumString = char(enumValue);
        end

        function enumStrings = getStringArray(enumClass)
            %GETSTRINGARRAY Returns a string array of all members in an enumeration class.

            enumMembers = enumeration(enumClass);
            enumStrings = cell(1, numel(enumMembers));
            for i = 1:numel(enumMembers)
                enumStrings{i} = char(enumMembers(i));
            end
        end
    end
end