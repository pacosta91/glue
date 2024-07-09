function CorrectionFactor = CVSMassCorrectionFactor(CO2concentration, Q_CVS, V_CVS, V_Bypass, alpha, NoRawBenches)

global LM;

%Determine if V_Bypass is reasonable (within 15% of the expected value)
%The expected flow value is 35 scf/hr or .01944 scf when the volume is
%computed for a single second

if NoRawBenches==0, CorrectionFactor = 1; return; end;

ExpectedValue = mean(V_Bypass)/length(V_Bypass)*3600;

if ExpectedValue < 0 || ExpectedValue > 60
    LM.DebugPrint(1,'WARNING: The units of V_Bypass do not seem correct, Glue was expecting units of scf over a second');
    CorrectionFactor = ones(size(CO2concentration));
    return;
end

if abs(mean(Q_CVS)/60-mean(V_CVS)) > 1
    LM.DebugPrint(1,'WARNING: The units of V_CVS do not seem correct, Glue was expecting units of scf over a second');
    CorrectionFactor = ones(size(CO2concentration));
    return;
end

% Compute the correction factor
CorrectionFactor = 1+100./(CO2concentration.*(1+alpha/2+3.76*(1+alpha/4))).*V_Bypass./V_CVS;