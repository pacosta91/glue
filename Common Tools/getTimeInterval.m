function interval = getTimeInterval(time_vector, precision)  
% Determines the constant time interval of a time vector 
%
% Note: If the time vector does not have a constant interval, 0 is returned
% instead.
%
% Syntax:   
%   getTimeInterval(time_vector)       
%
% Inputs:
%   time_vector - (dbl) A n x 1 or 1 x n array of times
%
%   precision - (int) {optional} The number of decimal places to round to;
%   use a very large number (e.g. 999) to avoid rounding or don't include
%   it as an input.
%
% Outputs:
%   interval - (dbl) A common time interval or 0. 
%   
% Example: 
%   interval = getTimeInterval(time_vector);
%
% Other m-files required: 
%   None
%
% Subfunctions: 
% None
%
% MAT-files required: 
%   None
%

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0   06/18/2015  Eric Simon

% =========================================================================

    interval = 0;
    s = size(time_vector);
    
    if s(1) == 1 || s(2) == 1
        intervals = diff(time_vector);
        constant_check = find(intervals ~= intervals(1));
        if isempty(constant_check)
            interval = intervals(1); 
        else 
            interval = mode(intervals);
            warning('DATA INTEGRITY: %s: The time interval is not constant! The mode will be returned instead.', FunctionAndLineNumber()); 
        end  
        if exist('precision', 'var') && isnumeric(precision)
            interval = round(interval, precision);
        end
    end
end

