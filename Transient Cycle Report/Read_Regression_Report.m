function RegressionData = Read_Regression_Report(filename, pathname, ModeNumber)

global TESTNUMBER; %#ok

if nargin == 0
    [filename, pathname] = uigetfile('*.csv');
else
    filename = left(filename, length(filename)-4);
    filename = [filename '_REG_' num2str(ModeNumber) '.csv'];
end

fileName = fullfile(pathname, filename);

% Verify that the file exists and throw an exception if it doesn't
if ~exist(fileName,'file')                   
    ME = MException('MATLAB:FileNotFound', 'Unable to find %s regression file', filename);
    throw(ME); 
end

temp = mImport(fileName, 1, 11);

RegressionData.IdleSpeed       = temp{2,2};
RegressionData.IdleTorque      = temp{3,2};
RegressionData.MaxMappedTorque = temp{4,2};
RegressionData.MaxMappedPower  = temp{5,2};
RegressionData.CycleLength     = temp{6,2};

RegressionData.TimeLag         = temp{15,2};

for j = 2:4
    switch j
        case 2, Results = 'Speed';
        case 3, Results = 'Torque';
        case 4, Results = 'Power';
    end
    RegressionData.(Results).Slope     = temp{17,j};
    RegressionData.(Results).Intercept = temp{18,j};
    RegressionData.(Results).SEE       = temp{19,j};
    RegressionData.(Results).R2        = temp{20,j};
    RegressionData.(Results).NumPoints = temp{21,j};
    if RegressionData.(Results).NumPoints > RegressionData.CycleLength, RegressionData.(Results).NumPoints = RegressionData.CycleLength; end
end

% Populate the RegressionData structure with the raw data. Note that the
% cells in the RegressionData.OmitSpeed, RegressionData.OmitTorque and
% RegressionData.OmitPower columns can be empty or contain alphanumeric
% characters ('y1','y2','y3','y4'). I'll be conservative and toss out
% anything but numerical data in each cell and replace all blank cells with
% zeros.

RegressionData.Time            = [ temp{24:end,1}  ]';

RegressionData.ReferenceSpeed  = [ temp{24:end,2}  ]';
RegressionData.ActualSpeed     = [ temp{24:end,3}  ]';
tempOmitSpeed = regexprep(temp(24:end,4), '[^0-9]', '');
tempOmitSpeed(cellfun(@isempty,tempOmitSpeed)) = {'0'};
RegressionData.OmitSpeed = str2num(cell2mat(tempOmitSpeed));

RegressionData.ReferenceTorque = [ temp{24:end,5}  ]';
RegressionData.ActualTorque    = [ temp{24:end,6}  ]';
tempOmitTorque = regexprep(temp(24:end,8), '[^0-9]', '');
tempOmitTorque(cellfun(@isempty,tempOmitTorque)) = {'0'};
RegressionData.OmitTorque = str2num(cell2mat(tempOmitTorque));

RegressionData.ReferencePower  = [ temp{24:end,9}  ]';
RegressionData.ActualPower     = [ temp{24:end,10} ]';
tempOmitPower = regexprep(temp(24:end,11), '[^0-9]', '');
tempOmitPower(cellfun(@isempty,tempOmitPower)) = {'0'};
RegressionData.OmitPower = str2num(cell2mat(tempOmitPower));

RegressionData.Throttle        = [ temp{24:end,7} ]';

RegressionData.MaxCycleSpeed   = max(RegressionData.ReferenceSpeed);
