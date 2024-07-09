classdef Channel < handle
    
    properties
        Parent
        Name
        Type
        IsOn
        Current_Units
        StreamingData
        ModeCompositeData
        PhaseCompositeData
        Index
        Exported = 0;
    end
    
    methods
        
        function obj = Channel(parent, name, type, import_units, index)
            obj.Parent = parent; %Parent is the channels collection object - this allows for other channels (and options) to be referenced inside any channel
            obj.Name = name;
            obj.Type = type;
            obj.Current_Units = import_units;
            obj.IsOn = 1;
            obj.Index = index;
            obj.StreamingData = [];
            obj.ModeCompositeData = [];
            obj.PhaseCompositeData = [];
        end
        
    end
    
    methods (Abstract)
        %{
        
        The following methods are useful for adjusting the data as needed - they are undefined here because definition would then require that all
        classes inheriting the Channel class to have these functions defined. This just isn't feasible for channels like INCA where units aren't
        known before translation. Thus making this a rather inadequate interface document. 
        
        Also it should be recognized that the Analyzer_Channel departs from these prototypes significantly.
        
        In the future these prototypes will be significantly different for all inheriting classes - for example Flow Channels will be able to receive
        the temperature and pressure of a particular flow in order to allow for standard/actual conversion.
        
        %}
        
        %{
        [sConverted, mConverted, pConverted] = Convert(obj, NewUnit) %Converts the data without changing any of the values internally, 
                                                                     %useful when performing a secondary calculation
                                                                     
        obj = ConvertChannel(obj, NewUnit) %Converts the data inside the channel, use this to convert the channel for everything moving forward
        
        ConvertedData = ConvertStreaming(obj,NewUnit) %Same as Convert, however, only operates on the streaming data
        
        ConvertedData = ConvertModeComposite(obj,NewUnit) %Same as Convert, however, only operates on the mode composite data
        
        ConvertedData = ConvertPhaseComposite(obj,NewUnit) %Same as Convert, however, only operates on the phase composite data
        %}
        
    end
end