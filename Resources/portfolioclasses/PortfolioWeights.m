classdef PortfolioWeights
    properties
        Assets (1, :) string 
        Weights (1, :) double
        WeightsTable table  % Property to store the weights as a table
  
    end
    
    methods
        function obj = PortfolioWeights(assets, weights)
             if nargin == 0  % Check if no inputs are provided
                obj.WeightsTable = table.empty; % Initialize with an empty table
                return; 
             end
             
            if ~isvector(assets) || ~isvector(weights) || length(assets) ~= length(weights)
                error('Assets and Weights must be vectors of the same length.');
            end
            if abs(sum(weights) - 1) > utilities.Tolerance.AbsTol % Tolerance for floating-point comparison
                error('Portfolio weights must sum to 1.');
            end
            obj.Assets = assets;
            obj.Weights = weights;
            obj.WeightsTable = array2table(obj.Weights,'VariableNames', obj.Assets);
        end
        
        
    end
    
    methods (Static)
        function obj = fromTable(tbl)
            if ~istable(tbl) 
                error('Input must be a table with ''Assets''  columns.');
            end
            assets = tbl.Properties.VariableNames;
            weights = tbl{1,:};
            obj = PortfolioWeights(assets, weights);
        end
    end
end