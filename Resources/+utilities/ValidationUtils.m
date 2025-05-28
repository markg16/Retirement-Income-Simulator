classdef ValidationUtils
    %UNTITLED8 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods(Static)
        function mustBeValidFrequency(freq)
            validFrequencies = enumeration('utilities.FrequencyType');
            if ~ismember(freq, string(validFrequencies))
                error('Invalid frequency. Choose from: %s', strjoin(string(validFrequencies), ', '));
            end
        end
        function isValid = validateWithParser(validatorFcn, x, p)
            % .p must be an inputparser object.
            % .. (documentation) ...
            isValid = validatorFcn(x, p);
        end

        function isValid = validateAnnuityType(x,p)
            try
                annuityType = p.Results.AnnuityType;
                validAnnuityType = enumeration('AnnuityType');
               
                if ismember(annuityType, validAnnuityType)
                    isValid = true;
                else
                    error('Invalid annuity type. Choose from: %s', validAnnuityType);
                end
                % Conversion successful
            catch
                isValid = false; % Conversion failed
            end



        end

        function isValid = validateFrequency(x, p)
            try
                frequencyValue = p.Results.Frequency;
                validFrequencies = enumeration('utilities.FrequencyType');
                if ismember(frequencyValue, validFrequencies)
                    isValid = true;
                else
                    error('Invalid frequency. Choose from: %s', validFrequencies);
                end
                % Conversion successful
            catch
                isValid = false; % Conversion failed
            end
        end
        
        function isValid = validateContributionFrequency(x, p)
            try
                frequencyValue = p.Results.ContributionFrequency;
                validFrequencies = enumeration('utilities.FrequencyType');
                if ismember(frequencyValue, validFrequencies)
                    isValid = true;
                else
                    error('Invalid frequency. Choose from: %s', validFrequencies);
                end
                % Conversion successful
            catch
                isValid = false; % Conversion failed
            end
        end
        function isValid = validateCountry(x)
            isValid = isstring(x) && ...
                      ismember(x, ["AU","US","UK","NZ","GB"]) && ...
                      strlength(x) <= 3;
        end
        function isValid = validateTableVariableNames(tbl, allowedNames)
            %VALIDATETABLEVARIABLENAMES Checks if table variable names are in a cell array.
            %   isValid = VALIDATEETABLEVARIABLENAMES(tbl, allowedNames) checks if all the
            %   variable names (column headers) in the table 'tbl' are contained within
            %   the cell array of allowed names 'allowedNames'.

            isValid = all(ismember(tbl.Properties.VariableNames, allowedNames));
        end
        function cacheFile = checkCachedFolderExists(cacheFolder,cacheFileName)
            
            % 1. Check if cached rate curves or folder exist and return
            % cacheFile (fullpathname)
            if ~isfolder(cacheFolder)
                mkdir(cacheFolder);
            end

            cacheFile = fullfile(cacheFolder, cacheFileName);

            
        end
        
    end
end