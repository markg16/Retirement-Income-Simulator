classdef LifeAndOtherContingencies
    %UNTITLED2 Summary of this class goes here
    %   Detailed explanation goes here

    properties
        MortalityTable
    end

    methods
        function obj = createMortalitTableCollection(baseLifeTableFolder)
            %UNTITLED2 Construct an instance of this class
            %   Detailed explanation goes here
            obj.MortalityTable = loadBaseMortalityTable(obj,baseLifeTableFolder) ;
        end

        

        function obj = readMortalityImprovementFactors(improvementFactorsFile)
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
            improvementFactors = array2table(averageImprovementFactors,'VariableNames',{'Age', 'M', 'F'});
            obj.MortalityTable.ImprovementFactors = improvementFactors;
        end
        
        function improvedLifeTable = applyMortalityImprovement(obj,improvementFactorsFile)
        % There would need to be a life table for every posible netry table
        % to cater for possible annuitants. I have elected to generate
        % improved mortality and survivorship on the fly for each
        % annuitant. THis should be less memory and compute intense for
        % small numbers of annuitants.
        % this method could sit in the Annuity class and be invoked when an
        % annuity object is created. I have set this up assuming the
        % reference to the improved life table is stored in the annuitants
        % properties

            %test for improvement factors property exists and is non empty,
            %ifnot populated then use
            %readMortalityImprovementFactors(improvementFactorsFile) to
            %initialsie



            baseLifeTable = obj.MortalityTable;

            improvementFactors =   obj.MortalityTable.ImprovementFactors;
            
            improvedLifeTable = baseLifeTable;

            %check what fiedls are in the improvement factors data expect
            %[age,M,F]'
            genders = ['M','F'];

            for i = 1:2

                % Load Mortality Data from lifeTable (assuming it's a structured array)
                gender = genders(i);
                qx = baseLifeTable.(gender).qx;  % Get qx for the specified gender
                lx = baseLifeTable.(gender).lx;  % Get lx for the specified gender
                fx = [improvementFactors.Age,improvementFactors.(gender)];

                % Adjust the mortality table based on improvement factors
                [revisedlx,revisedqx] = utilities.LifeTableUtilities.adjustMortalityTable(qx,lx, fx, entryAge);


                improvedLifeTable.(gender).qx = revisedqx;
                improvedLifeTable.(gender).lx = revisedlx;
            end
     


        end

        function [survivalProbabilities =  getSurvivalProbabilities(obj,annuitant,valuationDate)

            
            
            
            survivalProbabilities =obj.MortalityTable;  
            
            % TODO add code to extract relevant lx assume that we have a mortality table
            % with appropriate improvement factors allready and just need
            % to extract survival probabilities

        end
    end
end