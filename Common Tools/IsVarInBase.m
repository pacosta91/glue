function InBase = IsVarInBase(var1)
W = evalin('base','who');
InBase=0;
for i = 1:length(W)
nm1 = W{i};
InBase = strcmp(nm1,var1) + InBase;
end
InBase(InBase>0) = 1;
end