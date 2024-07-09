function A = mImport(filename, start, width)
%Important: Uses sscanf instead of str2double!!!
%mImport will import data from a csv of a mixed data type - that is with
%strings and floats thrown around loosely. The data is brought into A, a
%cell array which can be referenced as A{i,j}
start = 1;

if nargin == 0
    [filename, pathname] = uigetfile('*.*','MultiSelect','off');
    if filename == 0, return; end
    filename = fullfile(pathname, filename);
end

nrows = NumberOfRows('', filename);
fid = fopen(filename);
thisline = textscan(fgetl(fid),'%s','delimiter',',');

if nargin == 2
    A = cell(nrows, length(thisline{1}));
else
    A = cell(nrows, width);
end

for i = 1:length(thisline{1})
%     if isnan(str2double(thisline{1}{i}))
    if isempty(sscanf(thisline{1}{i}, '%f'))
        A{start,i} = thisline{1}{i};
    else
%         A{start,i} = str2double(thisline{1}{i});
        A{start,i} = sscanf(thisline{1}{i}, '%f');
    end
end

count = 1;
while ~feof(fid)
    thisline = fgetl(fid);
    if strcmp(thisline,''), count = count+1; continue; end
    data1 = textscan(thisline,'%s','delimiter',',');
    for i = 1:length(data1{1})
%         if isnan(str2double(data1{1}{i}))
        if isempty(sscanf(data1{1}{i}, '%f'))
            A{start+count,i} = data1{1}{i};
        else
%             A{start+count,i} = str2double(data1{1}{i});
            A{start+count,i} = sscanf(data1{1}{i}, '%f');
        end
    end
    count = count + 1;
end
fclose(fid);


