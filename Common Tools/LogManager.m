% LogManager.m
% LogManager is a singleton class responsible for handling all
% communications with the log file. The LogManager holds two variables
% m_fId which stores the log file identifier, and m_DebugLevel which
% controls which messages are and aren't printed to the LogFile
% 
% DebugLevel    OutputSummary
% =========================================================================
%     0         No log is produced
%     1         Only errors and warnings
%     2         Standard output, includes errors and warnings

% Author:   Eric Simon
% File Version: 1.1
% History:  09.18.2014  Edited original file created by Jared.
%                       Added functionality to specify log file directory,
%                       made sure the directory existed and created it if
%                       it didn't. Included calls to a newly-created common
%                       file, createSeparator.m, that essentially returns a
%                       repeated character used to separate log file
%                       sections. Included comments for clarity.


classdef LogManager < handle
    properties
        m_fId
        m_fdir = 'D:\Testing\Engine\Cell Mgt\Glue\ROAMING4\Glue\Log'; % Allow users to specify log file location
        m_DebugLevel
        m_CommandWindowLevel
        m_MaximumWidth = 128;
        m_CommandWindowMaximumWidth = 140;
    end
    methods
        function obj = LogManager(DebugLevel, CommandWindowLevel, GlueVersion, IssueDate, filename)
            obj.m_DebugLevel = DebugLevel;
            obj.m_CommandWindowLevel = CommandWindowLevel;
            if obj.m_DebugLevel ~= 0
                % Grab the test number from the filename
                Test = left(filename{1},length(filename{1})-4);
                
                % Create the logname by including a time stamp
                logname = [Test '_' ETC_TimeStamp(now, 1)];
                
                % Make sure the log directory exists and create the
                % directory if it doesn't
                if ~isequal(exist(obj.m_fdir, 'dir'),7) % 7 = directory
                    % Right now, I'm not doing anything with the status so
                    % if the directory doesn't get created the calling
                    % program should bomb during file open (fopen; see
                    % below)
                    status = mkdir(obj.m_fdir);
                end        
                
                % Open an existin log file or create a new one. Here again
                % we aren't doing anything in cases when the file can't be
                % opened or created.
                obj.m_fId = fopen([obj.m_fdir logname '.log'],'w+');
                
                % Write to the log file
                fprintf(obj.m_fId,'%s\n',createSeparator(61, '', obj.m_MaximumWidth));
                fprintf(obj.m_fId,[createSeparator(61, GlueVersion, obj.m_MaximumWidth) '\n']);               
                fprintf(obj.m_fId,[createSeparator(61, IssueDate, obj.m_MaximumWidth) '\n']);
                fprintf(obj.m_fId,'%s\n',createSeparator(61, '', obj.m_MaximumWidth));                
             
                % Grab the current time to include in the log (slightly
                % superfluous given that the date is encoded in the log
                % file name)
                launchdate = datestr(now,'dd-mmm-yyyy');
                
                % Grab information about the computer being used 
                currentLocation = pwd; %MATLAB 2010b complains if using a network directory.
                cd C:\;
                [~, launchingcomputer] = system('hostname');
                cd(currentLocation);
                
                % Continue to write to the log file
                fprintf(obj.m_fId,['Launched: ' launchdate '  From: ' launchingcomputer]);
                fprintf(obj.m_fId,'%s\n',createSeparator(61, '', obj.m_MaximumWidth));
                fprintf(obj.m_fId,'Test(s) Loaded:\n');
                for k = 1:length(filename)
                    fprintf(obj.m_fId,['  ' filename{k} '\n']);
                end
                fprintf(obj.m_fId,'%s\n',createSeparator(61, '', obj.m_MaximumWidth));
            end
        end
        
        function DebugPrint(obj, DebugLevel, varargin)
            switch nargin
                case 3
                    Message = varargin{1};
                case 4
                    Message = sprintf(varargin{1},varargin{2});
                case 5
                    Message = sprintf(varargin{1},varargin{2},varargin{3});
                case 6
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4});
                case 7
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5});
                case 8
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6});
                case 9
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6},varargin{7});
                case 10
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6},varargin{7},varargin{8});
                case 11
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6},varargin{7},varargin{8},varargin{9});
                case 12
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6},varargin{7},varargin{8},varargin{9},varargin{10});
                case 13
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6},varargin{7},varargin{8},varargin{9},varargin{10}, ...
                        varargin{11});
                otherwise
                    Message = sprintf(varargin{1},varargin{2},varargin{3},varargin{4},varargin{5}, ...
                        varargin{6},varargin{7},varargin{8},varargin{9},varargin{10}, ...
                        varargin{11});
                    Message = [Message '... Too many inputs message has been truncated'];
            end
            
            Message = strrep(Message,'\','\\');
            Message = strrep(Message,'%','%%');
            
            if DebugLevel <= obj.m_DebugLevel
                FileMessage = [datestr(now,'hh:mm:ss') ': ' Message];
                parseFileMessage(obj.m_fId, FileMessage, obj.m_MaximumWidth)
            end
            
            if DebugLevel <= obj.m_CommandWindowLevel
                if strcmp(left(Message,9),'WARNING: ') || strcmp(left(Message,7),'ALARM: ') || strcmp(left(Message,9),'   file: ')
                    parseFileMessage(2, Message, obj.m_CommandWindowMaximumWidth); 
                else
                    parseFileMessage(0, Message, obj.m_CommandWindowMaximumWidth);
                end
            end
        end % function DebugPrint(obj, DebugLevel, varargin)
        
        function delete(obj)
%             fclose(obj.m_fId);
        end
    end
end
