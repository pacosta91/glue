classdef Miscellaneous_Channel < Channel
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
        
        function obj = Miscellaneous_Channel(parent, name, type, units, streamingdata, index)
            obj = obj@Channel(parent, name, type, units, index);
            obj.StreamingData = streamingdata;
        end
        
        function [sConvertedData, mConvertedData, pConvertedData] = Convert(obj, NewUnit)
            global LM;
            if strcmp(obj.Name, 'Work')                        
                sConvertedData = unitConversion(obj.Type, obj.Name, obj.StreamingData, obj.Current_Units, NewUnit);
                mConvertedData = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData, obj.Current_Units, NewUnit);
                pConvertedData = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData, obj.Current_Units, NewUnit);                         
            else
                sConvertedData = obj.StreamingData;
                mConvertedData = obj.ModeCompositeData;
                pConvertedData = obj.PhaseCompositeData;
                LM.DebugPrint(1,'WARNING: Unit conversion for %s is not supported',obj.Name);
            end
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
            if strcmp(obj.Name, 'Work')
                for k = 1:ModeSegregation.nModes
                    obj.ModeCompositeData(k) = sum((obj.StreamingData(ModeSegregation.getModeIndices(k)==1)>=0).*obj.StreamingData(ModeSegregation.getModeIndices(k)==1));
                end
            elseif instr(obj.Name, 'Fuel') && strcmp(obj.Current_Units, 'g') 
                for k = 1:ModeSegregation.nModes
                    obj.ModeCompositeData(k) = sum(obj.StreamingData(ModeSegregation.getModeIndices(k)==1));
                end
            elseif instr(obj.Name, 'Time')
                for k = 1:ModeSegregation.nModes
                    obj.ModeCompositeData(k) = sum(ModeSegregation.getModeIndices(k))*obj.Parent('Options').delta_T;
                end
            elseif instr(obj.Name, 'Modal_Weights')
                obj.ModeCompositeData = obj.StreamingData;
                obj.StreamingData = zeros(size(obj.Parent('Time').StreamingData));
                for k = 1:ModeSegregation.nModes
                    obj.StreamingData = obj.StreamingData+ModeSegregation.getModeIndices(k)*obj.ModeCompositeData(k);
                end
            else
                for k = 1:ModeSegregation.nModes
                    obj.ModeCompositeData(k) = mean(obj.StreamingData(ModeSegregation.getModeIndices(k)==1));
                end
            end
        end
        
    end
end