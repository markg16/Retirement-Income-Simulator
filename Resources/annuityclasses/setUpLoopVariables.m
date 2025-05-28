function loopVariables  = setUpLoopVariables()

% Assuming AnnuityInputType is defined as an enum
% Example:
% enumdef AnnuityInputType
%    enumeration
%        InterestRate, AnnuityTerm, Age, DefermentPeriod
%    end
% end

% Example values (replace with your actual values)
baseLevelRate = 0.05;
maxNumPmts = 20;
person.Age = 60;

% Define the mapping for loop variable values using AnnuityInputType enumeration
valueMap = containers.Map(...
    {char(AnnuityInputType.InterestRate), char(AnnuityInputType.AnnuityTerm),...
     char(AnnuityInputType.Age), char(AnnuityInputType.DefermentPeriod)},...
    {@() (-0.02:0.01:baseLevelRate+0.07),...
     @() (5:1:maxNumPmts + 10),...
     @() [person.Age, person.Age + 5],...
     @() [0 5 10]});

% Get the keys from the valueMap (AnnuityInputType names)
keys = valueMap.keys();

% Initialize the loopVariables struct array
loopVariables(length(keys)).name = ''; % Preallocate
for i = 1:length(keys)
    loopVariables(i).name = keys{i};
    loopVariablesRangeFunction = valueMap(keys{i});
    loopVariables(i).values = loopVariablesRangeFunction(); % Execute the anonymous function to get the values
end


end