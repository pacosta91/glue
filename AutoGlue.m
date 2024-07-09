function AutoGlue(timeInterval, maxIterations, fileSizeLimit, killExcel)
% Checks to see if there are files to be processed by SuperGlue and processes them at a fixed interval
%
% Syntax:
%   AutoGlue OR
%   AutoGlue(timeInterval, maxIterations, fileSizeLimit, killExcel)
%
% Inputs:
%   timeInterval - time in seconds between database reads
%   maxIterations - the number timer iterations
%   filesizeLimit - the maximum filesize (in MB) AutoGlue will process
%   killExcel - true/false flag indicating whether any currently running
%               instance of Excel should be terminated
%
% Outputs:
%   None; runs SuperGlue (see SuperGlue for outputs)
%
% CFR Requirement(s) Implemented:
%   None
%
% Example:
%   None
%
% Other m-files required:
%   None; requires SuperGlue input files
%
% Subfunctions:
%   None
%
% MAT-files required:
%   None
%

% Author:           Eric Simon
% File Version:     1.0
% Revision History:
% 1.0   09/29/2014  Edited original file created by Jared

% =========================================================================

% Debugging code to record CPU and memory usage. You must use a fixed
% number of iterations!
% startRecordPerformance;

% Specify default settings
if ~exist('timeInterval', 'var'), timeInterval = 180; end
if ~exist('maxIterations', 'var'), maxIterations = Inf; end
if ~exist('fileSizeLimit', 'var'), filesizeLimit = Inf; end
if ~exist('killExcel', 'var'), killExcel = true; end

% Initialize the counter
iterations = 1;

% Make sure the log file directory exists and if not create it
if ~exist('C:\MATLAB\LogFiles', 'dir')
    % Right now, I'm not doing anything with the status and simply assuming the
    % directory gets created.
    status = mkdir('C:\MATLAB\LogFiles');
end

% Create a diary to record screen output
diaryName = ['C:\MATLAB\LogFiles\AutoGlue_Logfile_' date '.txt'];
diary(diaryName);

