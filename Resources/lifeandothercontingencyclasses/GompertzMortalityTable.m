classdef GompertzMortalityTable < MortalityTable
    %GOMPERTZMORTALITYTABLE A concrete mortality table based on Gompertz's Law.
    %   Generates mortality rates qx and lx based on the Gompertz parameters B and c.
    %   The force of mortality mu_x = B * c^x.

    % --- Properties that fulfill the abstract requirements from MortalityTable ---
    properties
        TableName
        SourceType
        SourcePath
        LastUpdated
    end

    % --- Property to hold the actual mortality data ---
    properties (SetAccess = private)
        MortalityRates % Struct with .Male and .Female, each having .Age, .lx, .qx
    end
    
    properties (Access = private)
        GompertzB % The B parameter (modal value)
        GompertzC % The c parameter (dispersion)
    end

    methods
        function obj = GompertzMortalityTable(B, c, maxAge)
            % Constructor for a Gompertz mortality table.
            % Inputs:
            %   B: The Gompertz B parameter (e.g., 0.0001)
            %   c: The Gompertz c parameter (e.g., 1.1)
            %   maxAge: The maximum age for the table (e.g., 120)

            if nargin < 3, maxAge = 120; end

            obj@MortalityTable(); % Call superclass constructor

            obj.GompertzB = B;
            obj.GompertzC = c;
            
            % Set descriptive properties
            obj.TableName = sprintf('Gompertz(B=%.5f, c=%.3f)', B, c);
            obj.SourceType = 'Formula';
            obj.SourcePath = 'Gompertz Law';
            obj.LastUpdated = datetime('now');

            % Pre-calculate the entire table upon construction for efficiency
            obj.MortalityRates = obj.generateGompertzRates(maxAge);
            
            % Validate the generated structure
            MortalityTableFactory.validateTableData(obj.MortalityRates);
        end

        % --- Implementation of abstract methods from MortalityTable ---
        function rate = getRate(obj, gender, age)
            % Retrieves the pre-calculated Gompertz mortality rate (qx).
            % For this model, we assume rates are the same for Male and Female.
            if ~isfield(obj.MortalityRates, gender)
                error('GompertzMortalityTable:InvalidGender', 'Gender "%s" not recognized.', gender);
            end
            
            ageIndex = find(obj.MortalityRates.(gender).Age == age, 1);
            if isempty(ageIndex)
                error('GompertzMortalityTable:AgeNotFound', 'Age %d not found in this Gompertz table.', age);
            end
            rate = obj.MortalityRates.(gender).qx(ageIndex);
        end

        function lxVal = getLx(obj, gender, age)
            % Retrieves the pre-calculated Gompertz number of lives (lx).
            if ~isfield(obj.MortalityRates, gender)
                error('GompertzMortalityTable:InvalidGender', 'Gender "%s" not recognized.', gender);
            end

            ageIndex = find(obj.MortalityRates.(gender).Age == age, 1);
            if isempty(ageIndex)
                error('GompertzMortalityTable:AgeNotFound', 'Age %d not found in this Gompertz table.', age);
            end
            lxVal = obj.MortalityRates.(gender).lx(ageIndex);
        end

        function survivorshipProbabilities = getSurvivorshipProbabilities(obj, gender, currentAge, finalAge)
            % Delegates the calculation to the static utility function.
            survivorshipProbabilities = utilities.LifeTableUtilities.getSurvivorship(obj, gender, currentAge, finalAge);
        end
    end
    
    methods (Access = private)
        function ratesStruct = generateGompertzRates(obj, maxAge)
            % Generates the full qx and lx table based on the Gompertz parameters.
            ages = (0:maxAge)';
            
            % Formula for t_p_x under Gompertz: exp( (B/log(c)) * c^x * (1 - c^t) )
            % From which we can derive qx = 1 - 1_p_x
            
            B = obj.GompertzB;
            c = obj.GompertzC;
            log_c = log(c);
            
            % Calculate 1-year survival probabilities (p_x) for all ages
            p_x = exp( (B/log_c) * (c.^ages) * (1 - c) );
            
            % Calculate q_x = 1 - p_x
            q_x = 1 - p_x;
            
            % Calculate lx table from qx, starting with a radix of 100,000
            l_x = zeros(size(ages));
            l_x(1) = 100000; % Radix at age 0
            for i = 2:length(ages)
                l_x(i) = l_x(i-1) * (1 - q_x(i-1));
            end
            
            genderRates = struct('Age', ages, 'lx', l_x, 'qx', q_x);
            
            % Since Gompertz is gender-neutral here, apply the same rates to both
            ratesStruct.Male = genderRates;
            ratesStruct.Female = genderRates;
            ratesStruct.TableName = obj.TableName; % Add metadata
        end
    end
end