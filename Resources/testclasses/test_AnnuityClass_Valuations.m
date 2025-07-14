classdef test_AnnuityClass_Valuations < matlab.unittest.TestCase
    %TEST_AnnuityClass_Valuations suite for Gompertz Law using
    %cachemanager

    properties (ClassSetupParameter)
        % Creates a shared resource for all tests in this class, making it faster.
        SharedSource = {true}
    end

    properties (Constant)
        EXPECTED_TABLE_COUNT = 1;
    end

    properties (Access = private)
        % This property is populated by the [TestClassSetup] method.
        DataSource
    end

    methods (Access = private)

    end

    methods (TestClassSetup)
        function setupClass(testCase, SharedSource)
            % This runs ONCE before any test in the class.
            if SharedSource
                try
                    % Create a single, shared instance of the source for all tests.
                    % OverwriteExisting=true ensures a clean state for the test run.
                    testCase.DataSource = AnalyticalMortalityDataSource();
                    testCase.assumeNotEmpty(testCase.DataSource, 'Fatal: Failed to initialize the shared DataSource.');
                catch ME
                    testCase.assumeFail(['Fatal: Test class setup failed: ' ME.message]);
                end
            end
        end
    end

    methods (TestMethodTeardown)
        function inspectAndClearCache(testCase)
            % This runs after EACH test.
            availableTables = testCase.DataSource.getAvailableTables();
            if ~isempty(availableTables)
                fprintf('\n'); % For better console formatting during test runs
                for i = 1:length(availableTables)
                    tableEnum = availableTables(i);
                    try
                        % Get the data struct to pass to the new sampler method
                        dataStruct = testCase.DataSource.getMortalityTable(tableEnum);
                        % Call the new method on the DataSource instance
                        testCase.DataSource.logMortalityTableSample(dataStruct, ...
                            sprintf('---> Sampling cached data for: %s (after test)', char(tableEnum)));
                    catch ME
                        testCase.DataSource.log('Error during post-test sampling for %s: %s', char(tableEnum), ME.message);
                    end
                end
            end
            testCase.DataSource.clearCache();
        end
    end

    methods (TestClassTeardown)

        % This block can be empty or removed if you have nothing else to run once at the very end.
        function finalCleanup(testCase)
            testCase.DataSource.log('--- Test Class Finished ---');
        end


    end

    methods (Test)


        function testAnnuityPV_GompertzValidation(testCase)
            %#Test, #:Tags "Unit"
            % Validates a PV calculation against an analytical Gompertz model.

            % Create a person
            annuitantAge = 65;
            annuitantGender = utilities.GenderType.Male; 
            annuitantCountry = "AU";
            annuityIncome  = 1000;
            annuityDefermentPeriod = 0; 
            annuityType = AnnuityType.SingleLifeTimeAnnuity;
            annuityTerm = 25; 
            annuitantInitialValue = 1000000; % should not be needed
            annuityStartDate = datetime('2017-03-31','Format','dd/MM/uuuu HH:mm:ss');
            annuityStartDate.TimeZone = 'Australia/Sydney';

            annuityFrequency = utilities.FrequencyType.Annually;
            annuityIncomeGtdIncrease = 0 ; 
            analyticMortalityDataSource = testCase.DataSource; 
            
            % Define Gompertz and financial parameters
            gompertzB = 0.0002;
            gompertzC = 1.09;

            % Create a mortality table identifier
            gompertzTableIdentifier = struct('Model', MortalityModelNames.Gompertz, ...
                'B', gompertzB, 'c', gompertzC);


            % Create a CashflowStrategy using this Gompertz table
            % Note: We are injecting the already-created table object directly,
            % bypassing the need for a DataSource for this specific unit test.
            localCashflowStrategy = CashflowStrategy(gompertzTableIdentifier,analyticMortalityDataSource,'AnnualAmount',annuityIncome,'StartDate',...
                annuityStartDate ,'MaxNumPayments',annuityTerm,'Frequency',annuityFrequency,...
                'InflationRate',annuityIncomeGtdIncrease);

            localPerson = Person('Gender',annuitantGender,'Age',annuitantAge,'Country',annuitantCountry,'InitialValue',annuitantInitialValue,...
                'TargetIncome',annuityIncome,'IncomeDeferement',annuityDefermentPeriod,'CashflowStrategy',localCashflowStrategy);


            % Define a rate curve
            %set up a ratecurve object
            levelInterestRate = 0.03;
            type = 'zero';
            settle = annuityStartDate; %valuationDates(1);
            dates = calyears([1,3,5,10,20,40]);
            compounding = -1;
            basis = 0;
            rates = ones(1,length(dates))*levelInterestRate;
            rateCurve = marketdata.RateCurveKaparra(type, settle, dates, rates, compounding, basis);



            % Create Annuity object

            dateLastAnnuityPayment = annuityStartDate + calyears(annuityDefermentPeriod + annuityTerm);
            dateFirstAnnuityPayment = annuityStartDate + years(annuityDefermentPeriod);

            annuityPaymentDates = utilities.generateDateArrays(dateFirstAnnuityPayment, dateLastAnnuityPayment,annuityFrequency);

            annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);
            annuity = annuityFactory.createInstrument(localPerson, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityDefermentPeriod, ...
                annuityTerm,annuityFrequency,annuityPaymentDates);
            
            
            %--- Simulated Annuity Valuation  ----
            pvSimulatedAnnuityValue = annuity.presentValue(rateCurve,annuityIncomeGtdIncrease, annuityStartDate);


            
            
            % --- Analytical "Gold Standard" Calculation ---
            % Calculates PV of an annuity of 1, so we multiply by annualAmount

            levelContInterestRate = exp(levelInterestRate)-1; % convert to continuously compounded as the annuity functions assume continously compounded.
            pvAnalytical = annuityIncome * AnalyticalAnnuityValuations.calculateAnnuityPV_Gompertz(gompertzB, gompertzC, annuitantAge, annuityTerm, levelContInterestRate);


            % 3. ASSERT
            testCase.verifyEqual(pvSimulatedAnnuityValue, pvAnalytical, 'RelTol', 1e-3, ...
                'The PV calculated by the system components must match the analytical Gompertz formula.');

            testCase.DataSource.log('Gompertz Test: PV from System = %.4f, Analytical PV = %.4f', pvSimulatedAnnuityValue, pvAnalytical);
        end


        function testProgressionWithLevelRate(testCase)
            %#Test, #:Tags "Unit"
            % This test validates the end-to-end progression analysis machinery
            % using a simple, controlled scenario with a single level interest rate.

            %Set up progressionConfig Parameters
            valuationStartDate =  utilities.DateUtilities.createDateTime('InputDate',utilities.DefaultScenarioParameters.defaultStartDate);
            % utilities.DateUtilities.createDateTime('InputDate',utilities.DefaultScenarioParameters.defaultStartDate)
            valuationEndDate = utilities.DateUtilities.createDateTime('InputDate',valuationStartDate + years(30));
            referenceTime =  utilities.DefaultScenarioParameters.defaultReferenceTime;
            frequency = utilities.FrequencyType.Annually;
            [valuationStartDates, valuationEndDates]= utilities.generateDateArrays( valuationStartDate, valuationEndDate,frequency,referenceTime );

            annuityValuationDates = [valuationStartDates valuationEndDates(end)];
           %---- Run Analysis----
           annuitant = Person();

           annuityIncome=annuitant.CashflowStrategy.AnnualAmount;
           annuityIncomeGtdIncrease = annuitant.CashflowStrategy.InflationRate;
           annuityStartDate = annuitant.CashflowStrategy.StartDate;
           annuityDefermentPeriod = annuitant.IncomeDeferement;
           annuityTerm=annuitant.CashflowStrategy.MaxNumPayments;
           annuityFrequency=annuitant.CashflowStrategy.Frequency;
           % annuityType = AnnuityType.SingleLifeTimeAnnuity;
           annuityType = AnnuityType.FixedAnnuity ;



           annuityFactory = AnnuityStrategyFactory.createAnnuityStrategyFactory(annuityType);
           annuity = annuityFactory.createInstrument(annuitant, annuityIncome,annuityIncomeGtdIncrease,annuityStartDate,annuityDefermentPeriod, ...
                annuityTerm,annuityFrequency);
          
           annuitant.Annuity  = annuity;

           resultsTimeTable = runAnnuityAnalysisOfChange('annuitant',annuitant,'valuationDates',annuityValuationDates);

           
           % set up plot config

           showRedundant = true;
           % The interval for plotting. 1 means plot every period, 5 means plot
           % every fifth period, etc.
           plotInterval = 10;

           plotConfig = WaterfallPlotConfig(...
               'ShowRedundantTotals', showRedundant, ...
               'PlotInterval', plotInterval);


           % % --- 5. PLOT THE RESULTS ---
           % % (Plotting logic remains the same)
            if height(resultsTimeTable) > 0
                fprintf('Analysis complete. Preparing plot...\n');

                % a. Create a new figure window to draw on.
                fig = uifigure('Name', 'Annuity Progression Analysis');

                % b. Create the axes for the plot. For a single plot, we just need one.
                ax = uiaxes(fig);

                % c. Create the 'axesMap' that the PlotManager expects.
                %    The key must be the string name of the AnnuityType.
                axesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
                annuityTypeName = resultsTimeTable.AnnuityType(1); % Assuming this is the type being analyzed
                axesMap(annuityTypeName) = ax;

                % d. Prepare the data structure that the PlotManager expects.
                %    It needs a struct array with .AnnuityType and .Data fields.
                plotData.AnnuityType = annuityTypeName;
                plotData.Data = resultsTimeTable;

                % e. Call the static PlotManager method with all the prepared components.
                %    The `annuityParametersToPlot` is not used by the waterfall, so we pass [].
                try
                    PlotManager.plotProgression(axesMap, plotData,plotConfig);
                    fprintf('Plot generated successfully.\n');
                catch ME
                    fprintf(2, 'Error during plotting: %s\n', ME.message);
                end

            else
                fprintf('Analysis completed but produced no results to plot.\n');
            end
        
            % --- ASSERT ---

            % 6. Verify the structure and content of the results.
            testCase.verifyClass(resultsTimeTable, 'timetable', 'The result should be a table.');
            testCase.verifyEqual(height(resultsTable), 1, 'The analysis should produce exactly one row for a one-year period.');
            testCase.verifyTrue(ismember('ProgressionData', resultsTable.Properties.VariableNames), 'Results table must contain ProgressionData.');

            % Get the waterfall data from the results
            waterfallTimetable = resultsTimeTable.ProgressionData{1};
            testCase.verifyClass(waterfallTimetable, 'timetable', 'ProgressionData should contain a timetable.');

            % Perform a basic sanity check on the waterfall values
            startValue = waterfallTimetable.Change(1);
            endValue = waterfallTimetable.Change(end);

            testCase.verifyGreaterThan(startValue, 0, 'Starting PV should be positive.');
            testCase.verifyGreaterThan(endValue, 0, 'Ending PV should be positive.');

            % A key actuarial check: for a single life, the PV should decrease with age (all else equal)
            testCase.verifyLessThan(endValue, startValue, 'Ending PV should be less than Starting PV for a one-year progression with constant rate curve.');

            testCase.log('Successfully validated progression analysis with a level 4%% rate.');
            disp(waterfallTimetable);


        end
    end


