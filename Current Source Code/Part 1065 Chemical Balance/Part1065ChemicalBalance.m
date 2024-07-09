function datastream = Part1065ChemicalBalance(datastream, ModeSegregation, Bench, ConcentrationsToUse)

global LM;

Iterations = 1;
IterationLimit = 100;

if strcmp(datastream('Options').Part_1065.Ignition_Type,'Compression')
    NONOx = 0.75;
    NO2NOx = 0.25;
    LM.DebugPrint(2,'Compression Engine, 75% of NOx is NO, 25% of NOx is NO2.')
elseif strcmp(datastream('Options').Part_1065.Ignition_Type,'Spark')
    NONOx = 1.00;
    NO2NOx = 0.00;
    LM.DebugPrint(2,'Spark Engine, 100% of NOx is NO.')
else
    LM.DebugPrint(1,'ALARM: Ignition_Type must be set to either Compression or Spark on the Options Panel.')
end

WetMeasurements = 0;
if strcmp(Bench,'Bag_Dilute'), WetMeasurements = 1; end;

NOxAccess = ['NOx_',Bench];
HNOxAccess = ['HNOx_',Bench]; % ES added
COlAccess = ['CO_l_',Bench];
COhAccess = ['CO_h_',Bench];
CO2Access = ['CO2_',Bench];
HCAccess = ['HC_',Bench];
HHCAccess = ['HHC_',Bench];
CO2egrAccess = ['CO2_egr_',Bench];
CO2TrAccess = ['CO2_Tr_',Bench];
O2Access = ['O2_',Bench];
NMHCAccess = ['NMHC_',Bench];
CH4Access = ['CH4_',Bench,'_Corrected'];
N2OAccess = ['N2O_',Bench]; % ES added

DataToUse = [ConcentrationsToUse 'Concentration'];

part1065.x_H2Oexhdry = 0.05*ones(size(datastream('Time').StreamingData));
part1065.x_rawexhdry = 0.2*ones(size(datastream('Time').StreamingData));

part1065.delta_x_H2Oexhdry = ones(size(datastream('Time').StreamingData));
part1065.delta_x_rawexhdry = ones(size(datastream('Time').StreamingData));

