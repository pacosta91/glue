classdef Channels < containers.Map
    %#ok<*AGROW>
    methods

        function obj = CorrectVZS(obj, ModeSegregation)
             for k = 1:length(obj.values)
                if strcmp(obj.keys{k},'Options'), continue; end; %I'm pretty comfortable with this but it isn't documented that the key index will always correspond with the value index
                if strcmp(obj.values{k}.Type,'Analyzer') && obj.values{k}.IsOn
                    obj.values{k}.CorrectVZS(ModeSegregation);
                end
             end
        end

        function obj = PerformComposite(obj, ModeSegregation)
            for k = 1:length(obj.values)
                if strcmp(obj.keys{k},'Options'), continue; end;
                obj.values{k}.ModalComposite(ModeSegregation);
                % obj.values{k}.PhaseComposite(ModeSegregation);
            end
        end

        function sortedValues = Sort(obj)
            for k = 1:length(obj.values)
                if strcmp(obj.keys{k},'Options'), continue; end;
                if obj.values{k}.Index == 0, continue; end;
                sortedValues{obj.values{k}.Index} = obj.values{k};
            end
        end

%         function obj = TimeAlign(obj)
%         end

%         function obj = Translate(obj, TranslationFile)
%         end

        function [CArray, HeaderTable, EmissionsTable, BSFCTable, PMTable, AmbientTable, VZSTable, DriftTable, saveasNamec, saveasNames] = MakeReports(obj, ModeSegregation, pathname)
            global LOCALPATH FILENAME;
            StreamingArray = obj.MakeStreamingArray();
            CArray = obj.MakeCompositeArray(ModeSegregation);
            HeaderTable = obj.MakeHeaderTable();
            EmissionsTable = obj.MakeEmissionsTable();
            BSFCTable = obj.MakeBSFCTable();
            PMTable = obj.MakePMTable(ModeSegregation);
            CustomerDefinedTables = obj.MakeCustomerDefinedTables();
            AmbientTable = obj.MakeAmbientTable();
            VZSTable = obj.MakeVZSTable();
            DriftTable = obj.MakeDriftTable();
            for m = 1:length(obj.Values('Work').ModeCompositeData)
                if obj.Values('Work').ModeCompositeData(m) == 0
                    if obj.Values('Options').Part_1065.IsOn
                        for k = 7:size(EmissionsTable,2)
                            EmissionsTable{m+1,k} = '-';
                        end
                    else
                        for k = 6:size(EmissionsTable,2)
                            EmissionsTable{m+1,k} = '-';
                        end
                    end
                    for k = 4:6
                        BSFCTable{m+1,k} = '-';
                    end
                    for k = 2:size(DriftTable,2)
                        DriftTable{m+1,k} = '-';
                    end
                end
            end
            CompositeArray = obj.MergeTables(CArray, HeaderTable, EmissionsTable, BSFCTable, PMTable, CustomerDefinedTables, AmbientTable, VZSTable, DriftTable);

            % Determine the file name and path for the _Composite.xlsx and
            % _Streaming.xlsx files.
            if strcmp(obj.Values('Options').Option_Panel,'Network')
                saveasNamec = strcat(pathname,left(FILENAME, length(FILENAME)-4),'_Composite.xlsx');
                saveasNames = strcat(pathname,left(FILENAME, length(FILENAME)-4),'_Streaming.xlsx');
                thispath = pathname; %#ok
            else
                saveasNamec = [LOCALPATH '\Test Results\' left(FILENAME, length(FILENAME)-4) '_Composite.xlsx'];
                saveasNames = [LOCALPATH '\Test Results\' left(FILENAME, length(FILENAME)-4) '_Streaming.xlsx'];
                thispath = LOCALPATH; %#ok
            end

            % Determine the version to save
            count = 1;
            while exist(saveasNamec,'file') || exist(saveasNames,'file')
                % [thispath, ~, ~] = fileparts(saveasNamec);
                saveasNamec = strcat(thispath,'\',left(FILENAME, length(FILENAME)-4),'_Composite(',num2str(count),').xlsx');
                saveasNames = strcat(thispath,'\',left(FILENAME, length(FILENAME)-4),'_Streaming(',num2str(count),').xlsx');
                count = count + 1;
            end

            fileexists = 2;
            if strcmp(obj.Values('Options').Change_File_Location,'SilenceNo')
                fileexists = 0;
            elseif strcmp(obj.Values('Options').Change_File_Location,'SilenceYes')
                fileexists = 1;
            else
                while ~any(fileexists == 0:1)
                    if fileexists~=2
                        disp('I didn''t understand your input please try again.\n');
                    end
                    fileexists = input('Would you like to select a different location to save the results files? Enter 1 for yes; 0 for no:\n');
                    if fileexists == -1; keyboard; end;
                    if fileexists == -2; return; end; %exit without producing report
                end
            end
            if fileexists, fileexists=fileexists+2; end
            while fileexists
                if fileexists~=3, disp('A file with that name already exists, please change your file name'); end
                [~, pathnameC] = uiputfile({'*.xlsx'},'Save Results To...',saveasNamec);
                saveasNamec = [pathnameC left(FILENAME, length(FILENAME)-4),'_Composite.xlsx'];
                saveasNames = [pathnameC left(FILENAME, length(FILENAME)-4),'_Streaming.xlsx'];
                count = 1;
                while exist(saveasNamec,'file') || exist(saveasNames,'file')
                    [thispath, ~, ~] = fileparts(saveasNamec);
                    saveasNamec = strcat(thispath,'\',left(FILENAME, length(FILENAME)-4),'_Composite(',num2str(count),').xlsx');
                    saveasNames = strcat(thispath,'\',left(FILENAME, length(FILENAME)-4),'_Streaming(',num2str(count),').xlsx');
                    count = count + 1;
                end
                fileexists = exist(saveasNamec, 'file')+exist(saveasNames, 'file');
            end

%             try
%                 compositeWrite = xlswc(saveasNamec,'Vertical',CompositeArray,{});
%                 streamingWrite = xlswc(saveasNames,'Vertical',StreamingArray,{});
%             catch
%             end
%
            xlswc(saveasNamec,'Vertical',CompositeArray,{});
            maxIterations = 60; iterations = 0;
            while iterations < maxIterations
                iterations = iterations + 1;
                try
                    xlswc(saveasNames,'Vertical',StreamingArray,{});
                    pause(1);
                    break; % A mite hackish but this should allow matlab to catchup after writing the composite.
                catch %#ok
                end

            end
        end

        function obj = CalculateInstantaneousBSFC(obj)

            if obj.isKey('Q_Fuel_Mass_C')
                StreamingData = obj.Values('Q_Fuel_Mass_C').StreamingData./(3.6*obj.Values('Work').StreamingData);
                ModeCompositeData = obj.Values('Q_Fuel_Mass_C').ModeCompositeData./(3.6*obj.Values('Work').ModeCompositeData).*obj.Values('Time').ModeCompositeData;
            else
                StreamingData = nan(size(obj.Values('Time').StreamingData));
                ModeCompositeData = nan(size(obj.Values('Time').ModeCompositeData));
            end
            if obj.isKey('BSFC_Fuel')
                obj.Values('BSFC_Fuel').StreamingData = StreamingData;
                obj.Values('BSFC_Fuel').ModeCompositeData = ModeCompositeData;
            else
                tempChannel = Miscellaneous_Channel(obj, 'BSFC_Fuel', 'Miscellaneous', 'g/kW.hr', StreamingData, 0);
                tempChannel.ModeCompositeData = ModeCompositeData;
                obj = AddChannel(obj, 'BSFC_Fuel', tempChannel);
            end

            if obj.isKey('Fuel_CB')
                StreamingData = obj.Values('Fuel_CB').StreamingData./(obj.Values('Work').StreamingData);
                ModeCompositeData = obj.Values('Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData);
            else
                StreamingData = nan(size(obj.Values('Time').StreamingData));
                ModeCompositeData = nan(size(obj.Values('Time').ModeCompositeData));
            end
            if obj.isKey('BSFC_CB')
                obj.Values('BSFC_CB').StreamingData = StreamingData;
                obj.Values('BSFC_CB').ModeCompositeData = ModeCompositeData;
            else
                tempChannel = Miscellaneous_Channel(obj, 'BSFC_CB', 'Miscellaneous', 'g/kW.hr', StreamingData, 0);
                tempChannel.ModeCompositeData = ModeCompositeData;
                obj = AddChannel(obj, 'BSFC_CB', tempChannel);
            end

            if obj.isKey('MF_Fuel_CB')
                StreamingData = obj.Values('MF_Fuel_CB').StreamingData./(obj.Values('Work').StreamingData);
                ModeCompositeData = obj.Values('MF_Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData);
            else
                StreamingData = nan(size(obj.Values('Time').StreamingData));
                ModeCompositeData = nan(size(obj.Values('Time').ModeCompositeData));
            end
            if obj.isKey('MF_BSFC_CB')
                obj.Values('MF_BSFC_CB').StreamingData = StreamingData;
                obj.Values('MF_BSFC_CB').ModeCompositeData = ModeCompositeData;
            else
                tempChannel = Miscellaneous_Channel(obj, 'MF_BSFC_CB', 'Miscellaneous', 'g/kW.hr', StreamingData, 0);
                tempChannel.ModeCompositeData = ModeCompositeData;
                obj = AddChannel(obj, 'MF_BSFC_CB', tempChannel);
            end

        end

        function obj = MakeNANChannels(obj)
            global LOCALPATH;
            if strcmp(obj.Values('Options').Option_Panel,'Network')
                fid = fopen([obj.Values('Options').Network_Path 'Settings Files\Standard Channel List.txt']);
            else
                fid = fopen([LOCALPATH '\Settings Files\Standard Channel List.txt']);
            end
            while ~feof(fid)
                DataMill = stringread(fgetl(fid),',');
                [name, units] = obj.Segregate(DataMill{1});
                if length(DataMill)==1
                    sname = ProcessChannelNameb(name);
                    if ~obj.isKey(sname)
                        if strcmp(sname, 'Mode_Duration')
                            %Do Nothing - Mode Duration is not a Channel
                            continue;
                        elseif instr(name, 'Bench')
                            clear StreamingData ModeCompositeData;
                            StreamingData.Concentration = nan(size(obj.Values('Time').StreamingData));
                            StreamingData.Part86Concentration = nan(size(obj.Values('Time').StreamingData));
                            StreamingData.Part1065Concentration = nan(size(obj.Values('Time').StreamingData));
                            StreamingData.Mass = nan(size(obj.Values('Time').StreamingData));
                            StreamingData.Part86Mass = nan(size(obj.Values('Time').StreamingData));
                            StreamingData.Part1065Mass = nan(size(obj.Values('Time').StreamingData));
                            ModeCompositeData.Concentration = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part86Concentration = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part1065Concentration = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Mass = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part86Mass = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part1065Mass = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.BrakeSpecificMass = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.MassPerMile = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part86BrakeSpecificMass = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part86MassPerMile = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part1065BrakeSpecificMass = nan(size(obj.Values('Time').ModeCompositeData));
                            ModeCompositeData.Part1065MassPerMile = nan(size(obj.Values('Time').ModeCompositeData));
                            tempChannel = Analyzer_Channel(obj, name, 'Analyzer', units, 0);
                            tempChannel.StreamingData = StreamingData;
                            tempChannel.ModeCompositeData = ModeCompositeData;
                        else
                            StreamingData = nan(size(obj.Values('Time').StreamingData));
                            ModeCompositeData = nan(size(obj.Values('Time').ModeCompositeData));
                            tempChannel = Miscellaneous_Channel(obj, name, 'Miscellaneous', units, StreamingData, 0);
                            tempChannel.ModeCompositeData = ModeCompositeData;
                        end
                        obj = AddChannel(obj, sname, tempChannel);
                    end
                end
            end
            fclose(fid);
        end

        function StreamingArray = MakeStreamingArray(obj)

            global LOCALPATH;
            if strcmp(obj.Values('Options').Option_Panel,'Network')
                fid = fopen([obj.Values('Options').Network_Path 'Settings Files\Standard Channel List.txt']);
            else
                fid = fopen([LOCALPATH '\Settings Files\Standard Channel List.txt']);
            end
            k = 1;
            while ~feof(fid)
                DataMill = stringread(fgetl(fid),',');
                [name, units] = obj.Segregate(DataMill{1});
                if length(DataMill)==1
                    sname = ProcessChannelNameb(name);
                    if obj.isKey(sname)
                        if instr(name,'Bench') && ~instr(name,'°') && ~instr(name,'Mol')
                            Precursor = 'Part86';
                            if strcmp(left(name,2),'MF'), Precursor = 'Part1065'; end;
                            switch units
                                case 'ppm'
                                    if ~strcmp(obj.Values(sname).Current_Units{1},units)
                                        units = obj.Values(sname).Current_Units{1};
                                    end
                                    DataGet = [Precursor 'Concentration'];
                                case '%'
                                    if ~strcmp(obj.Values(sname).Current_Units{1},units)
                                        units = obj.Values(sname).Current_Units{1};
                                    end
                                    DataGet = [Precursor 'Concentration'];
                                case 'g'
                                    if ~strcmp(obj.Values(sname).Current_Units{2},units)
                                        units = obj.Values(sname).Current_Units{2};
                                    end
                                    DataGet = [Precursor 'Mass'];
                                case 'g/kW.hr'
                                    continue;
                            end
                            if obj.Values('Options').Part_1065.IsOn
                                if strcmp(sname,'CH4_Bag_Dilute') && strcmp(left(name,3),'MF_'), sname = 'CH4_Bag_Dilute_Corrected'; end;
                                if obj.Values('Options').Use_HC
                                    if strcmp(sname,'HC_Bag_Dilute') && strcmp(left(name,3),'MF_'), sname = 'HC_Bag_Dilute_Corrected'; end;
                                else
                                    if strcmp(sname,'HHC_Bag_Dilute') && strcmp(left(name,3),'MF_'), sname = 'HHC_Bag_Dilute_Corrected'; end;
                                end
                            end
                            if isempty(obj.Values(sname).StreamingData.(DataGet)) %This makes sense to have here, even if an analyzer does exist, there is a possibilty of the chemical balance not being performed
                                if strcmp(units,'')
                                    StreamingArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
                                else
                                    StreamingArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
                                end
                                k = k+1;
                            else
                                if strcmp(units,'')
                                    StreamingArray(:, k) = [{name}; num2cell(obj.Values(sname).StreamingData.(DataGet))];
                                else
                                    StreamingArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values(sname).StreamingData.(DataGet))];
                                end
                                k = k+1;
                            end
                            tempChannel = obj.Values(sname);
                            tempChannel.Exported = 1;
                        else
                            if ~strcmp(obj.Values(sname).Current_Units,units)
                                units = obj.Values(sname).Current_Units;
                            end
                            if strcmp(units,'')
                                StreamingArray(:, k) = [{name}; num2cell(obj.Values(sname).StreamingData)];
                            else
                                StreamingArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values(sname).StreamingData)];
                            end
                            tempChannel = obj.Values(sname);
                            tempChannel.Exported = 1;
                            k = k+1;
                        end
                    else
                        if strcmp(sname, 'Mode_Duration')
                            StreamingArray(:, k) = [{'Time (s)'}; num2cell(obj.Values('Time').StreamingData)];
                            k = k+1;
                            tempChannel = obj.Values('Time');
                            tempChannel.Exported = 1;
                        elseif strcmp(sname, 'BSFC_Fuel')
							if obj.isKey('BSFC_Meter')
								if ~strcmp(obj.Values('BSFC_Meter').Current_Units,units)
									units = obj.Values('BSFC_Meter').Current_Units;
								end
                                if strcmp(units,'')
                                    StreamingArray(:, k) = [{name}; num2cell(obj.Values('BSFC_Meter').StreamingData)];
                                else
                                    StreamingArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('BSFC_Meter').StreamingData)];
                                end
                                tempChannel = obj.Values('BSFC_Meter');
								tempChannel.Exported = 1;
								k = k+1;
							else
								if strcmp(units,'')
									StreamingArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
								else
									StreamingArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
								end
								k = k+1;
							end
                        elseif strcmp(sname, 'BSFC_CB')
							if obj.isKey('BSFC_CB')
								if ~strcmp(obj.Values('BSFC_CB').Current_Units,units)
									units = obj.Values('BSFC_CB').Current_Units;
								end
                                if strcmp(units,'')
                                    StreamingArray(:, k) = [{name}; num2cell(obj.Values('BSFC_CB').StreamingData)];
                                else
                                    StreamingArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('BSFC_CB').StreamingData)];
                                end
                                tempChannel = obj.Values('BSFC_CB');
								tempChannel.Exported = 1;
								k = k+1;
							else
								if strcmp(units,'')
									StreamingArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
								else
									StreamingArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
								end
								k = k+1;
							end
                        elseif strcmp(sname, 'MF_BSFC_CB')
							if obj.isKey('MF_Fuel_CB')
								units =[obj.Values('MF_Fuel_CB').Current_Units '/' obj.Values('Work').Current_Units];
								StreamingArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('MF_Fuel_CB').StreamingData./(obj.Values('Work').StreamingData))];
								k = k+1;
							else
								if strcmp(units,'')
									StreamingArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
								else
									StreamingArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
								end
								k = k+1;
							end
                        else
                            if strcmp(units,'')
                                StreamingArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
                            else
                                StreamingArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').StreamingData)))))];
                            end
                            k = k+1;
                        end
                    end
                else
                    if strcmp(DataMill{3},'SP_P_SimBaro') || strcmp(DataMill{3}, 'SP_T_In_Air')
                        if strcmp(units,'')
                            StreamingArray(:, k) = [{name}; num2cell(obj.Values('Options').(DataMill{3})*ones(size(obj.Values('Time').StreamingData)))];
                        else
                            StreamingArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('Options').(DataMill{3})*ones(size(obj.Values('Time').StreamingData)))];
                        end
                        k = k+1;
                    end
                end
            end
            fclose(fid);

            incaMap = containers.Map('KeyType','char','ValueType','int32');
            for m = 1:length(obj.values)
                if strcmp(left(obj.keys{m},4),'INCA')
                    incaMap(obj.keys{m}) = m;
                end
            end

            incaKeys = incaMap.keys();

            for m = 1:length(incaMap.values())
                myOBJ = obj.Values(incaKeys{m});
                if strcmp(myOBJ.Current_Units,'')
                    StreamingArray(:, k) = [{myOBJ.Name}; num2cell(myOBJ.StreamingData)];
                else
                    StreamingArray(:, k) = [{[myOBJ.Name ' (' myOBJ.Current_Units ')']}; num2cell(myOBJ.StreamingData)];
                end
                myOBJ.Exported = 1;
                k = k+1;
            end

            casMap = containers.Map('KeyType','char','ValueType','int32');
            for m = 1:length(obj.values)
                if strcmp(left(obj.keys{m},3),'CAS')
                    casMap(obj.keys{m}) = m;
                end
            end

            casKeys = casMap.keys();

            for m = 1:length(casMap.values())
                myOBJ = obj.Values(casKeys{m});
                if strcmp(myOBJ.Current_Units,'')
                    StreamingArray(:, k) = [{myOBJ.Name}; num2cell(myOBJ.StreamingData)];
                else
                    StreamingArray(:, k) = [{[myOBJ.Name ' (' myOBJ.Current_Units ')']}; num2cell(myOBJ.StreamingData)];
                end
                myOBJ.Exported = 1;
                k = k+1;
            end

            sordidValues = obj.Sort(); % They are really filthy.
            for j = 1:length(sordidValues)
                if ~isempty(sordidValues{j}) && ~sordidValues{j}.Exported
                    if strcmp(sordidValues{j}.Current_Units,'')
                        StreamingArray(:,k) = [{sordidValues{j}.Name}; num2cell(sordidValues{j}.StreamingData)];
                    else
                        if instr(sordidValues{j}.Name, 'Bench')
                            if obj.Values('Options').Part_1065.IsOn
                                StreamingArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{1} ')']}; num2cell(sordidValues{j}.StreamingData.Part86Concentration)];
                                k = k+1;
                                StreamingArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{2} ')']}; num2cell(sordidValues{j}.StreamingData.Part86Mass)];
                                k = k+1;
                                StreamingArray(:,k) = [{['MF_' sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{1} ')']}; num2cell(sordidValues{j}.StreamingData.Part1065Concentration)];
                                k = k+1;
                                StreamingArray(:,k) = [{['MF_' sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{2} ')']}; num2cell(sordidValues{j}.StreamingData.Part1065Mass)];
                            else
                                StreamingArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{1} ')']}; num2cell(sordidValues{j}.StreamingData.Part86Concentration)];
                                k = k+1;
                                StreamingArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{2} ')']}; num2cell(sordidValues{j}.StreamingData.Part86Mass)];
                            end
                        else
                            StreamingArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units ')']}; num2cell(sordidValues{j}.StreamingData)];
                        end
                    end
                    k = k+1;
                end
            end
        end

        function CompositeArray = MakeCompositeArray(obj, ModeSegregation)
            global LM LOCALPATH FILENAME;
            if strcmp(obj.Values('Options').Option_Panel,'Network')
                fid = fopen([obj.Values('Options').Network_Path 'Settings Files/Standard Channel List.txt']);
            else
                fid = fopen([LOCALPATH '\Settings Files\Standard Channel List.txt']);
            end
            k = 1;
            while ~feof(fid)
                DataMill = stringread(fgetl(fid),',');
                [name, units] = obj.Segregate(DataMill{1});
                if length(DataMill)==1
                    sname = ProcessChannelNameb(name);
                    if obj.isKey(sname)
                        if instr(name,'Bench') && ~instr(name,'°') && ~instr(name,'Mol')
                            Precursor = 'Part86';
                            if strcmp(left(name,2),'MF'), Precursor = 'Part1065'; end;
                            switch units
                                case 'ppm'
                                    if ~strcmp(obj.Values(sname).Current_Units{1},units)
                                        LM.DebugPrint(1, 'WARNING: Unexpected units for %s, expected units of %s, received units of %s',sname,units,obj.Values(sname).Current_Units{1});
                                        units = obj.Values(sname).Current_Units{1};
                                    end
                                    DataGet = [Precursor 'Concentration'];
                                case '%'
                                    if ~strcmp(obj.Values(sname).Current_Units{1},units)
                                        LM.DebugPrint(1, 'WARNING: Unexpected units for %s, expected units of %s, received units of %s',sname,units,obj.Values(sname).Current_Units{1});
                                        units = obj.Values(sname).Current_Units{1};
                                    end
                                    DataGet = [Precursor 'Concentration'];
                                case 'g'
                                    if ~strcmp(obj.Values(sname).Current_Units{2},units)
                                        LM.DebugPrint(1, 'WARNING: Unexpected units for %s, expected units of %s, received units of %s',sname,units,obj.Values(sname).Current_Units{2});
                                        units = obj.Values(sname).Current_Units{2};
                                    end
                                    DataGet = [Precursor 'Mass'];
                                case 'g/kW.hr'
                                    if ~strcmp(obj.Values(sname).Current_Units{3},units)
                                        LM.DebugPrint(1, 'WARNING: Unexpected units for %s, expected units of %s, received units of %s',sname,units,obj.Values(sname).Current_Units{3});
                                        units = obj.Values(sname).Current_Units{3};
                                    end
                                    DataGet = [Precursor 'BrakeSpecificMass'];
                            end
                            if obj.Values('Options').Part_1065.IsOn
                                if strcmp(sname,'CH4_Bag_Dilute') && strcmp(left(name,3),'MF_'), sname = 'CH4_Bag_Dilute_Corrected'; end;
                                if obj.Values('Options').Use_HC
                                    if strcmp(sname,'HC_Bag_Dilute') && strcmp(left(name,3),'MF_'), sname = 'HC_Bag_Dilute_Corrected'; end;
                                else
                                    if strcmp(sname,'HHC_Bag_Dilute') && strcmp(left(name,3),'MF_'), sname = 'HHC_Bag_Dilute_Corrected'; end;
                                end
                            end
                            if isempty(obj.Values(sname).ModeCompositeData.(DataGet)) %This makes sense to have here, even if an analyzer does exist, there is a possibilty of the chemical balance not being performed
                                if strcmp(units,'')
                                    CompositeArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                else
                                    CompositeArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                end
                                k = k+1;
                            else
                                if strcmp(units,'')
                                    CompositeArray(:, k) = [{name}; num2cell(obj.Values(sname).ModeCompositeData.(DataGet))];
                                else
                                    CompositeArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values(sname).ModeCompositeData.(DataGet))];
                                end
                                k = k+1;
                            end
                        else
                            if ~strcmp(obj.Values(sname).Current_Units,units)
                                LM.DebugPrint(1, 'WARNING: Unexpected units for %s, expected units of %s, received units of %s',sname,units,obj.Values(sname).Current_Units);
                                units = obj.Values(sname).Current_Units;
                            end
                            if strcmp(units,'')
                                CompositeArray(:, k) = [{name}; num2cell(obj.Values(sname).ModeCompositeData)];
                            else
                                CompositeArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values(sname).ModeCompositeData)];
                            end
                            k = k+1;
                        end
                    else % if the field doesn't exist
                        switch sname
                            case 'Mode_Duration'
                                CompositeArray(:, k) = [{'Mode_Duration (s)'}; num2cell(obj.Values('Time').ModeCompositeData)];
                                k = k+1;

                            case 'BSFC_Fuel'
                                if obj.isKey('Q_Fuel_Mass_C')
                                    units =['g/' obj.Values('Work').Current_Units];
                                    CompositeArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('Q_Fuel_Mass_C').ModeCompositeData./(3.6*obj.Values('Work').ModeCompositeData).*obj.Values('Time').ModeCompositeData)];
                                    k = k+1;
                                else
                                    if strcmp(units,'')
                                        CompositeArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    else
                                        CompositeArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    end
                                    k = k+1;
                                end

                            case 'BSFC_CB'
                                if obj.isKey('Fuel_CB')
                                    units =[obj.Values('Fuel_CB').Current_Units '/' obj.Values('Work').Current_Units];
                                    CompositeArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData))];
                                    k = k+1;
                                else
                                    if strcmp(units,'')
                                        CompositeArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    else
                                        CompositeArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    end
                                    k = k+1;
                                end

                            case 'MF_BSFC_CB'
                                if obj.isKey('MF_Fuel_CB')
                                    units =[obj.Values('MF_Fuel_CB').Current_Units '/' obj.Values('Work').Current_Units];
                                    CompositeArray(:, k) = [{[name ' (' units ')']}; num2cell(obj.Values('MF_Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData))];
                                    k = k+1;
                                else
                                    if strcmp(units,'')
                                        CompositeArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    else
                                        CompositeArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    end
                                    k = k+1;
                                end

                            case 'BS_MSS'
                                % Additional MSS calculation because I am snoopy and spoofing
                                % PM data is scary...
                                if obj.isKey('MSS_CC') && mean(obj.Values('MSS_CC').StreamingData)>0
                                    if obj.Values('Options').MSS_Sample_Position == 9 || obj.Values('Options').MSS_Sample_Position == 6
                                        BSMSSg = obj.Values('MSS_CC').StreamingData.*obj.Values('Q_CVS_C').StreamingData.*obj.Values('Options').delta_T./ ...
                                                    (35.314666*60*1000);
                                    else
                                        BSMSSg = obj.Values('MSS_CC').StreamingData.*obj.Values('Q_Ex').StreamingData.*obj.Values('Options').delta_T./ ...
                                                    (35.314666*60*1000);
                                    end
                                    CompositeArray{1,k} = 'BS_MSS (g/kW.hr)';
                                    for j = 1:ModeSegregation.nModes
                                        CompositeArray{j+1,k} = sum(BSMSSg(ModeSegregation.getModeIndices(j)==1))./obj.Values('Work').ModeCompositeData(j);
                                    end
                                    k = k + 1;
                                else
                                    CompositeArray(:, k) = [{'BS_MSS (g/kW.hr)'}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    k= k +1;
                                end

                            case 'BS_SM'
                                if obj.isKey('SM_CC') && mean(obj.Values('SM_CC').StreamingData)>0
                                    if obj.Values('Options').Smoke_Meter_Sample_Position == 9 || obj.Values('Options').Smoke_Meter_Sample_Position == 6
                                        SMg = obj.Values('SM_CC').StreamingData.*obj.Values('Q_CVS_C').StreamingData.*obj.Values('Options').delta_T./ ...
                                                    (35.314666*60*1000);
                                    else
                                        SMg = obj.Values('SM_CC').StreamingData.*obj.Values('Q_Ex').StreamingData.*obj.Values('Options').delta_T./ ...
                                                    (35.314666*60*1000);
                                    end
                                    CompositeArray{1,k} = 'BS_SM (g/kW.hr)';
                                    for j = 1:ModeSegregation.nModes
                                        CompositeArray{j+1,k} = sum(SMg(ModeSegregation.getModeIndices(j)==1))./obj.Values('Work').ModeCompositeData(j);
                                    end
                                    k = k + 1;
                                else
                                    CompositeArray(:, k) = [{'BS_SM (g/kW.hr)'}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                    k= k +1;
                                end

                            otherwise
                                if strcmp(units,'')
                                    CompositeArray(:, k) = [{name}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                else
                                    CompositeArray(:, k) = [{[name ' (' units ')']}; cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))))];
                                end
                                k = k+1;
                        end
                    end
                else % If the data requested is an Option
                    switch DataMill{2}
                        case 'Options'
                            try
                                if ~isempty(strfind(DataMill{3},'.'))
                                    [lefter, righter] = strtok(DataMill{3},'.');
                                    [righter, ~] = strtok(righter,'.');
                                    val = obj.Values('Options').(lefter).(righter);
                                elseif strcmp(DataMill{3},'Test_Start')
                                    val = [datestr(obj.Values('Options').Test_Start, 23) ' ' datestr(obj.Values('Options').Test_Start, 14)];
                                elseif strcmp(DataMill{3},'Aftertreatment_Configuration')
                                    decCombo = obj.Values('Options').Aftertreatment_Configuration;
                                    hexString = num2str(dec2hex(decCombo));
                                    while length(hexString) < 4
                                        hexString = [hexString '0'];
                                    end
                                    switch DataMill{1}
                                        case 'ATComp_1'
                                            val = hexString(1);
                                        case 'ATComp_2'
                                            val = hexString(2);
                                        case 'ATComp_3'
                                            val = hexString(3);
                                        case 'ATComp_4'
                                            val = hexString(4);
                                    end
                                    switch val
                                        case '0'
                                            val = 'NONE';
                                        case '1'
                                            val = 'DOC';
                                        case '2'
                                            val = 'DPF';
                                        case '3'
                                            val = 'DNX';
                                        case '4'
                                            val = 'CAT';
                                    end
                                else
                                    val = obj.Values('Options').(DataMill{3});
                                end
                            catch %#ok
                                val = '-';
                            end
                            CompositeArray{1, k} = DataMill{1};
                            for m = 2:length(obj.Values('Time').ModeCompositeData)+1
                                CompositeArray{m, k} = val;
                            end
                            k = k+1;
                        case 'GLOBAL'
                            CompositeArray{1, k} = DataMill{1};
                            for m = 2:length(obj.Values('Time').ModeCompositeData)+1
                                CompositeArray{m, k} = left(FILENAME, length(FILENAME)-4);
                            end
                            k = k+1;
                    end
                end
            end
            fclose(fid);

            %wow this is a bastardization of a class! incaMap isn't much of
            %a map - mostly I'm just using it to hold a list of INCA
            %channels and provide automatic sorting
            incaMap = containers.Map('KeyType','char','ValueType','int32');
            for m = 1:length(obj.values)
                if strcmp(left(obj.keys{m},4),'INCA')
                    incaMap(obj.keys{m}) = m;
                end
            end

            incaKeys = incaMap.keys();

            for m = 1:length(incaMap.values())
                myOBJ = obj.Values(incaKeys{m});
                if strcmp(myOBJ.Current_Units,'')
                    CompositeArray(:, k) = [{myOBJ.Name}; num2cell(myOBJ.ModeCompositeData)];
                else
                    CompositeArray(:, k) = [{[myOBJ.Name ' (' myOBJ.Current_Units ')']}; num2cell(myOBJ.ModeCompositeData)];
                end
                k = k+1;
            end

            casMap = containers.Map('KeyType','char','ValueType','int32');
            for m = 1:length(obj.values)
                if strcmp(left(obj.keys{m},3),'CAS')
                    casMap(obj.keys{m}) = m;
                end
            end

            casKeys = casMap.keys();

            for m = 1:length(casMap.values())
                myOBJ = obj.Values(casKeys{m});
                if strcmp(myOBJ.Current_Units,'')
                    CompositeArray(:, k) = [{myOBJ.Name}; num2cell(myOBJ.ModeCompositeData)];
                else
                    CompositeArray(:, k) = [{[myOBJ.Name ' (' myOBJ.Current_Units ')']}; num2cell(myOBJ.ModeCompositeData)];
                end
                k = k+1;
            end

            sordidValues = obj.Sort(); % This rearranges any dangling data so that the initial order is preserved
            for j = 1:length(sordidValues)
                if ~isempty(sordidValues{j}) && ~sordidValues{j}.Exported
                    if strcmp(sordidValues{j}.Current_Units,'')
                        CompositeArray(:,k) = [{sordidValues{j}.Name}; num2cell(sordidValues{j}.ModeCompositeData)];
                    else
                        if instr(sordidValues{j}.Name, 'Bench')
                            if obj.Values('Options').Part_1065.IsOn
                            CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{1} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part86Concentration)];
                            k = k+1;
                            CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{2} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part86Mass)];
                            k = k+1;
                            CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{3} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part86BrakeSpecificMass)];
                            k = k+1;
                            CompositeArray(:,k) = [{['MF_' sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{1} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part1065Concentration)];
                            k = k+1;
                            CompositeArray(:,k) = [{['MF_' sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{2} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part1065Mass)];
                            k = k+1;
                            CompositeArray(:,k) = [{['MF_' sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{3} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part1065BrakeSpecificMass)];
                            else
                                CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{1} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part86Concentration)];
                                k = k+1;
                                CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{2} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part86Mass)];
                                k = k+1;
                                CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units{3} ')']}; num2cell(sordidValues{j}.ModeCompositeData.Part86BrakeSpecificMass)];
                            end
                        else
                            CompositeArray(:,k) = [{[sordidValues{j}.Name ' (' sordidValues{j}.Current_Units ')']}; num2cell(sordidValues{j}.ModeCompositeData)];
                        end
                    end
                    k = k+1;
                end
            end % end sorting procedure



        end


        function HeaderTable = MakeHeaderTable(obj)

            global GLUEVERSION;

            HeaderTable = cell(15, 26);

            HeaderTable{1,1} = 'SGS - Environmental Testing Center';
            HeaderTable{1,26} = '2022 Helena St, Aurora, CO 80011';
            HeaderTable{2,26} = '303-880-5064';
            HeaderTable{4,1} = 'General Data';
            HeaderTable(6:14,3:13) = {'Customer'        ''    ''  'Fuel'                                ''  ''       'Aftertreatment Component 1'                ''   ''      'Engine Calibration'                    '';
                                      'Engine No.'      ''    ''  'Fuel Density (kg/L)'                 []  ''       'Aftertreatment Component 2'                ''   ''      'Pre-Test Comment'                      '';
                                      'Date'            ''    ''  'Fuel Lower Heating Value (BTU/lb)'   []  ''       'Aftertreatment Component 3'                ''   ''      'Post-Test Comment'                     '';
                                      'Tech'            ''    ''  'Fuel w_C'                            []  ''       'Aftertreatment Component 4'                ''   ''      'PM?'                                   '';
                                      'Test Cell'       ''    ''  'Fuel w_H'                            []  ''       'Sample Position of Engine Bench'           []   ''      'Sample Position of Smoke Meter'        [];
                                      'Test Type'       ''    ''  'Fuel w_O'                            []  ''       'Sample Position of Mid Bench'              []   ''      'Sample Position of Micro Soot Sensor'  [];
                                      'Certification?'  ''    ''  'Fuel w_S'                            []  ''       'Sample Position of Flex Bench'             []   ''      'Sample Position of FTIR'               [];
                                      'Validity?'       ''    ''  'Fuel w_N'                            []  ''       'Sample Position of Tailpipe Bench'         []   ''      'Glue Version'                          '';
                                      'Profile File'    ''    ''  'Playback File'                       ''  ''       ''                                          ''   ''      'ECCS Version'                          ''};

            % Value Assignment
            try
                HeaderTable{6,4} = obj.Values('Options').Customer;
            catch %#ok
                HeaderTable{6,4} = '-';
            end
            try
                HeaderTable{7,4} = obj.Values('Options').Engine_ID;
            catch %#ok
                HeaderTable{7,4} = '-';
            end
            try
                HeaderTable{8,4} = [datestr(obj.Values('Options').Test_Start, 23) ' ' datestr(obj.Values('Options').Test_Start, 14)];
            catch %#ok
                HeaderTable{8,4} = '-';
            end
            try
                HeaderTable{9,4} = obj.Values('Options').Test_Tech;
            catch %#ok
                HeaderTable{9,4} = '-';
            end
            try
                HeaderTable{10,4} = obj.Values('Options').Test_Cell;
            catch %#ok
                HeaderTable{10,4} = '-';
            end
            try
                HeaderTable{11,4} = obj.Values('Options').Test_Type;
            catch %#ok
                HeaderTable{11,4} = '-';
            end
            try
                if obj.Values('Options').Cert_Test_Flag == 1
                    HeaderTable{12,4} = 'Yes';
                else
                    HeaderTable{12,4} = 'No';
                end
            catch %#ok
                HeaderTable{12,4} = '-';
            end
            if isfield(obj.Values('Options'),'Void_Flag')
                switch obj.Values('Options').Void_Flag
                    case 0,  HeaderTable{13,4} = 'Valid';
                    case 1,  HeaderTable{13,4} = 'Invalid';
                    case 2,  HeaderTable{13,4} = 'Needs Review';