end
    %     % This is at the end of your class file, AFTER the main class 'end'
    % % Helper function for cleanup, can be outside the class or as a local function
    % % if MATLAB version supports it in scripts/class files.
    % function cleanupMockUtility(testSpecificUtilDir, originalUtilPath)
    %     % originalUtilPath is not strictly used in this version but kept for signature consistency
    %     % if you later decide to restore the exact path. For now, rmpath is targeted.
    %
    %     % Check if directory exists before trying to remove it from path to avoid warnings
    %     if exist(testSpecificUtilDir, 'dir')
    %         rmpath(testSpecificUtilDir);
    %     end
    %
    %     % Check again if directory exists before trying to remove it physically
    %     if exist(testSpecificUtilDir, 'dir')
    %         % Attempt to remove the directory and its contents.
    %         % The 's' flag allows removal of non-empty directories.
    %         % Use with caution and ensure testSpecificUtilDir is correctly defined.
    %         status = rmdir(testSpecificUtilDir, 's');
    %         if ~status
    %             warning('cleanupMockUtility:rmdirFailed', 'Failed to remove directory: %s. It might be in use or permissions are lacking.', testSpecificUtilDir);
    %         end
    %     end
    %     % If you needed to restore the original path state more precisely:
    %     % path(originalUtilPath);
    % end
