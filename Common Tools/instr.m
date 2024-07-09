function bool = instr(String, SubString)
bool = 0;
if ~isempty(strfind(String,SubString)), bool = 1; return; end;