function folders = getPathFolders(path)

% Create a cell array of folder names comprising the path
folders = strsplit80(path,'\');

% Remove empty elements from each cell array
if iscell(folders), folders = folders(~cellfun('isempty',folders)); end


