classdef AssetPortfolioFactory < PortfolioFactory

    % Reasons for Making createAssetPortfolio Static:
    %
    %       1. Factory Pattern: The Factory pattern is designed to encapsulate the creation of objects. In this pattern, a factory class (like AssetPortfolioFactory) is responsible for creating objects of a certain type (like AssetPortfolio). Since the factory itself is not an AssetPortfolio, it doesn't have an obj representing itself. Therefore, the methods used for object creation within the factory are naturally static.
    %
    %       2. No Dependency on Object State: The createAssetPortfolio method only needs the initialValue and strategy parameters to create a new AssetPortfolio object. It doesn't rely on any existing AssetPortfolio object's data or state.
    %
    %       3. Clearer Usage: By making the method static, the syntax for calling it becomes more explicit: AssetPortfolioFactory.createAssetPortfolio(...). This clearly indicates that you're calling a factory method to create a new object, rather than a method on an existing object.
    % Have elected to have a portfolio factory and an assetportfolio factory
    % because i think at some point i might want to have a compositeportfolio
    % or entity portfolio which would contain assetportfolios or composite
    % portfolios

    methods (Static)
        function portfolio = createPortfolio(TradingStrategyType, StartDate, varargin)
            %CREATEASSETPORTFOLIO Creates an AssetPortfolio object.
            %   portfolio = CREATEASSETPORTFOLIO(tradingStrategyType, startDate, varargin)
            %   creates an AssetPortfolio with the specified trading strategy type and start date.
            %
            %   Optional name-value pairs:
            %       'portfolioCountry' - Country code (e.g., 'AU'). Default: 'AU'
            %       'initialValue' - Initial portfolio value. Default: 1e6
            %       'benchmarkReturns' - Timetable of benchmark returns. Default: empty timetable
            %       'cashflowsInputData' - Struct with cashflow data. Default: empty struct
            %       'targetPortfolioWeights' - Target portfolio weights for the strategy. Default: []
            %       'marketIndexAcctParameters' - Parameters for market index account. Default: []

            % Define input parser
            p = inputParser;
              % Validation function for strategyTypes
            validStrategyTypes = enumeration('TradingStrategyType'); % Get all enum values
            isValidStrategyType = @(x) iscell(x) && all(cellfun(@(s) ismember(s, validStrategyTypes), x)); 
           

            addRequired(p, 'TradingStrategyType', isValidStrategyType);
            addRequired(p, 'StartDate', @isdatetime);
            % addParameter(p, 'portfolioCountry', "AU", ...
            %     @(x) all(~validateattributes(x, {'string'}, ...
            %                            {'mustBeMember', ["AU","US","UK","NZ","GB"], ...
            %                             'scalartext', ...  % Ensures it's a scalar char vector
            %                             'maxLength', 3})));  % Max length of 3
            addParameter(p, 'PortfolioCountry', "AU", ...
                @(x) utilities.ValidationUtils.validateCountry(x));
            addParameter(p, 'InitialValue', 1e6, @isnumeric);
            addParameter(p, 'BenchmarkReturns', timetable.empty, @istimetable);
            addParameter(p, 'CashflowsInputData', struct.empty, @(x) isstruct(x) || isempty(x));
            addParameter(p, 'TargetPortfolioWeights', PortfolioWeights(), @(x) isa(x, 'PortfolioWeights'));
            addParameter(p, 'MarketIndexAcctParameters', struct.empty, @isstruct);
            addParameter(p, 'AllowablePortfolioHoldings', {}, @(x) iscell(x));
            parse(p, TradingStrategyType, StartDate, varargin{:});

            % Validate the 'cashflowsInputData' struct
            cashflows = p.Results.CashflowsInputData;
            
            if ~isempty(cashflows)
                requiredFields = {'DefaultCashFlow', 'Contribution', 'ContributionFrequency','GuaranteedPayment','GuaranteedPaymentFrequency', 'PortfolioPayment','PortfolioPaymentFrequency','InflationRateAssumption'};
                missingFields = setdiff(requiredFields, fieldnames(cashflows));
                if ~isempty(missingFields)
                    error('cashflowsInputData struct is missing the following fields: %s', strjoin(missingFields, ', '));
                end

                if ~ismember(cashflows.PortfolioPaymentFrequency, enumeration('utilities.FrequencyType'))
                    error('cashflowsInputData.PortfolioPaymentFrequency must be a valid FrequencyType enum value.');
                end
                if ~ismember(cashflows.GuaranteedPaymentFrequency, enumeration('utilities.FrequencyType'))
                    error('cashflowsInputData.GuaranteedPaymentFrequency must be a valid FrequencyType enum value.');
                end
            end

            %validate the 'allowablePortfolioHoldings' table

            % Create the AssetPortfolio object
            portfolio = AssetPortfolio(TradingStrategyType, StartDate, ...
                'portfolioCountry', p.Results.PortfolioCountry, ...
                'initialValue', p.Results.InitialValue, ...
                'benchmarkReturns', p.Results.BenchmarkReturns, ...
                'cashflowsInputData', p.Results.CashflowsInputData, ...
                'targetPortfolioWeights', p.Results.TargetPortfolioWeights, ...
                'marketIndexAcctParameters', p.Results.MarketIndexAcctParameters, ...
                'allowablePortfolioHoldings',p.Results.AllowablePortfolioHoldings);
    
        end
    end
end