function Write_Transient_Cycle_Report_QA(Excel, datastream, ModeSegregation, Mode, PM_Data, inputs)
% Updates the following sections in the Transient Cycle Report: 
%
% Fuel/Carbon Balance Check
% Altitude Simulation Check
% CVS Check
% Cold Start Check
% Combustion Air Check
% Intercooler Check
% PM Sampler Check
%
% Syntax:   
%   Called from Write_Transient_Cycle_Report.m       
%
% Inputs:
%   Excel - (obj) A handle to an Excel COM server's default interface
%   datastream - (obj) A SuperGlue Channels object
%   ModeSegregation - (obj) A SuperGlue Mode object
%   ModeNumber - (int) The current mode
%   PM_Data -   TBD. From what I can tell it is a ModeSegregation.nModes-by-3
%               vector consisting of PM data or -1 if not used.
%   inputs - (obj) An object containing the following fields:
%
%       inputs.maxRawExhaust - (mixed) A value or methodology for computing the
%                               Maximum Raw Exhaust Flow.
%       inputs.saveMaxRawExhaust - (bool) A true/false flag indicating
%                                   whether or not the Maximum Raw Exhaust 
%                                   flow should be saved in the database.
%
% Outputs:
%   None. Updates the sections listed above in the Excel object
%   
% Example: 
%   Write_Transient_Cycle_Report_QA(Excel, datastream, ModeSegregation, k, PM_Data, inputs);
%   (as called from Write_Transient_Cycle_Report.m)
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   The Excel, datastream, and ModeSegregation inputs are objects which
%   contain many of their own methods utilized in the code below. For
%   example, isKey is a method of the MATLAB containers.Map class which is 
%   parent to the Channels class in SuperGlue, but there are numerous other
%   examples.
%
% MAT-files required: 
%   None
%
% See also: http://www.mathworks.com/help/matlab/ref/actxserver.html

% Author:           Eric Simon
% File Version:     1.1
% Revision History:   
% 1.0               Original file created by Jared Stewart.
% 1.1   09/22/2014  Added standard header.  
% 2.0   07/01/2015  Recoded to accommodate template changes.

% =========================================================================
global ENGINENUMBER;
if isempty(ENGINENUMBER), ENGINENUMBER = 0; end
if datastream('Options').Part_1065.IsOn, name = 'MF_NOx_Corr'; else name = 'NOx_Corr'; end 

