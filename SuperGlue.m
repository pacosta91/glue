function SuperGlue(WholeFile, QuitAtClose, automationMode, runQA, runTransient)
% Processes raw data and exports it into Excel files for later processing
%
% Syntax:
%   SuperGlue(WholeFile, QuitAtClose, automationMode)
%
% Inputs:
%   WholeFile - (str) The path and filename of the *.csv file to be processed
%   QuitAtClose - (int) 1 = quit MATLAB when done processing.
%   automationMode - (int) 1 = designed for use with AutoGlue. Ignores all
%   calls for interactions with user.
%   runQA - (int) 1 = attempt to run the QA report
%   runTransient - (int) 1 = attempt to run the Transient Cycle Report

%
% Outputs:
%   Produces the _Steaming.xlsx, _Composite.xlsx, and (optionally) the .mat file.
%
% Example:
%   SuperGlue(WholeFile, QuitAtClose, automationMode, runQA, runTransient)
%
% Other m-files required:
%   TBD (many)
%
% Subfunctions:
%   TBD (many)

%
% MAT-files required:
%   optional
%

% Author:           Eric Simon
% File Version:     5.0
% Revision History:
% 1.0               Original file created by Jared Stewart.
% 4.0   01/15/2015  Mostly documentation.
% 5.0   09/01/2015  Added the ability to specify QA and Transient cycle
%                   report execution

% =========================================================================

% Move to MATLAB start folder
% cd E:\ROAMING4\Glue
cd 'D:\Testing\Engine\Cell Mgt\Glue\ROAMING4\Glue'

% Clear out current path
% restoredefaultpath

% Add appropriate subdirectories
addpath(genpath(pwd))

% Verify that the proper files are being used
% verifyToolFilePath('SuperGlue.m','SuperGlue_dependencies.mat',1);

% Set default values for optional inputs
if nargin < 3, automationMode = 0; end
if nargin < 4, runQA = 0; end % Make the default to not run QA
if nargin < 5, runTransient = 0; end

% Get username
userlist = {'P. Acosta','N. Bellovary','J. Forster'}; % add to this list
selMade = 0;

while selMade == 0
    [selIdx,selMade] = listdlg('PromptString','Test Engineer','SelectionMode','single','ListString',userlist);
end

% If you don't want to be interupted by constant popups comment out lines
% 64 to 66 and uncomment the two lines below. Change the selIdx to select
% the correct user.
% selIdx = 2;
% selMade = 1;

% Global Variable Declarations
global LM SPECIES BENCHES LOCALPATH FILENAME TESTNUMBER GLUEVERSION ENGINENUMBER TESTENGINEER;

% DO NOT Change the sequence of these variables, it will ruin everything!
SPECIES = {'HC' 'CO_l' 'CO_h' 'NOx' 'CO2' 'CH4' 'HHC' 'NMHC' 'CO2_Tr' 'CO2_egr' 'O2' 'N2O' 'HC-NDIR' 'HNOx'};
BENCHES = {'Bag_Dilute' 'Engine' 'Tailpipe'};
[LOCALPATH, ~, ~] = fileparts(which('SuperGlue.m'));

% Version Information
GLUEVERSION = 'Glue v.4.7';
IssueDate = 'May 1, 2023';

% Assign test engineer
TESTENGINEER = userlist{selIdx};

% SET LOG MANAGER SETTINGS
% These are hard-coded here and don't change. DebugLevel 0 = no log
% is produced, 1 = only errors and warnings are reported, and 2 = standard
% output, includes errors and warnings. CommandWindowLevel is used in
% conjunction with the DebugLevel. See LogManager.m for details.
DebugLevel = 2;
CommandWindowLevel = 1;

