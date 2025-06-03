function outPath = createDirectory(currentDirectory,outputFolderName)
%Creates an output folder relative to the current working directory

%   takes as input the folder name and makes a directory relatvie to
%   current working directory


outPath = fullfile(currentDirectory, outputFolderName);
  
if exist(outPath, 'dir') == 7
        warning('Directory "%s" already exists. Proceeding with existing directory.', outPath); 
    else
        try
            mkdir(outPath);
        catch ME
            if strcmp(ME.identifier, 'MATLAB:MKDIR:Permission')
                error('Error creating output directory "%s": Insufficient permissions. Please adjust permissions and try again.', outPath);
            else
                rethrow(ME); % Re-throw other types of errors 
            end  % end try catch
        end %end if
end