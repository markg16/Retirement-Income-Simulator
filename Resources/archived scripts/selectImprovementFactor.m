function improvementFactor = selectImprovementFactor(age,lookupTable)
    
    numBins = size(lookupTable, 1);

    if age>= lookupTable(numBins,1)
        improvementFactor = lookupTable(numBins, 2);
    else
        for i = 1:numBins-1 
    
            if age >= lookupTable(i, 1) && age < lookupTable(i + 1, 1) 
                improvementFactor = -lookupTable(i, 2); % Select male/female factors from 2/3 columns
                break; % improve perfromance by breaking out if match occurs
            end
          
        end % end for
    end % end if else

end