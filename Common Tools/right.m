function strPiece = right(strName, intLen) 
% right(strName, intLen)
% returns the rightmost intLen characters of a string
    if length(strName) < intLen
        intLen = length(strName);
    end
	strPiece = strName(length(strName)-intLen+1:length(strName));
end % function