function Swap_INCA_Names(datastream, INCA_Map)

global LM;

Keys = INCA_Map.keys;
Values = INCA_Map.values;

for k = 1:length(Keys)
    if datastream.isKey(Keys{k})
        [newName, newUnit] = Segregate(Values{k});
        ThisChannel = datastream(Keys{k}); % I love singletons!
        ThisChannel.Name = newName;
        ThisChannel.Current_Units = newUnit;
        INCA_Map(Keys{k}) = newName;
    else
        LM.DebugPrint(1,'WARNING: INCA/CAS channel, %s - %s, not in ECCS data', Keys{k}, Values{k});
    end
end