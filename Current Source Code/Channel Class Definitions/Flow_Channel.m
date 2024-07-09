classdef Flow_Channel < Channel
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
        function obj = Flow_Channel(parent, name, type, units, streamingdata, index)
            obj = obj@Channel(parent, name, type, units, index);
            obj.StreamingData = streamingdata;
        end

        function [sConvertedData, mConvertedData, pConvertedData] = Convert(obj, NewUnit)
            % Currently only conversions for channels already in standardized flow is supported.               
            sConvertedData = unitConversion(obj.Type, obj.Name, obj.StreamingData, obj.Current_Units, NewUnit);
            mConvertedData = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData, obj.Current_Units, NewUnit);
            pConvertedData = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData, obj.Current_Units, NewUnit);                
        end
        
        function ConvertedData = ConvertStreaming(obj,NewUnit)
            [ConvertedData, ~, ~] = obj.Convert(NewUnit);
        end
        
        function ConvertedData = ConvertModeComposite(obj,NewUnit)
            [~, ConvertedData, ~] = obj.Convert(NewUnit);
        end
        
        function ConvertedData = ConvertPhaseComposite(obj,NewUnit)
            [~, ~, ConvertedData] = obj.Convert(NewUnit);
        end
            
        function obj = ConvertChannel(obj, NewUnit)
            [obj.StreamingData, obj.ModeCompositeData, obj.PhaseCompositeData] = obj.Convert(NewUnit);
            obj.Current_Units = NewUnit;
        end
        
        function obj = ModalComposite(obj, ModeSegregation)
            obj.ModeCompositeData = zeros(ModeSegregation.nModes, 1);
            for k = 1:ModeSegregation.nModes 
                obj.ModeCompositeData(k) = mean(obj.StreamingData(ModeSegregation.getModeIndices(k)==1));
            end
        end
        
    end
end