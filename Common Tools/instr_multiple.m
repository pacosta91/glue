function returnArray = instr_multiple(cellArray, string)
returnArray = zeros(size(cellArray,1),size(cellArray,2));
for k = 1:size(cellArray,1)
    for m = 1:size(cellArray,2)
        returnArray(k,m) = instr(cellArray{k,m},string);
    end
end