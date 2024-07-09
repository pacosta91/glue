function bPF = DewT_in_Exh_QA(datastream)
global LM;
bPF = 0; %By default the test fails
if ~(datastream.isKey('T_Tunn_1') && datastream.isKey('T_Tunn_2') && datastream.isKey('P_Ex') && datastream.isKey('MF_x_H2Oexh_Bag_Dilute') && ...
    datastream.isKey('Q_CVS_Mol_C'))
    if datastream('Options').Part_1065.IsOn
        LM.DebugPrint(1,'WARNING: There is insufficient information data to verify that the water lost in diluted exhaust is negligible.');
    end
    return;
end
T_Tunn = min(datastream('T_Tunn_1').StreamingData,datastream('T_Tunn_2').StreamingData);
if all(datastream('MF_DT_dilexh').StreamingData < T_Tunn)
    bPF = 1;
    return;
end
% See 1065.140(c)(6)(ii)(C)
H2O_max = Dew_Temperature(T_Tunn)./(datastream('P_CFV').StreamingData);
H2Olost = datastream('MF_x_H2Oexh_Bag_Dilute').StreamingData-H2O_max;
H2Olost = H2Olost.*(H2Olost>0); %negative values to zero
if max(H2Olost) < 0.02 && sum(H2Olost.*datastream('Q_CVS_Mol_C').StreamingData./60)/sum(datastream('Q_CVS_Mol_C').StreamingData./60) < 0.005
    bPF = 1;
else
    LM.DebugPrint(1,'WARNING: This test did not pass the check for water lost in the diluted exhaust')
end
