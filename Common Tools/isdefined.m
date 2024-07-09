function bDef = isdefined(var)
bDef = 1;
try
    var;
catch
    bDef = 0;
end