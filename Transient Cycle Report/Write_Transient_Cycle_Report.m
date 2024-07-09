function Write_Transient_Cycle_Report(inputs)
% Creates a Cycle Report
%
% Syntax:
%   Write_Transient_Cycle_Report
%
% Inputs:
%   inputs -   (obj) An object containing includeCriteria, maxRawExhaust,
%               and saveMaxRawExhaust.
%   inputs.includeCriteria -   (boolean) A true/false flag; if true the pdf report
%                               will include the success criteria
%   inputs.maxRawExhaust -     (mixed) A numeric value, 'db', '3s', '5s'
%                               The default is 'max' (i.e., max(Q_ex))
%                               if not specified.
%   inputs.saveMaxRawExhaust - (bool) A true/false flag indicating
%                               whether or not the Maximum Raw Exhaust
%                               flow should be saved in the database.
%   inputs.matfile -           (string) The name of the MAT-files to
%                               be processed. Does not allow multiple
%                               files.
%   inputs.outputdir -          (string) The directory where the output
%                               files should be stored.
%
%   MAT-files required (see below)
%
% Outputs (example):
%   140917_236567_EW5_18645_NRTC_1_Report.xls
%   140917_236567_EW5_18645_NRTC_1_Report.pdf
%   (Note: These files are stored in the same directory as the *.mat file!)
%
% Example:
%   Write_Transient_Cycle_Report
%
% Other m-files required:
%   Write_Transient_Cycle_Analyzer_QA.m
%   Write_Transient_Cycle_General_Data.m
%   Write_Transient_Cycle_Regression_QA.m
%   Write_Transient_Cycle_Report_QA.m
%   Write_Transient_Cycle_Test_Results.m
%   ../Common Tools/left.m
%
% Subfunctions:
%   None
%
% MAT-files required (example):
%   140917_236567_EW5_18645_NRTC_1.mat
%
% See also: http://www.mathworks.com/help/matlab/ref/actxserver.html

% Author:           Eric Simon
% File Version:     1.1
% Revision History:
% 1.0               Original file created by Jared Stewart.
% 1.1   09/19/2014  Removed arguments since the function wouldn't do
%                   anything if executed with them included. Added a call
%                   to the (new) setdirs m-file so all paths are contained
%                   in one location and not hardcoded throughout the tool
%                   scripts. Added comments for clarity. Added standard
%                   header.

% =========================================================================

% Set the options parameters if not supplied; outputdir is dealt with in
% another section of the code (see below)
if ~exist('inputs', 'var') || ~isfield(inputs, 'includeCriteria'), inputs.includeCriteria = false; end
if ~exist('inputs', 'var') || ~isfield(inputs, 'maxRawExhaust'), inputs.maxRawExhaust = 'max'; end
if ~exist('inputs', 'var') || ~isfield(inputs, 'saveMaxRawExhaust'), inputs.saveMaxRawExhaust = false; end
if ~exist('inputs', 'var') || ~isfield(inputs, 'matfile'), inputs.matfile = ''; end

% Set the current directory to return to after processing
currentdir = pwd;

% Move to MATLAB start folder
cd C:\MATLAB

% Clear out current path
restoredefaultpath

% Add appropriate subdirectories
addpath(genpath(pwd))

% Verify that the proper files are being used
% verifyToolFilePath('Write_Transient_Cycle_Report.m','Write_Transient_Cycle_Report_dependencies.mat',1);

% Grab the tool location
[InstallPath, ~, ~] = fileparts(which('Write_Transient_Cycle_Report.m'));

% Include the location of the input directory. This is used to save
% the user time traversing the file directory by starting in the engine
% testing area when locating the *.mat file.
setdirs;

% Define and intialize the TESTNUMBER; note that this variable is in the
% *.mat file that gets loaded so it isn't strictly necessary to initialize
% it to 0.
global TESTNUMBER;
if isempty(TESTNUMBER), TESTNUMBER = 0; end

