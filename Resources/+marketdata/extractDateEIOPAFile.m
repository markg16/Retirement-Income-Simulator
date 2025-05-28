function outputFileDate= extractDateEIOPAFile(inputFileName)
%This function reads the EIOPA file name and extracts the date of the file. 
% Assumes that date format is yyyyMMdd and the first number in the name is the date. 

    % Find the index of the first digit
    startIndex = find(isstrprop(inputFileName, 'digit'), 1);  
    endIndex = find(~isstrprop(inputFileName(startIndex:end), 'digit'), 1) + startIndex - 2; 
    
    %extract the date string
    dateString = inputFileName(startIndex:endIndex);  
    
    %convert to DateTime type
    dateFormat = 'yyyyMMdd';  % Or adjust this if needed upon inspection
    outputFileDate = datetime(dateString, 'InputFormat', dateFormat);


end