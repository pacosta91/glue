classdef Analyzer_Channel < Channel
    properties
%{
        INHERITED PROPERTIES

        Name
        Type
        IsOn
        Current_Units -> Becomes a cell array Current_Units{1} (Concentration Units), Current_Units{2} (Mass Units), Current_Units{3} (Brake-Specific Mass Units)

        StreamingData ->EXPANDED STRUCTURE
        -----------------------------------------------------------------
        StreamingData.Concentration                   [NoVZS_Correction]
        StreamingData.Part86Concentration             [ECCS_PreTestVZS_Correction]
        StreamingData.Part1065Concentration           [PreAndPostTestVZS_Correction]
        StreamingData.Mass                            [Part1065Calculation_NoVZS_Correction]
        StreamingData.Part86Mass                      [ECCS_PreTestVZS_Correction]
        StreamingData.Part1065Mass                    [Part1065Calculation_PreAndPostTestVZS_Correction]

        ModeCompositeData ->EXPANDED STRUCTURE
        -----------------------------------------------------------------
        ModeCompositeData.Concentration               [NoVZS_Correction]
        ModeCompositeData.Part86Concentration         [ECCS_PreTestVZS_Correction]
        ModeCompositeData.Part1065Concentration       [PreAndPostTestVZS_Correction]
        ModeCompositeData.Mass                        [Part1065Calculation_NoVZS_Correction]
        ModeCompositeData.Part86Mass                  [ECCS_PreTestVZS_Correction]
        ModeCompositeData.Part1065Mass                [Part1065Calculation_PreAndPostTestVZS_Correction]
        ModeCompositeData.BrakeSpecificMass           [Part1065Calculation_NoVZS_Correction]
        ModeCompositeData.MassPerMile                 [Where appropiate - not currently supported]
        ModeCompositeData.Part86BrakeSpecificMass     [ECCS_PreTestVZS_Correction]
        ModeCompositeData.Part86MassPerMile           [Where appropiate - not currently supported]
        ModeCompositeData.Part1065BrakeSpecificMass   [Part1065Calculation_PreAndPostTestVZS_Correction]
        ModeCompositeData.Part1065MassPerMile         [Where appropiate - not currently supported]

        PhaseCompositeData ->EXPANDED STRUCTURE
        -----------------------------------------------------------------
        PhaseCompositeData.Concentration               [NoVZS_Correction]
        PhaseCompositeData.Part86Concentration         [ECCS_PreTestVZS_Correction]
        PhaseCompositeData.Part1065Concentration       [PreAndPostTestVZS_Correction]
        PhaseCompositeData.Mass                        [Part1065Calculation_NoVZS_Correction]
        PhaseCompositeData.Part86Mass                  [ECCS_PreTestVZS_Correction]
        PhaseCompositeData.Part1065Mass                [Part1065Calculation_PreAndPostTestVZS_Correction]
        PhaseCompositeData.BrakeSpecificMass           [Part1065Calculation_NoVZS_Correction]
        PhaseCompositeData.MassPerMile                 [Where appropiate - not currently supported]
        PhaseCompositeData.Part86BrakeSpecificMass     [ECCS_PreTestVZS_Correction]
        PhaseCompositeData.Part86MassPerMile           [Where appropiate - not currently supported]
        PhaseCompositeData.Part1065BrakeSpecificMass   [Part1065Calculation_PreAndPostTestVZS_Correction]
        PhaseCompositeData.Part1065MassPerMile         [Where appropiate - not currently supported]
%}
        VZS
%{
        VZS(Range).MaximumConcentration       #FROM DATABASE
        VZS(Range).ReferenceZero              #FROM DATABASE
        VZS(Range).ReferenceConcentration     #FROM DATABASE
        VZS(Range).RawPreTestZero             #FROM DATABASE
        VZS(Range).RawPreTestSpan             #FROM DATABASE
        VZS(Range).RawPostTestZero            #CALCULATED - USED IN APPLYING 1065 DRIFT CORRECTIONS
        VZS(Range).RawPostTestSpan            #CALCULATED - USED IN APPLYING 1065 DRIFT CORRECTIONS
        VZS(Range).CorrectedPreTestZeroCheck  #FROM DATABASE - USED IN APPLYING HC/NMHC/CH4 CORRECTIONS FROM PART 1065.660
        VZS(Range).CorrectedPostTestZero      #FROM DATABASE
        VZS(Range).CorrectedPostTestSpan      #FROM DATABASE
%}
        Ambient
