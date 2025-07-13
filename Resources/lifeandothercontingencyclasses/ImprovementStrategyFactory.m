% File: ImprovementStrategyFactory.m
classdef ImprovementStrategyFactory
    %IMPROVEMENTSTRATEGYFACTORY A factory for creating instances of improvement strategy classes.
    %   Uses an enum (MortalityImprovementStrategyNames) to determine which
    %   concrete strategy object to instantiate.

    methods (Static)
        function strategyObject = create(strategyEnum, varargin)
            % Creates an instance of an ImprovementFactorStrategy subclass.
            % Inputs:
            %   strategyEnum: A MortalityImprovementStrategyNames enum member.
            %   varargin:     Optional arguments to pass to the strategy's constructor
            %                 (e.g., a constant factor for ConstantImprovementFactorStrategy).
            
            if ~isa(strategyEnum, 'MortalityImprovementStrategyNames')
                error('ImprovementStrategyFactory:InvalidInput', 'Input must be a valid MortalityImprovementStrategyNames enum member.');
            end
            
            % Use a switch statement to call the correct constructor
            switch strategyEnum
                case MortalityImprovementStrategyNames.MeanImprovementFactorStrategy
                    % This strategy has no constructor arguments.
                    strategyObject = MeanImprovementFactorStrategy();
                    
                case MortalityImprovementStrategyNames.ConstantImprovementFactorStrategy
                    % This strategy takes a constant factor as an argument.
                    % If no factor is provided via varargin, we'll default to 0.
                    if ~isempty(varargin)
                        constantFactor = varargin{1};
                    else
                        constantFactor = 0; % Default to 0% improvement
                    end
                    strategyObject = ConstantImprovementFactorStrategy(constantFactor);
                    
                otherwise
                    % This case handles any future enum members you might add
                    % without adding a corresponding case here.
                    error('ImprovementStrategyFactory:NotImplemented', 'The creation logic for strategy "%s" has not been implemented.', char(strategyEnum));
            end
        end
    end
end