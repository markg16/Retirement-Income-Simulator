function averageImprovementFactors = readImprovementFactors(improvementFactorsFile)
%UNTITLED Summary of this function goes here
%   Detailed explanation goes here
try 
      % Read improvement Factors fileLifeTables
    improvementFactorsData = readmatrix(improvementFactorsFile, 'Sheet', 'ALT Improvement Factors', 'FileType', 'spreadsheet'); 

    % Check for sufficient number of columns
    if size(improvementFactorsData, 2) < 4
        error('ImprovementFactors file has insufficient columns');
    end %end if    

  catch ME

    %handle errors gracefully
    disp('Error reading improvement factors: ');
    rethrow(ME);

  end % try catch block

    % Extract relevant columns
    ages = improvementFactorsData(:,1);
    maleFactors = improvementFactorsData(:,2);
    femaleFactors = improvementFactorsData(:,3);


  binEdges = [0 50 65 85 Inf]; % Include 'Inf' for the last "> 85" group
  [ageCounts, binEdges,binIdx] = histcounts(ages, binEdges);
  averageImprovementFactors = zeros(length(binEdges) - 1, 3); % Store male and female factors

  for i = 1:length(binEdges) - 1
      inBin = binIdx == i;
      averageImprovementFactors(i, 1) = binEdges(i);
      averageImprovementFactors(i, 2) = mean(maleFactors(inBin));
      averageImprovementFactors(i, 3) = mean(femaleFactors(inBin));
  end
end