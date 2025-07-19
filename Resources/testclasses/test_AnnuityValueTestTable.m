% File: test_AnnuityValueTestTable.m
classdef test_AnnuityValueTestTable < matlab.unittest.TestCase
    %TEST_ANNUITYVALUETESTTABLE Validates annuity calculations against a known table.
    
    properties
        DataSourceManager % Will hold the manager instance for this test class
        DataSource        % Will hold the specific data source for each test
        
        % Use the enum for type safety and clarity
        TestTableName = TableNames.UK_a55_Ult; 
        %TestTableName = TableNames.Zero_Mortality; 
    end
    properties (Constant)
        % Define the central directory for all test-related data and caches.
        TestResourceDirectory = 'G:\My Drive\Kaparra Software\Rates Analysis\Resources\testclasses';
    end

   
    methods (TestClassSetup)
        % --- NEW METHOD for one-time setup ---
        
        
        
        function setupTestClass(testCase)
            % This method runs once before any tests in this file.
            % This method runs once before any tests in this file.
            
            % 1. Define the specific cache directory for this test suite.
            testCacheDir = fullfile(testCase.TestResourceDirectory, 'cache');
            
            % Ensure the directory exists for the test run.
            if ~isfolder(testCacheDir), mkdir(testCacheDir); end

            % 2. Create a single, shared CacheManager instance configured with this specific directory.
            sharedTestCache = utilities.MortalityCacheManager('cacheDir', testCacheDir, 'cacheFile', 'SharedAnnuityTestCache.mat');
            sharedTestCache.clearCache(); % Start with a clean slate

            % 3. Get the singleton instance of the DataSourceManager and reset it.
            manager = DataSourceManager();
            manager.reset();

            % 4. Configure the manager: tell it to use our dedicated test cache
            %    whenever it needs to create a MortalityTableForTestingAnnuityValuesSource.
            sourceEnum = MortalityDataSourceNames.MortalityTableForTestingAnnuityValuesSource;
            manager.registerCacheManager(sourceEnum, sharedTestCache);

            % 5. Store the configured manager in a property for use in other methods.
            testCase.DataSourceManager = manager;
        end
    end

    methods (TestMethodSetup)
        
        function createDataSource(testCase)
            % This method now correctly uses the manager to get the data source.
            % It runs before each test method.
            
            % Get the manager that was configured for the whole class.
            manager = testCase.DataSourceManager;
            
            % Get the specific data source instance for the table we want to test.
            % The manager will use the registered testCache when creating this object.
            testCase.DataSource = manager.getDataSourceForTable(testCase.TestTableName);
            
            % We can also clear the cache before each test for absolute isolation.
            testCase.DataSource.clearCache();
        end
        
        
        % function createDataSource(testCase)
        %     % Create a fresh instance of the data source before each test.
        %     testCase.DataSource = MortalityTableForTestingAnnuityValuesSource();
        %     testCase.DataSource.clearCache();
        % 
        % 
        % end
    end
    
    methods (Test)
        
        function testTableCreationAndCaching(testCase)
            % Test 1: Verifies that the test table can be loaded and cached correctly.
            
            % ACT
            % The getMortalityTable method will fetch, parse, and cache the object.
            tableObject = testCase.DataSource.getMortalityTable(testCase.TestTableName);

            % ASSERT
            testCase.verifyClass(tableObject, 'BasicMortalityTable', 'Should return a BasicMortalityTable object.');
            testCase.verifyNotEmpty(tableObject.MortalityRates, 'MortalityRates property should be populated.');
            
            % Verify that the special 'ax' column was loaded.
            testCase.verifyTrue(isfield(tableObject.MortalityRates.Male, 'ax'), 'The "ax" field must exist for Male data.');
            testCase.verifyTrue(isfield(tableObject.MortalityRates.Female, 'ax'), 'The "ax" field must exist for Female data.');

            % Verify caching
            cacheManager = testCase.DataSource.getCacheManager();
            [~, isCached] = cacheManager.getTable(char(testCase.TestTableName));
            testCase.verifyTrue(isCached, 'The table object should be in the cache after the first call.');
            
            % Verify the cache file was created in the specified test directory
            expectedCacheFile = fullfile(testCase.TestResourceDirectory, 'cache', 'SharedAnnuityTestCache.mat');
            testCase.verifyEqual(cacheManager.getCacheFile(), expectedCacheFile, 'CacheManager should be using the specified test directory.');
        end
        
        function testAnnuityValueAgainstPublished(testCase)
            % Test 2: Compares calculated annuity PVs against the 'ax' values in the test table.
           %Test assumes that max payments is long enough that axdue = ax +1.  ise the term does not materially impact.xx
            relTol = 5e-2;
           
            % --- ARRANGE ---
            
            % Load the test table. This contains the "expected" ax values.
            testTableObject = testCase.DataSource.getMortalityTable(char(testCase.TestTableName));
            
            % Define annuity assumptions for this test
            interestRate = log(1.04);
            inflation = 0.0;
            annualPayment = 1; % For direct comparison with ax
            deferment = 0;
            startDate = datetime('today');
            startDate.TimeZone = 'Australia/Sydney';
            referenceTime = hours(17);
            startDate = startDate +referenceTime;
            frequency = utilities.FrequencyType.Annually;
            compounding = 1;
            
            % Create a flat rate curve for the 4% interest rate.
            curveDates = startDate + calyears([1, 5, 10, 20, 30]);
            rates = ones(size(curveDates)) * interestRate;
            rateCurve = marketdata.RateCurveKaparra('zero', startDate, curveDates, rates, compounding, 0);

            genders = {'Male', 'Female'};

            numRows = 90; % The total number of iterations
            variableNames = {'Gender', 'Age', 'CalculatedPV', 'ExpectedAX'};
            variableTypes = {'string', 'double', 'double', 'double'};

            % Pre-allocate the table
            pvCollection = table('Size', [numRows, 4], 'VariableTypes', variableTypes, 'VariableNames', variableNames);
            counter = 1;
            for g_idx = 1:length(genders)
                gender = genders{g_idx};
                
                % Get the data for the current gender from the test table.
                genderData = testTableObject.MortalityRates.(gender);
                
                % --- ACT & ASSERT (inside the loop for each age) ---
                
                testCase.DataSource.log('Validating annuity values for %s...', gender);
                
                for i = 1:length(genderData.Age)
                    currentAge = genderData.Age(i);
                    expected_ax_due = genderData.ax(i)+1; % lifetime annuity due = annuity immediate +1
                    expected_qx = genderData.qx(i);
                    
                    % The annuity should be a lifetime annuity starting now.
                    % MaxNumPayments should be long enough to cover all ages.
                    maxNumPayments = 45; 
                    
                    % Create a Person object for this specific age.
                    % The CashflowStrategy uses the testTableObject itself.

                    mortalityIdentifier = testTableObject.TableName;
                    mortalityDataSource = testCase.DataSource;
                    personStrategy = CashflowStrategy(mortalityIdentifier, ...
                                                      mortalityDataSource, ...
                                                      'AnnualAmount', annualPayment, ...
                                                      'Frequency', frequency, ...
                                                      'MaxNumPayments', maxNumPayments, ...
                                                      'InflationRate', inflation, ...
                                                      'StartDate', startDate);
                    
                    person = Person('Age', currentAge, 'Gender', gender, 'CashflowStrategy', personStrategy);
                    
                    % % Create the annuity instrument to be valued.
                    % dateLastAnnuityPayment = startDate + years(maxNumPayments);
                    % annuityPaymentDates = utilities.DateUtilities.generateDateArrays(startDate, dateLastAnnuityPayment,frequency);
                    annuity = AnnuityStrategyFactory.createAnnuityStrategyFactory(AnnuityType.SingleLifeTimeAnnuity).createInstrumentFromParams(person, ...
                        annualPayment, inflation, startDate, deferment, maxNumPayments, frequency);
                        
                    % Calculate the PV using the system.
                    calculated_pv = annuity.presentValue(rateCurve, inflation, startDate);
                    % calculated_pv = annuity.presentValue(rateCurve, inflation, startDate)*(1-expected_qx)/(1+interestRate);
                    
                    % Compare the calculated PV to the expected 'ax' from the table.
                    % Use a relative tolerance for financial values.
                    testCase.verifyEqual(calculated_pv, expected_ax_due, 'RelTol', relTol, ...
                        sprintf('Calculated PV for %s age %d (%.4f) must match expected ax (%.4f).', ...
                        gender, currentAge, calculated_pv, expected_ax_due));
                    % pvCollection{g_idx,i} =[gender,currentAge,calculated_pv,expected_ax] ;
                    pvCollection(counter, :) = {string(gender), currentAge, calculated_pv, expected_ax_due};
                    counter = counter + 1;
                end
                
            end
            display(pvCollection)
        end
        function testAnnuityValueConsistency(testCase)
            % Test 3: Checks for internal consistency bewteen values
            % Compares calculated annuity PVs against the 'ax' values derived from test table.
            % assumes that for large n: 
            % a(x:n)due = 1+ a(x:n-1) and d|a(x)due = dpx*v^d*(a(x+d)+1);
            relTol = 5e-2;
            % --- ARRANGE ---
            
            % Load the test table. This contains the "expected" ax values.
            testTableObject = testCase.DataSource.getMortalityTable(char(testCase.TestTableName));
            
            % Define annuity assumptions for this test
            interestRate = log(1.04);
            inflation = 0.0;
            annualPayment = 1; % For direct comparison with ax
            maxNumPayments = 45;
            
            startDate = datetime('today');
            startDate.TimeZone = 'Australia/Sydney';
            referenceTime = hours(17);
            startDate = startDate +referenceTime;
            frequency = utilities.FrequencyType.Annually;
            compounding = 1;
            age = 67;
            gender ="Female";
            % Create a flat rate curve for the 4% interest rate.
            curveDates = startDate + calyears([1, 5, 10, 20, 30]);
            rates = ones(size(curveDates)) * interestRate;
            rateCurve = marketdata.RateCurveKaparra('zero', startDate, curveDates, rates, compounding, 0);

            deferments = [0,10,20,25];
            ages = [age,age+deferments(2), age + deferments(3)];
            for g_idx = 1:length(deferments)
                currentDeferment = deferments(g_idx);
                
                % Get the data for the current gender from the test table.
                genderData = testTableObject.MortalityRates.(gender);
                
                % --- ACT & ASSERT (inside the loop for each age) ---
                
                testCase.DataSource.log('Validating annuity values for %s...', currentDeferment);
                
                for i = 1:length(ages)
                    currentAge = ages(i);
                   
                    ageIndex = find(genderData.Age == currentAge, 1);
                    expected_ax = genderData.ax(ageIndex)+1;
                    expected_qx = genderData.qx(ageIndex);

                    %TODO Handle age plus deferment greater than test table
                    expected_axAtDeferral = genderData.ax(ageIndex+currentDeferment)+1; % assumes ages are one year apart in teh table
                    probabilityOfSurvivalToDeferment = genderData.lx(ageIndex+currentDeferment)/genderData.lx(ageIndex);
                    discountFactor =(1+interestRate)^-currentDeferment;
                    expected_axAtDeferralDiscounted = expected_axAtDeferral*probabilityOfSurvivalToDeferment*discountFactor;
                    
                    % The annuity should be a lifetime annuity starting now.
                    % % MaxNumPayments should be long enough to cover all ages.
                     maxNumPayments = 110 - currentAge; 
                    
                    % Create a Person object for this specific age.
                    % The CashflowStrategy uses the testTableObject itself.

                    mortalityIdentifier = testTableObject.TableName;
                    mortalityDataSource = testCase.DataSource;
                    personStrategy = CashflowStrategy(mortalityIdentifier, ...
                                                      mortalityDataSource, ...
                                                      'AnnualAmount', annualPayment, ...
                                                      'Frequency', frequency, ...
                                                      'MaxNumPayments', maxNumPayments, ...
                                                      'InflationRate', inflation, ...
                                                      'StartDate', startDate);
                    
                    person = Person('Age', currentAge, 'Gender', gender, 'CashflowStrategy', personStrategy);
                    
                    % Create the annuity instrument to be valued.
                    %dateLastAnnuityPayment = startDate + years(maxNumPayments);
                    %annuityPaymentDates = utilities.generateDateArrays(startDate+years(currentDeferment), dateLastAnnuityPayment,frequency);
                    annuity = AnnuityStrategyFactory.createAnnuityStrategyFactory(AnnuityType.SingleLifeTimeAnnuity).createInstrumentFromParams(person, ...
                        annualPayment, inflation, startDate, currentDeferment, maxNumPayments, frequency);
                        
                    % Calculate the PV using the system.
                    calculated_pv = annuity.presentValue(rateCurve, inflation, startDate);
                    % calculated_pv = annuity.presentValue(rateCurve, inflation, startDate)*(1-expected_qx)/(1+interestRate);
                    
                    % Compare the calculated PV to the expected 'ax' from the table.
                    % Use a relative tolerance for financial values.
                    testCase.verifyEqual(calculated_pv, expected_axAtDeferralDiscounted, 'RelTol', relTol, ...
                        sprintf('Calculated PV for %s age %d (%.4f) must match expected ax (%.4f).', ...
                        gender, currentAge, calculated_pv, expected_axAtDeferralDiscounted));
                    pvCollection{g_idx,i} =[currentAge,currentDeferment,calculated_pv,expected_axAtDeferralDiscounted] ;
                end
                summary = array2table(pvCollection);
                display(summary)
            end
        end
        
    end
end