classdef Pressure_Channel < Channel
    properties
% Properties Inherited from Channel
%         Name
%         Type
%         IsOn
%         Import_Index
%         Import_Units
%         Current_Units
%         Export_Index
%         Export_Units
%         StreamingData
%         ModeCompositeData
%         PhaseCompositeData
    end
    
    methods
        
        function obj = Pressure_Channel(parent, name, type, units, streamingdata, index)
            obj = obj@Channel(parent, name, type, units, index);
            obj.StreamingData = streamingdata;
        end
        
        function [sConvertedData, mConvertedData, pConvertedData] = Convert(obj, NewUnit)
            % if strcmp(NewUnit,obj.Current_Units), return; end; % ES 3/13/2017: It doesn't matter if the units are the same       
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