classdef AppUtilities
    %UNTITLED Summary of this class goes here
    %   Detailed explanation goes here

    properties
        Property1
    end

    methods (Static)
        function UIFigureCloseRequest(app, event)
            % % Stop timers
            % stop(app.MyTimer);
            % 
            % % Close files or connections
            % fclose(app.fileID);

            % ... other cleanup actions ...

            % (Optional) Confirmation dialog
            selection = uiconfirm(app.UIFigure, 'Confirm Close', 'Are you sure you want to close the app?');
            switch selection
                case 'OK'
                    delete(app.UIFigure); % Allow the app to close
                case 'Cancel'
                    event.cancel(); % Prevent the app from closing
            end
        end
    end
end