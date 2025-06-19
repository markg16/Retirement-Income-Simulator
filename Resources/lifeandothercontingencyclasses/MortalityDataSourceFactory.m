classdef MortalityDataSourceFactory < handle
    %MORTALITYDATASOURCEFACTORY Factory for creating mortality data sources
    %   Manages the creation and caching of different mortality data sources
    
    properties (Access = private)
        Sources  % Map of available data sources
    end
    
    methods
        function obj = MortalityDataSourceFactory()
            obj.Sources = containers.Map();
            obj.initializeSources();
        end
        
        function source = getSource(obj, sourceName)
            % Get a specific data source by name
            if ~obj.Sources.isKey(sourceName)
                error('Unknown data source: %s', sourceName);
            end
            source = obj.Sources(sourceName);
        end
        
        function sources = getAllSources(obj)
            % Get all available data sources
            sources = values(obj.Sources);
        end
        
        function available = getAvailableSources(obj)
            % Get only the data sources that are currently available
            sources = obj.getAllSources();
            available = sources([sources.checkAvailability]);
        end
    end
    
    methods (Access = private)
        function initializeSources(obj)
            % Initialize all available data sources
            obj.Sources('Australian') = AustralianGovernmentActuarySource();
            obj.Sources('NewZealand') = NewZealandMortalitySource();
            obj.Sources('UK') = UKMortalitySource();
            obj.Sources('Analytic') = AnalyticalMortalityDataSource();
        end
    end
end 