if nargin == 0
    if exist('D:\Testing\Engine\Customers\','dir')
      cd('D:\Testing\Engine\Customers\');
    end

    % Get file(s)
    [filename, pathname] = uigetfile('*.csv','MultiSelect','on');
    if ~iscell(filename)
        if filename == 0, return; end
        filename = cellstr(filename);
    end
    QuitAtClose = 0;
else
    [pathname, filename, fext] = fileparts(WholeFile);
    pathname = [pathname '\'];
    filename = cellstr([filename fext]);
end

% Create an instance of the LogManager. Note that if multiple files are
% loaded the name of the logfile reflects only 1 of those files but all
% files are detailed inside the file.
LM = LogManager(DebugLevel, CommandWindowLevel, GLUEVERSION, IssueDate, filename);
for k = 1:length(filename)
    try
        FILENAME = filename{k};
        LM.DebugPrint(1,'%s',[pathname filename{k}]);

        % Grab the filename
        Test = stringread(filename{k}, '_');

        % Parse the filename to grab the engine number, test cell, and
        % test number
        ENGINENUMBER = Test{2};
        if isnumeric(ENGINENUMBER), ENGINENUMBER = num2str(ENGINENUMBER); end
        TestCell = Test{3};
        TESTNUMBER = Test{4};

        % ES - Define the datastream. Note that the datastream may contain
        % fewer channels than columns in the *.csv file. This is due to the
        % fact that the analyzer channels will contains two streams of data
        % representing mass (g) and concentration (ppm or %).
        [datastream, status] = SetUpTestC(filename{k}, pathname);
        if ~status
            LM.DebugPrint(1,'The test file, %s, was empty!',filename{k});
            return            
        end        
        
        ModeSegregation = Mode(datastream('Mode').StreamingData, datastream('Cycle').StreamingData, datastream('Phase').StreamingData);
        datastream = ImportOptions3(['Options Panel ', TestCell, '.txt'],datastream);
        datastream = ImportOptionsDB(TESTNUMBER, datastream, ModeSegregation, automationMode);
        % ES - Here we overwrite options depending on how we run SuperGlue.
        if nargin > 0
            options = datastream('Options');
            options.Change_File_Location = 'SilenceNo';
            options.Produce_MAT_File = 'SilenceYes';
            options.Delete_Modes = 'SilenceNo';
            datastream('Options') = options;
        end
        ModeSegregation.TrimToCycleLength(datastream);
        ModeSegregation = Mode(datastream('Mode').StreamingData, datastream('Cycle').StreamingData, datastream('Phase').StreamingData);
        datastream = CheckFor1065RequiredData(datastream);
        if datastream('Options').Part_1065.IsOn
            datastream.CorrectVZS(ModeSegregation);
        end
        datastream = AddCorrectedChannels(datastream, ModeSegregation);
        if datastream('Options').Part_1065.IsOn
            if datastream('Options').Part_1065.DriftCorrection
                if datastream('Options').Bag_Dilute_Bench
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Bag_Dilute', 'Part1065');
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Bag_Dilute', '');
                end
                if datastream('Options').Engine_Bench
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Engine', 'Part86');
                end
                if datastream('Options').Tailpipe_Bench
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Tailpipe', 'Part86');
                end
            else
                if datastream('Options').Bag_Dilute_Bench
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Bag_Dilute', 'Part86');
                end
                if datastream('Options').Engine_Bench
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Engine', 'Part86');
                end
                if datastream('Options').Tailpipe_Bench
                    datastream = Part1065ChemicalBalance(datastream, ModeSegregation, 'Tailpipe', 'Part86');
                end
            end
        end
        datastream.PerformComposite(ModeSegregation);
        INCA_File = Get_INCA_Names_File( str2double( ETC_TimeStamp( datastream('Options').Test_Start, 1 ) ) );
        if ~strcmp(INCA_File,'')
            INCA_Map = Load_INCA_Names(INCA_File);
            Swap_INCA_Names(datastream, INCA_Map);
        end
        datastream.CalculateInstantaneousBSFC();
        [C_Array, HT, ER, BSFCR, PMR, AR, ~, DR, compositeFileName, streamingFileName] = datastream.MakeReports(ModeSegregation, pathname);
        datastream.MakeNANChannels();
        if strcmp(datastream('Options').Produce_MAT_File,'SilenceNo')
            fileexists = 0;
        elseif strcmp(datastream('Options').Produce_MAT_File,'SilenceYes')
            fileexists = 1;
        else
            fileexists = input('Would you like to save a .mat file for this test? Enter 1 for yes; 0 for no:\n');
        end

        if fileexists ==  1; save([pathname left(FILENAME, length(FILENAME)-4) '.mat']); end

        % Run the QA software if specified
        if runQA % && ~datastream('Options').Engine_Modal_Amb_Bag_Test
            try
                LM.DebugPrint(1,'Attempting to run the QA Report for Test %i ...',TESTNUMBER);
                QA(compositeFileName, streamingFileName, [], [], [], ~datastream('Options').Engine_Modal_Amb_Bag_Test); % Create a copy in the test directory
                % QA(compositeFileName, streamingFileName, '', '', '\\autoglue\QA\reports\')
            catch mException
                LM.DebugPrint(1,'ALARM: The QA Report software terminated prematurely for Test %i because of the following reason;',TESTNUMBER);
                LM.DebugPrint(1,'%s\n',mException.message);
                for m = 1:length(mException.stack)
                    LM.DebugPrint(1,'   file: %s\n   name: %s\n   line: %i\n',mException.stack(m).file, mException.stack(m).name, mException.stack(m).line);
                end
            end
        end

        % Run the Transient Cycle Report software if specified
        if runTransient
            try
                % transientinputs.maxRawExhaust = 'db';
                transientinputs.matfile = [pathname left(FILENAME, length(FILENAME)-4) '.mat'];
                LM.DebugPrint(1,'Attempting to run the Transient Cycle Report for Test %i ...',TESTNUMBER);
                Write_Transient_Cycle_Report(transientinputs);
            catch mException
                LM.DebugPrint(1,'ALARM: The Transient Cycle Report software terminated prematurely for Test %i because of the following reason;',TESTNUMBER);
                LM.DebugPrint(1,'%s\n',mException.message);
                for m = 1:length(mException.stack)
                    LM.DebugPrint(1,'   file: %s\n   name: %s\n   line: %i\n',mException.stack(m).file, mException.stack(m).name, mException.stack(m).line);
                end
            end
        end

    catch mException
        LM.DebugPrint(1,'ALARM: SuperGlue terminated prematurely for Test %i because of the following reason;',TESTNUMBER);
        LM.DebugPrint(1,'%s\n',mException.message);
        for m = 1:length(mException.stack)
            LM.DebugPrint(1,'   file: %s\n   name: %s\n   line: %i\n',mException.stack(m).file, mException.stack(m).name, mException.stack(m).line);
        end

        % Allow the error to bubble up to AutoGlue when running in
        % automation mode
        if automationMode ~= 0, throw(mException); end

    end
end

clear global;

if QuitAtClose %Intended for automation, do not engage unless you want MATLAB to exit when you are done processing files
    quit;
end