% Altitude Simulation Check
if isKey(datastream,'P_SimBaro')
    try
        set(Range(Excel,'Barometric_Pressure_Min'),'Value',min(datastream('P_SimBaro').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Barometric_Pressure_Avg'),'Value',mean(datastream('P_SimBaro').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Barometric_Pressure_Max'),'Value',max(datastream('P_SimBaro').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
    catch
    end
end

if isKey(datastream,'P_Ex')
    try
        if ~length(find(isnan(datastream('P_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1)))) % Check for NaNs 
            P_Ex = unitConversion(datastream('P_Ex').Type, datastream('P_Ex').Name, datastream('P_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1), datastream('P_Ex').Current_Units, 'kPa');
            set(Range(Excel,'Exhaust_Pressure_Min'),'Value',min(P_Ex));
            set(Range(Excel,'Exhaust_Pressure_Avg'),'Value',mean(P_Ex));
            set(Range(Excel,'Exhaust_Pressure_Max'),'Value',max(P_Ex));       
        end
    catch
    end
end

if isKey(datastream,'P_CFV')
    try
        if ~length(find(isnan(datastream('P_CFV').StreamingData(ModeSegregation.getModeIndices(Mode)==1)))) % Check for NaNs
            P_CFV = unitConversion(datastream('P_CFV').Type, datastream('P_CFV').Name, datastream('P_CFV').StreamingData(ModeSegregation.getModeIndices(Mode)==1), datastream('P_CFV').Current_Units, 'kPa');
            set(Range(Excel,'CFV_Pressure_Min'),'Value',min(P_CFV));
            set(Range(Excel,'CFV_Pressure_Avg'),'Value',mean(P_CFV));
            set(Range(Excel,'CFV_Pressure_Max'),'Value',max(P_CFV));
        end
    catch
    end
end

% CVS Check
if isKey(datastream,'Q_CVS')
    try
        set(Range(Excel,'CVS_Flow_Min'),'Value',min(datastream('Q_CVS').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'CVS_Flow_Avg'),'Value',mean(datastream('Q_CVS').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'CVS_Flow_Max'),'Value',max(datastream('Q_CVS').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
    catch
    end
end

if isKey(datastream,'T_Dil_Air')
    try
        set(Range(Excel,'Dilution_Air_Temp_Min'),'Value',min(datastream('T_Dil_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Dilution_Air_Temp_Avg'),'Value',mean(datastream('T_Dil_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Dilution_Air_Temp_Max'),'Value',max(datastream('T_Dil_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
    catch
    end
end

if isKey(datastream,'T_In_Air')
    try
        set(Range(Excel,'Combustion_Air_Temp_Min'),'Value',min(datastream('T_In_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Combustion_Air_Temp_Avg'),'Value',mean(datastream('T_In_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Combustion_Air_Temp_Max'),'Value',max(datastream('T_In_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
    catch
    end
end

if isKey(datastream,'DT_Air_2')
    try
        set(Range(Excel,'Combustion_Air_Dew_Temp_Min'),'Value',min(datastream('DT_Air_2').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Combustion_Air_Dew_Temp_Avg'),'Value',mean(datastream('DT_Air_2').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'Combustion_Air_Dew_Temp_Max'),'Value',max(datastream('DT_Air_2').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
    catch
    end
end

if isKey(datastream,name)
    try        
        set(Range(Excel,'NOX_Correction_Factor_Min'),'Value',min(datastream(name).StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'NOX_Correction_Factor_Avg'),'Value',mean(datastream(name).StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        set(Range(Excel,'NOX_Correction_Factor_Max'),'Value',max(datastream(name).StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
    catch
    end
end

if isKey(datastream,'T_IC1_GI')
    try
        if ~length(find(isnan(datastream('T_IC1_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)))) % Check for NaNs
            set(Range(Excel,'Intercooler1_Glycol_Min'),'Value',min(datastream('T_IC1_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Intercooler1_Glycol_Avg'),'Value',mean(datastream('T_IC1_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Intercooler1_Glycol_Max'),'Value',max(datastream('T_IC1_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        end
    catch
    end
end

if isKey(datastream,'T_IC2_GI')
    try
        if ~length(find(isnan(datastream('T_IC2_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)))) % Check for NaNs
            set(Range(Excel,'Intercooler2_Glycol_Min'),'Value',min(datastream('T_IC2_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Intercooler2_Glycol_Avg'),'Value',mean(datastream('T_IC2_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Intercooler2_Glycol_Max'),'Value',max(datastream('T_IC2_GI').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        end
    catch
    end
end

% Fuel/Carbon Balance Check
if isKey(datastream,'Q_Fuel_Mass_C')
    try
        set(Range(Excel,'Fuel_Meter'),'Value',datastream('Q_Fuel_Mass_C').ModeCompositeData(Mode)*datastream('Time').ModeCompositeData(Mode) / 3.6 );
        set(Range(Excel,'Fuel_Meter_Power'),'Value',datastream('Q_Fuel_Mass_C').ModeCompositeData(Mode)*datastream('Time').ModeCompositeData(Mode) / ...
            (3.6*datastream('Work').ModeCompositeData(Mode)));
    catch
    end
end

if datastream('Options').Part_1065.IsOn
    if isKey(datastream,'MF_Fuel_CB')
        set(Range(Excel,'Carbon_Balance'),'Value',datastream('MF_Fuel_CB').ModeCompositeData(Mode));
        set(Range(Excel,'Carbon_Balance_Power'),'Value',datastream('MF_Fuel_CB').ModeCompositeData(Mode)/datastream('Work').ModeCompositeData(Mode));
    end
else
    if isKey(datastream,'Fuel_CB')
        set(Range(Excel,'Carbon_Balance'),'Value',datastream('MF_Fuel_CB').ModeCompositeData(Mode));
        set(Range(Excel,'Carbon_Balance_Power'),'Value',datastream('Fuel_CB').ModeCompositeData(Mode)/datastream('Work').ModeCompositeData(Mode));
    end
end

if isKey(datastream,'CO2_Bag_Dilute') && isKey(datastream,'CO2_Tr_Tailpipe')
    if  datastream('Options').Part_1065.IsOn
        try
            set(Range(Excel,'Tracer_Agreement_Avg'),'Value',mean(datastream('CO2_Bag_Dilute').StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(Mode)==1) ...
                -datastream('CO2_Tr_Tailpipe').StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(Mode)==1)));
        catch 
            set(Range(Excel,'Tracer_Agreement_Avg'),'Value',mean(datastream('CO2_Bag_Dilute').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(Mode)==1) ...
                -datastream('CO2_Tr_Tailpipe').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(Mode)==1)));
        end
        
        % Dilute Exhaust Dew Point
        try
            set(Range(Excel,'Dilute_Exhaust_Dew_Point_Min'),'Value',min(datastream('MF_DT_dilexh').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Dilute_Exhaust_Dew_Point_Avg'),'Value',mean(datastream('MF_DT_dilexh').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Dilute_Exhaust_Dew_Point_Max'),'Value',max(datastream('MF_DT_dilexh').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        
            T_Tunn = zeros(2,1);
            T_Tunn(1) = min(datastream('T_Tunn_1').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
            T_Tunn(2) = min(datastream('T_Tunn_2').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
            set(Range(Excel,'Dilute_Exhaust_Dew_Point_Lower_Limit'),'Value',min(T_Tunn));

            if DewT_in_Exh_QA(datastream)
                set(Range(Excel,'Dilute_Exhaust_Dew_Point_Check'),'Value','PASSED');
            else
                set(Range(Excel,'Dilute_Exhaust_Dew_Point_Check'),'Value','FAILED');
            end
        catch
        end
    else
        try
            set(Range(Excel,'Tracer_Agreement_Avg'),'Value',mean(datastream('CO2_Bag_Dilute').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(Mode)==1) ...
                -datastream('CO2_Tr_Tailpipe').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(Mode)==1)));
        catch
        end
    end
end

% Cold Start Check
if strcmp(datastream('Options').Start_Type,'Cold')
    try
        if isKey(datastream,'T_Oil') && ~isnan(datastream('T_Oil').StreamingData(1))
            set(Range(Excel,'Oil_Temperature_At_Test_Start'),'Value',datastream('T_Oil').StreamingData(1));
        elseif isKey(datastream,'T_OilGal') && ~isnan(datastream('T_OilGal').StreamingData(1))
            set(Range(Excel,'Oil_Temperature_At_Test_Start'),'Value',datastream('T_OilGal').StreamingData(1));
        end
    catch
    end
    
    try
        if isKey(datastream,'T_Cool_I') && ~isnan(datastream('T_Cool_I').StreamingData(1))
            set(Range(Excel,'Coolant_Temperature_At_Test_Start'),'Value',datastream('T_Cool_I').StreamingData(1));
        elseif isKey(datastream,'T_Cool_I_C') && ~isnan(datastream('T_Cool_I_C').StreamingData(1))
            set(Range(Excel,'Coolant_Temperature_At_Test_Start'),'Value',datastream('T_Cool_I_C').StreamingData(1));
        elseif isKey(datastream,'T_Cool_O')&& ~isnan(datastream('T_Cool_O').StreamingData(1))
            set(Range(Excel,'Coolant_Temperature_At_Test_Start'),'Value',datastream('T_Cool_O').StreamingData(1));
        elseif isKey(datastream,'T_Cool_O_C')&& ~isnan(datastream('T_Cool_O_C').StreamingData(1))
            set(Range(Excel,'Coolant_Temperature_At_Test_Start'),'Value',datastream('T_Cool_O_C').StreamingData(1));
        end
    catch
    end
end

if strcmp(datastream('Options').Particulate_On,'Yes')
    
    % PM Sampler Check
    if isKey(datastream,'T_PM_Tree')
        try        
            set(Range(Excel,'Filter_Temp_Min'),'Value',min(datastream('T_PM_Tree').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Filter_Temp_Avg'),'Value',mean(datastream('T_PM_Tree').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Filter_Temp_Max'),'Value',max(datastream('T_PM_Tree').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        catch
        end
    end    
    
    if isKey(datastream,'T_2Dil_Air')
        try        
            set(Range(Excel,'Secondary_Dil_Temp_Min'),'Value',min(datastream('T_2Dil_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Secondary_Dil_Temp_Avg'),'Value',mean(datastream('T_2Dil_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
            set(Range(Excel,'Secondary_Dil_Temp_Max'),'Value',max(datastream('T_2Dil_Air').StreamingData(ModeSegregation.getModeIndices(Mode)==1)));
        catch
        end
    end      
    
    Q_Part = datastream('Q_Part').ConvertStreaming('scf/m');
    Q_Sample = datastream('Q_Part').ConvertStreaming('scf/m')-datastream('Q_2Dil').ConvertStreaming('scf/m');
    DR_2 = Q_Part./Q_Sample;
    Q_CVS = datastream('Q_CVS').ConvertStreaming('scf/m');
    SEE = SEE_Proportional_Sampling(Q_Sample(ModeSegregation.getModeIndices(Mode)==1),Q_CVS(ModeSegregation.getModeIndices(Mode)==1));
    set(Range(Excel,'SEE_Avg'),'Value',SEE/mean(Q_Sample(ModeSegregation.getModeIndices(Mode)==1)));    
    set(Range(Excel,'Secondary_Dilution_Min'),'Value',min(DR_2(ModeSegregation.getModeIndices(Mode)==1)));
    
    
    if isKey(datastream,'V_Bypass')
        try
            Q_Bypass = 60*datastream('V_Bypass').ModeCompositeData(Mode)/datastream('Time').ModeCompositeData(Mode);
            set(Range(Excel,'Average_Raw_Bench_Flow_Rate'),'Value',Q_Bypass);
        catch
        end
    else
        try
            set(Range(Excel,'Average_Raw_Bench_Flow_Rate'),'Value',0);
        catch
        end
    end
    
    % Use the options.maxRawExhaust argument value or methodolgy to compute the
    % Maximum Raw Exhaust Flow
    maxRawExhaustError = 0;
    maxRawExhaust_method = '* Calculated as the maximum value of Raw Exhaust';
    Average_Dilute_Exhaust_Flow = mean(datastream('Q_CVS').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
   
    if isnumeric(inputs.maxRawExhaust)
        maxRawExhaust_value = inputs.maxRawExhaust;
        maxRawExhaust_method = '* User Input';
        
    elseif strcmp(inputs.maxRawExhaust,'3s') 
        time_int = getTimeInterval(datastream('Time').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
        if time_int ~= 0
            maxRawExhaust_value = max(movingmean(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1),3*(1/time_int),[],[]));
            maxRawExhaust_method = '* Calculated as the maximum value of a 3s moving average of Raw Exhaust';
        else
            maxRawExhaustError = 1;
            warning('The time vector interval is not constant! The default Maximum Raw Exhaust Flow value max(Q_Ex) will be used!');
            maxRawExhaust_value = max(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
        end
            
    elseif strcmp(inputs.maxRawExhaust,'5s') 
        time_int = getTimeInterval(datastream('Time').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
        if time_int ~= 0
            maxRawExhaust_value = max(movingmean(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1),5*(1/time_int),[],[]));
            maxRawExhaust_method = '* Calculated as the maximum value of a 5s moving average of Raw Exhaust';
        else
            maxRawExhaustError = 1;
            warning('The time vector interval is not constant! The default Maximum Raw Exhaust Flow value max(Q_Ex) will be used!');
            maxRawExhaust_value = max(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
        end
        
    elseif strcmp(inputs.maxRawExhaust,'db')
        try % Connect to database - if database isn't available then use the default 
            NET.addAssembly('System.Data'); %this imports the library into MATLAB
            connString = 'DSN=ETRE';
            odbcCN = System.Data.Odbc.OdbcConnection(connString); 
            odbcCN.Open(); % connects to the SQL Server (must have DSN)
            
            sql = ['SELECT max_raw_exh FROM engine WHERE control = ''' num2str(ENGINENUMBER) '''']; % It already is a string but just in case
            odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
            
            res = odbcCOM.ExecuteReader();
            while (res.Read())
                if strcmp(strtrim(char(res.GetName(0))),'max_raw_exh') % This is really unneccessary but just in case
                    maxRawExhaust_value = res.GetValue(0);
                    maxRawExhaust_method = '* Database value';
                else 
                    maxRawExhaustError = 1;
                    warning('MATLAB was unable to execute the appropriate query! The default Maximum Raw Exhaust Flow value max(Q_Ex) will be used instead!');
                    maxRawExhaust_value = max(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
                end                
            end
            
            res.Close();
            odbcCN.Close();
            
        catch 
            maxRawExhaustError = 1;
            warning('MATLAB was unable to connect to the requested database! The default Maximum Raw Exhaust Flow value max(Q_Ex) will be used instead!');
            maxRawExhaust_value = max(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1));
        end
        
    else
        maxRawExhaust_value = max(datastream('Q_Ex').StreamingData(ModeSegregation.getModeIndices(Mode)==1)); % Use default
    end
    
    try
        set(Range(Excel,'Maximum_Raw_Exhaust_Flow'),'Value',maxRawExhaust_value); % Maximum Raw Exhaust Flow
        set(Range(Excel,'Maximum_Raw_Exhaust_Flow_Method'),'Value',maxRawExhaust_method); % Maximum Raw Exhaust Flow Calculation Method
        set(Range(Excel,'Average_Dilute_Exhaust_Flow'),'Value',mean(datastream('Q_CVS').StreamingData(ModeSegregation.getModeIndices(Mode)==1))); % Average Dilute Exhaust Flow 
    catch
    end
    
    % Set Primary Dilution minimum
    if isnumeric(maxRawExhaust_value) && isnumeric(Average_Dilute_Exhaust_Flow) && isnumeric(Q_Bypass) && (maxRawExhaust_value - Q_Bypass) ~= 0
        Primary_Dilution_Minimum = Average_Dilute_Exhaust_Flow / (maxRawExhaust_value - Q_Bypass);
        set(Range(Excel,'Primary_Dilution_Min'),'Value',Primary_Dilution_Minimum);
    end      
    
    if size(PM_Data,2) == 3
        try
            set(Range(Excel,'PM_Filter_Tare_Min'),'Value',PM_Data(Mode,2));
            set(Range(Excel,'PM_Filter_Gross_Min'),'Value',PM_Data(Mode,1));
        catch
        end
    end
    
    % Save the new maxRawExhaust_value to the database (disabled)
    if maxRawExhaustError == 0 && inputs.saveMaxRawExhaust 
        warning('This functionality has been disabled! The Maximum Raw Exhaust Flow value was not saved!')
    end    
end