classdef (Abstract) InstrumentFactory
    methods (Abstract)
        instrument = createInstrument(obj, varargin); 
    end
end