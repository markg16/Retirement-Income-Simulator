% File: test_Analytical.m
classdef test_Analytical_AnnuityValues < matlab.unittest.TestCase
    %TEST_ANALYTICAL Unit tests for the Analytical utility class.
    %   Validates the annuity PV calculations against known boundary conditions
    %   and theoretical financial formulas.

    properties
        % Define common parameters to be used across tests for consistency
        GompertzB = 0.0002;
        GompertzC = 1.09;
        Age = 65;
        Term = 25;
        InterestRate = 0.03;
    end
    
    methods (Test)
        
        function testZeroTermAnnuity(testCase)
            % Test Case 1: An annuity with a term of 0 years should have a PV of 0.
            
            % ARRANGE
            term = 0;
            expectedPV = 0;
            
            % ACT
            actualPV = AnalyticalAnnuityValuations.calculateAnnuityPV_Gompertz(...
                testCase.GompertzB, testCase.GompertzC, testCase.Age, term, testCase.InterestRate);
            
            % ASSERT
            testCase.verifyEqual(actualPV, expectedPV, ...
                'PV of a 0-term annuity should be 0.');
        end
        
        function testOneYearTermAnnuity(testCase)
            % Test Case 2: An annuity-due with a term of 1 year makes a single payment of 1 at t=0.
            % The PV should be exactly 1, as there is no discounting and survivorship is 1.
            
            % ARRANGE
            term = 1;
            expectedPV = 1;
            
            % ACT
            actualPV = AnalyticalAnnuityValuations.calculateAnnuityPV_Gompertz(...
                testCase.GompertzB, testCase.GompertzC, testCase.Age, term, testCase.InterestRate);
            
            % ASSERT
            testCase.verifyEqual(actualPV, expectedPV, ...
                'PV of a 1-year annuity-due should be 1.');
        end
        
        function testZeroInterestAnnuity(testCase)
            % Test Case 3: With zero interest, the PV should be the sum of survivorship probabilities.
            
            % ARRANGE
            interestRate = 0;
            
            % Manually calculate the expected sum of survivorship probabilities (_t_p_x)
            expectedPV = 0;
            log_c = log(testCase.GompertzC);
            for t = 0:(testCase.Term - 1)
                t_p_x = exp( (testCase.GompertzB / log_c) * (testCase.GompertzC ^ testCase.Age) * (1 - testCase.GompertzC ^ t) );
                expectedPV = expectedPV + t_p_x;
            end
            
            % ACT
            actualPV = AnalyticalAnnuityValuations.calculateAnnuityPV_Gompertz(...
                testCase.GompertzB, testCase.GompertzC, testCase.Age, testCase.Term, interestRate);
            
            % ASSERT
            testCase.verifyEqual(actualPV, expectedPV, 'AbsTol', 1e-9, ...
                'PV with zero interest should equal the sum of survivorship probabilities.');
        end
        
        function testZeroMortalityAnnuityCertain(testCase)
            % Test Case 4: With zero mortality (B=0), the life annuity becomes an annuity-certain.
            % Its value should match the standard financial formula for an annuity-certain-due.
            
            % ARRANGE
            mortalityParameterB = 0; % This effectively makes survivorship probability always 1
            
            % Calculate the expected PV using the financial formula for an annuity-certain-due of 1
            % Formula: (1 - v^n) / d, where d = i*v
            v = 1 / (1 + testCase.InterestRate);
            d = testCase.InterestRate * v;
            expectedPV = (1 - v^testCase.Term) / d;

            % ACT
            actualPV = AnalyticalAnnuityValuations.calculateAnnuityPV_Gompertz(...
                mortalityParameterB, testCase.GompertzC, testCase.Age, testCase.Term, testCase.InterestRate);
                
            % ASSERT
            testCase.verifyEqual(actualPV, expectedPV, 'AbsTol', 1e-9, ...
                'PV with zero mortality should match the formula for an annuity-certain-due.');
        end
        
    end
end
