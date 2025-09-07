% runAllTests Script
% This script is the main entry point for running the entire test suite
% for the Retirement Income Simulator. It is designed to be run from the
% command line or by a Continuous Integration (CI) server.
% v1 

try
    % --- 1. Set up the Environment ---
    fprintf('Setting up MATLAB path for testing...\n');
    
    % Get the full path to the directory where this script is located
    projectRoot = fileparts(mfilename('fullpath'));
    
    % Add the necessary source code folders to the path so MATLAB can find the classes.
    % This is crucial for the CI environment which starts with a clean path.
    addpath(fullfile(projectRoot, 'Resources', 'annuityclasses'));
    addpath(fullfile(projectRoot, 'Resources', 'lifeandothercontingencyclasses'));
    addpath(fullfile(projectRoot, 'Resources', 'marketdata'));
    addpath(fullfile(projectRoot, 'Resources', 'plottingclasses'));
    addpath(fullfile(projectRoot, 'Resources', 'scenarios'));
    addpath(fullfile(projectRoot, 'Resources', 'userappclasses'));
    addpath(fullfile(projectRoot, 'Resources', 'utilities'));
    addpath(fullfile(projectRoot, 'Resources', 'testclasses')); % Also add the test folder itself
    
    fprintf('Path setup complete.\n');
    
    % --- 2. Discover and Run Tests ---
    
    % Specifically create a test suite from your 'testclasses' folder.
    % This is more robust than testsuite() which might find other tests.
    testFolder = fullfile(projectRoot, 'Resources', 'testclasses');
    fprintf('Discovering tests in: %s\n', testFolder);
    
    suite = testsuite(testFolder);
    
    if isempty(suite)
        error('runAllTests:NoTestsFound', 'No tests were discovered in the specified test folder.');
    end
    
    fprintf('Test discovery complete. Found %d tests.\n', numel(suite));
    
    % Create a test runner with text output to the command window
    runner = matlab.unittest.TestRunner.withTextOutput('OutputDetail', matlab.unittest.Verbosity.Detailed);
    
    % --- 3. Configure Reports for CI ---
    
    % Create a folder for the test results
    resultsFolder = fullfile(projectRoot, 'test-results');
    if ~exist(resultsFolder, 'dir'), mkdir(resultsFolder); end
    
    % Add a plugin to produce a JUnit-style XML file for CI systems
    junitFile = fullfile(resultsFolder, 'results.xml');
    runner.addPlugin(matlab.unittest.plugins.XMLPlugin.producingJUnitFormat(junitFile));
    
    % Add a plugin to produce a user-friendly HTML report
    htmlFile = fullfile(resultsFolder, 'TestReport.html');
    runner.addPlugin(matlab.unittest.plugins.TestReportPlugin.producingHTML(htmlFile));
    
    fprintf('Running tests and generating reports...\n');
    
    % --- 4. Run the Tests ---
    results = runner.run(suite);
    
    % Display the results table in the command window
    disp(table(results));
    
    % --- 5. Exit with Correct Status Code ---
    
    % This is crucial for the CI system.
    % If any tests failed, exit with a non-zero status code to tell the
    % CI server that the build has failed.
    if any([results.Failed])
        fprintf('One or more tests failed. Exiting with status 1.\n');
        exit(1);
    else
        fprintf('All tests passed successfully! Exiting with status 0.\n');
        exit(0);
    end
    
catch ME
    % If there is any error during the setup or running of the tests,
    % catch it, display it, and exit with a failure code.
    fprintf(2, 'An error occurred during the test run:\n');
    fprintf(2, '%s\n', ME.getReport('extended', 'hyperlinks', 'off'));
    exit(1);
end

