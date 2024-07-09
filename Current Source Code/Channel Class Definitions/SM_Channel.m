classdef SM_Channel < Channel
    properties
% Properties Inherited from Channel
%         Name
%         Type
%         IsOn
%         Current_Units
%         StreamingData
%         ModeCompositeData
%         PhaseCompositeData
    end
    methods
        
        function obj = SM_Channel(parent, name, type, units, streamingdata, index)
            obj = obj@Channel(parent, name, type, units, index);
            obj.StreamingData = streamingdata;
        end
        
        function obj = Convert(obj, NewUnit)
        end
        
        function obj = ModalComposite(obj, ModeSegregation)
            obj.ModeCompositeData = zeros(ModeSegregation.nModes, 1);
            for k = 1:ModeSegregation.nModes 
                obj.ModeCompositeData(k) = mean(obj.StreamingData(ModeSegregation.getModeIndices(k)==1));
            end
        end
        
    end
end