while iterations <= maxIterations

    iterations = iterations + 1;
    diary on

    % Initialize the test_number, data_path and cert_test arrays. Create
    % the cell arrays to store the test numbers and data paths from the
    % database. We'll never read more than 20 records at a time so we can
    % preallocate the space.
    test_number = cell(80,1);
    data_path = cell(80,1);
    initialrun = zeros(80,1);
    finalrun = zeros(80,1);
    include_particulate = cell(80,1);
    cert_test = zeros(80,1);

    try
        % Define the SQL select statement
        SelectSQL = ['SELECT DISTINCT TOP(80) LTRIM(RTRIM(a.Test_Number)) AS Test_Number, a.Data_Path, ISNULL(a.InitialRun, 0) AS InitialRun, ' ...
            'ISNULL(b.Include_Particulate, ''No'') AS Include_Particulate, ' ...
            'ISNULL(b.Cert_Test, 0) AS Cert_Test FROM tblTestLog AS a LEFT OUTER JOIN tblTestResults AS b ' ...
            'ON a.Test_Number = b.Test_Number ORDER BY Test_Number ASC'];

        % Create a connection to the ETRE database
        NET.addAssembly('System.Data'); %this imports the library into MATLAB
        connString = 'DSN=ETRE';
        odbcCN = System.Data.Odbc.OdbcConnection(connString);
        odbcCN.Open(); % connects to the SQL Server (must have DSN)

        % Fetch completed tests and store the results in the test_number
        % and data_path arrays
        odbcCOM = System.Data.Odbc.OdbcCommand(SelectSQL, odbcCN);
        res = odbcCOM.ExecuteReader;
        idx = 0;

        while (res.Read())
            try
                idx = idx + 1;
                test_number{idx} = strtrim(char(res.GetValue(0)));
                data_path{idx} = strtrim(char(res.GetValue(1)));
                initialrun(idx) = strtrim(char(res.GetValue(2)));
                include_particulate{idx} = strtrim(char(res.GetValue(3)));
                cert_test(idx) = res.GetValue(4);
            catch ME
                error(ME.message);
            end
        end % while

        % Close the reader and terminate the connection
         res.Close();
         if strcmp(char(odbcCN.State()),'Open'), odbcCN.Close(); end

    catch ME
        % There was an error trying to communicate with the database
        msg = sprintf('An error was detected as AutoGlue attempted to establish communication with the database. The error is as follows:\n\n');

        % Display the message on-screen
        error([msg ME.message]);

    end % try

    % Remove empty elements from each cell array.
    test_number = test_number(~cellfun('isempty',test_number));
    data_path = data_path(~cellfun('isempty',data_path));
    include_particulate = include_particulate(~cellfun('isempty',include_particulate));
       
    % Replace the previous USFS150 base path to Engine test results with
    % the new one. This should not be necessary and is only a precaution.
    data_path = strrep(data_path, 'D:\Testing\Engine\', 'D:\Testing\Engine\Customers\');

    % Get the number of records to process. Remember that we already
    % checked to make sure length(test_number) = length(data_path) so we
    % can use either one.
    N = length(test_number);

    if N == 0 

        disp([datestr(now) ' - No tests ready to be processed!']);
        
    else

        % The test records were successfully loaded into the test_number
        % and data_path arrays. We'll trim the initialrun and finalrun
        % array then we'll loop through the results and process each test.
        initialrun = initialrun(1:N);
        finalrun = finalrun(1:N);

        % Grab the PM data in VTRE to see which tests can be run a final time
        include_particulate_test_number = test_number(strcmp(include_particulate,'Yes'));
        PM_test_number = [];

        if ~isempty(include_particulate_test_number)
            SelectSQL = ['SELECT Test_Number FROM tbl_PM_Filter WHERE AvgGrossWeight IS NOT NULL ' ...
                'AND Test_Number IN (' strjoin(include_particulate_test_number,',') ')'];
            try
                % Create a connection to the VTRE database
                NET.addAssembly('System.Data'); %this imports the library into MATLAB
                connString = 'DSN=VTREUPDATE';
                odbcCN = System.Data.Odbc.OdbcConnection(connString);
                odbcCN.Open(); % connects to the SQL Server (must have DSN)
                odbcCN.ChangeDatabase('VTREDATA'); % This shouldn't be neccessary

                % Fetch completed tests and store the results in the test_number
                % and data_path arrays
                odbcCOM = System.Data.Odbc.OdbcCommand(SelectSQL, odbcCN);
                res = odbcCOM.ExecuteReader;

                idx = 0;
                while (res.Read())
                    try
                        idx = idx + 1;
                        PM_test_number(idx) = res.GetValue(0);
                    catch ME
                        error(ME.message);
                    end
                end % while

                % Close the reader and terminate the connection
                res.Close();
                if strcmp(char(odbcCN.State()),'Open'), odbcCN.Close(); end

            catch ME
            % There was an error trying to communicate with the database
            msg = sprintf('An error was detected as AutoGlue attempted to establish communication with the database. The error is as follows:\n\n');

            % Display the message on-screen
            disp([msg ME.message]);

            end % try

        end % ~isempty(include_particulate_test_number)

        % Loop through the results arrays
        for i = 1:N
            % Check settings file to see if AutoGlue should even be run. Note:
            % Since the settings files is also opened by SuperGlue this seems a
            % bit redundant. The code should be rewritten to allow for more
            % seamless integration.
            
            try

                % Grab the filename parts
                [~, filename, ext] = fileparts(data_path{i});
                Test = stringread(filename, '_');
                TestCell = Test{3};

                runAutoGlue = getAutoGlueOptions(['Options Panel ', TestCell, '.txt']);

                if runAutoGlue

                    % Make sure all instances of the Excel application server are
                    % terminated by first grabbing the tasklist (taskmanager) and verifying
                    % that an instance of Excel is running.
                    [status, tasks] = system('tasklist');
                    if killExcel && ~status && ~isempty(strfind(tasks, 'EXCEL.EXE')), system('taskkill /F /IM EXCEL.EXE'); end

                    try
                        % Make sure the file exists and isn't too big
                        if exist(data_path{i}, 'file')

                            % Check file size
                            fileAttributes = dir(data_path{i});
                            if (fileAttributes.bytes / 2^20 > fileSizeLimit)
                                finalrun(i) = 1; % Delete the test from the que
                                ME = MException('MATLAB:FilesizeLimitExceeded', 'The file %s exceeded the %i MB maximum allowed', filename, fileSizeLimit);
                                throw(ME);
                            end

                            if initialrun(i) == 0 && strcmp(include_particulate(i),'Yes') % Attempt to run super glue for all "new" files with PM

                                % Check to see if PM data is available
                                currenttest = str2num(test_number{i});
                                if find(PM_test_number == currenttest)
                                    % Run super glue for files with PM data available. The only real reason why
                                    % this has been placed in an if-statement is because we want to delete these
                                    % tests from the que. Also, PM is required for the Transient Cycle Report.
                                    disp([datestr(now) ' - ' test_number{i} ': begin SuperGlue processing...']);
                                    SuperGlue(data_path{i}, 0, 1, 1, cert_test(i));
                                    disp([datestr(now) ' - ' test_number{i} ': end SuperGlue processing...']);
                                    initialrun(i) = 1; finalrun(i) = 1;
                                else
                                    disp([datestr(now) ' - ' test_number{i} ': begin SuperGlue processing...']);
                                    SuperGlue(data_path{i}, 0, 1, 1, 0);
                                    disp([datestr(now) ' - ' test_number{i} ': end SuperGlue processing...']);
                                    initialrun(i) = 1;
                                end

                                munlock SuperGlue
                                clear SuperGlue

                            elseif initialrun(i) == 0

                                disp([datestr(now) ' - ' test_number{i} ': begin SuperGlue processing...']);
                                SuperGlue(data_path{i}, 0, 1, 1, 0);
                                disp([datestr(now) ' - ' test_number{i} ': end SuperGlue processing...']);
                                initialrun(i) = 1;
                                munlock SuperGlue
                                clear SuperGlue

                            end

                            % Attempt to re-run Super Glue for tests with PM
                            if initialrun(i) == 1 && strcmp(include_particulate(i),'Yes')

                                % Check to see if PM data is available
                                currenttest = str2num(test_number{i});
                                if find(PM_test_number == currenttest)
                                    % Run super glue for files with PM data available
                                    disp([datestr(now) ' - ' test_number{i} ': begin SuperGlue processing...']);
                                    SuperGlue(data_path{i}, 0, 1, 1, cert_test(i));
                                    disp([datestr(now) ' - ' test_number{i} ': end SuperGlue processing...']);
                                    finalrun(i) = 1;
                                    munlock SuperGlue
                                    clear SuperGlue
                                end

                            end % initialrun(i) == 1 && strcmp(include_particulate(i),'Yes')

                        else
                            disp([datestr(now) ' - ' test_number{i} ': File Not Found ...']);
                            disp(data_path{i});

                        end

                    catch ME

                            msg = sprintf('An error was detected when AutoGlue attempted to execute SuperGlue for test %s using file %s. The error is as follows:\n', test_number{i}, data_path{i});

                            % Display an error message to screen.
                            disp([datestr(now) ' - ' test_number{i} ': ERROR: File Not Processed: ' data_path{i}]);
                            disp([msg ME.message]);

                    end % try

                 end % if runAutoGlue

            catch ME
                try
                    msg = sprintf('An error was detected when AutoGlue attempted to execute SuperGlue for test %s using file %s. The error is as follows:\n', test_number{i}, data_path{i});
                    disp([datestr(now) ' - ' test_number{i} ': ERROR: File Not Processed: ' data_path{i}]);
                    disp([msg ME.message]);
                catch
                    msg = sprintf('An error occurred on iteration %d.', i);
                    disp(msg);
                    disp(data_path)
                end

            end % try
            
            % General housekeeping. Try to restore memory by clearing all
            % variables except those required by AutoGlue.
            if ~exist('SuperGlue', 'var')
                munlock SuperGlue
                clear SuperGlue
            end

            % Move back to the MATLAB directory
            cd C:\MATLAB

            % Kill Excel instances again
            [status, tasks] = system('tasklist');
            if killExcel && ~status && ~isempty(strfind(tasks, 'EXCEL.EXE')), system('taskkill /F /IM EXCEL.EXE'); end

            % Close all other files that might be open
            if ~isempty(fopen('all')), fclose('all'); end

        end % for i = 1:N

        % Create the list of tests to be deleted from that database. Note
        % that only those tests that point to files that actually exist are
        % deleted and that we only attempt to delete these records AFTER we
        % attempted to run SuperGlue for the current record cache. Thus, if
        % AutoGlue hung up during the above loop, the following code deleting
        % these records would not have been executed.
        delete_list = cell(size(test_number));
        for i = 1:N
            %if exist(data_path{i}, 'file')
                if initialrun(i) == 1 && strcmp(include_particulate(i),'No')
                    delete_list{i} = test_number{i};
                elseif finalrun(i) == 1
                    delete_list{i} = test_number{i};
                else
                    delete_list{i} = [];
                end
            %end
        end
        delete_list = delete_list(~cellfun('isempty',delete_list));
        update_list = setdiff(test_number(find(initialrun==1)), delete_list);

        try

             if ~isempty(delete_list) || ~isempty(update_list)

                % Create a connection to the database
                NET.addAssembly('System.Data'); %this imports the library into MATLAB
                connString = 'DSN=ETRE';
                % connString = 'DSN=ETREDEBUG;UID=ES;PWD=ES'; % DEBUG
                odbcCN = System.Data.Odbc.OdbcConnection(connString);
                odbcCN.Open(); % connects to the SQL Server (must have DSN)

                if ~isempty(delete_list)
                    DeleteSQL = ['DELETE FROM tblTestLog WHERE Test_Number IN (' strjoin(delete_list) ')'];
                    odbcCOM = System.Data.Odbc.OdbcCommand(DeleteSQL, odbcCN);
                    odbcCOM.ExecuteNonQuery;
                end

                if ~isempty(update_list)
                    UpdateSQL = ['UPDATE tblTestLog SET InitialRun = 1 WHERE Test_Number IN (' strjoin(update_list) ')'];
                    odbcCOM = System.Data.Odbc.OdbcCommand(UpdateSQL, odbcCN);
                    odbcCOM.ExecuteNonQuery;
                end

                % Terminate the connection
                if strcmp(char(odbcCN.State()),'Open'), odbcCN.Close(); end

             end % if ~isempty(delete_list) || ~isempty(update_list)

        catch ME
            % There was an error trying to communicate with the database
            msg = sprintf('An error was detected as AutoGlue attempted to establish communication with the database. The error is as follows:\n\n');

            % Display the message on-screen
            error([msg ME.message]);

        end % try

    end % isempty(test_number)

    diary off
    
    % Update the auto glue state file. This file can be read by other
    % applications to verify that autoglue is running.
    try
        fid = fopen('D:\Testing\Post Processing Logs\AutoGlue Status\AutoGlueStateFile.txt', 'wt');
        fprintf(fid, char(datetime));
        fclose(fid);        
    catch
    end

    pause(timeInterval);

end % iterations <= timerCalls

% Debugging code to display CPU and memory usage
% stopRecordAndDisplay;