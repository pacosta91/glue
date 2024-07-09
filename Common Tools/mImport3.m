function A = mImport3(filename, start, width)
% This function loads in the header and body separately to improve load
% times. It relies on the fact that the data in the csv is NOT a mixed data
% type (i.e., comprised of strings and floats thrown around loosely) but
% rather that the header is comprised of string data and the body doubles
% and/or integers. The data is brought into A, a cell array which can be
% referenced as A{i,j}.
%
% Note: The 'start' parameter refers to the location of the first row of
% data, not including the header. Thus start = 1, refers to the first row
% of data in the file, not the header. The 'width' parameter refers to the
% number of columns to import, beginning with the first column.

if ~exist('start', 'var'), start = 1; end

if nargin == 0
    [filename, pathname] = uigetfile('*.*','MultiSelect','off');
    if filename == 0, return; end
    filename = fullfile(pathname, filename);
end

try
    % Grab the file body
    temp = csvread(filename, start, 0); %error('Fake Error');
       
    % Grab the file header
    fid = fopen(filename);
    temphdr = textscan(fgetl(fid),'%s','delimiter',',');
    fclose(fid);
    
    % Limit the width if available
    if nargin == 3 
        data = temp(:,[1:floor(width)]);
        header = temphdr{1}(1:floor(width))';
    else
        data = temp;
        header = temphdr{1}';
    end
    
    % The first row is assumed to contain the data headers. The quickest
    % method would be as follows:
    %
    % A.colheaders = header{1}';
    % A.data = temp;
    %
    % We want the output from this function to be exactly the same as the 
    % previous implementation:
    A = [header; num2cell(data)];  
    
catch ME
    % Since the new method bombed, we'll revert back to the old import
    % method
    clear temp fid emphdr data header A
    nrows = NumberOfRows('', filename);
    fid = fopen(filename);
    thisline = textscan(fgetl(fid),'%s','delimiter',',');

    % Although it isn't quite as efficient as loading just a portion of the
    % file, we'll nonetheless load the entire file then trim it later.
    temp = cell(nrows, length(thisline{1}));
    
    for i = 1:length(thisline{1})
        if isempty(sscanf(thisline{1}{i}, '%f'))
            temp{1,i} = thisline{1}{i};
        else
            temp{1,i} = sscanf(thisline{1}{i}, '%f');
        end
    end

    count = 2;
    
    while ~feof(fid)
        thisline = fgetl(fid);
        if strcmp(thisline,''), continue; end
        data1 = textscan(thisline,'%s','delimiter',',');
        for i = 1:length(data1{1})
            if isempty(sscanf(data1{1}{i}, '%f'))
                temp{count,i} = data1{1}{i};
            else
                temp{count,i} = sscanf(data1{1}{i}, '%f');
            end
        end
        count = count + 1;
    end
    fclose(fid);
    
    % Trim the final cell array
    A = [temp(1, 1:12); temp(start+1:end, 1:12)];
    
end