if WetMeasurements %Also assumes diluted exhaust

    if datastream('Options').Part_1065.HCContaminationCorrection
        if datastream('Options').Use_HC
            if datastream.isKey(['HC_',Bench,'_Corrected']), HCAccess = ['HC_',Bench,'_Corrected']; end % ES - Verify that the corrected channel exists
        else
            if datastream.isKey(['HHC_',Bench,'_Corrected']), HHCAccess = ['HHC_',Bench,'_Corrected']; end % ES - Verify that the corrected channel exists
        end
    end

    part1065.x_H2Oint = Dew_Temperature(datastream('DT_Air_2').StreamingData)./(datastream('P_SimBaro').ConvertStreaming('kPa'));
    part1065.x_H2Ointdry = part1065.x_H2Oint./(1-part1065.x_H2Oint); %1065.655-11k

    part1065.x_H2Odil = Dew_Temperature(datastream('DT_Dil_Air').StreamingData)./(datastream('P_SimBaro').ConvertStreaming('kPa'));
    part1065.x_H2Odildry = part1065.x_H2Odil./(1-part1065.x_H2Odil); %1065.655-13k

    part1065.x_CO2int = datastream('Options').Part_1065.CO2_int; %1065.655-10 k
    part1065.x_CO2intdry = part1065.x_CO2int.*(1+part1065.x_H2Ointdry);

    part1065.x_O2int = (datastream('Options').Part_1065.O2CO2_intdry-part1065.x_CO2intdry)./(1+part1065.x_H2Ointdry); %1065.655-9 k

    part1065.x_CO2dil = datastream('Options').Part_1065.CO2_dil;
    part1065.x_CO2dildry = part1065.x_CO2dil.*(1+part1065.x_H2Odildry); %from 1065.655-12 k

    % Determine the molar concentration of NOx
    part1065.x_NOx = datastream(NOxAccess).ConvertStreaming('mol/mol',DataToUse);
    part1065.x_NO = NONOx.*part1065.x_NOx;
    part1065.x_NO2 = NO2NOx.*part1065.x_NOx;

    if datastream.isKey(COlAccess) && datastream.isKey(COhAccess)
        COldata = datastream(COlAccess).ConvertStreaming('mol/mol',DataToUse);
        COhdata = datastream(COhAccess).ConvertStreaming('mol/mol',DataToUse);
        part1065.x_CO = zeros(size(COldata));
        for k = 1:ModeSegregation.nModes
            if datastream('Options').([Bench '_CO_l_InUse'])
                part1065.x_CO(ModeSegregation.getModeIndices(k)==1) = COldata(ModeSegregation.getModeIndices(k)==1);
            else
                part1065.x_CO(ModeSegregation.getModeIndices(k)==1) = COhdata(ModeSegregation.getModeIndices(k)==1);
            end
        end
        clear COldata COhdata;
    else
        if datastream.isKey(COlAccess)
            part1065.x_CO = datastream(COlAccess).ConvertStreaming('mol/mol',DataToUse);
        else
            part1065.x_CO = datastream(COhAccess).ConvertStreaming('mol/mol',DataToUse);
        end
    end

    % ES - Temporary check to see if part1065.x_CO = []. This condition
    % will throw an error so we'll warn the user.
    if isempty(part1065.x_CO), LM.DebugPrint(1,'ALARM: Verify that the CO data is in the database!'); end

    part1065.x_CO2 = datastream(CO2Access).ConvertStreaming('mol/mol',DataToUse);

    if datastream('Options').Use_HC
        part1065.x_HC = datastream(HCAccess).ConvertStreaming('mol/mol',DataToUse);
    else
        part1065.x_HC = datastream(HHCAccess).ConvertStreaming('mol/mol',DataToUse);
    end

    while sum(abs(part1065.delta_x_H2Oexhdry))+sum(abs(part1065.delta_x_rawexhdry)) > 0.0000000001 && Iterations < IterationLimit

        Iterations = Iterations+1;

        % TIER 1

        part1065.x_dilexh = 1-part1065.x_rawexhdry./(1+part1065.x_H2Oexhdry); % Eq.1065.655-1
        part1065.x_H2Oexh = part1065.x_H2Oexhdry./(1+part1065.x_H2Oexhdry); % Eq. 1065.655-2

        % TIER 2 INITIALIZATION

        part1065.x_dilexhdry = part1065.x_dilexh./(1-part1065.x_H2Oexh); % Eq. 1065.655-6
        part1065.x_COdry = part1065.x_CO./(1-part1065.x_H2Oexh); % Eq. 1065.655-14
        part1065.x_CO2dry = part1065.x_CO2./(1-part1065.x_H2Oexh); % Eq. 1065.655-15
        part1065.x_NOdry = part1065.x_NO./(1-part1065.x_H2Oexh); % Eq. 1065.655-16
        part1065.x_NO2dry = part1065.x_NO2./(1-part1065.x_H2Oexh); % Eq. 1065.655-17
        part1065.x_HCdry = part1065.x_HC./(1-part1065.x_H2Oexh); % Eq. 1065.655-18

        % TIER 3 INITIALIZATION

        part1065.x_H2dry = (part1065.x_COdry.*(part1065.x_H2Oexhdry-part1065.x_H2Odil.*part1065.x_dilexhdry))./ ...
            (datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry-part1065.x_CO2dil.*part1065.x_dilexhdry)); %1065.655-4

        % TIER 4 INITIALIZATION

        part1065.x_Ccombdry = (((2.*part1065.x_O2int.*(part1065.x_CO2dry+part1065.x_COdry+part1065.x_HCdry-part1065.x_CO2dil.*(1+ ...
            part1065.x_H2Oexhdry-part1065.x_rawexhdry)))./part1065.x_CO2int)+part1065.x_COdry-part1065.x_NOdry-2.*part1065.x_NO2dry ...
            +part1065.x_H2dry+(datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).* ...
            part1065.x_HCdry)./((2.*part1065.x_O2int)./part1065.x_CO2int+(datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+ ...
            2*datastream('Options').Fuel.gamma)); %derived from equations 1065.655-3 and 1065.655-7 so as to remove circular reference

        % TIER 5 INITIALIZATION

        part1065.x_intexhdry = 1./(2.*part1065.x_O2int).*((datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+ ...
            2*datastream('Options').Fuel.gamma).*(part1065.x_Ccombdry-part1065.x_HCdry)-(part1065.x_COdry-part1065.x_NOdry-2.*part1065.x_NO2dry ...
            +part1065.x_H2dry)); %1065.655-7

        % TIER 6 EVALUATION

        part1065.x_H2Oexhdryeval = -((datastream('Options').Fuel.alpha/2).*(part1065.x_Ccombdry-part1065.x_HCdry)+part1065.x_H2Odil ...
            .*part1065.x_dilexhdry+part1065.x_H2Oint.*part1065.x_intexhdry-part1065.x_H2dry-part1065.x_H2Oexhdry); %1065.655-5
        part1065.x_rawexhdryeval = -(0.5.*((datastream('Options').Fuel.alpha/2+datastream('Options').Fuel.beta+datastream('Options').Fuel.delta).* ...
            (part1065.x_Ccombdry-part1065.x_HCdry)+(2.*part1065.x_HCdry)+(part1065.x_COdry-part1065.x_NO2dry+part1065.x_H2dry))+ ...
            part1065.x_intexhdry-part1065.x_rawexhdry); %1065.655-8

        % TAKING DERIVATIVES

            % Emission Derivatives with Respect to x_H2Oexhdry

        part1065.dx_NO_dx_H2Oexhdry_bag_dilute = -part1065.x_NO./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_NO2_dx_H2Oexhdry_bag_dilute = -part1065.x_NO2./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_CO_dx_H2Oexhdry_bag_dilute = -part1065.x_CO./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_CO2_dx_H2Oexhdry_bag_dilute = -part1065.x_CO2./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_HC_dx_H2Oexhdry_bag_dilute = -part1065.x_HC./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);

            % H2 with respect to both

        part1065.dx_H2dry_dx_H2Oexhdry = ((part1065.dx_CO_dx_H2Oexhdry_bag_dilute.*(part1065.x_H2Oexhdry ...
            -part1065.x_H2Odil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))+part1065.x_COdry- ...
            part1065.x_COdry.*part1065.x_H2Odil).*datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry-part1065.x_CO2dil ...
            .*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))-part1065.x_COdry.*(part1065.x_H2Oexhdry- ...
            part1065.x_H2Odil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry)).*datastream('Options').Part_1065.KH2Ogas ...
            .*(part1065.dx_CO2_dx_H2Oexhdry_bag_dilute+part1065.x_CO2dil))./((datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry ...
            -part1065.x_CO2dil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))).^2);
        part1065.dx_H2dry_dx_rawexhdry = (part1065.x_COdry.*part1065.x_H2Odil.*datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry ...
            -part1065.x_CO2dil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))-part1065.x_COdry.* ...
            (part1065.x_H2Oexhdry-part1065.x_H2Odil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry)).* ...
            datastream('Options').Part_1065.KH2Ogas.*part1065.x_CO2dil)./((datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry-part1065.x_CO2dil.*(1 ...
            +part1065.x_H2Oexhdry-part1065.x_rawexhdry))).^2);

            % Ccombdry with respect to both

        part1065.dx_Ccombdry_dx_H2Oexhdry = (((2.*part1065.x_O2int.*(part1065.dx_CO2_dx_H2Oexhdry_bag_dilute ...
            +part1065.dx_CO_dx_H2Oexhdry_bag_dilute+part1065.dx_HC_dx_H2Oexhdry_bag_dilute-part1065.x_CO2dil))./part1065.x_CO2int) ...
            +part1065.dx_CO_dx_H2Oexhdry_bag_dilute-part1065.dx_NO_dx_H2Oexhdry_bag_dilute-2.*part1065.dx_NO2_dx_H2Oexhdry_bag_dilute+ ...
            part1065.dx_H2dry_dx_H2Oexhdry+(datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*part1065.dx_HC_dx_H2Oexhdry_bag_dilute)./(2.*part1065.x_O2int ...
            ./part1065.x_CO2int+datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma);
        part1065.dx_Ccombdry_dx_rawexhdry = (((2.*part1065.x_O2int.*part1065.x_CO2dil)./part1065.x_CO2int) ...
            +part1065.dx_H2dry_dx_rawexhdry)./(2.*part1065.x_O2int./part1065.x_CO2int+datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma);

            % intexhdry with respect to both

        part1065.dx_intexhdry_dx_H2Oexhdry = 1./(2.*part1065.x_O2int).*((datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*(part1065.dx_Ccombdry_dx_H2Oexhdry ...
            -part1065.dx_HC_dx_H2Oexhdry_bag_dilute)-part1065.dx_CO_dx_H2Oexhdry_bag_dilute+part1065.dx_NO_dx_H2Oexhdry_bag_dilute ...
            +2.*part1065.dx_NO2_dx_H2Oexhdry_bag_dilute-part1065.dx_H2dry_dx_H2Oexhdry);
        part1065.dx_intexhdry_dx_rawexhdry = 1./(2.*part1065.x_O2int).*((datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*part1065.dx_Ccombdry_dx_rawexhdry ...
            -part1065.dx_H2dry_dx_rawexhdry);

            % jacobian terms

        part1065.dx_f1_dx_H2Oexhdry = datastream('Options').Fuel.alpha/2.*(part1065.dx_Ccombdry_dx_H2Oexhdry-part1065.dx_HC_dx_H2Oexhdry_bag_dilute) ...
            +part1065.x_H2Odil+part1065.x_H2Oint.*part1065.dx_intexhdry_dx_H2Oexhdry-part1065.dx_H2dry_dx_H2Oexhdry-1;
        part1065.dx_f1_dx_rawexhdry = datastream('Options').Fuel.alpha/2.*part1065.dx_Ccombdry_dx_rawexhdry-part1065.x_H2Odil+part1065.x_H2Oint ...
            .*part1065.dx_intexhdry_dx_rawexhdry-part1065.dx_H2dry_dx_rawexhdry;
        part1065.dx_f2_dx_H2Oexhdry = 0.5.*((datastream('Options').Fuel.alpha/2+datastream('Options').Fuel.beta+datastream('Options').Fuel.delta).*(part1065.dx_Ccombdry_dx_H2Oexhdry-part1065.dx_HC_dx_H2Oexhdry_bag_dilute) ...
            +2.*part1065.dx_HC_dx_H2Oexhdry_bag_dilute+part1065.dx_CO_dx_H2Oexhdry_bag_dilute-part1065.dx_NO2_dx_H2Oexhdry_bag_dilute ...
            +part1065.dx_H2dry_dx_H2Oexhdry)+part1065.dx_intexhdry_dx_H2Oexhdry;
        part1065.dx_f2_dx_rawexhdry = 0.5.*((datastream('Options').Fuel.alpha/2+datastream('Options').Fuel.beta+datastream('Options').Fuel.delta).*part1065.dx_Ccombdry_dx_rawexhdry+part1065.dx_H2dry_dx_rawexhdry)+ ...
            part1065.dx_intexhdry_dx_rawexhdry-1;

        % SOLVE THE SYSTEM OF EQUATIONS USING CRAMER'S RULE

        part1065.delta_x_H2Oexhdry = (part1065.x_H2Oexhdryeval.*part1065.dx_f2_dx_rawexhdry ...
            -part1065.x_rawexhdryeval.*part1065.dx_f1_dx_rawexhdry)./(part1065.dx_f1_dx_H2Oexhdry ...
            .*part1065.dx_f2_dx_rawexhdry-part1065.dx_f1_dx_rawexhdry.*part1065.dx_f2_dx_H2Oexhdry);
        part1065.delta_x_rawexhdry = (part1065.x_rawexhdryeval.*part1065.dx_f1_dx_H2Oexhdry ...
            -part1065.x_H2Oexhdryeval.*part1065.dx_f2_dx_H2Oexhdry)./(part1065.dx_f1_dx_H2Oexhdry ...
            .*part1065.dx_f2_dx_rawexhdry-part1065.dx_f1_dx_rawexhdry.*part1065.dx_f2_dx_H2Oexhdry);

        % UPDATE INITIAL GUESS

        part1065.x_H2Oexhdry = part1065.x_H2Oexhdry+part1065.delta_x_H2Oexhdry;
        part1065.x_rawexhdry = part1065.x_rawexhdry+part1065.delta_x_rawexhdry;

    end % SOLUTION ACHIEVED

    if Iterations == IterationLimit, LM.DebugPrint(1,'WARNING: Iteration ceiling reached for chemical balance on %s_Bench: a chemical balance may not have been adequately determined', Bench); end;

    % Calculate NOx Correction Factor
    if strcmp(datastream('Options').Part_1065.Ignition_Type,'Spark')
        part1065.NOx_cor = 18.840*part1065.x_H2Oint+0.68094;
    else % Assumed compression ignition
        part1065.NOx_cor = 9.953*part1065.x_H2Oint+0.832;
    end

    % ES 2/2/2017 - Added logic to handle ambient bag concentrations.

    part1065.n_exh = datastream('Q_CVS_Mol_C').ConvertStreaming('mol/s');

    % CO_l
    if datastream.isKey(COlAccess)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(COlAccess).Ambient,'BagRead') || any(datastream(COlAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(COlAccess).StreamingData.Concentration)) * datastream(COlAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(COlAccess).StreamingData.Concentration)) * mean(datastream(COlAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(COlAccess).Ambient.BagRead.Concentration';
        end
        part1065.CO_l_m = datastream('Options').Molar_Mass.CO.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(COlAccess).ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.CO_l_m = part1065.CO_l_m.*(part1065.CO_l_m>=0);
    end

    % CO_h
    if datastream.isKey(COhAccess)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(COhAccess).Ambient,'BagRead') || any(datastream(COhAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(COhAccess).StreamingData.Concentration)) * datastream(COhAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(COhAccess).StreamingData.Concentration)) * mean(datastream(COhAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(COlAccess).Ambient.BagRead.Concentration';
        end
        part1065.CO_h_m = datastream('Options').Molar_Mass.CO.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(COhAccess).ConvertStreaming('mol/mol',DataToUse)-1e-2*AmbientConc.*part1065.x_dilexh);
        part1065.CO_h_m = part1065.CO_h_m.*(part1065.CO_h_m>=0);
    end

    % CO2
    if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(CO2Access).Ambient,'BagRead') || any(datastream(CO2Access).Ambient.BagRead.Concentration == -999)
        AmbientConc = ones(size(datastream(CO2Access).StreamingData.Concentration)) * datastream(CO2Access).Ambient.([ConcentrationsToUse 'Average']);
    else
        % AmbientConc = ones(size(datastream(CO2Access).StreamingData.Concentration)) * mean(datastream(CO2Access).Ambient.BagRead.Concentration);
        AmbientConc = ModeSegregation.PhaseIndices * datastream(CO2Access).Ambient.BagRead.Concentration';
    end
    part1065.CO2_m = datastream('Options').Molar_Mass.CO2.*part1065.n_exh.*datastream('Options').delta_T.* ...
        (datastream(CO2Access).ConvertStreaming('mol/mol',DataToUse)-1e-2*AmbientConc.*part1065.x_dilexh);
    part1065.CO2_m = part1065.CO2_m.*(part1065.CO2_m>=0);

    % NOx
    if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(NOxAccess).Ambient,'BagRead') || any(datastream(NOxAccess).Ambient.BagRead.Concentration == -999)
        AmbientConc = ones(size(datastream(NOxAccess).StreamingData.Concentration)) * datastream(NOxAccess).Ambient.([ConcentrationsToUse 'Average']);
    else
        % AmbientConc = ones(size(datastream(NOxAccess).StreamingData.Concentration)) * mean(datastream(NOxAccess).Ambient.BagRead.Concentration);
        AmbientConc = ModeSegregation.PhaseIndices * datastream(NOxAccess).Ambient.BagRead.Concentration';
    end
    part1065.NOx_m = datastream('Options').Molar_Mass.NOx.*part1065.n_exh.*part1065.NOx_cor.*datastream('Options').delta_T.* ...
        (datastream(NOxAccess).ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
    part1065.NOx_m = part1065.NOx_m.*(part1065.NOx_m>=0);

    % NO2
    if datastream.isKey(N2OAccess)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(N2OAccess).Ambient,'BagRead') || any(datastream(N2OAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(N2OAccess).StreamingData.Concentration)) * datastream(N2OAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(N2OAccess).StreamingData.Concentration)) * mean(datastream(N2OAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(N2OAccess).Ambient.BagRead.Concentration';
        end
        part1065.N2O_m = datastream('Options').Molar_Mass.N2O.*part1065.n_exh.*datastream('Options').delta_T.* ...
        (datastream(N2OAccess).ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.N2O_m = part1065.N2O_m.*(part1065.N2O_m>=0);
    end

    % HNOx
    if datastream.isKey(HNOxAccess)
        if ~isfield(datastream(HNOxAccess).Ambient,'BagRead') || any(datastream(HNOxAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(HNOxAccess).StreamingData.Concentration)) * datastream(HNOxAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(HNOxAccess).StreamingData.Concentration)) * mean(datastream(HNOxAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(HNOxAccess).Ambient.BagRead.Concentration';
        end
        part1065.HNOx_m = datastream('Options').Molar_Mass.NOx.*part1065.n_exh.*part1065.NOx_cor.*datastream('Options').delta_T.* ...
        (datastream(HNOxAccess).ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.HNOx_m = part1065.HNOx_m.*(part1065.HNOx_m>=0);
    end

    if datastream('Options').Use_HC

        % HC_Bag_Dilute_Corrected
        if datastream.isKey('HC_Bag_Dilute_Corrected')
            if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('HC_Bag_Dilute_Corrected').Ambient,'BagRead') || any(datastream('HC_Bag_Dilute_Corrected').Ambient.BagRead.Concentration == -999)
                AmbientConc = ones(size(datastream('HC_Bag_Dilute_Corrected').StreamingData.Concentration)) * datastream('HC_Bag_Dilute_Corrected').Ambient.([ConcentrationsToUse 'Average']);
            else
                % AmbientConc = ones(size(datastream('HC_Bag_Dilute_Corrected').StreamingData.Concentration)) * mean(datastream('HC_Bag_Dilute_Corrected').Ambient.BagRead.Concentration);
                AmbientConc = ModeSegregation.PhaseIndices * datastream('HC_Bag_Dilute_Corrected').Ambient.BagRead.Concentration';
            end
            part1065.HC_m_c = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
                (datastream('HC_Bag_Dilute_Corrected').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
            part1065.HC_m_c = part1065.HC_m_c.*(part1065.HC_m_c>=0);
        end

        % HC_Bag_Dilute
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('HC_Bag_Dilute').Ambient,'BagRead') || any(datastream('HC_Bag_Dilute').Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream('HC_Bag_Dilute').StreamingData.Concentration)) * datastream('HC_Bag_Dilute').Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream('HC_Bag_Dilute').StreamingData.Concentration)) * mean(datastream('HC_Bag_Dilute').Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream('HC_Bag_Dilute').Ambient.BagRead.Concentration';
        end
        part1065.HC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream('HC_Bag_Dilute').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.HC_m = part1065.HC_m.*(part1065.HC_m>=0);

        % HHC
        if datastream.isKey(['HHC_',Bench])
            if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('HHC_Bag_Dilute').Ambient,'BagRead') || any(datastream('HHC_Bag_Dilute').Ambient.BagRead.Concentration == -999)
                AmbientConc = ones(size(datastream('HHC_Bag_Dilute').StreamingData.Concentration)) * datastream('HHC_Bag_Dilute').Ambient.([ConcentrationsToUse 'Average']);
            else
                % AmbientConc = ones(size(datastream('HHC_Bag_Dilute').StreamingData.Concentration)) * mean(datastream('HHC_Bag_Dilute').Ambient.BagRead.Concentration);
                AmbientConc = ModeSegregation.PhaseIndices * datastream('HHC_Bag_Dilute').Ambient.BagRead.Concentration';
            end
            part1065.HHC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
                (datastream('HHC_Bag_Dilute').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
            part1065.HHC_m = part1065.HHC_m.*(part1065.HHC_m>=0);
        end

    else

        % HC_Bag_Dilute
        if datastream.isKey(['HC_',Bench])
            if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('HC_Bag_Dilute').Ambient,'BagRead') || any(datastream('HC_Bag_Dilute').Ambient.BagRead.Concentration == -999)
                AmbientConc = ones(size(datastream('HC_Bag_Dilute').StreamingData.Concentration)) * datastream('HC_Bag_Dilute').Ambient.([ConcentrationsToUse 'Average']);
            else
                % AmbientConc = ones(size(datastream('HC_Bag_Dilute').StreamingData.Concentration)) * mean(datastream('HC_Bag_Dilute').Ambient.BagRead.Concentration);
                AmbientConc = ModeSegregation.PhaseIndices * datastream('HC_Bag_Dilute').Ambient.BagRead.Concentration';
            end
            part1065.HC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
                (datastream('HC_Bag_Dilute').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
            part1065.HC_m = part1065.HC_m.*(part1065.HC_m>=0);
        end

        % HHC
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('HHC_Bag_Dilute').Ambient,'BagRead') || any(datastream('HHC_Bag_Dilute').Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream('HHC_Bag_Dilute').StreamingData.Concentration)) * datastream('HHC_Bag_Dilute').Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream('HHC_Bag_Dilute').StreamingData.Concentration)) * mean(datastream('HHC_Bag_Dilute').Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream('HHC_Bag_Dilute').Ambient.BagRead.Concentration';
        end
        part1065.HHC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream('HHC_Bag_Dilute').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.HHC_m = part1065.HHC_m.*(part1065.HHC_m>=0);

        % HHC_Bag_Dilute_Corrected
        if datastream.isKey('HHC_Bag_Dilute_Corrected')
            if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('HHC_Bag_Dilute_Corrected').Ambient,'BagRead') || any(datastream('HHC_Bag_Dilute_Corrected').Ambient.BagRead.Concentration == -999)
                AmbientConc = ones(size(datastream('HHC_Bag_Dilute_Corrected').StreamingData.Concentration)) * datastream('HHC_Bag_Dilute_Corrected').Ambient.([ConcentrationsToUse 'Average']);
            else
                % AmbientConc = ones(size(datastream('HHC_Bag_Dilute_Corrected').StreamingData.Concentration)) * mean(datastream('HHC_Bag_Dilute_Corrected').Ambient.BagRead.Concentration);
                AmbientConc = ModeSegregation.PhaseIndices * datastream('HHC_Bag_Dilute_Corrected').Ambient.BagRead.Concentration';
            end
            part1065.HHC_m_c = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
                (datastream('HHC_Bag_Dilute_Corrected').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
            part1065.HHC_m_c = part1065.HHC_m_c.*(part1065.HHC_m_c>=0);
        end

    end

    % CO2_egr
    if datastream.isKey(CO2egrAccess)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(CO2egrAccess).Ambient,'BagRead') || any(datastream(CO2egrAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(CO2egrAccess).StreamingData.Concentration)) * datastream(CO2egrAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(CO2egrAccess).StreamingData.Concentration)) * mean(datastream(CO2egrAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(CO2egrAccess).Ambient.BagRead.Concentration';
        end
        part1065.CO2_egr_m = datastream('Options').Molar_Mass.CO2.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(CO2egrAccess).ConvertStreaming('mol/mol',DataToUse)-1e-2*AmbientConc.*part1065.x_dilexh);
        part1065.CO2_egr_m = part1065.CO2_egr_m.*(part1065.CO2_egr_m>=0);
    end

    % CO2_tr
    if datastream.isKey(CO2TrAccess)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(CO2TrAccess).Ambient,'BagRead') || any(datastream(CO2TrAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(CO2TrAccess).StreamingData.Concentration)) * datastream(CO2TrAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(CO2TrAccess).StreamingData.Concentration)) * mean(datastream(CO2TrAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(CO2TrAccess).Ambient.BagRead.Concentration';
        end
        part1065.CO2_Tr_m = datastream('Options').Molar_Mass.CO2.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(CO2TrAccess).ConvertStreaming('mol/mol',DataToUse)-1e-2*AmbientConc.*part1065.x_dilexh);
        part1065.CO2_Tr_m = part1065.CO2Tr_m.*(part1065.CO2_Tr_m>=0);
    end

    % O2
    if datastream.isKey(O2Access)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(O2Access).Ambient,'BagRead') || any(datastream(O2Access).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(O2Access).StreamingData.Concentration)) * datastream(O2Access).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(O2Access).StreamingData.Concentration)) * mean(datastream(O2Access).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(O2Access).Ambient.BagRead.Concentration';
        end
        part1065.O2_m = datastream('Options').Molar_Mass.O2.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(O2Access).ConvertStreaming('mol/mol',DataToUse)-1e-2*AmbientConc.*part1065.x_dilexh);
        part1065.O2_m = part1065.O2_m.*(part1065.O2_m>=0);
    end

    if datastream.isKey(['CH4_',Bench,'_Corrected'])
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(CH4Access).Ambient,'BagRead') || any(datastream(CH4Access).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(CH4Access).StreamingData.Concentration)) * datastream(CH4Access).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(CH4Access).StreamingData.Concentration)) * mean(datastream(CH4Access).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(CH4Access).Ambient.BagRead.Concentration';
        end
        part1065.CH4_m_c = datastream('Options').Molar_Mass.CH4.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(CH4Access).ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.CH4_m_c = part1065.CH4_m_c.*(part1065.CH4_m_c>=0);

        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream('CH4_Bag_Dilute').Ambient,'BagRead') || any(datastream('CH4_Bag_Dilute').Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream('CH4_Bag_Dilute').StreamingData.Concentration)) * datastream('CH4_Bag_Dilute').Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream('CH4_Bag_Dilute').StreamingData.Concentration)) * mean(datastream('CH4_Bag_Dilute').Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream('CH4_Bag_Dilute').Ambient.BagRead.Concentration';
        end
        part1065.CH4_m = datastream('Options').Molar_Mass.CH4.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream('CH4_Bag_Dilute').ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.CH4_m = part1065.CH4_m.*(part1065.CH4_m>=0);
    end

    if datastream.isKey(NMHCAccess)
        if ~datastream('Options').Engine_Modal_Amb_Bag_Test || ~isfield(datastream(NMHCAccess).Ambient,'BagRead') || any(datastream(NMHCAccess).Ambient.BagRead.Concentration == -999)
            AmbientConc = ones(size(datastream(NMHCAccess).StreamingData.Concentration)) * datastream(NMHCAccess).Ambient.([ConcentrationsToUse 'Average']);
        else
            % AmbientConc = ones(size(datastream(NMHCAccess).StreamingData.Concentration)) * mean(datastream(NMHCAccess).Ambient.BagRead.Concentration);
            AmbientConc = ModeSegregation.PhaseIndices * datastream(NMHCAccess).Ambient.BagRead.Concentration';
        end
        part1065.NMHC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.* ...
            (datastream(NMHCAccess).ConvertStreaming('mol/mol',DataToUse)-1e-6*AmbientConc.*part1065.x_dilexh);
        part1065.NMHC_m = part1065.NMHC_m.*(part1065.NMHC_m>=0);

        if datastream('Options').Use_HC
            part1065.NMHC_m = 0.98.*part1065.HC_m_c.*(part1065.NMHC_m > 0.98.*part1065.HC_m_c)+part1065.NMHC_m.*(part1065.NMHC_m <= 0.98.*part1065.HC_m_c);
        else
            part1065.NMHC_m = 0.98.*part1065.HHC_m_c.*(part1065.NMHC_m > 0.98.*part1065.HHC_m_c)+part1065.NMHC_m.*(part1065.NMHC_m <= 0.98.*part1065.HHC_m_c);
        end
    end

    p_H2Oexh = part1065.x_H2Oexh.*datastream('P_CFV').StreamingData;

    % Computing the Dew Temperature of the diluted exhaust see the "vapor to dew model.docx" for a description of how this method was performed
    DTE = 18.6024+0.0177./p_H2Oexh+0.5795.*p_H2Oexh-0.0025.*p_H2Oexh.^2+5.1276.*log(p_H2Oexh.^2)-15.7077.*0.79.^p_H2Oexh; %initial regression
    part1065.Dew_T_dilexh = 0.01488+1.03342.*DTE-2.936e-4.*DTE.^2-5.979e-5.*DTE.^3+5.175e-7.*DTE.^4+2.441e-8.*DTE.^5-2.247e-10.*DTE.^6-2.132e-12.*DTE.^7 ... %update regression
        +2.210e-14.*DTE.^8;

    part1065.Fuel_CB = part1065.n_exh.*12.0107.*datastream('Options').delta_T.*part1065.x_Ccombdry./(datastream('Options').Fuel.w_C.*(1+part1065.x_H2Oexhdry));

else % Dry concentrations, assumes not dilution/raw exhaust

    part1065.x_H2Oint = Dew_Temperature(datastream('DT_Air_2').StreamingData)./(datastream('P_SimBaro').ConvertStreaming('kPa'));
    part1065.x_H2Ointdry = part1065.x_H2Oint./(1-part1065.x_H2Oint); %1065.655-11k

    part1065.x_H2Odil = part1065.x_H2Oint;
    part1065.x_H2Odildry = part1065.x_H2Odil./(1-part1065.x_H2Odil); %1065.655-13k

    part1065.x_CO2int = datastream('Options').Part_1065.CO2_int; %1065.655-10 k
    part1065.x_CO2intdry = part1065.x_CO2int.*(1+part1065.x_H2Ointdry);

    part1065.x_O2int = (datastream('Options').Part_1065.O2CO2_intdry-part1065.x_CO2intdry)./(1+part1065.x_H2Ointdry); %1065.655-9 k

    part1065.x_CO2dil = datastream('Options').Part_1065.CO2_dil;
    part1065.x_CO2dildry = part1065.x_CO2dil.*(1+part1065.x_H2Odildry); %from 1065.655-12 k

    part1065.x_NOxdry = datastream(NOxAccess).ConvertStreaming('mol/mol',DataToUse);
    part1065.x_NOdry = NONOx.*part1065.x_NOxdry;
    part1065.x_NO2dry = NO2NOx.*part1065.x_NOxdry;

    if datastream.isKey(COlAccess) && datastream.isKey(COhAccess)
        COldata = datastream(COlAccess).ConvertStreaming('mol/mol',DataToUse);
        COhdata = datastream(COhAccess).ConvertStreaming('mol/mol',DataToUse);
        part1065.x_COdry = zeros(size(COldata));
        for k = 1:ModeSegregation.nModes
            if datastream('Options').([Bench '_CO_l_InUse'])
                part1065.x_COdry(ModeSegregation.getModeIndices(k)==1) = COldata(ModeSegregation.getModeIndices(k)==1);
            else
                part1065.x_COdry(ModeSegregation.getModeIndices(k)==1) = COhdata(ModeSegregation.getModeIndices(k)==1);
            end
        end

        clear COldata COhdata;
    else
        if datastream.isKey(COlAccess)
            part1065.x_COdry = datastream(COlAccess).ConvertStreaming('mol/mol',DataToUse);
        else
            part1065.x_COdry = datastream(COhAccess).ConvertStreaming('mol/mol',DataToUse);
        end
    end

    part1065.x_CO2dry = datastream(CO2Access).ConvertStreaming('mol/mol',DataToUse);

    part1065.x_HCdry = datastream(HCAccess).ConvertStreaming('mol/mol',DataToUse);

    while sum(abs(part1065.delta_x_H2Oexhdry))+sum(abs(part1065.delta_x_rawexhdry)) > 0.0000000001 && Iterations < IterationLimit

        Iterations = Iterations+1;

        % TIER 1

        part1065.x_dilexh = 1-part1065.x_rawexhdry./(1+part1065.x_H2Oexhdry); %1065.655-1
        part1065.x_H2Oexh = part1065.x_H2Oexhdry./(1+part1065.x_H2Oexhdry); %1065.655-2

        % TIER 2 INITIALIZATION

        part1065.x_dilexhdry = part1065.x_dilexh./(1-part1065.x_H2Oexh); %1065.655-6
        part1065.x_CO = part1065.x_COdry.*(1-part1065.x_H2Oexh); %1065.655-14
        part1065.x_CO2 = part1065.x_CO2dry.*(1-part1065.x_H2Oexh); %1065.655-15
        part1065.x_NO = part1065.x_NOdry.*(1-part1065.x_H2Oexh); %1065.655-16
        part1065.x_NO2 = part1065.x_NO2dry.*(1-part1065.x_H2Oexh); %1065.655-17
        part1065.x_HC = part1065.x_HCdry.*(1-part1065.x_H2Oexh); %1065.655-18

        % TIER 3 INITIALIZATION

        part1065.x_H2dry = (part1065.x_COdry.*(part1065.x_H2Oexhdry-part1065.x_H2Odil.*part1065.x_dilexhdry))./ ...
            (datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry-part1065.x_CO2dil.*part1065.x_dilexhdry)); %1065.655-4

        % TIER 4 INITIALIZATION

        part1065.x_Ccombdry = (((2.*part1065.x_O2int.*(part1065.x_CO2dry+part1065.x_COdry ...
            +part1065.x_HCdry-part1065.x_CO2dil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))) ...
            ./part1065.x_CO2int)+part1065.x_COdry-part1065.x_NOdry-2.*part1065.x_NO2dry ...
            +part1065.x_H2dry+(datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*part1065.x_HCdry)./((2.*part1065.x_O2int) ...
            ./part1065.x_CO2int+(datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma)); %derived from equations 1065.655-3 and 1065.655-7 so as to remove circular reference

        % TIER 5 INITIALIZATION

        part1065.x_intexhdry = 1./(2.*part1065.x_O2int).*((datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*(part1065.x_Ccombdry ...
            -part1065.x_HCdry)-(part1065.x_COdry-part1065.x_NOdry-2.*part1065.x_NO2dry ...
            +part1065.x_H2dry)); %1065.655-7

        % TIER 6 EVALUATION

        part1065.x_H2Oexhdryeval = -((datastream('Options').Fuel.alpha/2).*(part1065.x_Ccombdry-part1065.x_HCdry)+part1065.x_H2Odil ...
            .*part1065.x_dilexhdry+part1065.x_H2Oint.*part1065.x_intexhdry-part1065.x_H2dry ...
            -part1065.x_H2Oexhdry); %1065.655-5
        part1065.x_rawexhdryeval = -(0.5.*((datastream('Options').Fuel.alpha/2+datastream('Options').Fuel.beta+datastream('Options').Fuel.delta).*(part1065.x_Ccombdry-part1065.x_HCdry) ...
            +(2.*part1065.x_HCdry)+(part1065.x_COdry-part1065.x_NO2dry+part1065.x_H2dry)) ...
            +part1065.x_intexhdry-part1065.x_rawexhdry); %1065.655-8

        % TAKING DERIVATIVES

            % Emission Derivatives with Respect to x_H2Oexhdry

        part1065.dx_NO_dx_H2Oexhdry_bag_dilute = -part1065.x_NO./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_NO2_dx_H2Oexhdry_bag_dilute = -part1065.x_NO2./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_CO_dx_H2Oexhdry_bag_dilute = -part1065.x_CO./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_CO2_dx_H2Oexhdry_bag_dilute = -part1065.x_CO2./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);
        part1065.dx_HC_dx_H2Oexhdry_bag_dilute = -part1065.x_HC./((1-part1065.x_H2Oexh).^2.*(1+part1065.x_H2Oexhdry).^2);

            % H2 with respect to both

        part1065.dx_H2dry_dx_H2Oexhdry = ((part1065.x_COdry-part1065.x_COdry.*part1065.x_H2Odil) ...
            .*(datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry-part1065.x_CO2dil.*(1+part1065.x_H2Oexhdry ...
            -part1065.x_rawexhdry)))-(part1065.x_COdry.*(part1065.x_H2Oexhdry-datastream('Options').Part_1065.KH2Ogas ...
            .*part1065.x_CO2dil.*part1065.x_H2Odil.*(1+part1065.x_H2Oexhdry ...
            -part1065.x_rawexhdry))))./((datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry ...
            -part1065.x_CO2dil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))).^2);
        part1065.dx_H2dry_dx_rawexhdry = (part1065.x_COdry.*part1065.x_H2Odil.*datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry ...
            -part1065.x_CO2dil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry))-part1065.x_COdry.* ...
            (part1065.x_H2Oexhdry-part1065.x_H2Odil.*(1+part1065.x_H2Oexhdry-part1065.x_rawexhdry)).* ...
            datastream('Options').Part_1065.KH2Ogas.*part1065.x_CO2dil)./((datastream('Options').Part_1065.KH2Ogas.*(part1065.x_CO2dry-part1065.x_CO2dil.*(1 ...
            +part1065.x_H2Oexhdry-part1065.x_rawexhdry))).^2);

            % Ccombdry with respect to both

        part1065.dx_Ccombdry_dx_H2Oexhdry = (((-2.*part1065.x_O2int.*part1065.x_CO2dil)./part1065.x_CO2int) ...
            +part1065.dx_H2dry_dx_H2Oexhdry)./(2.*part1065.x_O2int./part1065.x_CO2int+datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma);
        part1065.dx_Ccombdry_dx_rawexhdry = (((2.*part1065.x_O2int.*part1065.x_CO2dil)./part1065.x_CO2int) ...
            +part1065.dx_H2dry_dx_rawexhdry)./(2.*part1065.x_O2int./part1065.x_CO2int+datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma);

            % intexhdry with respect to both

        part1065.dx_intexhdry_dx_H2Oexhdry = 1./(2.*part1065.x_O2int).*((datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*part1065.dx_Ccombdry_dx_H2Oexhdry ...
            -part1065.dx_H2dry_dx_H2Oexhdry);
        part1065.dx_intexhdry_dx_rawexhdry = 1./(2.*part1065.x_O2int).*((datastream('Options').Fuel.alpha/2-datastream('Options').Fuel.beta+2+2*datastream('Options').Fuel.gamma).*part1065.dx_Ccombdry_dx_rawexhdry ...
            -part1065.dx_H2dry_dx_rawexhdry);

            % jacobian terms

        part1065.dx_f1_dx_H2Oexhdry = datastream('Options').Fuel.alpha/2.*part1065.dx_Ccombdry_dx_H2Oexhdry+part1065.x_H2Odil+part1065.x_H2Oint ...
            .*part1065.dx_intexhdry_dx_H2Oexhdry-part1065.dx_H2dry_dx_H2Oexhdry-1;
        part1065.dx_f1_dx_rawexhdry = datastream('Options').Fuel.alpha/2.*part1065.dx_Ccombdry_dx_rawexhdry-part1065.x_H2Odil+part1065.x_H2Oint ...
            .*part1065.dx_intexhdry_dx_rawexhdry-part1065.dx_H2dry_dx_rawexhdry;
        part1065.dx_f2_dx_H2Oexhdry = 0.5.*((datastream('Options').Fuel.alpha/2+datastream('Options').Fuel.beta+datastream('Options').Fuel.delta).*part1065.dx_Ccombdry_dx_H2Oexhdry+part1065.dx_H2dry_dx_H2Oexhdry)+ ...
            part1065.dx_intexhdry_dx_H2Oexhdry;
        part1065.dx_f2_dx_rawexhdry = 0.5.*((datastream('Options').Fuel.alpha/2+datastream('Options').Fuel.beta+datastream('Options').Fuel.delta).*part1065.dx_Ccombdry_dx_rawexhdry+part1065.dx_H2dry_dx_rawexhdry)+ ...
            part1065.dx_intexhdry_dx_rawexhdry-1;

        % SOLVE THE SYSTEM OF EQUATIONS USING CRAMER'S RULE

        part1065.delta_x_H2Oexhdry = (part1065.x_H2Oexhdryeval.*part1065.dx_f2_dx_rawexhdry ...
            -part1065.x_rawexhdryeval.*part1065.dx_f1_dx_rawexhdry)./(part1065.dx_f1_dx_H2Oexhdry ...
            .*part1065.dx_f2_dx_rawexhdry-part1065.dx_f1_dx_rawexhdry.*part1065.dx_f2_dx_H2Oexhdry);
        part1065.delta_x_rawexhdry = (part1065.x_rawexhdryeval.*part1065.dx_f1_dx_H2Oexhdry ...
            -part1065.x_H2Oexhdryeval.*part1065.dx_f2_dx_H2Oexhdry)./(part1065.dx_f1_dx_H2Oexhdry ...
            .*part1065.dx_f2_dx_rawexhdry-part1065.dx_f1_dx_rawexhdry.*part1065.dx_f2_dx_H2Oexhdry);

        % UPDATE INITIAL GUESS

        part1065.x_H2Oexhdry = part1065.x_H2Oexhdry+part1065.delta_x_H2Oexhdry;
        part1065.x_rawexhdry = part1065.x_rawexhdry+part1065.delta_x_rawexhdry;

    end

    if Iterations == IterationLimit, LM.DebugPrint(1,'WARNING: Iteration ceiling reached for chemical balance on %s_Bench: a chemical balance may not have been adequately determined', Bench); end;

    % Calculate NOx Correction Factor
    if strcmp(datastream('Options').Part_1065.Ignition_Type,'Spark')
        part1065.NOx_cor = 18.840*part1065.x_H2Oint+0.68094;
    else % Assumed compression ignition
        part1065.NOx_cor = 9.953*part1065.x_H2Oint+0.832;
    end

    part1065.n_exh = datastream('Q_Fuel_Mass_C').StreamingData./3.6.*datastream('Options').Fuel.w_C.*(1+part1065.x_H2Oexhdry)./(12.0107.*part1065.x_Ccombdry);

    % convert all concentrations to wet
    if datastream.isKey(COlAccess)
        part1065.CO_l = datastream(COlAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
        part1065.CO_l_m = datastream('Options').Molar_Mass.CO.*part1065.n_exh.*datastream('Options').delta_T.*part1065.CO_l;
        part1065.CO_l_m = part1065.CO_l_m.*(part1065.CO_l_m>=0);
    end

    if datastream.isKey(COhAccess)
        part1065.CO_h = datastream(COhAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
        part1065.CO_h_m = datastream('Options').Molar_Mass.CO.*part1065.n_exh.*datastream('Options').delta_T.*part1065.CO_h;
        part1065.CO_h_m = part1065.CO_h_m.*(part1065.CO_h_m>=0);
    end

    part1065.CO2 = datastream(CO2Access).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
    part1065.CO2_m = datastream('Options').Molar_Mass.CO2.*part1065.n_exh.*datastream('Options').delta_T.*part1065.CO2;
    part1065.CO2_m = part1065.CO2_m.*(part1065.CO2_m>=0);

    part1065.NOx = datastream(NOxAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
    part1065.NOx_m = datastream('Options').Molar_Mass.NOx.*part1065.n_exh.*datastream('Options').delta_T.*part1065.NOx;
    part1065.NOx_m = part1065.NOx_m.*(part1065.NOx_m>=0);

    if datastream.isKey(['HHC_',Bench])
        part1065.HHC = datastream(HHCAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
        part1065.HHC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.*part1065.HHC;
        part1065.HHC_m = part1065.HHC_m.*(part1065.HHC_m>=0);
    end

    part1065.HC = datastream(HCAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
    part1065.HC_m = datastream('Options').Molar_Mass.HC.*part1065.n_exh.*datastream('Options').delta_T.*part1065.HC;
    part1065.HC_m = part1065.HC_m.*(part1065.HC_m>=0);

    if datastream.isKey(CO2egrAccess)
        part1065.CO2_egr = datastream(CO2egrAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
        part1065.CO2_egr_m = datastream('Options').Molar_Mass.CO2.*part1065.n_exh.*datastream('Options').delta_T.*part1065.CO2_egr;
        part1065.CO2_egr_m = part1065.CO2_egr_m.*(part1065.CO2_egr_m>=0);
    end

    if datastream.isKey(CO2TrAccess)
        part1065.CO2_Tr = datastream(CO2TrAccess).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
        part1065.CO2_Tr_m = datastream('Options').Molar_Mass.CO2.*part1065.n_exh.*datastream('Options').delta_T.*part1065.CO2_Tr;
        part1065.CO2_Tr_m = part1065.CO2_Tr_m.*(part1065.CO2_Tr_m>=0);
    end

    if datastream.isKey(O2Access)
        part1065.O2 = datastream(O2Access).ConvertStreaming('mol/mol',DataToUse).*(1-part1065.x_H2Oexh);
        part1065.O2_m = datastream('Options').Molar_Mass.O2.*part1065.n_exh.*datastream('Options').delta_T.*part1065.O2;
        part1065.O2_m = part1065.O2_m.*(part1065.O2_m>=0);
    end

end

datastream = SetChannels(part1065, Bench, DataToUse, datastream);
