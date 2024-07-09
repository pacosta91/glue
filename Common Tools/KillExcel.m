%% KillExcel 
%% Description 
% 
% Terminates every instance of Excel. 
 
%% Usage 
% 
% Status = *KillExcel*() 
 
%% Input Variable(s) 
% 
% None. 
 
%% Output Variable(s) 
% 
% *Status* _(logical)_ - A flag indicating whether or not the script
% executed successfully. 
% 
 
%% Output File(s) 
% 
% None. 
 
%% CFR Requirements 
% 
% None. 
 
%% m-files Required 
% 
% *GetExcelPID.m* 
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

function Status = KillExcel

Status = false;

try
    PID = GetExcelPID;
    
    % Kill all instances
    for i = 1:length(PID)
       command = sprintf('taskkill /f /PID %d', PID(i));
       system(command);
    end
    Status = true;
    
catch ME
    ReportError(ME);
end

end