%{
        Ambient.PreTest                       #CALCULATED
        Ambient.PostTest                      #CALCULATED
        Ambient.Average                       #CALCULATED
        Ambient.Part86PreTest                 #FROM DATABASE
        Ambient.Part86PostTest                #FROM DATABASE
        Ambient.Part86Average                 #CALCULATED
        Ambient.Part1065PreTest               #CALCULATED
        Ambient.Part1065PostTest              #CALCULATED
        Ambient.Part1065Average               #CALCULATED
%}
        Ranges

    end
    methods
        function obj = Analyzer_Channel(parent, name, type, units, index)
            obj = obj@Channel(parent, name, type, units, index);
            obj.Current_Units = cell(1,3);
            switch units
                case 'ppm'
                    obj.Current_Units{1} = units;
                case '%'
                    obj.Current_Units{1} = units;
                case 'g'
                    obj.Current_Units{2} = units;
            end
            obj.IsOn = 1;
            obj.VZS = containers.Map('KeyType','double','ValueType','any');
            obj.StreamingData.Concentration = [];
            obj.StreamingData.Part86Concentration = [];
            obj.StreamingData.Part1065Concentration = [];
            obj.StreamingData.Mass = [];
            obj.StreamingData.Part86Mass = [];
            obj.StreamingData.Part1065Mass = [];
            obj.ModeCompositeData.Concentration = [];
            obj.ModeCompositeData.Part86Concentration = [];
            obj.ModeCompositeData.Part1065Concentration = [];
            obj.ModeCompositeData.Mass = [];
            obj.ModeCompositeData.Part86Mass = [];
            obj.ModeCompositeData.Part1065Mass = [];
            obj.ModeCompositeData.BrakeSpecificMass = [];
            obj.ModeCompositeData.Part86BrakeSpecificMass = [];
            obj.ModeCompositeData.Part1065BrakeSpecificMass = [];
            obj.PhaseCompositeData.Concentration = [];
            obj.PhaseCompositeData.Part86Concentration = [];
            obj.PhaseCompositeData.Part1065Concentration = [];
            obj.PhaseCompositeData.Mass = [];
            obj.PhaseCompositeData.Part86Mass = [];
            obj.PhaseCompositeData.Part1065Mass = [];
            obj.PhaseCompositeData.BrakeSpecificMass = [];
            obj.PhaseCompositeData.Part86BrakeSpecificMass = [];
            obj.PhaseCompositeData.Part1065BrakeSpecificMass = [];
        end

        function obj = CorrectVZS(obj, ModeSegregation)
            obj.StreamingData.Concentration = zeros(size(obj.StreamingData.Part86Concentration));
            obj.StreamingData.Part1065Concentration = zeros(size(obj.StreamingData.Part86Concentration));
            for k = 1:ModeSegregation.nModes
                if length(obj.Ranges) >= k && isfield(obj.VZS(obj.Ranges(k)),'RawPostTestZero') % ES - changed from: if isfield(obj.VZS(obj.Ranges(k)),'RawPostTestZero')
                    AverageZero = (obj.VZS(obj.Ranges(k)).RawPreTestZero+obj.VZS(obj.Ranges(k)).RawPostTestZero)/2;
                    AverageSpan = (obj.VZS(obj.Ranges(k)).RawPreTestSpan+obj.VZS(obj.Ranges(k)).RawPostTestSpan)/2;
                    obj.StreamingData.Concentration = ((obj.StreamingData.Part86Concentration-obj.VZS(obj.Ranges(k)).ReferenceZero)/ ...
                        (obj.VZS(obj.Ranges(k)).ReferenceConcentration-obj.VZS(obj.Ranges(k)).ReferenceZero)*(obj.VZS(obj.Ranges(k)).RawPreTestSpan- ...
                        obj.VZS(obj.Ranges(k)).RawPreTestZero)+obj.VZS(obj.Ranges(k)).RawPreTestZero).*ModeSegregation.getModeIndices(k)+ ...
                        obj.StreamingData.Concentration;
                    obj.StreamingData.Part1065Concentration = (obj.VZS(obj.Ranges(k)).ReferenceZero+(obj.VZS(obj.Ranges(k)).ReferenceConcentration- ...
                        obj.VZS(obj.Ranges(k)).ReferenceZero)*(obj.StreamingData.Concentration-AverageZero)/(AverageSpan-AverageZero)).* ...
                        ModeSegregation.getModeIndices(k)+obj.StreamingData.Part1065Concentration;
                end
            end
        end

        function convertedData = ConvertStreaming(obj, NewUnit, DataSetToConvert)
            % This returns only one single value
            if instr(DataSetToConvert, 'Concentration')
                [StreamingData, ~, ~] = obj.Convert(NewUnit, 'Concentration');
                convertedData = StreamingData.(DataSetToConvert);
            elseif instr(DataSetToConvert, 'BrakeSpecific')
                [StreamingData, ~, ~] = obj.Convert(NewUnit, 'BrakeSpecificMass');
                convertedData = StreamingData.(DataSetToConvert);
            else %Assumed Mass
                [StreamingData, ~, ~] = obj.Convert(NewUnit, 'Mass');
                convertedData = StreamingData.(DataSetToConvert);
            end
        end

        function convertedData = ConvertModeComposite(obj, NewUnit, DataSetToConvert)
            % This returns only one single value
            if instr(DataSetToConvert, 'Concentration')
                [~, ModeCompositeData, ~] = obj.Convert(NewUnit, 'Concentration');
                convertedData = ModeCompositeData.(DataSetToConvert);
            elseif instr(DataSetToConvert, 'BrakeSpecific')
                [~, ModeCompositeData, ~] = obj.Convert(NewUnit, 'BrakeSpecificMass');
                convertedData = ModeCompositeData.(DataSetToConvert);
            else %Assumed Mass
                [~, ModeCompositeData, ~] = obj.Convert(NewUnit, 'Mass');
                convertedData = ModeCompositeData.(DataSetToConvert);
            end
        end

        function convertedData = ConvertPhaseComposite(obj, NewUnit, DataSetToConvert)
            % This returns only one single value
            if instr(DataSetToConvert, 'Concentration')
                [~, ~, PhaseCompositeData] = obj.Convert(NewUnit, 'Concentration');
                convertedData = PhaseCompositeData.(DataSetToConvert);
            elseif instr(DataSetToConvert, 'BrakeSpecific')
                [~, ~, PhaseCompositeData] = obj.Convert(NewUnit, 'BrakeSpecificMass');
                convertedData = PhaseCompositeData.(DataSetToConvert);
            else %Assumed Mass
                [~, ~, PhaseCompositeData] = obj.Convert(NewUnit, 'Mass');
                convertedData = PhaseCompositeData.(DataSetToConvert);
            end
        end

        function obj = ConvertChannel(obj, NewUnit, DataSetToConvert)
            [StreamingData, ModeCompositeData, PhaseCompositeData] = obj.Convert(NewUnit, DataSetToConvert);
            switch DataSetToConvert %Maintainer, this method prevents the accidental deletion of data. Alter at your own risk.
                case 'Concentration'
                    obj.Current_Units{1} = NewUnit;
                    obj.StreamingData.Concentration = StreamingData.Concentration;
                    obj.StreamingData.Part86Concentration = StreamingData.Part86Concentration;
                    obj.StreamingData.Part1065Concentration = StreamingData.Part1065Concentration;
                    obj.ModeCompositeData.Concentration = ModeCompositeData.Concentration;
                    obj.ModeCompositeData.Part86Concentration = ModeCompositeData.Part86Concentration;
                    obj.ModeCompositeData.Part1065Concentration = ModeCompositeData.Part1065Concentration;
                    obj.PhaseCompositeData.Concentration = PhaseCompositeData.Concentration;
                    obj.PhaseCompositeData.Part86Concentration = PhaseCompositeData.Part86Concentration;
                    obj.PhaseCompositeData.Part1065Concentration = PhaseCompositeData.Part1065Concentration;
                case 'Mass'
                    obj.Current_Units{2} = NewUnit;
                    obj.StreamingData.Mass = StreamingData.Mass;
                    obj.StreamingData.Part86Mass = StreamingData.Part86Mass;
                    obj.StreamingData.Part1065Mass = StreamingData.Part1065Mass;
                    obj.ModeCompositeData.Mass = ModeCompositeData.Mass;
                    obj.ModeCompositeData.Part86Mass = ModeCompositeData.Part86Mass;
                    obj.ModeCompositeData.Part1065Mass = ModeCompositeData.Part1065Mass;
                    obj.PhaseCompositeData.Mass = PhaseCompositeData.Mass;
                    obj.PhaseCompositeData.Part86Mass = PhaseCompositeData.Part86Mass;
                    obj.PhaseCompositeData.Part1065Mass = PhaseCompositeData.Part1065Mass;
                case 'BrakeSpecificMass'
                    obj.Current_Units{3} = NewUnit;
                    obj.ModeCompositeData.BrakeSpecificMass = ModeCompositeData.BrakeSpecificMass;
                    obj.ModeCompositeData.Part86BrakeSpecificMass = ModeCompositeData.Part86BrakeSpecificMass;
                    obj.ModeCompositeData.Part1065BrakeSpecificMass = ModeCompositeData.Part1065BrakeSpecificMass;
                    obj.PhaseCompositeData.BrakeSpecificMass = PhaseCompositeData.BrakeSpecificMass;
                    obj.PhaseCompositeData.Part86BrakeSpecificMass = PhaseCompositeData.Part86BrakeSpecificMass;
                    obj.PhaseCompositeData.Part1065BrakeSpecificMass = PhaseCompositeData.Part1065BrakeSpecificMass;
            end
        end

        function [sConvertedData, mConvertedData, pConvertedData] = Convert(obj, NewUnit, DataSetToConvert)
            % This will return sConvertedData, mConvertedData, and pConvertedData as a structure.
            switch DataSetToConvert
                case 'Concentration'
                    sConvertedData.Concentration = unitConversion(obj.Type, obj.Name, obj.StreamingData.Concentration, obj.Current_Units{1}, NewUnit);
                    sConvertedData.Part86Concentration = unitConversion(obj.Type, obj.Name, obj.StreamingData.Part86Concentration, obj.Current_Units{1}, NewUnit);
                    sConvertedData.Part1065Concentration = unitConversion(obj.Type, obj.Name, obj.StreamingData.Part1065Concentration, obj.Current_Units{1}, NewUnit);
                    mConvertedData.Concentration = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Concentration, obj.Current_Units{1}, NewUnit);
                    mConvertedData.Part86Concentration = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Part86Concentration, obj.Current_Units{1}, NewUnit);
                    mConvertedData.Part1065Concentration = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Part1065Concentration, obj.Current_Units{1}, NewUnit);
                    pConvertedData.Concentration = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData.Concentration, obj.Current_Units{1}, NewUnit);
                    pConvertedData.Part86Concentration = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData.Part86Concentration, obj.Current_Units{1}, NewUnit);
                    pConvertedData.Part1065Concentration = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData.Part1065Concentration, obj.Current_Units{1}, NewUnit);
                case 'Mass'
                    sConvertedData.Mass = unitConversion(obj.Type, obj.Name, obj.StreamingData.Mass, obj.Current_Units{2}, NewUnit);
                    sConvertedData.Part86Mass = unitConversion(obj.Type, obj.Name, obj.StreamingData.Part86Mass, obj.Current_Units{2}, NewUnit);
                    sConvertedData.Part1065Mass = unitConversion(obj.Type, obj.Name, obj.StreamingData.Part1065Mass, obj.Current_Units{2}, NewUnit);
                    mConvertedData.Mass = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Mass, obj.Current_Units{2}, NewUnit);
                    mConvertedData.Part86Mass = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Part86Mass, obj.Current_Units{2}, NewUnit);
                    mConvertedData.Part1065Mass = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Part1065Mass, obj.Current_Units{2}, NewUnit);
                    pConvertedData.Mass = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData.Mass, obj.Current_Units{2}, NewUnit);
                    pConvertedData.Part86Mass = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData.Part86Mass, obj.Current_Units{2}, NewUnit);
                    pConvertedData.Part1065Mass = unitConversion(obj.Type, obj.Name, obj.PhaseCompositeData.Part1065Mass, obj.Current_Units{2}, NewUnit);
                case 'BrakeSpecificMass'
                    CurrentUnits = stringread(obj.Current_Units{3},'/'); %This is a little more flexible
                    NewUnits =  stringread(NewUnit,'/');
                    sConvertedData = 0;

                    % Mass
                    sConvertedData.Mass = unitConversion(obj.Type, obj.Name, obj.StreamingData.Mass, Current_Units{1}, NewUnits{1});
                    sConvertedData.Part86Mass = unitConversion(obj.Type, obj.Name, obj.StreamingData.Part86Mass, Current_Units{1}, NewUnits{1});
                    sConvertedData.Part1065Mass = unitConversion(obj.Type, obj.Name, obj.StreamingData.Part1065Mass, Current_Units{1}, NewUnits{1});
                    mConvertedData.Mass = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Mass, Current_Units{1}, NewUnits{1});
                    mConvertedData.Part86Mass = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Part86Mass, Current_Units{1}, NewUnits{1});
                    mConvertedData.Part1065Mass = unitConversion(obj.Type, obj.Name, obj.ModeCompositeData.Part1065Mass, Current_Units{1}, NewUnits{1});

                    % Brake Specific Mass
                    mConvertedData.BrakeSpecificMass = unitConversion(obj.Type, obj.Name, mConvertedData.BrakeSpecificMass, CurrentUnits{2}, NewUnits{1});
                    mConvertedData.Part86BrakeSpecificMass = unitConversion(obj.Type, obj.Name, mConvertedData.Part86BrakeSpecificMass, CurrentUnits{2}, NewUnits{1});
                    mConvertedData.Part1065BrakeSpecificMass = unitConversion(obj.Type, obj.Name, mConvertedData.Part1065BrakeSpecificMass, CurrentUnits{2}, NewUnits{1});
                    pConvertedData.BrakeSpecificMass = unitConversion(obj.Type, obj.Name, pConvertedData.BrakeSpecificMass, CurrentUnits{2}, NewUnits{1});
                    pConvertedData.Part86BrakeSpecificMass = unitConversion(obj.Type, obj.Name, pConvertedData.Part86BrakeSpecificMass, CurrentUnits{2}, NewUnits{1});
                    pConvertedData.Part1065BrakeSpecificMass = unitConversion(obj.Type, obj.Name, pConvertedData.Part1065BrakeSpecificMass, CurrentUnits{2}, NewUnits{1});

                    % Work
                    mConvertedData.BrakeSpecificMass = unitConversion(obj.Type, obj.Name, mConvertedData.BrakeSpecificMass, CurrentUnits{2}, NewUnits{2});
                    mConvertedData.Part86BrakeSpecificMass = unitConversion(obj.Type, obj.Name, mConvertedData.Part86BrakeSpecificMass, CurrentUnits{2}, NewUnits{2});
                    mConvertedData.Part1065BrakeSpecificMass = unitConversion(obj.Type, obj.Name, mConvertedData.Part1065BrakeSpecificMass, CurrentUnits{2}, NewUnits{2});
                    pConvertedData.BrakeSpecificMass = unitConversion(obj.Type, obj.Name, pConvertedData.BrakeSpecificMass, CurrentUnits{2}, NewUnits{2});
                    pConvertedData.Part86BrakeSpecificMass = unitConversion(obj.Type, obj.Name, pConvertedData.Part86BrakeSpecificMass, CurrentUnits{2}, NewUnits{2});
                    pConvertedData.Part1065BrakeSpecificMass = unitConversion(obj.Type, obj.Name, pConvertedData.Part1065BrakeSpecificMass, CurrentUnits{2}, NewUnits{2});
            end
        end

        function obj = ModalComposite(obj, ModeSegregation)
            if ~isempty(obj.StreamingData.Concentration)
                obj.ModeCompositeData.Concentration = zeros(ModeSegregation.nModes, 1);
            end
            if ~isempty(obj.StreamingData.Part86Concentration)
                obj.ModeCompositeData.Part86Concentration = zeros(ModeSegregation.nModes, 1);
            end
            if ~isempty(obj.StreamingData.Part1065Concentration)
                obj.ModeCompositeData.Part1065Concentration = zeros(ModeSegregation.nModes, 1);
            end
            if ~isempty(obj.StreamingData.Mass)
                obj.ModeCompositeData.Mass = zeros(ModeSegregation.nModes, 1);
                obj.ModeCompositeData.BrakeSpecificMass = zeros(ModeSegregation.nModes, 1);
            end
            if ~isempty(obj.StreamingData.Part86Mass)
                obj.ModeCompositeData.Part86Mass = zeros(ModeSegregation.nModes, 1);
                obj.ModeCompositeData.Part86BrakeSpecificMass = zeros(ModeSegregation.nModes, 1);
            end
            if ~isempty(obj.StreamingData.Part1065Mass)
                obj.ModeCompositeData.Part1065Mass = zeros(ModeSegregation.nModes, 1);
                obj.ModeCompositeData.Part1065BrakeSpecificMass = zeros(ModeSegregation.nModes, 1);
            end
            
            Work = obj.Parent('Work').ConvertStreaming('kW.hr'); % ECCS computes work as the average work over 10Hz - this conversion is necessary
            obj.Current_Units{3} = 'g/kW.hr';
            
            % Convert Negative Work values to 0 
            Work = Work.*(Work>=0);
            
            for k = 1:ModeSegregation.nModes
                if ~isempty(obj.StreamingData.Concentration)
                    obj.ModeCompositeData.Concentration(k) = mean(obj.StreamingData.Concentration(ModeSegregation.getModeIndices(k)==1));
                end
                if ~isempty(obj.StreamingData.Part86Concentration)
                    obj.ModeCompositeData.Part86Concentration(k) = mean(obj.StreamingData.Part86Concentration(ModeSegregation.getModeIndices(k)==1));
                end
                if ~isempty(obj.StreamingData.Part1065Concentration)
                    obj.ModeCompositeData.Part1065Concentration(k) = mean(obj.StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(k)==1));
                end
                if ~isempty(obj.StreamingData.Mass)
                    obj.ModeCompositeData.Mass(k) = sum(obj.StreamingData.Mass(ModeSegregation.getModeIndices(k)==1));
                    obj.ModeCompositeData.BrakeSpecificMass(k) = sum(obj.StreamingData.Mass(ModeSegregation.getModeIndices(k)==1))/sum(Work(ModeSegregation.getModeIndices(k)==1));
                end
                if ~isempty(obj.StreamingData.Part86Mass)
                    obj.ModeCompositeData.Part86Mass(k) = sum(obj.StreamingData.Part86Mass(ModeSegregation.getModeIndices(k)==1));
                    obj.ModeCompositeData.Part86BrakeSpecificMass(k) = sum(obj.StreamingData.Part86Mass(ModeSegregation.getModeIndices(k)==1))/sum(Work(ModeSegregation.getModeIndices(k)==1));
                end
                if ~isempty(obj.StreamingData.Part1065Mass)
                    obj.ModeCompositeData.Part1065Mass(k) = sum(obj.StreamingData.Part1065Mass(ModeSegregation.getModeIndices(k)==1));
                    obj.ModeCompositeData.Part1065BrakeSpecificMass(k) = sum(obj.StreamingData.Part1065Mass(ModeSegregation.getModeIndices(k)==1))/sum(Work(ModeSegregation.getModeIndices(k)==1));
                end
            end
        end

    end
end