% Initialize the filename and path
if ~isempty(inputs.matfile) && exist(inputs.matfile,'file')
   [pathname2, filename2, ext] = fileparts(inputs.matfile);
   pathname2 = [pathname2 '\'];
   filename2 = cellstr([filename2 ext]);
else
    filename2 = '';
    pathname2 = '';

    % Set the current directory to return to after processing
    currentdir = pwd;

    % The inputdir is defined in the setdirs.m file
    cd(inputdir);

    [filename2, pathname2] = uigetfile('*.mat','MultiSelect','on');
    if ~iscell(filename2)
        if filename2 == 0, return; end
        filename2 = cellstr(filename2);
    end
end

try
    % Note: During debugging it is possible to change these properties to
    % true to "follow along" in order to see how the
    % Transient_Cycle_Report_Template.xlsx is being updated.
    Excel = actxserver('Excel.Application');
    Excel.Visible = false;         % invisible Excel window
    Excel.ScreenUpdating = false;  % turn off screen update to run faster
    Excel.Interactive = false;     % non-interactive mode, with no keyboard/mouse
    Excel.DisplayAlerts = false;   % no prompts or alert messages
    Excel.UserControl = false;     % object freed when reference count reaches zero
catch ME %#ok<NASGU>
    disp('ActiveX Server to Excel failed to load');
    return
end

% Loop through the chosen *.mat files
for i =1:length(filename2)
    load([pathname2 filename2{i}]);
    for k = 1:ModeSegregation.nModes

        % Open the Transient Cycle Report Template
        Workbook = Excel.Workbooks.Open([InstallPath '/Transient_Cycle_Report_Template.xlsx']);

        % Update the General Data section
        Write_Transient_Cycle_General_Data(Excel, datastream, k);

        % Update the Test Results section
        PM_Data = Write_Transient_Cycle_Test_Results(Excel, datastream, ModeSegregation, k);

        % Note: The Quality Checks section is updated in Excel

        % Update the Analyzer Check section
        Write_Transient_Cycle_Analyzer_QA(Excel, filename2{i}, datastream, ModeSegregation, k);

        % Update the Ambient (Background) Check section
        Write_Transient_Cycle_Background_QA(Excel, filename2{i}, datastream, ModeSegregation, k);

        % Update the Aqueous Condensation Check section
        Write_Transient_Cycle_Aqueous_Condensation_Check(Excel, filename2{i}, datastream, ModeSegregation, k);

        % Update the Regression Check section
        Write_Transient_Cycle_Regression_QA(Excel, filename2{i}, pathname2, k);

        % Update the Fuel/Carbon Balance Check section
        % Update the Altitude Simulation Check section
        % Update the CVS Check section
        % Update the Cold Start Check section
        % Update the Combustion Air Check section
        % Update the Intercooler Check section
        % Update the PM Sampler Check section
        Write_Transient_Cycle_Report_QA(Excel, datastream, ModeSegregation, k, PM_Data, inputs);

        % Name the output file
        if ~exist('inputs', 'var') || ~isfield(inputs, 'outputdir'), inputs.outputdir = pathname2; end
        if right(inputs.outputdir,1) ~= '\', inputs.outputdir = [inputs.outputdir '\']; end
        if ModeSegregation.nModes <= 1
            finalname = [inputs.outputdir left(filename2{i}, length(filename2{i})-4) '_Report'];
        else
            finalname = [inputs.outputdir left(filename2{i}, length(filename2{i})-4) '_Cycle' num2str(k) '_Report'];
        end

        % Set the print area
        if inputs.includeCriteria
            range = 'A1:AG290'; % temporary
        else
            range = 'A1:AG232'; % Don't include Success Criteria
        end
        Excel.ActiveSheet.PageSetup.PrintArea = range;

        % Move the selection to A1
        MyRange = Range(Excel, 'A1');
        MyRange.Select;

        % Try to save the Transient Cycle Report as a *.pdf file in the
        % same directory as the *.mat file
        try
            % Save the Transient Cycle Report as a *.pdf file in the same
            % directory as the *.mat file
            % ExportAsFixedFormat(Excel.ActiveSheet,'xlTypePDF',[finalname '.pdf']);
        catch %#ok
        end

        % Now try to save the Transient Cycle Report as an *.xlsx file
        try
            invoke(Workbook, 'SaveAs', [finalname '.xlsx'])
        catch %#ok
        end

        Workbook.Close;

    end % k-loop
end % i-loop

% Quit Excel and delete the COM object
Excel.Quit;
if iscom(Excel), delete(Excel); end

% Return to the original directory
cd(currentdir);