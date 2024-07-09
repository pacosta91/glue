function b=isfunc(FuncName)

if ~strcmp(right(FuncName,2),'.m')
    FuncName = [FuncName '.m'];
end

fid = fopen(FuncName);
if fid == -1
    b = 0;
else
    fclose(fid);
    b =1;
end