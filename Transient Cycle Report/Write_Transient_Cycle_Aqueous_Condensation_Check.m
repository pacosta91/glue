function Write_Transient_Cycle_Aqueous_Condensation_Check(Excel, filename, datastream, ModeSegregation, ModeNumber)
% Updates the Background Check section in the Transient Cycle Report 
%
% Syntax:   
%   Called from Write_Transient_Cycle_Report.m       
%
% Inputs:
%   Excel - (obj) A handle to an Excel COM server's default interface
%   filename (str) - The name of the file being processed
%   datastream - (obj) A SuperGlue Channels object
%   ModeSegregation - (obj) A SuperGlue Mode object
%   ModeNumber - (int) The current mode
%
% Outputs:
%   None. Updates the Aqueous Condensation section in the Excel object (see
%   above)
%   
% Example: 
%    Write_Transient_Cycle_Aqueous_Condensation_Check(Excel, datastream, ModeSegregation, k);
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
% File Version:     1.0
% Revision History:   
% 1.0               Original file based on concepts by NB.

% =========================================================================

% Grab the engine number 
temp = stringread(filename, '_');
engineID = temp{2};
testnumber = temp{4};

Aqueous_Time = datastream('Time').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);
MF_DT_dilexh = datastream('MF_DT_dilexh').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);
T_Tunn_1 = datastream('T_Tunn_1').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);
T_Tunn_2 = datastream('T_Tunn_2').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);
Q_CVS_Mol_C = datastream('Q_CVS_Mol_C').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);
P_CFV = datastream('P_CFV').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);
MF_x_H2Oexh_Bag_Dilute = datastream('MF_x_H2Oexh_Bag_Dilute').StreamingData(ModeSegregation.getModeIndices(ModeNumber)==1);

% Calculated Values
Partial_P_H2O_dilexh = 10 .^ (10.79574 * (1 - 273.16 ./ (MF_DT_dilexh + 273.16)) ... 
    - 5.028 * log10((MF_DT_dilexh + 273.16) ./ 273.16) + ...
    0.000150475 * (1 - 10 .^ (-8.2969 * ((MF_DT_dilexh + 273.16) ./ 273.16 - 1))) + 0.0042873 * ...
    (10 .^ (4.76955 * (1 - 273.16 ./ (MF_DT_dilexh + 273.16))) - 1) - 0.2138602);

Xh2oexh = Partial_P_H2O_dilexh ./ P_CFV;
Min_Tunnel_Wall_T = min(T_Tunn_1,T_Tunn_2);

Partial_P_H2O_Min_Wall_T = 10 .^ (10.79574 * (1 - 273.16 ./ (Min_Tunnel_Wall_T + 273.16)) ... 
    - 5.028 * log10((Min_Tunnel_Wall_T + 273.16) ./ 273.16) + ...
    0.000150475 * (1 - 10 .^ (-8.2969 * ((Min_Tunnel_Wall_T + 273.16) ./ 273.16 - 1))) + 0.0042873 * ...
    (10 .^ (4.76955 * (1 - 273.16 ./ (Min_Tunnel_Wall_T + 273.16))) - 1) - 0.2138602);

Max_H2O_Fract_Min_Wall_T = Partial_P_H2O_Min_Wall_T ./ P_CFV;
Potential_H2O_Mole_Fraction_Loss = max(0, Xh2oexh - Max_H2O_Fract_Min_Wall_T);
Potential_H2O_Mole_Flow_Loss = Potential_H2O_Mole_Fraction_Loss .* Q_CVS_Mol_C;
Cumulative_Potential_H2O_Mole_Flow_Loss = cumsum(Potential_H2O_Mole_Flow_Loss/60);
dilexh_dp_higher_min_wall_temp = double(Min_Tunnel_Wall_T < MF_DT_dilexh);

total_time_dilexh_dp_higher_min_wall_temp = sum(dilexh_dp_higher_min_wall_temp);
max_continuous_potential_for_mole_fraction_loss = max(Potential_H2O_Mole_Fraction_Loss);
total_potential_for_mole_fraction_loss = sum(Potential_H2O_Mole_Flow_Loss) / sum(Q_CVS_Mol_C);
fraction_of_test_time = total_time_dilexh_dp_higher_min_wall_temp / length(dilexh_dp_higher_min_wall_temp);

