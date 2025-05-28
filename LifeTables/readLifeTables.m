function lifeTable = readLifeTables(maleFile, femaleFile)

  
      % Variable Names
      ageColumn = 1;
      lxColumn = 2;
      qxColumn = 5;  


    try 
          % Read Male Life Table 
        maleData = readmatrix(maleFile, 'Sheet', 'Males', 'FileType', 'spreadsheet'); 
        % Check for sufficient number of columns
        if size(maleData, 2) < qxColumn
            error('Male life table file has insufficient columns');
        end %end if 
    
        lifeTable.M.Age = maleData(:, ageColumn);
        lifeTable.M.lx = maleData(:, lxColumn);
        lifeTable.M.qx = maleData(:, qxColumn);
    
        % Read Female Life Table
        femaleData = readmatrix(femaleFile, 'Sheet', 'Females', 'FileType', 'spreadsheet');  
        % Check for sufficient number of columns
        if size(femaleData, 2) < qxColumn
            error('Female life table file has insufficient columns');
        end %end if
    
        lifeTable.F.Age = femaleData(:, ageColumn);
        lifeTable.F.lx = femaleData(:, lxColumn);
        lifeTable.F.qx = femaleData(:, qxColumn);
    
    catch ME
        %handle errors gracefully
        disp('Error reading life tables: ');
        rethrow(ME);
    end % try catch block
end