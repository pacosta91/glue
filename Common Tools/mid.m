function mid = mid(str, intFirst, intLength)
if intFirst > length(str)
    mid = '';
    return
elseif intFirst + intLength - 1 > length(str)
    intLength = length(str)+1-intFirst;
end
mid = str(intFirst:intFirst+intLength-1);