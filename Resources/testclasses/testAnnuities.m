classdef testAnnuities < matlab.unittest.TestCase
    
%example https://au.mathworks.com/help/matlab/matlab_prog/write-independent-and-repeatable-tests.html
% classdef SymmetryExampleTest < matlab.unittest.TestCase
%     methods (TestClassSetup)
%         function setFormat(testCase)
%             originalFormat = format;
%             testCase.addTeardown(@format,originalFormat)
%             format("compact")
%         end
%     end
% 
%     methods (Test)
%         function formatTest1(testCase)
%             testCase.verifyEqual(format().LineSpacing,"compact")
%         end
% 
%         function formatTest2(testCase)
%             testCase.verifyEqual(format().LineSpacing,"compact")
%         end
%     end
% end


    methods(TestClassSetup)
        % Shared setup for the entire test class


    end
    
    methods(TestMethodSetup)
        % Setup for each test
    end
    
    methods(Test)
        % Test methods
        
        function valueEqualsNeillTest(testCase)
            calculatedValue = annuity.calculateValue();
            neilValue = 10.737; %(see page 426 age 65
            testCase.verifyEqual(neillValue,calculatedValue);
        end
    end
    
end