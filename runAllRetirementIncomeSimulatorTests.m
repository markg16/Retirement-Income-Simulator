% runAllRetirementIncomeSimulatorTests.m
%
% This script discovers and runs all unit tests in the current project folder
% and its subfolders. It generates a detailed HTML report with the results,
% including any messages logged with testCase.log().

fprintf('--- Starting Test Suite Execution ---\n\n');

% 1. Discover all tests in the current folder and subfolders.
%    By providing no arguments, testsuite() automatically finds all test classes.
try
    suite = testsuite();
    fprintf('Successfully discovered %d test classes.\n', numel(suite));
catch ME
    error('Failed to discover tests. Ensure test files are on the path and named correctly. Original error: %s', ME.message);
end

% 2. Create a test runner with detailed text output to the Command Window.
runner = matlab.unittest.TestRunner.withTextOutput('OutputDetail', matlab.unittest.Verbosity.Detailed);

% 3. Create the HTML report plugin.
%    Define a dedicated folder for the test results.
resultsFolder = fullfile(pwd, 'test-results');
if ~isfolder(resultsFolder)
    mkdir(resultsFolder);
end
reportFile = fullfile(resultsFolder, 'TestReport.html');
fprintf('HTML report will be generated at: %s\n', reportFile);

%    The plugin will automatically write the results to the file.
plugin = matlab.unittest.plugins.TestReportPlugin.producingHTML(reportFile);

% 4. Add the plugin to the runner.
runner.addPlugin(plugin);

% 5. Run the tests.
fprintf('\n--- Running Tests ---\n\n');
results = runner.run(suite);

% 6. Display the final results table in the Command Window and open the report.
fprintf('\n--- Test Execution Complete ---\n\n');
disp(results);

% Automatically open the generated HTML report for review.
web(reportFile, '-browser');