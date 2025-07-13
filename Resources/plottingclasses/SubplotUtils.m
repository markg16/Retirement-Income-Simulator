% File: SubplotUtils.m
classdef SubplotUtils
    %SUBPLOTUTILS A collection of static helper methods for creating UI plots.

    methods (Static)
        function axesMap = createSubplots(plotPanel, typesEnum)
            % Creates a grid of subplots in a given panel and returns them
            % as a containers.Map, where the key is the string name of the
            % enumeration member and the value is the axes handle.
            %
            % Inputs:
            %   plotPanel: The uipanel or figure to create the plots in.
            %   typesEnum: An array of enumeration members (e.g., enumeration('AnnuityType')).
            %
            % Returns:
            %   axesMap:   A containers.Map linking type names to axes handles.

            % 1. Initialize the output map.
            axesMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            
            numTypes = length(typesEnum);
            if numTypes == 0
                return; % Return an empty map if no types are provided.
            end

            % 2. Calculate grid dimensions for a visually pleasing layout.
            switch numTypes
                case 1, nRows = 1; nCols = 1;
                case 2, nRows = 2; nCols = 1;
                case 3, nRows = 3; nCols = 1;
                case 4, nRows = 2; nCols = 2;
                otherwise
                    nRows = ceil(sqrt(numTypes));
                    nCols = ceil(numTypes / nRows);
            end
            
            % Clear the panel and create a new tiled layout.
            cla(plotPanel, 'reset');
            t = tiledlayout(plotPanel, nRows, nCols, 'TileSpacing', 'compact', 'Padding', 'compact');
            
            % 3. Create subplots and populate the map.
            for i = 1:numTypes
                % Get the string name of the current enum member to use as the map key.
                typeNameStr = char(typesEnum(i));
                
                % Create the next subplot axes.
                ax = nexttile(t);
                
                % Set a title on the subplot for immediate visual feedback.
                title(ax, typeNameStr);
                
                % Add the axes handle to the map with its corresponding name as the key.
                axesMap(typeNameStr) = ax;
            end
        end
    end
end