function INCA_Map = Load_INCA_Names(filename)

if nargin == 0
    currentFolder = pwd;
    if exist('D:\Testing\Engine\Cell Mgt\Glue\INCA Channel Names\','dir')
        cd('D:\Testing\Engine\Cell Mgt\Glue\INCA Channel Names\');
    end
    [filename, pathname] = uigetfile('*.csv');
    filename = fullfile(pathname, filename);
    cd(currentFolder);
end

fid = fopen(filename);
INCA_Raw = textscan(fid,'%s%s','Delimiter',',');
INCA_Raw = [INCA_Raw{1} INCA_Raw{2}];
fclose(fid);

INCA_Map = containers.Map();

for k = 1:length(INCA_Raw)
    INCA_Map(INCA_Raw{k,1}) = INCA_Raw{k,2};
end