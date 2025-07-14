% File: test_AnnuityValueTestTable.m
classdef test_AnnuityValueTestTable < matlab.unittest.TestCase
    %TEST_ANNUITYVALUETESTTABLE Validates annuity calculations against a known table.
    
    properties
        DataSource % Instance of the data source under test
        TestTableName = 'UK-annuity-tables-a(55)'; % The name of your test file
    end

    methods (TestMethodSetup)
        function createDataSource(testCase)
            % Create a fresh instance of the data source before each test.
            testCase.DataSource = MortalityTableForTestingAnnuityValuesSource();
            testCase.DataSource.clearCache();
        end
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
            [~, isCached] = cacheManager.getTable(testCase.TestTableName);
            testCase.verifyTrue(isCached, 'The table object should be in the cache after the first call.');
        end
        
        function testAnnuityValueValidation(testCase)
            % Test 2: Compares calculated annuity PVs against the 'ax' values in the test table.
            relTol = 2.5e-2;
            % --- ARRANGE ---
            
            % Load the test table. This contains the "expected" ax values.
            testTableObject = testCase.DataSource.getMortalityTable(testCase.TestTableName);
            
            % Define annuity assumptions for this test
            interestRate = 0.04;
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
            for g_idx = 1:length(genders)
                gender = genders{g_idx};
                
                % Get the data for the current gender from the test table.
                genderData = testTableObject.MortalityRates.(gender);
                
                % --- ACT & ASSERT (inside the loop for each age) ---
                
                testCase.DataSource.log('Validating annuity values for %s...', gender);
                
                for i = 1:length(genderData.Age)
                    currentAge = genderData.Age(i);
                    expected_ax = genderData.ax(i);
                    expected_qx = genderData.qx(i);
                    
                    % The annuity should be a lifetime annuity starting now.
                    % MaxNumPayments should be long enough to cover all ages.
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
                    dateLastAnnuityPayment = startDate + years(maxNumPayments);
                    annuityPaymentDates = utilities.generateDateArrays(startDate, dateLastAnnuityPayment,frequency);
                    annuity = AnnuityStrategyFactory.createAnnuityStrategyFactory(AnnuityType.SingleLifeTimeAnnuity).createInstrument(person, ...
                        annualPayment, inflation, startDate, deferment, maxNumPayments, frequency, annuityPaymentDates);
                        
                    % Calculate the PV using the system.
                    calculated_pv = annuity.presentValue(rateCurve, inflation, startDate)*(1-expected_qx)/(1+interestRate);
                    % calculated_pv = annuity.presentValue(rateCurve, inflation, startDate)*(1-expected_qx)/(1+interestRate);
                    
                    % Compare the calculated PV to the expected 'ax' from the table.
                    % Use a relative tolerance for financial values.
                    testCase.verifyEqual(calculated_pv, expected_ax, 'RelTol', relTol, ...
                        sprintf('Calculated PV for %s age %d (%.4f) must match expected ax (%.4f).', ...
                        gender, currentAge, calculated_pv, expected_ax));
                    pvCollection{i} =[currentAge,calculated_pv,expected_ax] ;
                end
                summary = array2table(pvCollection);
            end
        end
        
    end
end