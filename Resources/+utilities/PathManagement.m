classdef PathManagement
    %PATHMANAGEMENT Summary of this class goes here
    %   Detailed explanation goes here
    
    
    
    methods (Static)
        function filteredPath= addPaths(rootPath,excludeSubFolderText)
            %ADDPATHS Adds folders to the MATLAB search path, excluding 
            % those containing 'archive'.

            % Generate the full path including all subfolders
            subFolders = genpath(rootPath);

            % Split the path string into a cell array of individual folders
            folderList = strsplit(subFolders, pathsep);

            % Filter out folders containing 'archive' (case-insensitive)
            filteredFolders = folderList(~contains(folderList, excludeSubFolderText, 'IgnoreCase', true));

            % Join the filtered folders back into a single path string
            filteredPath = strjoin(filteredFolders, pathsep);

            % Add the filtered path to the MATLAB search path
            addpath(filteredPath); 
        end
    end
end

