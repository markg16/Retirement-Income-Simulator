% Test script to check URL patterns for AGA tables
fprintf('Starting URL pattern test...\n');

% Create the data source
source = AustralianGovernmentActuarySource();

% Test URL patterns for all available tables
source.testUrlPatterns();

fprintf('URL pattern test completed. Check the logs directory for results.\n'); 