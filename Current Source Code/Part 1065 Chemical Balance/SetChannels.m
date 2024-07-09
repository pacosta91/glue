function datastream = SetChannels(part1065, Bench, DataToUse, datastream)
global SPECIES;

if strcmp(DataToUse, 'Concentration'), Part_1065 = 0; else Part_1065 = 1; end;

for k = 1:length(SPECIES)
    if datastream.isKey([SPECIES{k} '_' Bench])
        tempChannel = datastream([SPECIES{k} '_' Bench]);
        if Part_1065
            tempChannel.StreamingData.Part1065Mass = part1065.([SPECIES{k} '_m']);
        else
            tempChannel.StreamingData.Mass = part1065.([SPECIES{k} '_m']);
        end
    end
end

if strcmp('Bag_Dilute',Bench)
    if datastream.isKey('HHC_Bag_Dilute_Corrected')
        tempChannel = datastream('HHC_Bag_Dilute_Corrected');
        if Part_1065
            tempChannel.StreamingData.Part1065Mass = part1065.HHC_m_c;
        else
            tempChannel.StreamingData.Mass = part1065.HHC_m_c;
        end
    end
    if datastream.isKey('HC_Bag_Dilute_Corrected')
        tempChannel = datastream('HC_Bag_Dilute_Corrected');
        if Part_1065
            tempChannel.StreamingData.Part1065Mass = part1065.HC_m_c;
        else
            tempChannel.StreamingData.Mass = part1065.HC_m_c;
        end
    end
    if datastream.isKey('CH4_Bag_Dilute_Corrected')
        tempChannel = datastream('CH4_Bag_Dilute_Corrected');
        if Part_1065
            tempChannel.StreamingData.Part1065Mass = part1065.CH4_m_c;
        else
            tempChannel.StreamingData.Mass = part1065.CH4_m_c;
        end
    end
end

if Part_1065 %No need to do this twice.
    switch Bench
        case 'Bag_Dilute'
            datastream('MF_NOx_Corr') = Miscellaneous_Channel(datastream, 'MF_NOx_Corr', 'Miscellaneous', '', part1065.NOx_cor, 0);
            datastream('MF_DT_dilexh') = Temperature_Channel(datastream, 'MF_DT_dilexh', 'Temperature', '°C', part1065.Dew_T_dilexh, 0);
            datastream('MF_x_H2Oexh_Bag_Dilute') = Miscellaneous_Channel(datastream, 'MF_x_H2Oexh_Bag_Dilute_Bench', 'Miscellaneous', 'mol/mol', part1065.x_H2Oexh, 0);
            datastream('MF_x_H2Oint') = Miscellaneous_Channel(datastream, 'MF_x_H2Oint', 'Miscellaneous', 'mol/mol', part1065.x_H2Oint, 0);
            datastream('MF_x_dilexh') = Miscellaneous_Channel(datastream, 'MF_x_dilexh', 'Miscellaneous', 'mol/mol', part1065.x_dilexh, 0);
            datastream('DR') = Miscellaneous_Channel(datastream, 'DR', 'Miscellaneous', 'mol/mol', 1 ./ (1 - part1065.x_dilexh), 0); 
            datastream('MF_Fuel_CB') = Miscellaneous_Channel(datastream, 'MF_Fuel_CB', 'Miscellaneous', 'g', part1065.Fuel_CB, 0);
        case 'Engine'
            datastream('Q_Engine_Mol') = Miscellaneous_Channel(datastream, 'MF_Q_Engine_Bench_Mol', 'Flow', 'mol/s', part1065.n_exh, 0);
        case 'Tailpipe'
            datastream('Q_Tailpipe_Mol') = Miscellaneous_Channel(datastream, 'MF_Q_Tailpipe_Bench_Mol', 'Flow', 'mol/s', part1065.n_exh, 0);
    end
end