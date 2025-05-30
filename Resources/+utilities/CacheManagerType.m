classdef CacheManagerType
    %CACHEMANAGERTYPE Defines the types of cache managers available.
    %   Enumeration to provide type-safe selection of cache managers.
    
    enumeration
        Mortality   % For caching mortality data
        Economic    % For caching economic data
        % Add other types here as needed
    end
end