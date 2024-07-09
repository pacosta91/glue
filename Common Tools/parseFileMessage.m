function parseFileMessage(fid, Message, maxWidth)
% Outputs a long text string as lines of text whose length is less than or equal to maxWidth
%
% Syntax:  
%   parseFileMessage(Message, maxWidth)
%
% Inputs:
%   fid -   (int) A file identifier obtained from fopen, 1 = standard output,
%           2 = standard error, or 0 = disregard (i.e., use fprintf without 
%           the fid)
%   Message - (str) The message to be output
%   maxWidth - (string) The line width (must be >= 10)
%
% Outputs:
%   A formatted message (see above function description_
%
% Example: 
%   None
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   None
%
% MAT-files required: 
%   None
%
% See also: None

% Author:           Eric Simon
% File Version:     1.0
% Revision History:          
% 1.0   10/01/2014  Created as a generic function in order to remove
%                   similar code found in the LogManager.m file. The manner
%                   in which k is calculated also changed in order to more
%                   easily deal with cases in which the message doesn't
%                   contain spaces. As near as I can tell, the only reason
%                   fprintf is used with fid = 2 to ensure that the message
%                   printed to the command window is red, not black, since
%                   it is generally used to output errors or warnings.
 
% =========================================================================

% Set the minimum width to 10
if maxWidth < 10, maxWidth = 10; end

while length(Message) > maxWidth
    % As long as the FileMessage length is greater than the maximum width,
    % continue to divide the FileMessage into (MaximumWidth) character
    % blocks. In order to avoid splitting the message in the middle of a
    % word, search this block of code (from right to left) for the first
    % space character and shorten the block accordingly. Note that all but
    % the first sentence is indented.
    k = max([strfind(Message(1:maxWidth),' ') 0]);
    
    % In cases when Message has no spaces, the value of k will be properly
    % calculated the first iteration through the loop. Thereafter, k will
    % be at least 3 (since we are indenting). In such cases, k should be
    % set to the maxWidth.
    if k <= 3
        Message2 = Message(maxWidth+1:end);
        Message = Message(1:maxWidth);
    else
        Message2 = Message(k+1:end);
        Message = Message(1:k-1);
    end
    
    if fid == 0, fprintf([Message '\n']); else fprintf(fid, [Message '\n']); end
    Message = ['   ' Message2];

end
if fid == 0, fprintf([Message '\n']); else fprintf(fid, [Message '\n']); end