function nrows = NumberOfRows(pathname, filename)
nrows = 0;
if nargin == 0
    % cd('\\usfs150\ETC\Testing\Engine\Customers\');
    [filename, pathname] = uigetfile('*.csv');
end
fname = fullfile(pathname,filename);
fid = fopen(fname);
fgetl(fid);
while ~feof(fid)
    fgetl(fid);
    nrows = nrows + 1;
end
fclose(fid);