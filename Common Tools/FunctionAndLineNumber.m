function ret = FunctionAndLineNumber()
% returns the current linenumber
    stack  = dbstack;
    N = length(stack);
    if N > 1, idx = 2; else idx = 1; end
    ret = [stack(idx).name ' (line ' num2str(stack(idx).line) ')']; % the function name and line number 
end