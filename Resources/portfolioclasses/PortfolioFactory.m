classdef (Abstract) PortfolioFactory
    methods (Abstract,Static)
        portfolio = createPortfolio(varargin);
    end
end