% Populate the Excel spreadsheet
set(Range(Excel,['AqueousCheck!A3:A' num2str(length(Aqueous_Time)+2)]),'Value',Aqueous_Time);
set(Range(Excel,['AqueousCheck!B3:B' num2str(length(MF_DT_dilexh)+2)]),'Value',MF_DT_dilexh);
set(Range(Excel,['AqueousCheck!C3:C' num2str(length(T_Tunn_1)+2)]),'Value',T_Tunn_1);
set(Range(Excel,['AqueousCheck!D3:D' num2str(length(T_Tunn_2)+2)]),'Value',T_Tunn_2);
set(Range(Excel,['AqueousCheck!E3:E' num2str(length(Q_CVS_Mol_C)+2)]),'Value',Q_CVS_Mol_C);
set(Range(Excel,['AqueousCheck!F3:F' num2str(length(P_CFV)+2)]),'Value',P_CFV);
set(Range(Excel,['AqueousCheck!G3:G' num2str(length(MF_x_H2Oexh_Bag_Dilute)+2)]),'Value',MF_x_H2Oexh_Bag_Dilute);
set(Range(Excel,['AqueousCheck!H3:H' num2str(length(Partial_P_H2O_dilexh)+2)]),'Value',Partial_P_H2O_dilexh);
set(Range(Excel,['AqueousCheck!I3:I' num2str(length(Xh2oexh)+2)]),'Value',Xh2oexh);
set(Range(Excel,['AqueousCheck!J3:J' num2str(length(Min_Tunnel_Wall_T)+2)]),'Value',Min_Tunnel_Wall_T);
set(Range(Excel,['AqueousCheck!K3:K' num2str(length(Partial_P_H2O_Min_Wall_T)+2)]),'Value',Partial_P_H2O_Min_Wall_T);
set(Range(Excel,['AqueousCheck!L3:L' num2str(length(Max_H2O_Fract_Min_Wall_T)+2)]),'Value',Max_H2O_Fract_Min_Wall_T);
set(Range(Excel,['AqueousCheck!M3:M' num2str(length(Potential_H2O_Mole_Fraction_Loss)+2)]),'Value',Potential_H2O_Mole_Fraction_Loss);
set(Range(Excel,['AqueousCheck!N3:N' num2str(length(Potential_H2O_Mole_Flow_Loss)+2)]),'Value',Potential_H2O_Mole_Flow_Loss);
set(Range(Excel,['AqueousCheck!O3:O' num2str(length(Cumulative_Potential_H2O_Mole_Flow_Loss)+2)]),'Value',Cumulative_Potential_H2O_Mole_Flow_Loss);
set(Range(Excel,['AqueousCheck!P3:P' num2str(length(dilexh_dp_higher_min_wall_temp)+2)]),'Value',dilexh_dp_higher_min_wall_temp);

set(Range(Excel,'Time_Dil_Exh_DP_Above_Min_Tunnel'),'Value',total_time_dilexh_dp_higher_min_wall_temp);
set(Range(Excel,'Max_Potential_Fraction_For_Drop_Out'),'Value',max_continuous_potential_for_mole_fraction_loss);
set(Range(Excel,'Accum_Potential_Fraction_For_Drop_Out'),'Value',total_potential_for_mole_fraction_loss);
set(Range(Excel,'Fraction_of_Test_Time'),'Value',fraction_of_test_time);

Sheet = get(Excel.Sheets,'Item','Report');
Activate(Sheet);
Chart = Sheet.ChartObjects('AqueousCondensationChart').Chart;
x_axis_min = 0;
x_axis_max = ceil(max(Aqueous_Time));
y_axis_min = floor(min([MF_DT_dilexh; Min_Tunnel_Wall_T]));
y_axis_max = ceil(max([MF_DT_dilexh; Min_Tunnel_Wall_T]));
set(Chart.Axes(1),'MinimumScale',x_axis_min);
set(Chart.Axes(1),'MaximumScale',x_axis_max);
set(Chart.Axes(1),'MajorUnit',x_axis_max - x_axis_min);
% set(Chart.Axes(2),'MinimumScale',y_axis_min);
% set(Chart.Axes(2),'MaximumScale',y_axis_max);

end