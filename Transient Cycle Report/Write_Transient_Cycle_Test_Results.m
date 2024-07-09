function PM_Data = Write_Transient_Cycle_Test_Results(Excel, datastream, ModeSegregation, Mode)
% Updates the Test Results section in the Transient Cycle Report and
% returns the PM_Data
%
% Syntax:
%   Called from Write_Transient_Cycle_Report.m
%
% Inputs:
%   Excel - (obj) A handle to an Excel COM server's default interface
%   datastream - (obj) A SuperGlue Channels object
%   ModeSegregation - (obj) A SuperGlue Mode object
%   ModeNumber - (int) The current mode
%
% Outputs:
%   PM_Data -   TBD. From what I can tell it is a ModeSegregation.nModes-by-3
%               vector consisting of PM data of type double or -1 if not used.
%   Also updates the Test Results section in the Excel object (see
%   above)
%
% Example:
%   PM_Data = Write_Transient_Cycle_Test_Results(Excel, datastream, ModeSegregation, k);
%   (as called from Write_Transient_Cycle_Report.m)
%
% Other m-files required:
%   None
%
% Subfunctions:
%   The Excel, datastream, and ModeSegregation inputs are objects which
%   contain many of their own methods utilized in the code below. For
%   example, isKey is a method of the MATLAB containers.Map class which is
%   parent to the Channels class in SuperGlue, but their are numerous other
%   examples.

%
% MAT-files required:
%   None
%
% See also: http://www.mathworks.com/help/matlab/ref/actxserver.html

% Author:           Eric Simon
% File Version:     2.0
% Revision History:
% 1.0               Original file created by Jared Stewart.
% 1.1   09/22/2014  Added standard header.
% 2.0   07/01/2015  Recoded to accommodate template changes. 

% =========================================================================

global TESTNUMBER;

% Fuel Meter BSFC
if isKey(datastream,'Q_Fuel_Mass_C')
    % Note that Q_Fuel_Mass_C units are kg/hr, Time is in seconds, and Work
    % units are kW.hr. Divide by 3.6 to convert to g/kW.hr.
    set(Range(Excel,'Fuel_Meter_BSFC') ,'Value',datastream('Q_Fuel_Mass_C').ModeCompositeData(Mode)*datastream('Time').ModeCompositeData(Mode) / ...
        (3.6*datastream('Work').ModeCompositeData(Mode))); 
end

% Cycle Work
set(Range(Excel,'Cycle_Work'),'Value',datastream('Work').ModeCompositeData(Mode)); 

% NOx Correction Factor and Carbon Balance BSFC
if  datastream('Options').Part_1065.IsOn
    set(Range(Excel,'NOx_Correction_Factor'),'Value',datastream('MF_NOx_Corr').ModeCompositeData(Mode)); % 1065 NOx Correction Factor
    if isKey(datastream,'MF_Fuel_CB')
        set(Range(Excel,'Carbon_Balance_BSFC'),'Value',datastream('MF_Fuel_CB').ModeCompositeData(Mode)/datastream('Work').ModeCompositeData(Mode)); % 1065 Carbon Balance BSFC
    end
else
    set(Range(Excel,'NOx_Correction_Factor'),'Value',datastream('NOx_Corr').ModeCompositeData(Mode)); % NOx Correction Factor
    if isKey(datastream,'Fuel_CB')
        set(Range(Excel,'Carbon_Balance_BSFC'),'Value',datastream('Fuel_CB').ModeCompositeData(Mode)/datastream('Work').ModeCompositeData(Mode)); % Carbon Balance BSFC
    end
end

