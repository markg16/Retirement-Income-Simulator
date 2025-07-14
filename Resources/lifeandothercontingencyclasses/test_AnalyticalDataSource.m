% File: test_AnalyticalDataSource.m
classdef test_AnalyticalDataSource < test_MortalityDataSource_Base
    % Tests the specific implementation of AnalyticalMortalityDataSource.
    % Inherits all generic tests from test_MortalityDataSource_Base.

    methods (TestMethodSetup)
        function createDataSource(testCase)
            % Provides a specific instance of AnalyticalMortalityDataSource.
            testCase.DataSource = AnalyticalMortalityDataSource();
            testCase.assumeNotEmpty(testCase.DataSource, 'Setup failed: Could not create AnalyticalMortalityDataSource.');
        end
    end
    
    methods (Access = protected)
        function identifier = getValidTableIdentifier(testCase)
            % Provides a valid model specification for the Analytical source.
            identifier = struct('Model', MortalityModelNames.Gompertz, 'B', 0.0002, 'c', 1.09, 'maxAge', 110);
        end
        
        function identifier = getInvalidTableIdentifier(testCase)
            % Provides an invalid model specification.
            identifier = struct('Model', MortalityModelNames.Gompertz,'c', 1.1);
        end
    end

    % --- TESTS SPECIFIC TO AnalyticalMortalityDataSource ONLY ---
    methods (Test)
        function testGompertzGenerationCorrectness(testCase)
            %#Test, #:Tags "Unit"
            % This test is specific to the analytical source's generation logic.
            spec = testCase.getValidTableIdentifier(); % Get the standard Gompertz spec
            gompertzTable = testCase.DataSource.getMortalityTable(spec);
            
            testCase.verifyClass(gompertzTable, 'GompertzMortalityTable');
            
            % Verify the qx calculation against the direct formula
            sampleAge = 65;
            p_x_analytical = exp((spec.B / log(spec.c)) * (spec.c ^ sampleAge) * (1 - spec.c));
            qx_analytical = 1 - p_x_analytical;
            
            qx_from_table = gompertzTable.getRate('Male', sampleAge);
            
            testCase.verifyEqual(qx_from_table, qx_analytical, 'AbsTol', 1e-9, ...
                'The qx value generated must match the analytical Gompertz formula.');
        end

        function testErrorHandlingForModels(testCase)
            % Tests that the source throws appropriate errors for bad model specifications.
            
            % Use the invalid identifier from the helper method
            incompleteSpec = testCase.getInvalidTableIdentifier();
            testCase.verifyError(@() testCase.DataSource.getMortalityTable(incompleteSpec), ...
                'AnalyticalMortalityDataSource:MissingParams', ...
                'Should throw an error for a supported model with missing parameters.');

            % Test an input that isn't a struct
            testCase.verifyError(@() testCase.DataSource.getMortalityTable('not_a_struct'), ...
                'AnalyticalMortalityDataSource:InvalidSpec', ...
                'Should throw an error if the input is not a struct.');
        end
    end
end
