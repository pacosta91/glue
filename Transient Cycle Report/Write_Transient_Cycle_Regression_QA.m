function Write_Transient_Cycle_Regression_QA(Excel, filename, pathname, ModeNumber)
% Updates the Regression Check section in the Transient Cycle Report
%
% Syntax:
%   Called from Write_Transient_Cycle_Report.m
%
% Inputs:
%   Excel - (obj) A handle to an Excel COM server's default interface
%   filename -  (string) The name of the *.mat file loaded by the calling
%               function, Write_Transient_Cycle_Report.m
%   pathname -  (string) The pathname to the *.mat file loaded by the
%               calling function, Write_Transient_Cycle_Report.m
%   ModeNumber - (int) The current mode
%
% Outputs:
%   None. Updates the Regression Check section in the Excel object (see
%   above)
%
% Example:
%   Write_Transient_Cycle_Regression_QA(Excel, filename2{i}, pathname2, k);
%   (as called from Write_Transient_Cycle_Report.m; note that filename2 is
%   a cell array in the Write_Transient_Cycle_Report.m function)
%
% Other m-files required:
%   None
%
% Subfunctions:
%   The Excel input is an object which contains its own methods utilized in the code below.
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

% =========================================================================

try
    RegressionData = Read_Regression_Report(filename, pathname, ModeNumber);
catch ME

    if strcmp(ME.identifier,'MATLAB:FileNotFound')
        warning(ME.identifier, [ME.message ' - regression check is being skipped\n']);
        return;
    else
        warning('MATLAB:Write_Transient_Cycle_Report','Unable to read %s regression file - regression check is being skipped\n', filename);
        return;
    end
end

% Prepare the data for export to Excel
AllData = [RegressionData.Time RegressionData.ReferenceSpeed RegressionData.ActualSpeed RegressionData.OmitSpeed RegressionData.ReferenceTorque RegressionData.ActualTorque...
     RegressionData.OmitTorque RegressionData.ReferencePower RegressionData.ActualPower RegressionData.OmitPower RegressionData.Throttle];

% Omitted points are designated by columns 4 (for speed), 7 (for torque),
% and 10 (for power). A non-zero value in any of these columns means that
% row should be omitted for that quantity (speed, torque, or power).
%SpeedMatrix = AllData(AllData(:,4) == 0, 1:3);
%TorqueMatrix = AllData(AllData(:,7) == 0, [1 5 6]);
%PowerMatrix = AllData(AllData(:,10) == 0, [1 8 9]);

InnerSet = {'Speed' 'Torque' 'Power'};
OuterSet = {'Slope' 'Intercept' 'SEE' 'R2' 'NumPoints'};

set(Range(Excel,'F66'),'Value',RegressionData.TimeLag);
set(Range(Excel,'R66'),'Value',RegressionData.MaxCycleSpeed);
set(Range(Excel,'R67'),'Value',RegressionData.MaxMappedTorque);
set(Range(Excel,'AB66'),'Value',RegressionData.IdleSpeed);
set(Range(Excel,'AB67'),'Value',RegressionData.MaxMappedPower);
pair = {'J' 'V' 'F' 'R' 'V'
        71   71  77  77  77};

for i = 1:5
    for j = 1:3
        set(Range(Excel,sprintf('%s',[pair{1,i} num2str(pair{2,i}+j-1)])),'Value',RegressionData.(InnerSet{j}).(OuterSet{i}));
    end
end

Sheet = get(Excel.Sheets,'Item','Regression Data');
Activate(Sheet);

% Populate the All Data section with every data point
range = strcat('A3:',dec2let(size(AllData,2)),num2str(size(AllData,1)+2)); % Add 2 since the data begins in row 3
MyRange = Range(Excel,sprintf('%s',range));
set(MyRange,'Value',AllData);

% Populate the Non Omitted Points section with only non-omitted points for
% Speed, Torque, and Power

% Speed
range = strcat('L3:','N',num2str(size(SpeedMatrix,1)+2)); % Add 2 since the data begins in row 3
MyRange = Range(Excel,sprintf('%s',range));
set(MyRange,'Value',SpeedMatrix);

% Torque
range = strcat('O3:','Q',num2str(size(TorqueMatrix,1)+2)); % Add 2 since the data begins in row 3
MyRange = Range(Excel,sprintf('%s',range));
set(MyRange,'Value',TorqueMatrix);

% Power
range = strcat('R3:','T',num2str(size(PowerMatrix,1)+2)); % Add 2 since the data begins in row 3
MyRange = Range(Excel,sprintf('%s',range));
set(MyRange,'Value',PowerMatrix);

