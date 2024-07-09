%% GetExcelPID 
%% Description 
% 
% Grabs all active Excel instances and returns the PID associated with each
% instance.
 
%% Usage 
% 
% PID = *GetExcelPID* 
 
%% Input Variable(s) 
% 
% None. 
 
%% Output Variable(s) 
% 
% *PID* _(double array)_ - An array consisting of the PID for each Excel
% instance.
% 
 
%% Output File(s) 
% 
% None. 
 
%% CFR Requirements 
% 
% None. 
 
%% m-files Required 
% 
% *ReportError.m* 
% 
 
%% MAT-files Required 
% 
% None. 
 
%% Other files Required 
% 
% None. 
 
%% Notes 
% 
% None. 
 
%% Revision History 
% 
% *Author* - Eric Simon 
% 
% *File Version* - 1 
% 
% *Date* - 23-Sep-2019 
% 
 
%% Software Version Information 
% 
% *MATLAB Version* - 9.2.0.959691 (R2017a) Update 3 
% 
% *Operating System* - Microsoft Windows 7 Enterprise  Version 6.1 (Build 7601: Service Pack 1) 
% 
% *Java Version* - Java 1.7.0_60-b19 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode 
% 
 
%% Code 

function PID = GetExcelPID

PID = []; % Process Identifier

try
    
    [~, tasks] = system('tasklist/fi "imagename eq Excel.exe"');
    tasks = sscanf(upper(tasks),'%s'); % concatenate into a single string of upper-case characters, removing spaces
    startidx = strfind(tasks,'EXCEL.EXE') + 9; % find the position of EXCEL.EXE
    endidx = strfind(tasks,'CONSOLE') - 1;
    
    % Verify nothing went wrong in the search process
    if isequal(size(startidx), size(endidx))
        for i = 1:size(startidx,2) % could have used either index
            PID(i) = str2double(tasks(startidx(i):endidx(i)));
        end        
    end
    
    % To kill all the active PIDs you can include this code in the calling
    % function
    % for i = 1:length(PID)
    %    command = ['taskkill /f /PID ', num2str(PID(i))];
    %    system(command);
    % end
    
catch ME
    ReportError(ME);
end

end