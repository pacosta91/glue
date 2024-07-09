%% ReportError 
%% Description 
% 
% Provides a common output format for errors and warnings and displays them
% to the screen. 
 
%% Usage 
% 
% *ReportError*(varargin) 
 
%% Input Variable(s) 
% 
% *varargin* _()_ - Either a MATLAB Exception object (in cases involving
% errors) OR an identifier, message string, and type (error or warning).
% For example, ReportError(ME) or ReportError('Title', 'This is the
% message.', 'warning'). Common syntax for the title is 
% [mfilename ':{ErrorType}'], e.g., [mfilename ':FileIO'].
% 
 
%% Output Variable(s) 
% 
% None. 
 
%% Output File(s) 
% 
% None. 
 
%% CFR Requirements 
% 
% None. 
 
%% m-files Required 
% 
% None. 
 
%% MAT-files Required 
% 
% None. 
 
%% Other files Required 
% 
% None. 
 
%% Notes 
% 
% Errors and warning are wrapped inside begin and end statments that
% include a datetimestamp (see below). To convert these timestamps back to
% a human-readable date and time do the following:
% datestr(str2num('737484.3631')) or simply datestr(737484.3631).
%
% begin WARNING_737484.3631
% ID: CreateHeader:NoOutputDirectorySpecified
% MSG: No output directory was specified. The current directory, "D:\Software Team\MATLAB_Working\", will be used.
% STACK: D:\Software Team\MATLAB_Working\SAMPL\CreateHeader.m -> line 78
% end WARNING_737484.3631
 
%% Revision History 
% 
% *Author* - Eric Simon 
% 
% *File Version* - 1 
% 
% *Date* - 28-Feb-2019 
% 
 
%% Software Version Information 
% 
% *MATLAB Version* - 9.2.0.538062 (R2017a) 
% 
% *Operating System* - Microsoft Windows 7 Enterprise  Version 6.1 (Build 7601: Service Pack 1) 
% 
% *Java Version* - Java 1.7.0_60-b19 with Oracle Corporation Java HotSpot(TM) 64-Bit Server VM mixed mode 
% 
 
%% Code 

function ReportError(varargin)

try
    
    % Record the current time
    format long
    timestamp = now;

    % In cases when there is only one argument, it must be the MATLAB
    % exception object.
    if nargin == 1
        ME = varargin{1};

        % Display the error
        % disp(repmat('-',1,80));
        disp(['begin ERROR_' num2str(timestamp)]);
        disp(['ID: ' ME.identifier]);
        disp(['MSG: ' ME.message]);

        % Display the stack (if it exists)
        N = size(ME.stack,1);
        if N == 0
            disp('STACK: ');
        else
            for i = 1:N
                stackStr = [ME.stack(i).file ' -> line ' num2str(ME.stack(i).line)];
                if i == 1, stackStr = ['STACK: ' stackStr]; end
                disp(stackStr);
            end
        end

        disp(['end ERROR_' num2str(timestamp)]);
        % disp(repmat('-',1,80));
        disp(newline);
        
    elseif nargin > 1
        
        % Default the type to error then check if a type was passed in 
        if nargin > 2, errortype = varargin{3}; end
        if ~exist('errortype', 'var') || isempty(errortype) || ~(strcmpi(errortype, 'ERROR') || strcmpi(errortype, 'WARNING')), errortype = 'ERROR'; end

        ME.identifier = varargin{1};
        ME.message = varargin{2};
        stack = dbstack;
        if length(stack) > 1, idx = 2; else idx = 1; end

        % Display the error
        % disp(repmat('-',1,80));
        disp(['begin ' upper(errortype) '_' num2str(timestamp)]);
        disp(['ID: ' varargin{1}]);
        disp(['MSG: ' varargin{2}]);
        disp(['STACK: ' which(stack(idx).file) ' -> line ' num2str(stack(idx).line)]);
        disp(['end ' upper(errortype) '_' num2str(timestamp)]);
        % disp(repmat('-',1,80));  
        disp(newline);
        
    end
        
catch
    % An error occurred but we won't do anything about it; we simply won't
    % display the reported error.
end   

end