Sheet = get(Excel.Sheets,'Item','Report');
Activate(Sheet);

% Chart Sequence:
% 1: Actual Speed and Reference Speed vs. Time
% 2: Actual Speed vs. Reference Speed
% 3: Actual Torque and Reference Torque vs. Time
% 4: Actual Power and Reference Power vs. Time
% 5: Actual Torque vs. Reference Torque
% 6: Actual Power vs. Reference Power

% Grab the minimum and maximum value for each quantity
Limits = [1, 1, min(SpeedMatrix(:,1)), max(SpeedMatrix(:,1)); % RegressionChart_1: Time axis (x)
          1, 2, min([SpeedMatrix(:,2); SpeedMatrix(:,3)]), max([SpeedMatrix(:,2); SpeedMatrix(:,3)]); % RegressionChart_1: Speed axis (actual and reference) (y)
          2, 1, min(SpeedMatrix(:,2)), max(SpeedMatrix(:,2)); % RegressionChart2: Reference Speed axis (x)
          2, 2, min(SpeedMatrix(:,3)), max(SpeedMatrix(:,3)); % RegressionChart2: Actual Speed (y)
          3, 1, min(TorqueMatrix(:,1)), max(TorqueMatrix(:,1)); % RegressionChart_3: Time axis (x)
          3, 2, min([TorqueMatrix(:,2); TorqueMatrix(:,3)]), max([TorqueMatrix(:,2); TorqueMatrix(:,3)]); % RegressionChart_3: Torque axis (actual and reference) (y)
          4, 1, min(TorqueMatrix(:,2)), max(TorqueMatrix(:,2)); % RegressionChart_4: Reference Torque (x)
          4, 2, min(TorqueMatrix(:,3)), max(TorqueMatrix(:,3)); % RegressionChart_4: Actual Torque (y)
          5, 1, min(PowerMatrix(:,1)), max(PowerMatrix(:,1)); % RegressionChart_5: Time axis (x)
          5, 2, min([PowerMatrix(:,2); PowerMatrix(:,3)]), max([PowerMatrix(:,2); PowerMatrix(:,3)]); % RegressionChart_5: Power axis (actual and reference) (y)
          6, 1, min(PowerMatrix(:,2)), max(PowerMatrix(:,2)); % RegressionChart_6: Reference Power axis (x)
          6, 2, min(PowerMatrix(:,3)), max(PowerMatrix(:,3))]; % RegressionChart_6: Actual Power axis (y)

% Adjust both axes to remove internal values and adjust the maximum and
% minimum scale values to account for the actual maximum and minimum
% values (Exel doesn't appear to always do this).
for k = 1:size(Limits,1)
    % Chart = Sheet.ChartObjects(Limits(k,1)).Chart;
    Chart = Sheet.ChartObjects(['RegressionChart_' num2str(Limits(k,1))]).Chart;
    dataMin = floor(min(Limits(k,3), get(Chart.Axes(Limits(k,2)),'MinimumScale')));
    dataMax = ceil(max(Limits(k,4), get(Chart.Axes(Limits(k,2)),'MaximumScale')));
    % Let's not rely on Excel at all (as above) and simply set the limits manually
    % dataMin = floor(Limits(k,3));
    % dataMax = ceil(Limits(k,4));
    set(Chart.Axes(Limits(k,2)),'MinimumScale',dataMin);
    set(Chart.Axes(Limits(k,2)),'MaximumScale',dataMax);
    set(Chart.Axes(Limits(k,2)),'MajorUnit',dataMax - dataMin);
end

% Rescale the plot area
for k = 1:6
    Chart = Sheet.ChartObjects(['RegressionChart_' num2str(k)]).Chart;
    set(Chart.PlotArea,'Top',0);
    set(Chart.PlotArea,'Left',0);
    set(Chart.PlotArea,'Width',260);
    set(Chart.PlotArea,'Height',140);
end

Sheet.Range('A1').Activate();

function s = dec2let(d)

list = 'A':'Z';
ext ='';
if d>702
    ext = list(floor((d-26)/676)-(floor((d-26)/676)==(d-26)/676));
    d = d-(floor((d-26)/676)-(floor((d-26)/676)==(d-26)/676))*676;
end
if d>26
    s = strcat(ext,list(floor(d/26)-(floor(d/26)==d/26)),list(mod(d,26)+26*(floor(d/26)==d/26)));
else
    s = list(mod(d,26)+26*(floor(d/26)==d/26));
end