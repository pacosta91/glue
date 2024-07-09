function RunMultipleTests(rootdir)

rootdir = 'D:\Testing\Engine\Customers\ISUZU\4H\834280\Data\';
listing = dir(rootdir);
files = {};

for i = 1:size(listing,1)
   if ~listing(i).isdir 
       [~,~,ext] = fileparts(listing(i).name);
       if strcmpi(ext,'.csv')
           files{end+1,1} = [rootdir, listing(i).name];
       end
   end    
end

% Run Glue
M = size(files,1);
for j = 1:M
    SuperGlue(files{j},0,1,0,0);
end

end