%                     case 3,  HeaderTable{13,4} = 'Electrical Power Outage';
%                     case 4,  HeaderTable{13,4} = 'Facility Systems';
%                     case 5,  HeaderTable{13,4} = 'Fuel Cabinet';
%                     case 6,  HeaderTable{13,4} = 'REPS/DATES - Automation System';
%                     case 7,  HeaderTable{13,4} = 'ECCS - Automation System';
%                     case 8,  HeaderTable{13,4} = 'Emissions Bench';
%                     case 9,  HeaderTable{13,4} = 'Emissions Sampling Contamination';
%                     case 10, HeaderTable{13,4} = 'Incorrect/Ambiguous Test Request';
%                     case 11, HeaderTable{13,4} = 'Technician Error';
%                     case 12, HeaderTable{13,4} = 'Customer Engine/Aftertreatment';
%                     case 13, HeaderTable{13,4} = 'Customer ECU or INCA';
%                     case 14, HeaderTable{13,4} = 'Other Billable Causes';
                    otherwise, HeaderTable{13,4} = 'Invalid';
                end
            else
                HeaderTable{13,4} = '-';
            end
            HeaderTable{14,4} =obj.Values('Options').ProfileFile;


            HeaderTable{6,7} = obj.Values('Options').Fuel.Name;
            HeaderTable{7,7} = obj.Values('Options').Fuel.Specific_Gravity;
            try
                HeaderTable{8,7} = obj.Values('Options').Fuel.Lower_Heating_Value;
            catch %#ok
                HeaderTable{8,7} = '-';
            end
            HeaderTable{9,7} = obj.Values('Options').Fuel.w_C;
            HeaderTable{10,7} = obj.Values('Options').Fuel.w_H;
            HeaderTable{11,7} = obj.Values('Options').Fuel.w_O;
            HeaderTable{12,7} = obj.Values('Options').Fuel.w_S;
            HeaderTable{13,7} = obj.Values('Options').Fuel.w_N;
            HeaderTable{14,7} = obj.Values('Options').PlaybackFile;

            decCombo = obj.Values('Options').Aftertreatment_Configuration;
            hexString = num2str(dec2hex(decCombo));
            while length(hexString) < 4
                hexString = [hexString '0'];
            end
            for k = 1:4
                try
                    % HeaderTable{5+k,10} = obj.AftertreatmentComponent(hexString(k));
                    HeaderTable{5+k,10} = AftertreatmentComponent(hexString(k));
                catch %#ok
                    HeaderTable{5+k,10} = '-';
                end
            end

            try
                HeaderTable{10,10} = obj.Values('Options').Engine_Bench_Sample_Position;
            catch %#ok
                HeaderTable{10,10} = '-';
            end
            try
                HeaderTable{11,10} = obj.Values('Options').Mid_Bench_Sample_Position;
            catch %#ok
                HeaderTable{11,10} = '-';
            end
            try
                HeaderTable{12,10} = obj.Values('Options').Flex_Bench_Sample_Position;
            catch %#ok
                HeaderTable{12,10} = '-';
            end
            try
                HeaderTable{13,10} = obj.Values('Options').Tailpipe_Bench_Sample_Position;
            catch %#ok
                HeaderTable{13,10} = '-';
            end

            try
                HeaderTable{6,13} = obj.Values('Options').Engine_Calibration;
            catch %#ok
                HeaderTable{6,13} = '-';
            end
            try
                HeaderTable{7,13} = obj.Values('Options').PreTest_Comment;
            catch %#ok
                HeaderTable{7,13} = 'Test analyzed offline - could not sync with database';
            end
            try
                HeaderTable{8,13} = obj.Values('Options').PostTest_Comment;
            catch %#ok
                HeaderTable{8,13} = '-';
            end
            if strcmp(obj.Values('Options').Particulate_On,'Yes')
                HeaderTable{9,13} = 'Yes';
            else
                HeaderTable{9,13} = 'No';
            end
            try
                HeaderTable{10,13} = obj.Values('Options').Smoke_Meter_Sample_Position;
            catch %#ok
                HeaderTable{10,13} = '-';
            end
            try
                HeaderTable{11,13} = obj.Values('Options').MSS_Sample_Position;
            catch %#ok
                HeaderTable{11,13} = '-';
            end
            try
                HeaderTable{12,13} = obj.Values('Options').FTIR_Sample_Position;
            catch %#ok
                HeaderTable{12,13} = '-';
            end
            HeaderTable{13,13} = GLUEVERSION;
            HeaderTable{14,13} = obj.Values('Options').ECCS_Ver;
        end

        function EmissionsTable = MakeEmissionsTable(obj)
            global SPECIES BENCHES;

            if obj.isKey('MF_Fuel_CB') && obj.isKey('Q_Fuel_Mass_C')
                BSFC_Comparison = (obj.Values('MF_Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData)-obj.Values('Q_Fuel_Mass_C').ModeCompositeData./(3.6*obj.Values('Work').ModeCompositeData).*obj.Values('Time').ModeCompositeData)./(obj.Values('Q_Fuel_Mass_C').ModeCompositeData./(3.6*obj.Values('Work').ModeCompositeData).*obj.Values('Time').ModeCompositeData);
            else
                BSFC_Comparison = zeros(size(obj.Values('Work').ModeCompositeData));
            end

            count = 0;
            bag_dilute_count=0;
            for k = 1:length(BENCHES)
                for m = 1:length(SPECIES)
                    if obj.isKey([SPECIES{m} '_' BENCHES{k}]) && obj.Values([SPECIES{m} '_' BENCHES{k}]).IsOn
                        count = count+1;
                    end
                end
                if obj.isKey(['CO_l_' BENCHES{k}]) && obj.isKey(['CO_h_' BENCHES{k}]) && obj.Values(['CO_l_' BENCHES{k}]).IsOn && obj.Values(['CO_h_' BENCHES{k}]).IsOn
                    count = count-1;
                end
                if k == 1
                    bag_dilute_count = count;
                end
            end
            detractor = 0;
            if obj.isKey('NMHC_Bag_Dilute'), detractor = 1; end

            ModalWeighting = 0; %This will be relocated later so that a channel is added for ModalWeighting the future code follows

            if obj.isKey('Modal_Weights')
                ModalWeighting = 1;
                ModalWeights = obj.Values('Modal_Weights').ModeCompositeData;
            end

            if obj.Values('Options').Part_1065.IsOn
                EmissionsTable = cell(size(obj.Values('Time').ModeCompositeData,1)+1,6+2*count-detractor);

                EmissionsTable{1,1} = 'Mode';
                EmissionsTable(2:end,1) = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');

                EmissionsTable{1,2} = 'Eng_Speed (RPM)';
                EmissionsTable(2:end,2) = num2cell(obj.Values('Eng_Speed').ModeCompositeData);

                EmissionsTable{1,3} = 'Torque (N.m)';
                EmissionsTable(2:end,3) = num2cell(obj.Values('Torque').ModeCompositeData);

                EmissionsTable{1,4} = 'Work (kW.hr)';
                EmissionsTable(2:end,4) = num2cell(obj.Values('Work').ModeCompositeData);

                EmissionsTable{1,5} = 'NOx_Corr';
                EmissionsTable(2:end,5) = num2cell(obj.Values('NOx_Corr').ModeCompositeData);

                EmissionsTable{1,6} = 'MF_NOx_Corr';
                if obj.Values('Options').Bag_Dilute_Bench
                    EmissionsTable(2:end,6) = num2cell(obj.Values('MF_NOx_Corr').ModeCompositeData);
                else
                    EmissionsTable(2:end,6) = cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))));
                end

                count86 = 7;

                count1065 = 6+count;

                for k = 1:length(BENCHES)
                    Single_CO = 0;
                    if obj.isKey(['CO_l_' BENCHES{k}]) && obj.isKey(['CO_h_' BENCHES{k}]), Single_CO = 1; end
                    for m = 1:length(SPECIES)
                        if strcmp(SPECIES{m},'CO_l') && Single_CO, continue; end
                        if obj.isKey([SPECIES{m} '_' BENCHES{k}])  && obj.Values([SPECIES{m} '_' BENCHES{k}]).IsOn
                            if strcmp(SPECIES{m},'CO_h') && Single_CO
                                EmissionsTable{1,count86} = ['CO_' BENCHES{k} ' (g/kW.hr)'];
                                EmissionsTable{1,count1065} = ['MF_CO_' BENCHES{k} ' (g/kW.hr)'];
                                for n = 2:size(obj.Values('Time').ModeCompositeData,1)+1
                                    if obj.Values('Options').([BENCHES{k} '_CO_l_InUse'])
                                        EmissionsTable{n,count86} = obj.Values(['CO_l_' BENCHES{k}]).ModeCompositeData.Part86BrakeSpecificMass(n-1);
                                        EmissionsTable{n,count1065} = obj.Values(['CO_l_' BENCHES{k}]).ModeCompositeData.Part1065BrakeSpecificMass(n-1);
                                    else
                                        EmissionsTable{n,count86} = obj.Values(['CO_h_' BENCHES{k}]).ModeCompositeData.Part86BrakeSpecificMass(n-1);
                                        EmissionsTable{n,count1065} = obj.Values(['CO_h_' BENCHES{k}]).ModeCompositeData.Part1065BrakeSpecificMass(n-1);
                                    end
                                end
                                count86 = count86+1;
                                count1065 = count1065+1;
                            elseif ~strcmp(SPECIES{m},'NMHC')
                                Corrected = '';
                                if strcmp('HHC',SPECIES{m}) && ~obj.Values('Options').Use_HC && strcmp(BENCHES{k},'Bag_Dilute')
                                    Corrected = '_Corrected';
                                elseif strcmp('HC',SPECIES{m}) && obj.Values('Options').Use_HC && strcmp(BENCHES{k},'Bag_Dilute')
                                    Corrected = '_Corrected';
                                elseif strcmp('CH4',SPECIES{m}) && strcmp(BENCHES{k},'Bag_Dilute')
                                    Corrected = '_Corrected';
                                end
                                EmissionsTable{1,count86} = [obj.Values([SPECIES{m} '_' BENCHES{k}]).Name ' (' obj.Values([SPECIES{m} '_' BENCHES{k}]).Current_Units{3} ')'];
                                EmissionsTable{1,count1065} = ['MF_' obj.Values([SPECIES{m} '_' BENCHES{k}]).Name ' (' obj.Values([SPECIES{m} '_' BENCHES{k}]).Current_Units{3} ')'];
                                EmissionsTable(2:end,count86) = num2cell(obj.Values([SPECIES{m} '_' BENCHES{k}]).ModeCompositeData.Part86BrakeSpecificMass);
                                EmissionsTable(2:end,count1065) = num2cell(obj.Values([SPECIES{m} '_' BENCHES{k} Corrected]).ModeCompositeData.Part1065BrakeSpecificMass);
                                count86 = count86+1;
                                count1065 = count1065+1;
                            else
                                EmissionsTable{1,count1065} = ['MF_' obj.Values([SPECIES{m} '_' BENCHES{k}]).Name ' (' obj.Values([SPECIES{m} '_' BENCHES{k}]).Current_Units{3} ')'];
                                EmissionsTable(2:end,count1065) = num2cell(obj.Values([SPECIES{m} '_' BENCHES{k}]).ModeCompositeData.Part1065BrakeSpecificMass);
                                count1065 = count1065+1;
                            end
                        end
                    end
                end

                count1065 = count + 6;
                for k = 1:length(BSFC_Comparison)
                    if abs(BSFC_Comparison(k)) < 0.1, continue; end
                    for m = count1065+bag_dilute_count:6+2*count-detractor
                        EmissionsTable{k+1,m} = '-';
                    end

                end

                if ModalWeighting
                    EmissionsTable = [EmissionsTable; cell(1,size(EmissionsTable,2))];
                    WeightedWorkArray = ModalWeights.*obj.Values('Work').ModeCompositeData;
                    WeightedWork = sum(ModalWeights.*obj.Values('Work').ModeCompositeData);
                    EmissionsTable{end,1} = '*MW';
                    EmissionsTable{end,2} = '-';
                    EmissionsTable{end,3} = '-';
                    EmissionsTable{end,4} = WeightedWork;
                    EmissionsTable{end,5} = '-';
                    EmissionsTable{end,6} = '-';
                    for k = 7:size(EmissionsTable,2)
                        EmissionsTable{end,k} = sum(WeightedWorkArray.*[EmissionsTable{2:(end-1),k}]')/WeightedWork;
                    end
                end


            else
                EmissionsTable = cell(size(obj.Values('Time').ModeCompositeData,1)+1,6+2);

                EmissionsTable{1,1} = 'Mode';
                EmissionsTable(2:end,1) = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');

                EmissionsTable{1,2} = 'Eng_Speed (RPM)';
                EmissionsTable(2:end,2) = num2cell(obj.Values('Eng_Speed').ModeCompositeData);

                EmissionsTable{1,3} = 'Torque (N.m)';
                EmissionsTable(2:end,3) = num2cell(obj.Values('Torque').ModeCompositeData);

                EmissionsTable{1,4} = 'Work (kW.hr)';
                EmissionsTable(2:end,4) = num2cell(obj.Values('Work').ModeCompositeData);

                EmissionsTable{1,5} = 'NOx_Corr';
                EmissionsTable(2:end,5) = num2cell(obj.Values('NOx_Corr').ModeCompositeData);

                count86 = 6;

                for k = 1:length(BENCHES)
                    Single_CO = 0;
                    if obj.isKey(['CO_l_' BENCHES{k}]) && obj.isKey(['CO_h_' BENCHES{k}]), Single_CO = 1; end
                    for m = 1:length(SPECIES)
                        if strcmp(SPECIES{m},'CO_l') && Single_CO, continue; end
                        if obj.isKey([SPECIES{m} '_' BENCHES{k}])
                            if strcmp(SPECIES{m},'CO_h') && Single_CO
                                EmissionsTable{1,count86} = ['CO_' BENCHES{k} ' (g/kW.hr)'];
                                for n = 2:size(obj.Values('Time').ModeCompositeData,1)+1
                                    if obj.Values('Options').([BENCHES{k} '_CO_l_InUse'])
                                        EmissionsTable{n,count86} = obj.Values(['CO_l_' BENCHES{k}]).ModeCompositeData.Part86BrakeSpecificMass(n-1);
                                    else
                                        EmissionsTable{n,count86} = obj.Values(['CO_h_' BENCHES{k}]).ModeCompositeData.Part86BrakeSpecificMass(n-1);
                                    end
                                end
                                count86 = count86+1;
                            else
                                EmissionsTable{1,count86} = [obj.Values([SPECIES{m} '_' BENCHES{k}]).Name ' (' obj.Values([SPECIES{m} '_' BENCHES{k}]).Current_Units{3} ')'];
                                EmissionsTable(2:end,count86) = num2cell(obj.Values([SPECIES{m} '_' BENCHES{k}]).ModeCompositeData.Part86BrakeSpecificMass);
                                count86 = count86+1;
                            end
                        end
                    end
                end

                if ModalWeighting
                    EmissionsTable = [EmissionsTable; cell(1,size(EmissionsTable,2))];
                    WeightedWorkArray = ModalWeights.*obj.Values('Power').ModeCompositeData;
                    WeightedWork = sum(ModalWeights.*obj.Values('Power').ModeCompositeData);
                    EmissionsTable{end,1} = '*MW';
                    EmissionsTable{end,2} = '-';
                    EmissionsTable{end,3} = '-';
                    EmissionsTable{end,4} = WeightedWork;
                    EmissionsTable{end,5} = '-';
                    for k = 6:size(EmissionsTable,2)
                        EmissionsTable{end,k} = sum(WeightedWorkArray.*[EmissionsTable{2:end-1,k}]')/WeightedWork;
                    end
                end
            end
        end

        function BSFCTable = MakeBSFCTable(obj)
            BSFCTable = cell(size(obj.Values('Time').ModeCompositeData,1)+1,6);

            BSFCTable{1,1} = 'Mode';
            BSFCTable(2:end,1) = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');

            BSFCTable{1,2} = 'Eng_Speed (RPM)';
            BSFCTable(2:end,2) = num2cell(obj.Values('Eng_Speed').ModeCompositeData);

            BSFCTable{1,3} = 'Torque (N.m)';
            BSFCTable(2:end,3) = num2cell(obj.Values('Torque').ModeCompositeData);

            BSFCTable{1,4} = 'BSFC C-Bal Part 86 (g/kW.hr)';
            if obj.isKey('Fuel_CB')
                BSFCTable(2:end,4) = num2cell(obj.Values('Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData));
            else
                BSFCTable(2:end,4) = cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))));
            end

            BSFCTable{1,5} = 'BSFC C-Bal Part 1065 (g/kW.hr)';
            if obj.isKey('MF_Fuel_CB')
                BSFCTable(2:end,5) = num2cell(obj.Values('MF_Fuel_CB').ModeCompositeData./(obj.Values('Work').ModeCompositeData));
            else
                BSFCTable(2:end,5) = cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))));
            end

            BSFCTable{1,6} = 'BSFC Meter (g/kW.hr)';
            if obj.isKey('Q_Fuel_Mass_C')
                BSFCTable(2:end,6) = num2cell(obj.Values('Q_Fuel_Mass_C').ModeCompositeData./(3.6*obj.Values('Work').ModeCompositeData).*obj.Values('Time').ModeCompositeData);
            else
                BSFCTable(2:end,6) = cellstr(char(45*(ones(size(obj.Values('Time').ModeCompositeData)))));
            end
        end

        function PMTable = MakePMTable(obj, ModeSegregation)
            global LM LOCALPATH TESTNUMBER;

            PMTable = 0;
            PM_Data = obj.GetPMData(ModeSegregation);

            if strcmp(obj.Values('Options').Option_Panel,'Local')
                try
                    PM_Data = importdata([LOCALPATH  '\PM Files\' num2str(TESTNUMBER) '_PM.txt']);
                    LM.DebugPrint(1, 'PM data taken from local text file');
                catch %#ok
                    PMTable = -1;
                end
            else
                try
                    PM_Data = importdata([obj.Values('Options').Network_Path 'PM Files\' num2str(TESTNUMBER) '_PM.txt']);
                    LM.DebugPrint(1, 'PM data taken from network text file');
                catch %#ok
                    PMTable = -1;
                end
            end

            if PMTable == -1 %a text file wasn't found
                if PM_Data ~= -1 %nothing was found on the database either
                    LM.DebugPrint(1, 'PM data taken from database');
                else
                    LM.DebugPrint(1, 'No PM data found');
                    return; %returns PMTable = -1 so that Channels knows not to make table
                end
            end

            LM.DebugPrint(2, 'PM data was found, calculations are being performed');

            MinPrimaryDR = zeros(ModeSegregation.nModes , 1);
            MinSecondaryDR = zeros(ModeSegregation.nModes , 1);
            MinTotalDR = zeros(ModeSegregation.nModes , 1);
            if obj.isKey('MSS_CC') && mean(obj.Values('MSS_CC').StreamingData)>0
                if obj.Values('Options').MSS_Sample_Position == 9 || obj.Values('Options').MSS_Sample_Position == 6
                    BSMSSg = obj.Values('MSS_CC').StreamingData.*obj.Values('Q_CVS_C').StreamingData.*obj.Values('Options').delta_T./ ...
                                (35.314666*60*1000);
                else
                    BSMSSg = obj.Values('MSS_CC').StreamingData.*obj.Values('Q_Ex').StreamingData.*obj.Values('Options').delta_T./ ...
                                (35.314666*60*1000);
                end
                BSMSS = zeros(ModeSegregation.nModes , 1);
            end
            for k = 1:ModeSegregation.nModes
                MinPrimaryDR(k) = min(obj.Values('DR').StreamingData(ModeSegregation.getModeIndices(k)==1));
                MinSecondaryDR(k) = min(obj.Values('Q_Part').StreamingData(ModeSegregation.getModeIndices(k)==1)./ ...
                    (obj.Values('Q_Part').StreamingData(ModeSegregation.getModeIndices(k)==1)-obj.Values('Q_2Dil').StreamingData(ModeSegregation.getModeIndices(k)==1)));
                MinTotalDR(k) = min(obj.Values('Q_Part').StreamingData(ModeSegregation.getModeIndices(k)==1).* ...
                    obj.Values('DR').StreamingData(ModeSegregation.getModeIndices(k)==1)./(obj.Values('Q_Part').StreamingData(ModeSegregation.getModeIndices(k)==1)- ...
                    obj.Values('Q_2Dil').StreamingData(ModeSegregation.getModeIndices(k)==1)));
                if obj.isKey('MSS_CC') && mean(obj.Values('MSS_CC').StreamingData)>0
                    BSMSS(k) = sum(BSMSSg(ModeSegregation.getModeIndices(k)==1))./obj.Values('Work').ModeCompositeData(k);
                end
            end

            if length(PM_Data) == ModeSegregation.nModes
                if obj.isKey('MSS_CC') && mean(obj.Values('MSS_CC').StreamingData)>0
                    if obj.Values('Options').MSS_Sample_Position == 9 || obj.Values('Options').MSS_Sample_Position == 6
                        LM.DebugPrint(1, 'MSS Calculation uses CVS Flow')
                        PMTable = cell(length(PM_Data)+1, 13);
                        PMTable(1,:)      = {'Mode' 'Eng_Speed (RPM)' 'Torque (N.m)' 'Weight_Gain (mg)' 'Q_Part (scf/m)' 'Q_Aux_CVS_Eq (scf/m)' 'Minimum Primary DR' 'Minimum Secondary DR' 'Minimum Combined DR' 'BSPM (g/kW.hr)' 'MSS_CC (mg/m3)' 'Q_CVS_C (scf/m)' 'BS_MSS (g/kW.hr)'};
                        PMTable(2:end,1)  = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');
                        PMTable(2:end,2)  = num2cell(obj.Values('Eng_Speed').ModeCompositeData);
                        PMTable(2:end,3)  = num2cell(obj.Values('Torque').ModeCompositeData);
                        PMTable(2:end,4)  = num2cell(PM_Data);
                        PMTable(2:end,5)  = num2cell(obj.Values('Q_Part').ConvertModeComposite('scf/m'));
                        PMTable(2:end,6)  = num2cell(obj.Values('Q_Part').ConvertModeComposite('scf/m').*obj.Values('Q_CVS_C').ModeCompositeData./ ...
                            (obj.Values('Q_Part').ConvertModeComposite('scf/m')-obj.Values('Q_2Dil').ConvertModeComposite('scf/m')));
                        PMTable(2:end,7)  = num2cell(MinPrimaryDR);
                        PMTable(2:end,8)  = num2cell(MinSecondaryDR);
                        PMTable(2:end,9)  = num2cell(MinTotalDR);
                        PMTable(2:end,10) = num2cell(PM_Data.*(obj.Values('Q_Part').ConvertModeComposite('scf/m').*obj.Values('Q_CVS_C').ModeCompositeData./ ...
                            (obj.Values('Q_Part').ConvertModeComposite('scf/m')-obj.Values('Q_2Dil').ConvertModeComposite('scf/m')))./(1000.*obj.Values('Q_Part').ConvertModeComposite('scf/m').* ...
                            obj.Values('Work').ModeCompositeData));
                        PMTable(2:end,11) = num2cell(obj.Values('MSS_CC').ModeCompositeData);
                        PMTable(2:end,12) = num2cell(obj.Values('Q_CVS_C').ModeCompositeData);
                        PMTable(2:end,13) = num2cell(BSMSS);
                    else
                        LM.DebugPrint(1, 'MSS Calculation uses Raw Exhaust Flow')
                        PMTable = cell(length(PM_Data)+1, 13);
                        PMTable(1,:)      = {'Mode' 'Eng_Speed (RPM)' 'Torque (N.m)' 'Weight_Gain (mg)' 'Q_Part (scf/m)' 'Q_Aux_CVS_Eq (scf/m)' 'Minimum Primary DR' 'Minimum Secondary DR' 'Minimum Combined DR' 'BSPM (g/kW.hr)' 'MSS_CC (mg/m3)' 'Q_Ex (scf/m)' 'BS_MSS (g/kW.hr)'};
                        PMTable(2:end,1)  = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');
                        PMTable(2:end,2)  = num2cell(obj.Values('Eng_Speed').ModeCompositeData);
                        PMTable(2:end,3)  = num2cell(obj.Values('Torque').ModeCompositeData);
                        PMTable(2:end,4)  = num2cell(PM_Data);
                        PMTable(2:end,5)  = num2cell(obj.Values('Q_Part').ConvertModeComposite('scf/m'));
                        PMTable(2:end,6)  = num2cell(obj.Values('Q_Part').ConvertModeComposite('scf/m').*obj.Values('Q_CVS_C').ModeCompositeData./ ...
                            (obj.Values('Q_Part').ConvertModeComposite('scf/m')-obj.Values('Q_2Dil').ConvertModeComposite('scf/m')));
                        PMTable(2:end,7)  = num2cell(MinPrimaryDR);
                        PMTable(2:end,8)  = num2cell(MinSecondaryDR);
                        PMTable(2:end,9)  = num2cell(MinTotalDR);
                        PMTable(2:end,10) = num2cell(PM_Data.*(obj.Values('Q_Part').ConvertModeComposite('scf/m').*obj.Values('Q_CVS_C').ModeCompositeData./ ...
                            (obj.Values('Q_Part').ConvertModeComposite('scf/m')-obj.Values('Q_2Dil').ConvertModeComposite('scf/m')))./(1000.*obj.Values('Q_Part').ConvertModeComposite('scf/m').* ...
                            obj.Values('Work').ModeCompositeData));
                        PMTable(2:end,11) = num2cell(obj.Values('MSS_CC').ModeCompositeData);
                        PMTable(2:end,12) = num2cell(obj.Values('Q_Ex').ModeCompositeData);
                        PMTable(2:end,13) = num2cell(BSMSS);
                    end
                else
                    PMTable = cell(length(PM_Data)+1, 10);
                    PMTable(1,:)      = {'Mode' 'Eng_Speed (RPM)' 'Torque (N.m)' 'Weight_Gain (mg)' 'Q_Part (scf/m)' 'Q_Aux_CVS_Eq (scf/m)' 'Minimum Primary DR' 'Minimum Secondary DR' 'Minimum Combined DR' 'BSPM (g/kW.hr)'};
                    PMTable(2:end,1)  = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');
                    PMTable(2:end,2)  = num2cell(obj.Values('Eng_Speed').ModeCompositeData);
                    PMTable(2:end,3)  = num2cell(obj.Values('Torque').ModeCompositeData);
                    PMTable(2:end,4)  = num2cell(PM_Data);
                    PMTable(2:end,5)  = num2cell(obj.Values('Q_Part').ConvertModeComposite('scf/m'));
                    PMTable(2:end,6)  = num2cell(obj.Values('Q_Part').ConvertModeComposite('scf/m').*obj.Values('Q_CVS_C').ModeCompositeData./ ...
                        (obj.Values('Q_Part').ConvertModeComposite('scf/m')-obj.Values('Q_2Dil').ConvertModeComposite('scf/m')));
                    PMTable(2:end,7)  = num2cell(MinPrimaryDR);
                    PMTable(2:end,8)  = num2cell(MinSecondaryDR);
                    PMTable(2:end,9)  = num2cell(MinTotalDR);
                    PMTable(2:end,10) = num2cell(PM_Data.*(obj.Values('Q_Part').ConvertModeComposite('scf/m').*obj.Values('Q_CVS_C').ModeCompositeData./ ...
                        (obj.Values('Q_Part').ConvertModeComposite('scf/m')-obj.Values('Q_2Dil').ConvertModeComposite('scf/m')))./(1000.*obj.Values('Q_Part').ConvertModeComposite('scf/m').* ...
                        obj.Values('Work').ModeCompositeData));
                end
            else % only one filter
                if length(PM_Data) == 1
                    if obj.isKey('MSS_CC') && mean(obj.Values('MSS_CC').StreamingData)>0
                        if obj.Values('Options').MSS_Sample_Position == 9 || obj.Values('Options').MSS_Sample_Position == 6
                            LM.DebugPrint(1, 'MSS Calculation uses CVS Flow')
                            PMTable = cell(2, 13);
                            PMTable(1,:)  = {'Mode' 'Eng_Speed (RPM)' 'Torque (N.m)' 'Weight_Gain (mg)' 'Q_Part (scf/m)' 'Q_Aux_CVS_Eq (scf/m)' 'Minimum Primary DR' 'Minimum Secondary DR' 'Minimum Combined DR' 'BSPM (g/kW.hr)' 'MSS_CC (mg/m3)' 'Q_CVS_C (scf/m)' 'BS_MSS (g/kW.hr)'};
                            PMTable{2,1}  = '-';
                            PMTable{2,2}  = mean(obj.Values('Eng_Speed').StreamingData);
                            PMTable{2,3}  = mean(obj.Values('Torque').StreamingData);
                            PMTable{2,4}  = PM_Data(1);
                            PMTable{2,5}  = mean(obj.Values('Q_Part').ConvertStreaming('scf/m'));
                            PMTable{2,6}  = mean(obj.Values('Q_Part').ConvertStreaming('scf/m').*obj.Values('Q_CVS_C').StreamingData./ ...
                                (obj.Values('Q_Part').ConvertStreaming('scf/m')-obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                            PMTable{2,7}  = min(obj.Values('DR').StreamingData);
                            PMTable{2,8}  = min(obj.Values('Q_Part').ConvertStreaming('scf/m')./(obj.Values('Q_Part').ConvertStreaming('scf/m')-obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                            PMTable{2,9}  = min(obj.Values('DR').StreamingData.*obj.Values('Q_Part').ConvertStreaming('scf/m')./(obj.Values('Q_Part').ConvertStreaming('scf/m')- ...
                                obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                            PMTable{2,10} = PMTable{2,4}.*PMTable{2,6}/(1000*PMTable{2,5}.*sum(obj.Values('Work').StreamingData(obj.Values('Work').StreamingData>=0)));
                            PMTable{2,11} = mean(obj.Values('MSS_CC').StreamingData);
                            PMTable{2,12} = mean(obj.Values('Q_CVS_C').StreamingData);
                            PMTable{2,13} = sum(BSMSSg)/sum(obj.Values('Work').ModeCompositeData);
                        else
                            LM.DebugPrint(1, 'MSS Calculation uses Raw Exhaust Flow')
                            PMTable = cell(2, 13);
                            PMTable(1,:)  = {'Mode' 'Eng_Speed (RPM)' 'Torque (N.m)' 'Weight_Gain (mg)' 'Q_Part (scf/m)' 'Q_Aux_CVS_Eq (scf/m)' 'Minimum Primary DR' 'Minimum Secondary DR' 'Minimum Combined DR' 'BSPM (g/kW.hr)' 'MSS_CC (mg/m3)' 'Q_Ex (scf/m)' 'BS_MSS (g/kW.hr)'};
                            PMTable{2,1}  = '-';
                            PMTable{2,2}  = mean(obj.Values('Eng_Speed').StreamingData);
                            PMTable{2,3}  = mean(obj.Values('Torque').StreamingData);
                            PMTable{2,4}  = PM_Data(1);
                            PMTable{2,5}  = mean(obj.Values('Q_Part').ConvertStreaming('scf/m'));
                            PMTable{2,6}  = mean(obj.Values('Q_Part').ConvertStreaming('scf/m').*obj.Values('Q_CVS_C').StreamingData./ ...
                                (obj.Values('Q_Part').ConvertStreaming('scf/m')-obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                            PMTable{2,7}  = min(obj.Values('DR').StreamingData);
                            PMTable{2,8}  = min(obj.Values('Q_Part').ConvertStreaming('scf/m')./(obj.Values('Q_Part').ConvertStreaming('scf/m')-obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                            PMTable{2,9}  = min(obj.Values('DR').StreamingData.*obj.Values('Q_Part').ConvertStreaming('scf/m')./(obj.Values('Q_Part').ConvertStreaming('scf/m')- ...
                                obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                            PMTable{2,10} = PMTable{2,4}.*PMTable{2,6}/(1000*PMTable{2,5}.*sum(obj.Values('Work').StreamingData(obj.Values('Work').StreamingData>=0)));
                            PMTable{2,11} = mean(obj.Values('MSS_CC').StreamingData);
                            PMTable{2,12} = mean(obj.Values('Q_Ex').StreamingData);
                            PMTable{2,13} = sum(BSMSSg)/sum(obj.Values('Work').ModeCompositeData);
                        end
                    else
                        PMTable = cell(2, 10);
                        PMTable(1,:)  = {'Mode' 'Eng_Speed (RPM)' 'Torque (N.m)' 'Weight_Gain (mg)' 'Q_Part (scf/m)' 'Q_Aux_CVS_Eq (scf/m)' 'Minimum Primary DR' 'Minimum Secondary DR' 'Minimum Combined DR' 'BSPM (g/kW.hr)'};
                        PMTable{2,1}  = '-';
                        PMTable{2,2}  = mean(obj.Values('Eng_Speed').StreamingData);
                        PMTable{2,3}  = mean(obj.Values('Torque').StreamingData);
                        PMTable{2,4}  = PM_Data(1);
                        PMTable{2,5}  = mean(obj.Values('Q_Part').ConvertStreaming('scf/m'));
                        PMTable{2,6}  = mean(obj.Values('Q_Part').ConvertStreaming('scf/m').*obj.Values('Q_CVS_C').StreamingData./ ...
                            (obj.Values('Q_Part').ConvertStreaming('scf/m')-obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                        PMTable{2,7}  = min(obj.Values('DR').StreamingData);
                        PMTable{2,8}  = min(obj.Values('Q_Part').ConvertStreaming('scf/m')./(obj.Values('Q_Part').ConvertStreaming('scf/m')-obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                        PMTable{2,9}  = min(obj.Values('DR').StreamingData.*obj.Values('Q_Part').ConvertStreaming('scf/m')./(obj.Values('Q_Part').ConvertStreaming('scf/m')- ...
                            obj.Values('Q_2Dil').ConvertStreaming('scf/m')));
                        PMTable{2,10} = PMTable{2,4}.*PMTable{2,6}/(1000*PMTable{2,5}.*sum(obj.Values('Work').StreamingData(obj.Values('Work').StreamingData>=0)));
                    end
                else
                    PMTable = cell(length(PM_Data)+1,2);
                    PMTable(1,:) = {'Filter #','Filter Weight Gain (mg)'};
                    for k = 1:length(PM_Data)
                        PMTable{k+1,1} = k;
                        PMTable{k+1,2} = PM_Data(k);
                    end
                end
            end
        end

        function CustomerDefinedTables = MakeCustomerDefinedTables(obj)
            global LM LOCALPATH;
            nModes = length(obj.Values('Time').ModeCompositeData);
            CustomerDefinedTables = [];
            for k = 1:obj.Values('Options').Number_CDRs
                filename = obj.Values('Options').(['CDR_' num2str(k)]);
                location = obj.Values('Options').(['CDR_' num2str(k) '_Location']);
                if strcmp(location,'Local')
                    try
                        nrows = NumberOfRows('',[LOCALPATH  '\Customer Defined Tables\' filename])+1;
                        fId = fopen([LOCALPATH  '\Customer Defined Tables\' filename]);
                    catch %#ok
                        LM.DebugPrint(1, 'No Customer Defined Table definition %s', filename);
                        continue;
                    end
                else
                    try
                        nrows = NumberOfRows('',[obj.Values('Options').Network_Path 'Customer Defined Tables\' filename])+1;
                        fId = fopen([obj.Values('Options').Network_Path 'Customer Defined Tables\' filename]);
                    catch %#ok
                        LM.DebugPrint(1, 'No Customer Defined Table definition %s', filename);
                        continue;
                    end
                end
                if isempty(CustomerDefinedTables)
                    CustomerDefinedTables = cell(nModes+1,nrows);
                else
                    LM.DebugPrint(1,'Multiple customer defined tables are not yet supported');
                end
                for j = 1:nrows
                    ChannelGet = fgetl(fId);
                    if ~isempty(ChannelGet)
                        CustomerDefinedTables{1,j} = ChannelGet;
                        if instr(ChannelGet, 'Bench')
                            if instr(ChannelGet, 'g/kW.hr')
                                CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ModeCompositeData.Part86BrakeSpecificMass);
                            elseif instr(ChannelGet, '(g)')
                                CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ModeCompositeData.Part86Mass);
                            else
                                CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ModeCompositeData.Part86Concentration);
                            end
                        elseif instr(ChannelGet, 'Options.')
                            ChannelGet = strrep(ChannelGet, 'Options.', '');
                            if ~instr(ChannelGet, '.')
                                CustomerDefinedTables{1,j} = ChannelGet;
                                if ischar(obj.Values('Options').(ChannelGet))
                                    CustomerDefinedTables(2:end,j) = cellstr(obj.Values('Options').(ChannelGet));
                                else
                                    CustomerDefinedTables(2:end,j) = num2cell(obj.Values('Options').(ChannelGet));
                                end
                            else
                                structure = stringread(ChannelGet, '.');
                                CustomerDefinedTables{1,j} = strrep(ChannelGet,'.','_');
                                options = obj.Values('Options');
                                a = options.(structure{1});
                                for m = 2:(length(structure)-1)
                                    a = a.(structure{m});
                                end
                                if ischar(a.(structure{m+1}))
                                    CustomerDefinedTables(2:end,j) = cellstr(a.(structure{m+1}));
                                else
                                    CustomerDefinedTables(2:end,j) = num2cell(a.(structure{m+1}));
                                end
                            end
                        else
                            % Check units
                            if obj.isKey(ProcessChannelNameb(ChannelGet))
                                if instr(ChannelGet, '(')
                                    Ropen = strfind(ChannelGet,'(');
                                    Rclose = strfind(ChannelGet,')');
                                    units = strtrim(ChannelGet(Ropen(end)+1:Rclose(end)-1));
                                    if ~strcmp(units,obj.Values(ProcessChannelNameb(ChannelGet)).Current_Units)
                                        try
                                            CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ConvertModeComposite(units));
                                        catch %#ok
                                            LM.DebugPrint(1,'Failed to convert %s',ChannelGet)
                                            CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ModeCompositeData);
                                        end
                                    else
                                        CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ModeCompositeData);
                                    end
                                else
                                    CustomerDefinedTables(2:end,j) = num2cell(obj.Values(ProcessChannelNameb(ChannelGet)).ModeCompositeData);
                                end
                            end
                        end
                    end
                end
                fclose(fId);
            end

            if isempty(CustomerDefinedTables)
                CustomerDefinedTables = -1;
            end
        end

        function AmbientTable = MakeAmbientTable(obj)
            global SPECIES;

            count = 0;
            for k = 1:length(SPECIES)
                if obj.isKey([SPECIES{k} '_Bag_Dilute']) && ~isempty(obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient)
                    count = count+1;
                end
                if obj.Values('Options').Part_1065.IsOn
                    if strcmp('HHC',SPECIES{k}) && ~obj.Values('Options').Use_HC
                        count = count+1;
                    elseif strcmp('HC',SPECIES{k}) && obj.Values('Options').Use_HC
                        count = count+1;
                    elseif strcmp('CH4',SPECIES{k})
                        count = count+1;
                    end
                end
            end

            if count ~= 0
                if obj.Values('Options').Part_1065.IsOn && obj.Values('Options').Part_1065.DriftCorrection
                    AmbientTable = cell(8, count+1);
                    AmbientTable(:,1) = {'Analyzer'; 'Units'; 'Pre-Test Ambient'; 'Post-Test Ambient'; 'Average Ambient'; 'MF Pre-Test Ambient'; 'MF Post-Test Ambient'; 'MF Average Ambient'};
                    position = 2;
                    for k = 1:length(SPECIES)
                        if obj.isKey([SPECIES{k} '_Bag_Dilute'])
                            AmbientTable{1, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Name;
                            AmbientTable{2, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Current_Units{1};
                            AmbientTable{3, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part86PreTest;
                            AmbientTable{4, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part86PostTest;
                            AmbientTable{5, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part86Average;
                            AmbientTable{6, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part1065PreTest;
                            AmbientTable{7, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part1065PostTest;
                            AmbientTable{8, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part1065Average;
                            position = position+1;
                        end
                        if obj.Values('Options').Part_1065.IsOn
                            if strcmp('HHC',SPECIES{k}) && ~obj.Values('Options').Use_HC && obj.isKey([SPECIES{k} '_Bag_Dilute'])
                                AmbientTable{1, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Name;
                                AmbientTable{2, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Current_Units{1};
                                AmbientTable{3, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86PreTest;
                                AmbientTable{4, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86PostTest;
                                AmbientTable{5, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86Average;
                                AmbientTable{6, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065PreTest;
                                AmbientTable{7, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065PostTest;
                                AmbientTable{8, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065Average;
                                position = position+1;
                            elseif strcmp('HC',SPECIES{k}) && obj.Values('Options').Use_HC && obj.isKey([SPECIES{k} '_Bag_Dilute'])
                                AmbientTable{1, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Name;
                                AmbientTable{2, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Current_Units{1};
                                AmbientTable{3, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86PreTest;
                                AmbientTable{4, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86PostTest;
                                AmbientTable{5, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86Average;
                                AmbientTable{6, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065PreTest;
                                AmbientTable{7, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065PostTest;
                                AmbientTable{8, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065Average;
                                position = position+1;
                            elseif strcmp('CH4',SPECIES{k}) && obj.isKey([SPECIES{k} '_Bag_Dilute'])
                                AmbientTable{1, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Name;
                                AmbientTable{2, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Current_Units{1};
                                AmbientTable{3, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86PreTest;
                                AmbientTable{4, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86PostTest;
                                AmbientTable{5, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part86Average;
                                AmbientTable{6, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065PreTest;
                                AmbientTable{7, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065PostTest;
                                AmbientTable{8, position} = obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).Ambient.Part1065Average;
                                position = position+1;
                            end
                        end
                    end
                else
                    AmbientTable = cell(5, count+1);
                    AmbientTable(:,1) = {'Analyzer'; 'Units'; 'Pre-Test Ambient'; 'Post-Test Ambient'; 'Average Ambient'};
                    position = 2;
                    for k = 1:length(SPECIES)
                        if obj.isKey([SPECIES{k} '_Bag_Dilute'])
                            AmbientTable{1, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Name;
                            AmbientTable{2, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Current_Units{1};
                            AmbientTable{3, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part86PreTest;
                            AmbientTable{4, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part86PostTest;
                            AmbientTable{5, position} = obj.Values([SPECIES{k} '_Bag_Dilute']).Ambient.Part86Average;
                            position = position+1;
                        end
                    end
                end
            else
                AmbientTable = -1;
            end
        end

        function VZSTable = MakeVZSTable(obj)
            global SPECIES BENCHES;

            count = 0;
            for k = 1:length(BENCHES)
                for m = 1:length(SPECIES)
                    if strcmp(SPECIES{k},'NMHC'), continue; end;
                    if obj.isKey([SPECIES{m} '_' BENCHES{k}])
                        count = count+1;
                    end
                end
            end

            VZSTable = cell(count+1,11);
            VZSTable(1,:) = {'Analyzer' 'Units' 'Range' 'Maximum Concentration' 'Reference Concentration' 'Pre Test Zero' 'Pre Test Span' 'Pre Test Zero Check' 'Post Test Zero' 'Post Test Span' 'Associated Modes'};
            position = 2;

            for k = 1:length(BENCHES)
                for m = 1:length(SPECIES)
                    if strcmp(SPECIES{m},'NMHC'), continue; end;
                    if obj.isKey([SPECIES{m} '_' BENCHES{k}])
                        ranges = cell2mat(obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS.keys);
                        for n = 1:length(ranges)
                            VZSTable{position, 1} = obj.Values([SPECIES{m} '_' BENCHES{k}]).Name;
                            VZSTable{position, 2} = obj.Values([SPECIES{m} '_' BENCHES{k}]).Current_Units{1};
                            VZSTable{position, 3} = ranges(n);
                            VZSTable{position, 4} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).MaximumConcentration;
                            VZSTable{position, 5} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).ReferenceConcentration;
                            VZSTable{position, 6} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).RawPreTestZero;
                            VZSTable{position, 7} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).RawPreTestSpan;
                            VZSTable{position, 8} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).CorrectedPreTestZeroCheck;
                            VZSTable{position, 9} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).CorrectedPostTestZero;
                            VZSTable{position, 10} = obj.Values([SPECIES{m} '_' BENCHES{k}]).VZS(ranges(n)).CorrectedPostTestSpan;
                            ActiveRanges = '';
                            for o = 1:size(obj.Values([SPECIES{m} '_' BENCHES{k}]).Ranges,2)
                                if strcmp(SPECIES{m},'CO_l') && obj.isKey(['CO_h_' BENCHES{k}])
                                    if obj.Values([SPECIES{m} '_' BENCHES{k}]).Ranges(o) == ranges(n) && obj.Values('Options').([BENCHES{k} '_CO_l_InUse'])(o) == 1
                                        ActiveRanges = [ActiveRanges num2str(o) ', '];
                                    end
                                elseif strcmp(SPECIES{m},'CO_h') && obj.isKey(['CO_l_' BENCHES{k}])
                                    if obj.Values([SPECIES{m} '_' BENCHES{k}]).Ranges(o) == ranges(n) && obj.Values('Options').([BENCHES{k} '_CO_l_InUse'])(o) == 0
                                        ActiveRanges = [ActiveRanges num2str(o) ', '];
                                    end
                                elseif obj.Values([SPECIES{m} '_' BENCHES{k}]).Ranges(o) == ranges(n)
                                    ActiveRanges = [ActiveRanges num2str(o) ', '];
                                end
                            end
                            ActiveRanges = left(ActiveRanges, length(ActiveRanges)-2);
                            if isempty(ActiveRanges), ActiveRanges = '-'; end;
                            VZSTable{position, 11} = ActiveRanges;
                            position = position+1;
                        end
                    end
                end
            end
        end

        function DriftTable = MakeDriftTable(obj)
            global SPECIES;

            if ~(obj.Values('Options').Part_1065.IsOn && obj.Values('Options').Part_1065.DriftCorrection), DriftTable = -1; return; end;

            count = 0;
            for k = 1:length(SPECIES)
                if obj.isKey([SPECIES{k} '_Bag_Dilute'])
                    count = count+1;
                end
            end

            DriftTable = cell(size(obj.Values('Time').ModeCompositeData,1)+1,3*count+1);

            DriftTable{1,1} = 'Mode';
            DriftTable(2:end,1) = num2cell((1:size(obj.Values('Time').ModeCompositeData,1))');

            position = 2;
            for k = 1:length(SPECIES)
                if obj.isKey([SPECIES{k} '_Bag_Dilute'])
                    
                    % Display the corrected and uncorrected values as well as the drift percentage. Note that we won't worry about division by 0 
                    % since MATLAB should return Inf if the numerator is nonzero and NaN if the numerator is 0.
                    if (strcmp('HHC',SPECIES{k}) && ~obj.Values('Options').Use_HC) || (strcmp('HC',SPECIES{k}) && obj.Values('Options').Use_HC) || (strcmp('CH4',SPECIES{k}))
                        DriftTable{1,position} = ['Uncorrected ' obj.Values([SPECIES{k} '_Bag_Dilute']).Name ' (' obj.Values([SPECIES{k} '_Bag_Dilute']).Current_Units{3} ')'];
                        DriftTable(2:end,position) = num2cell(obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).ModeCompositeData.BrakeSpecificMass);
                        position = position+1;
                        DriftTable{1,position} = [obj.Values([SPECIES{k} '_Bag_Dilute']).Name ' (' obj.Values([SPECIES{k} '_Bag_Dilute']).Current_Units{3} ')'];
                        DriftTable(2:end,position) = num2cell(obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).ModeCompositeData.Part1065BrakeSpecificMass);
                        position = position+1;
                        DriftTable{1,position} = ['% Error ' obj.Values([SPECIES{k} '_Bag_Dilute']).Name];
                        errors = cellstr(num2str(100*(obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).ModeCompositeData.Part1065BrakeSpecificMass - ...                            
                            obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).ModeCompositeData.BrakeSpecificMass) ./ ...
                            obj.Values([SPECIES{k} '_Bag_Dilute_Corrected']).ModeCompositeData.BrakeSpecificMass));                        
                    else
                        DriftTable{1,position} = ['Uncorrected ' obj.Values([SPECIES{k} '_Bag_Dilute']).Name ' (' obj.Values([SPECIES{k} '_Bag_Dilute']).Current_Units{3} ')'];
                        DriftTable(2:end,position) = num2cell(obj.Values([SPECIES{k} '_Bag_Dilute']).ModeCompositeData.BrakeSpecificMass);
                        position = position+1;
                        DriftTable{1,position} = [obj.Values([SPECIES{k} '_Bag_Dilute']).Name ' (' obj.Values([SPECIES{k} '_Bag_Dilute']).Current_Units{3} ')'];
                        DriftTable(2:end,position) = num2cell(obj.Values([SPECIES{k} '_Bag_Dilute']).ModeCompositeData.Part1065BrakeSpecificMass);
                        position = position+1;
                        DriftTable{1,position} = ['% Error ' obj.Values([SPECIES{k} '_Bag_Dilute']).Name];
                        errors = cellstr(num2str(100*(obj.Values([SPECIES{k} '_Bag_Dilute']).ModeCompositeData.Part1065BrakeSpecificMass - ...                           
                            obj.Values([SPECIES{k} '_Bag_Dilute']).ModeCompositeData.BrakeSpecificMass) ./ ...
                            obj.Values([SPECIES{k} '_Bag_Dilute']).ModeCompositeData.BrakeSpecificMass));              
                    end
                    
                    % Update Drift Table
                    for m = 1:length(errors), if ~strcmp(strtrim(errors{m}),'Inf') && ~strcmp(strtrim(errors{m}),'NaN'), errors{m} = [errors{m} '%']; end; end;
                    DriftTable(2:end,position) = errors;
                    position = position+1;                    
                end

            end

        end

        function containedObject = Values(obj, key)
            containedObject = obj.values{ismember(obj.keys, key)==1};
        end

    end

    methods (Static)

        function [name, units] = Segregate(channel)
            Ropen = strfind(channel,'(');
            Rclose = strfind(channel,')');
            if ~isempty(Ropen)
                units = strtrim(channel(Ropen(end)+1:Rclose(end)-1));
                name = strtrim([channel(1:Ropen(end)-1),' ',strtrim(channel(Rclose(end)+1:length(channel)))]);
            else
                units = '';
                name = channel;
            end
            if strcmpi(units,'n/a') || strcmpi(units,'none')
                units = '';
            end
        end

        function PMData = GetPMData(ModeSegregation)
            global LM TESTNUMBER;
            try %Connect to database - if database isn't available then have the user either quit out or select a fuel type
                NET.addAssembly('System.Data'); %this imports the library into MATLAB
                connString = 'DSN=VTREUPDATE';
                odbcCN = System.Data.Odbc.OdbcConnection(connString);
                odbcCN.Open(); % connects to the SQL Server (must have DSN)
            catch %#ok<CTCH>
                LM.DebugPrint(1,'ALARM: MATLAB was unable to connect to the requested database');
                PMData = -1;
                return;
            end
            sql = ['SELECT * FROM tbl_PM_Filter WHERE Test_Number = ' num2str(TESTNUMBER)];
            odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
            res = odbcCOM.ExecuteReader();

            PMData = zeros(ModeSegregation.nModes, 1);

            while (res.Read())
                try
                    ModeNumber = double(res.GetValue(19));
                    if ModeNumber == 0, LM.DebugPrint(1,'WARNING: PM Data was found for this test which doesn''t have a valid Mode Number, please adjust the database'); continue; end;
                    PMData(ModeNumber) = double(res.GetValue(11))-double(res.GetValue(10));
                    if PMData(ModeNumber) < 0, PMData(ModeNumber) = 0; LM.DebugPrint(1,'WARNING: PM Data was found for Mode #%d but the weight gain was negative',ModeNumber); end;
                catch %#ok
                    % DBNull should get funneled to here
                    LM.DebugPrint(1,'WARNING: PM Data was found for this test which doesn''t have a valid Mode Number, please adjust the database');
                end
            end

            if sum(PMData) == 0, PMData = -1; end;
            res.Close()
        end

        function CArray = MergeTables(CompositeArray, HeaderTable, EmissionsTable, BSFCTable, PMTable, CustomerDefinedTables, AmbientTable, VZSTable, DriftTable)
            widths = [size(CompositeArray,2) size(HeaderTable,2) size(EmissionsTable,2) size(BSFCTable,2) size(PMTable,2) size(CustomerDefinedTables,2) size(AmbientTable,2) size(VZSTable,2) size(DriftTable,2)];
            lengths = [size(CompositeArray,1) size(HeaderTable,1) size(EmissionsTable,1) size(BSFCTable,1) size(PMTable,1) size(CustomerDefinedTables,1) size(AmbientTable,1) size(VZSTable,1) size(DriftTable,1)];

            CArray = cell(sum(lengths)+24,max(widths)); % good heuristic for spacing pattern - modify as necessary
            current_pos = [1 1];

            for k = 1:9
                switch k
                    case 1
                        final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                        CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = CompositeArray;
                        current_pos = [current_pos(1)+lengths(k)+1 1];
                    case 2
                        final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                        CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = HeaderTable;
                        current_pos = [current_pos(1)+lengths(k) 1];
                        CArray{current_pos(1), current_pos(2)} = 'Results Summary';
                        current_pos = [current_pos+1, 2];
                    case 3
                        CArray{current_pos(1), current_pos(2)} = 'Emissions Report';
                        current_pos = [current_pos(1)+1, 3];
                        final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                        CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = EmissionsTable;
                        current_pos = [current_pos(1)+lengths(k)+1, 2];
                    case 4
                        CArray{current_pos(1), current_pos(2)} = 'BSFC Report';
                        current_pos = [current_pos(1)+1, 3];
                        final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                        CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = BSFCTable;
                        current_pos = [current_pos(1)+lengths(k)+1, 2];
                    case 5
                        if iscell(PMTable)
                            CArray{current_pos(1), current_pos(2)} = 'PM Report';
                            current_pos = [current_pos(1)+1, 3];
                            final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                            CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = PMTable;
                            current_pos = [current_pos(1)+lengths(k)+1, 2];
                        end
                    case 6
                        if iscell(CustomerDefinedTables)
                            CArray{current_pos(1), current_pos(2)} = 'Customer Defined Reports';
                            current_pos = [current_pos(1)+1, 3];
                            final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                            CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = CustomerDefinedTables;
                            current_pos = [current_pos(1)+lengths(k)+1, 1];
                            CArray{current_pos(1), current_pos(2)} = 'Analyzer Results';
                            current_pos = [current_pos(1)+1, 2];
                        end
                    case 7
                        if iscell(AmbientTable)
                            CArray{current_pos(1), current_pos(2)} = 'Ambient Report';
                            current_pos = [current_pos(1)+1, 3];
                            final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                            CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = AmbientTable;
                            current_pos = [current_pos(1)+lengths(k)+1, 2];
                        end
                    case 8
                        CArray{current_pos(1), current_pos(2)} = 'Zero Span Report';
                        current_pos = [current_pos(1)+1, 3];
                        final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                        CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = VZSTable;
                        current_pos = [current_pos(1)+lengths(k)+1, 2];
                    case 9
                        if iscell(DriftTable)
                            CArray{current_pos(1), current_pos(2)} = 'Drift Report';
                            current_pos = [current_pos(1)+1, 3];
                            final_pos = [current_pos(1)+lengths(k)-1 current_pos(2)+widths(k)-1];
                            CArray(current_pos(1):final_pos(1),current_pos(2):final_pos(2)) = DriftTable;
                        end
                end
            end
        end


    end
end
