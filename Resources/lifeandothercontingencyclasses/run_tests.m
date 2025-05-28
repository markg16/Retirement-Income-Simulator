%RUN_TESTS Run test suite and save results
%   Runs the AGA test suite and saves results to a file

% Add current directory to path
addpath(pwd);

% Create results file
resultsFile = fullfile(pwd, 'test_results.txt');
diary(resultsFile);

% Run tests
disp('Running AGA Test Suite...');
disp('------------------------');
results = runtests('test_AGA');

% Display detailed results
disp('Test Results:');
disp('-------------');
for i = 1:length(results)
    fprintf('Test: %s\n', results(i).Name);
    if isprop(results(i), 'Passed') && results(i).Passed
        fprintf('Result: PASSED\n');
    elseif isprop(results(i), 'Failed') && results(i).Failed
        fprintf('Result: FAILED\n');
    elseif isprop(results(i), 'Incomplete') && results(i).Incomplete
        fprintf('Result: INCOMPLETE\n');
    else
        fprintf('Result: UNKNOWN\n');
    end
    if isprop(results(i), 'Details') && ~isempty(results(i).Details)
        if ischar(results(i).Details) || isstring(results(i).Details)
            fprintf('Details: %s\n', results(i).Details);
        else
            fprintf('Details: [Struct or non-string value]\n');
        end
    end
    fprintf('\n');
end

% Summary
fprintf('Summary:\n');
fprintf('Total Tests: %d\n', length(results));
fprintf('Passed: %d\n', sum([results.Passed]));
fprintf('Failed: %d\n', sum([results.Failed]));
fprintf('Incomplete: %d\n', sum([results.Incomplete]));

% Close the diary
diary off;

% Display location of results file
disp(['Results saved to: ' resultsFile]); 