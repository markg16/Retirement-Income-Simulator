classdef MortalityTable < handle
    properties (Abstract)
        TableName
        SourceType % 'File' or 'Web'
        SourcePath % Path to file or URL
        LastUpdated
    end
    
    properties (Access = protected)
        ValidationStatus
        ValidationMessage
    end
    
    methods (Abstract)
        rate = getRate(obj, gender, age)
        lx = getLx(obj, gender, age)
        survivorshipProbabilities = getSurvivorshipProbabilities(obj, gender, currentAge, finalAge)
    end
    
    methods
        function validate(obj)
            % Basic validation that all concrete classes should implement
            if isempty(obj.TableName)
                obj.ValidationStatus = false;
                obj.ValidationMessage = 'Table name is required';
                return;
            end
            
            if isempty(obj.SourceType)
                obj.ValidationStatus = false;
                obj.ValidationMessage = 'Source type is required';
                return;
            end
            
            obj.ValidationStatus = true;
            obj.ValidationMessage = 'Validation successful';
        end
        
        function status = isValid(obj)
            status = obj.ValidationStatus;
        end
        
        function message = getValidationMessage(obj)
            message = obj.ValidationMessage;
        end
    end
end