function strPiece = left(strName, intLen)
    if length(strName) < intLen
        intLen = length(strName);
    end
	strPiece = strName(1:intLen);
end % function