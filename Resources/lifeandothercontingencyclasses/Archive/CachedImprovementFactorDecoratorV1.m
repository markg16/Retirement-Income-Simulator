classdef CachedImprovementFactorDecorator < MortalityTable
    
    % ... (baseTable, factor, cache properties as before)
    properties
        BaseTable
        Factor
        Cache
        CachedRatesMap
        CacheFilePath
        ImprovementFactorStrategy % Reference to the strategy used to calculate improvement factors
        ImprovementFactors % Property to hold improvement factors
    end

    methods
        function obj = CachedImprovementFactorDecorator(baseTable, factor, improvementFactorsFile, improvementFactorStrategy)
            % ... (constructor as before)
            obj.CacheFilePath = fullfile('G:', 'My Drive', 'Kaparra Software', 'Rates Analysis', 'LifeTables', 'decorator.mat');
            %obj.CacheFilePath = 'G:\My Drive\Kaparra Software\Rates Analysis\LifeTables\decorator';  % Construct filename based on baseTable, factor

            if isfile(obj.CacheFilePath)
                % obj.Cache = load(obj.CacheFilePath).cache;
                obj.CachedRatesMap =load(obj.CacheFilePath).cachedRatesMap;
            else
                % obj.Cache = containers.Map('KeyType', 'int32', 'ValueType', 'double');
                % Initialize cache as a Map with string keys
                obj.CachedRatesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');  % 'any' allows storing objects
            end


            obj.ImprovementFactorStrategy = improvementFactorStrategy;
            rawImprovementFactors = utilities.LifeTableUtilities.loadImprovementFactors(improvementFactorsFile);
            obj.ImprovementFactors = obj.ImprovementFactorStrategy.calculateAverageFactors(rawImprovementFactors);


            obj.BaseTable = baseTable;
            obj.Factor = factor;
            obj.CacheFilePath = fullfile('G:', 'My Drive', 'Kaparra Software', 'Rates Analysis', 'LifeTables', 'decorator');

        end

        function rate = getRate(obj, gender,age,startAge)
            
           
                baseRate = obj.BaseTable.getRate(gender,age);
                duration = max(0, age - startAge);   % Calculate duration since startAge
                improvementFactor = obj.getImprovementFactor(gender,age);
                rate = baseRate * (1 - improvementFactor)^duration; % Apply improvement based on duration
                           
        end

        function newlx= getImprovedLx(obj,gender,age,startAge)
            ages= obj.BaseTable.MortalityRates.(gender).Age(:);
            
            startAgeIndex = find(ages == startAge);
            
            endAgeIndex = find(ages == age);
           
            for idx = startAgeIndex:endAgeIndex
                if idx == startAgeIndex
                    newlx =  obj.BaseTable.getLx(gender,startAge);
                else
                    localAge = ages(idx);
                    qx= obj.getRate(gender,localAge,startAge);
                    newlx = newlx * (1- qx);
                end

            end

        end
        
        function factor = getImprovementFactor(obj, localGender,age)
            ages = obj.ImprovementFactors.Age;
            factors = obj.ImprovementFactors.(localGender); % Get factors for the specific gender

            % Find the bin index where the age falls
            binIndex = find(ages <= age, 1, 'last');

            if isempty(binIndex)
                factor = 0; % No improvement factor found for this age (should not happen if your table starts at age 0)
            else
                factor = factors(binIndex) / 100; % Get factor for the corresponding bin and convert to percentage
            end
        end
       
        function newTable = createImprovedTable(obj, startAge)
            
            genders = fieldnames(obj.BaseTable.MortalityRates);          
            % Create unique key based on age, startAge, and strategy class name
            strategyClassName = class(obj.ImprovementFactorStrategy);
            cacheKey = sprintf('%d_%s',startAge, strategyClassName);
            
            if obj.CachedRatesMap.isKey(cacheKey)
                newTable = obj.CachedRatesMap(cacheKey);
            else

                for idxGender = 1: length(genders)
                    gender= genders{idxGender};
                    ages = obj.BaseTable.MortalityRates.(gender).Age(:);

                    % Find the index of the startAge in the table
                    startIndex = find(ages == startAge);
                    endIndex = find(ages == ages(end));
                   
                    if isempty(startIndex)
                        error('Start age not found in the base table for this gender.');
                    end
                    
                    % initialise improved mortality table staring at StartAge
                    numAges = endIndex-startIndex +1;
                    maxAges = startAge + (endIndex-startIndex);  % Maximum age you'll be dealing with
                    newMortalityRates.(gender) = struct('Age', (startAge:maxAges)', 'lx',  zeros(numAges, 1), 'qx',  zeros(numAges, 1));
                    
                    %get improved qx and lx
                    for idx = 1:(endIndex-startIndex+1)
                        age = ages(idx+startIndex-1);
                        newMortalityRates.(gender).qx(idx) = obj.getRate(gender,age, startAge);% Pass startAge
                        newMortalityRates.(gender).lx(idx) = obj.getImprovedLx(gender,age, startAge);
                        
                    end
                end
                newTable = BasicMortalityTable(obj.BaseTable.TableFilePath, newMortalityRates);
                obj.CachedRatesMap(cacheKey) = newTable;  % Cache for future use
            end
            
        end

        function saveCache(obj)
            cachedRatesMap = obj.CachedRatesMap; % Extract cache for saving
            save(obj.CacheFilePath, 'cachedRatesMap');
        end
    end
end