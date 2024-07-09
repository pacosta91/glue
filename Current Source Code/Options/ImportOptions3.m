function datastream = ImportOptions3(fname, datastream)
% from Test - use customer/project/engine/type to determine which options
% panel to load, for now an example, experimental, file is pulled
% first scan local path, open local options panel.txt
global LM LOCALPATH NETWORKPATH;

fid = fopen([LOCALPATH, '\Settings Files\Options Panel.txt']);
Options = textscan(fid,'%s%s','Delimiter',',');
fclose(fid);
if strcmp(Options{1}{1},'Option_Panel')
    if strcmp(Options{2}{1},'Network')
        LM.DebugPrint(2, 'Using Network Options Panel, file:', fname);
        if strcmp(Options{1}{2},'Network_Path')
            try
                fid = fopen([Options{2}{2} 'Settings Files\' fname]);
                NETWORKPATH = Options{2}{2};
                LM.DebugPrint(2, 'Using Network Options Panel');
            catch %#ok - I'm not really concerned with what error occurs here, it's expected that the options panel file location is the source of the error
                NETWORKPATH = LOCALPATH; % this is really hackish....I'm so sorry.... please don't hate me....
                LM.DebugPrint(1, 'ALARM: Glue was unable to find the options panel file, %s, the local options panel will be used instead', [Options{2}{2} fname]);
            end
        else
            LM.DebugPrint(1, 'ALARM: The local options panel is not properly formatted for networked options panels - the local file will be used instead');
        end
    else
        fid = fopen([LOCALPATH, '\Settings Files\Options Panel.txt']);
        LM.DebugPrint(2, 'Using Local Options Panel');
    end
end


while ~feof(fid)
    OptionsLine = stringread(fgetl(fid),',');
    if length(OptionsLine) == 2
        data = OptionsLine{2};
    else
        if ~strcmp(class(OptionsLine{2}),'double')
            data = OptionsLine(2:end);
        else
            data = cell2mat(OptionsLine(2:end));
        end
    end

    % Assign settings using dot notation specified in settings file
    OptionsTitle = stringread(OptionsLine{1},'.');
    switch length(OptionsTitle)
        case 1
            options.(OptionsTitle{1}) = data;
        case 2
            options.(OptionsTitle{1}).(OptionsTitle{2}) = data;
        case 3
            options.(OptionsTitle{1}).(OptionsTitle{2}).(OptionsTitle{3}) = data;
        case 4
            options.(OptionsTitle{1}).(OptionsTitle{2}).(OptionsTitle{3}).(OptionsTitle{4}) = data;
        case 5
            options.(OptionsTitle{1}).(OptionsTitle{2}).(OptionsTitle{3}).(OptionsTitle{4}).(OptionsTitle{5}) = data;
    end
end
fclose(fid);

datastream('Options') = options;