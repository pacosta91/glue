classdef Mode < handle
    properties (SetAccess = private)
        nModes
        nPhases
        ModeIndices
        HillIndices
        PhaseIndices
    end
    methods
        function obj = Mode(modes, cycles, phases)
            global LM;
            % Create a vector comprised of zeros and ones corresponding to
            % mode changes. Note, though, that mode changes include cycle
            % and phase changes as well.
            ModeSeparator = logical(logical(diff(modes)) + logical(diff(cycles)) + logical(diff(phases)));
            PhaseSeparator = logical(diff(phases));
            
            % Calculate the number of distinct modes and phases. Note that
            % this is equal to the number of mode and phases changes plus
            % one.
            obj.nModes = sum(ModeSeparator)+1;            
            obj.nPhases = sum(PhaseSeparator)+1;            
            
            % Initialize the ModeIndices and PhaseIndices matrices
            obj.ModeIndices = zeros(length(modes),obj.nModes);
            obj.PhaseIndices = zeros(length(phases),obj.nPhases);
            
            % Popluate the ModeIndices matrix
            startIdx = [1; find(ModeSeparator == 1) + 1];
            endIdx = [find(ModeSeparator == 1); length(modes)];           
            for k = 1:obj.nModes, obj.ModeIndices(startIdx(k):endIdx(k),k) = 1; end
 
            % Popluate the PhaseIndices matrix
            startIdx = [1; find(PhaseSeparator == 1) + 1];
            endIdx = [find(PhaseSeparator == 1); length(phases)];
            for k = 1:obj.nPhases, obj.PhaseIndices(startIdx(k):endIdx(k),k) = 1; end 

            LM.DebugPrint(2, 'Detected %i modes of data', obj.nModes);
            LM.DebugPrint(2, 'Detected %i phases of data', obj.nPhases);
        end
        
        function obj = TrimToCycleLength(obj, datastream)
            global LM;
            % if ~isfield(datastream('Options'),'Test_Type'), return; end
            if ~any(strcmp_multiple({'NRTC','FTP','FTP75','WHTC','ETC','RMC','RMCNR'},datastream('Options').Test_Type)), return; end;
            TestDuration = length(datastream('Time').StreamingData);
            switch datastream('Options').Test_Type
                case 'NRTC',  CycleLength = 1238;
                case 'FTP',   CycleLength = 1200;
                case 'FTP75', CycleLength = 1874;
                case 'WHTC',  CycleLength = 1800;
                case 'ETC',   CycleLength = 1800;
                case 'RMC',   CycleLength = 2400;
                case 'RMCNR', CycleLength = 1800;
            end
            StartAtRow = find(datastream('Time').StreamingData==1); %Assumes that there will always be a time t=1
            Blocking = [zeros(StartAtRow-1,1); ones(CycleLength,1); zeros(TestDuration-CycleLength-StartAtRow+1,1)];
            BlockingOriginal = Blocking;
            for k = 1:obj.nModes
                IndexPositions = find(obj.ModeIndices(:,k)==1);
                if abs(sum(obj.ModeIndices(:,k))-CycleLength) > 60
                    LM.DebugPrint(1,['WARNING: There is a significant difference between the cycle length of this' ...
                        ' type of test and the cycle length actually used in this test it is likely that this test is incorrectly classified or that' ...
                        ' the cycle was prematurely ended']); 
                end
                if length(Blocking) == length(obj.ModeIndices(:,k))
                    obj.ModeIndices(:,k) = Blocking.*obj.ModeIndices(:,k);
                else
                    %Assume that the ModeIndices is always smaller than the
                    %Blocking
                    obj.ModeIndices(:,k) = Blocking(1:length(obj.ModeIndices(:,k))).*obj.ModeIndices(:,k);
                end
                Blocking = [zeros(IndexPositions(end),1); BlockingOriginal(1:length(BlockingOriginal)-IndexPositions(end))];
            end
            KeyRing = datastream.keys;
            ValidTestPoints = sum(obj.ModeIndices,2);
            for k = 1:length(KeyRing)
                if strcmp(KeyRing{k},'Options'), continue; end;
                if strcmp(datastream(KeyRing{k}).Type,'Analyzer')
                    %At this point in time the only streamins data for each analyzer is Part86Mass and Part86Concentration
                    tempChannel = datastream(KeyRing{k});
                    if ~isempty(tempChannel.StreamingData.Part86Concentration)
                        tempChannel.StreamingData.Part86Concentration = ...
                            tempChannel.StreamingData.Part86Concentration(ValidTestPoints==1);
                    end
                    if ~isempty(tempChannel.StreamingData.Part86Mass)
                        tempChannel.StreamingData.Part86Mass = tempChannel.StreamingData.Part86Mass(ValidTestPoints==1);
                    end
                    clear tempChannel;
                else
                    tempChannel = datastream(KeyRing{k});
                    tempChannel.StreamingData = tempChannel.StreamingData(ValidTestPoints==1);
                    clear tempChannel;
                end
            end
            TimeChannel = datastream('Time');
            for k = 1:length(datastream('Time').StreamingData) %Reprint Time
                TimeChannel.StreamingData(k) = k;
            end
        end
        
        function ind = getModeIndices(obj, Mode)
            ind = obj.ModeIndices(:,Mode);
        end

        function ind = getPhaseIndices(obj, Mode)
            ind = obj.PhaseIndices(:,Mode);
        end
        
    end
end