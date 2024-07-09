function separator = createSeparator(charcode, text, N)
% Creates a string separator with optionally centered text
%
% Syntax:  
%   separator = createSeparator(charcode, text, N)
%
% Inputs:
%   charcode - (int) An ASCII character code (1-255)
%   text - (string) A text description to be centered inside the separator string
%   N - (int) The length of the separator string
%
% Outputs:
%   separator - (string) A fixed-length string
%
% Example: 
%   createSeparator(61,'Hello World', 23) returns '===== Hello World ====='
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
% 1.0   09/18/2014  Created as a generic function in order to remove
%                   similar code found in the LogManager.m file. There is
%                   some additional error checking here but not a lot. 

% =========================================================================

% Initialize the return value
separator = '';

% Make sure the charcode is a valid number  
if charcode < 1 | charcode > 255 | ~isnumeric(charcode)
    charcode = 45;
end

% Figure out the number of characters to return
charLength = (N - (length(text) + 2)) / 2;

% If the text isn't a string or there isn't any text or the text is too long don't include it.
if ~ischar(text) || isequal(text,'') || charLength < 1
    separator = char(charcode*ones(1,N)); return
else
    if charLength == floor(charLength)
        separator = [char(charcode*ones(1,charLength)) ' ' text ' ' char(charcode*ones(1,charLength))]; 
    else
        separator = [char(charcode*ones(1,floor(charLength))) ' ' text '  ' char(charcode*ones(1,floor(charLength)))];
    end
end % ~ischar(text)

end % function