% Grab the PM Data from the database
PM_Data = zeros(ModeSegregation.nModes, 3); % Initialize to a nModes-by-3 double
if exist([datastream('Options').Network_Path 'PM Files\' num2str(TESTNUMBER) '_PM.txt'], 'file');
    PM_Data = importdata([datastream('Options').Network_Path 'PM Files\' num2str(TESTNUMBER) '_PM.txt']); % PM_DATA is overwritten loses 3 dimensions
else
    try
        NET.addAssembly('System.Data'); % this imports the library into MATLAB
        connString = 'DSN=VTREUPDATE';
        odbcCN = System.Data.Odbc.OdbcConnection(connString);
        odbcCN.Open(); % connects to the SQL Server (must have DSN)
        sql = ['SELECT * FROM tbl_PM_Filter WHERE Test_Number = ' num2str(TESTNUMBER)];
        odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
        res = odbcCOM.ExecuteReader();
        while (res.Read())
            try
                PM_Mode = double(res.GetValue(19));
                PM_Data(PM_Mode, 1) = double(res.GetValue(11));
                PM_Data(PM_Mode, 2) = double(res.GetValue(10));
                PM_Data(PM_Mode, 3) = double(res.GetValue(11))-double(res.GetValue(10));
                if PM_Data(PM_Mode) < 0, PM_Data(PM_Mode) = 0; end;
            catch %#ok
                % DBNull should get funneled to here
            end
        end
        if sum(PM_Data) == 0, PM_Data = -1; end;
        res.Close()
    catch %#ok<CTCH>
        PM_Data = -1;
    end
end

if PM_Data ~= -1
    PM_Width = size(PM_Data,2);
    PM = PM_Data(:,PM_Width).*(datastream('Q_Part').ConvertModeComposite('scf/m').*datastream('Q_CVS_C').ModeCompositeData./ ...
         (datastream('Q_Part').ConvertModeComposite('scf/m')-datastream('Q_2Dil').ConvertModeComposite('scf/m')))./(1000.*datastream('Q_Part').ConvertModeComposite('scf/m'));
end

if isKey(datastream,'SM_CC')
    if datastream('Options').Smoke_Meter_Sample_Position == 9 || datastream('Options').Smoke_Meter_Sample_Position == 6
        SM = datastream('SM_CC').StreamingData.*datastream('Q_CVS_C').StreamingData.*datastream('Options').delta_T./(35.314666*60*1000);
    elseif datastream('Options').Smoke_Meter_Sample_Position ~= 0
        SM = datastream('SM_CC').StreamingData.*datastream('Q_Ex').StreamingData.*datastream('Options').delta_T./(35.314666*60*1000);
    end
end

if isKey(datastream,'MSS_CC')
    if datastream('Options').MSS_Sample_Position == 9 || datastream('Options').MSS_Sample_Position == 6
        MSS = datastream('MSS_CC').StreamingData.*datastream('Q_CVS_C').StreamingData.*datastream('Options').delta_T./(35.314666*60*1000);
    elseif datastream('Options').MSS_Sample_Position ~= 0
        MSS = datastream('MSS_CC').StreamingData.*datastream('Q_Ex').StreamingData.*datastream('Options').delta_T./(35.314666*60*1000);
    end
end

species = {'CO2' 'CO_l'  'NOx' 'N2O' 'HC' 'CH4' 'NMHC' 'NMHC_NOx' 'PM' 'MSS' 'SM'};

for column = 1:length(species)
    
    % Define the Excel Ranges
    ConcRange = ['Avg_Concentration_' species{column}];
    MassRange = ['Mass_Emissions_' species{column}];
    BSRange = ['BSE_' species{column}];
    
    % Initialize the concentration, mass, and brake specific emissions values
    ConcValue = '-';
    MassValue = '-';
    BSValue = '-';

    switch species{column}
        case 'NMHC_NOx'
            if  datastream('Options').Part_1065.IsOn
                MassValue = datastream('NOx_Bag_Dilute').ModeCompositeData.Part1065Mass(Mode) + datastream('NMHC_Bag_Dilute').ModeCompositeData.Part1065Mass(Mode);
                BSValue = datastream('NOx_Bag_Dilute').ModeCompositeData.Part1065BrakeSpecificMass(Mode) + datastream('NMHC_Bag_Dilute').ModeCompositeData.Part1065BrakeSpecificMass(Mode);
            end
        case 'PM'
            % EDS: Since PM_Data can be a matrix or -1. Kludge.
            if PM_Data ~= -1
                MassValue = PM(Mode);
                BSValue = PM(Mode)/datastream('Work').ModeCompositeData(Mode);
            end
        case 'MSS'
            if isKey(datastream,'MSS_CC') && datastream('Options').MSS_Sample_Position ~= 0
                ConcValue = datastream('MSS_CC').ModeCompositeData(Mode);
                MassValue = sum(MSS(ModeSegregation.getModeIndices(Mode)==1));
                BSValue = sum(MSS(ModeSegregation.getModeIndices(Mode)==1))/datastream('Work').ModeCompositeData(Mode);
            end
        case 'SM'
            if isKey(datastream,'SM_CC') && datastream('Options').Smoke_Meter_Sample_Position ~= 0
                ConcValue = datastream('SM_CC').ModeCompositeData(Mode);
                MassValue = sum(SM(ModeSegregation.getModeIndices(Mode)==1));
                BSValue = sum(SM(ModeSegregation.getModeIndices(Mode)==1))/datastream('Work').ModeCompositeData(Mode);
            end
        otherwise
            if  datastream('Options').Part_1065.IsOn
                name = [species{column} '_Bag_Dilute'];
                if strcmp(species{column},'HC'), if datastream('Options').Use_HC, name = 'HC_Bag_Dilute_Corrected'; else name = 'HHC_Bag_Dilute_Corrected'; end; end
                if strcmp(species{column},'CH4'), name = 'CH4_Bag_Dilute_Corrected'; end

                if isKey(datastream,name)
                    ConcValue = datastream(name).ModeCompositeData.Part1065Concentration(Mode);
                    MassValue = datastream(name).ModeCompositeData.Part1065Mass(Mode);
                    BSValue = datastream(name).ModeCompositeData.Part1065BrakeSpecificMass(Mode);
                end
            else
                if strcmp(species{column},'NMHC'), continue; end
                name = [species{column} '_Bag_Dilute'];
                if isKey(datastream,name)
                    ConcValue = datastream(name).ModeCompositeData.Part1065Concentration(Mode);
                    MassValue = datastream(name).ModeCompositeData.Part1065Mass(Mode);
                    BSValue = datastream(name).ModeCompositeData.Part1065BrakeSpecificMass(Mode);
                end
            end
    end
    set(Range(Excel,ConcRange),'Value',ConcValue);
    set(Range(Excel,MassRange),'Value',MassValue);
    set(Range(Excel,BSRange),'Value',BSValue);
end