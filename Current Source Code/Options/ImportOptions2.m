function datastream = ImportOptions2(fname, datastream) 
% from Test - use customer/project/engine/type to determine which options
% panel to load, for now an example, experimental, file is pulled
% first scan local path, open local options panel.txt
global LM LOCALPATH;

fid = fopen([LOCALPATH, '\Settings Files\Options Panel.txt']);
Options = textscan(fid,'%s%s','Delimiter',',');
fclose(fid);
if strcmp(Options{1}{1},'Option_Panel')
    if strcmp(Options{2}{1},'Network')
        LM.DebugPrint(2, 'Using Network Options Panel, file:', fname);
        if strcmp(Options{1}{2},'Network_Path')
            try
                fid = fopen([Options{2}{2} 'Settings Files\' fname]);
                Options = textscan(fid,'%s%s','Delimiter',',');
                fclose(fid);
            catch %#ok - I'm not really concerned with what error occurs here, it's expected that the options panel file location is the source of the error
                LM.DebugPrint(1, 'ALARM: Glue was unable to find the options panel file, %s, the local options panel will be used instead', [Options{2}{2} fname]);
            end
        else
            LM.DebugPrint(1, 'ALARM: The local options panel is not properly formatted for networked options panels - the local file will be used instead');
        end
    else
        LM.DebugPrint(2, 'Using Local Options Panel');
    end
end


for i = 1:length(Options{1})
    if isnan(str2double(Options{2}{i}))
        set = Options{2}{i};
    else
        set = str2double(Options{2}{i});
    end
    if ~isempty(strfind(Options{1}{i},'.'))
        a = textscan(Options{1}{i},'%s','delimiter','.');
        b = a{1};
        switch length(b)
            case 2
                options.(b{1}).(b{2}) = set;
            case 3
                options.(b{1}).(b{2}).(b{3}) = set;
            case 4
                options.(b{1}).(b{2}).(b{3}).(b{4}) = set;
            case 5
                options.(b{1}).(b{2}).(b{3}).(b{4}).(b{5}) = set;
        end
    else
        if ischar(set)
            set = strrep(set,'/_',' ');
        end
        options.(Options{1}{i}) = set;
    end
end

datastream('Options') = options;