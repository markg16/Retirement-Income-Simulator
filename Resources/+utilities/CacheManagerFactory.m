classdef CacheManagerFactory
    methods (Static)
        function cacheManager = createCacheManager(type, varargin)
            %CREATECACHEMANAGER Creates a specific cache manager instance.
            %   Inputs:
            %       type - A CacheManagerType enumeration member (e.g., CacheManagerType.Mortality)
            %       varargin - Optional arguments to pass to the cache manager's constructor
            
            % Input validation
            if ~isa(type, 'utilities.CacheManagerType')
                error('Input must be of type CacheManagerType.');
            end
            
            % Switch based on the enumeration member
            switch type
                case utilities.CacheManagerType.Mortality
                    cacheManager = utilities.MortalityCacheManager(varargin{:});
                
                % case CacheManagerType.Economic
                %     % Assuming you have an EconomicCacheManager class
                %     cacheManager = EconomicCacheManager(varargin{:});
                    
                otherwise
                    error('Unsupported cache manager type: %s', char(type));
            end
        end
    end
end