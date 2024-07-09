function [time10Hz, data10Hz] = convertTo10Hz(timeArray, dataArray)
% Estimates the 10Hz data from 1Hz data using linear interpolation
% 
% Syntax:   
%   [time10Hz, data10Hz] = convertTo10Hz(timeArray, dataArray)      
%
% Inputs:
%   timeArray - (dbl) An n-by-1 vector of times (usually starting at zero)
%   dataArray - (dbl) An n-by-1 vector of data (usually rpm or torque) 
%
% Outputs:
%   time10Hz - (dbl) The timeArray converted to 10Hz
%   data10Hz - (dbl) The dataArray converted to 10Hz
%
% CFR Requirement(s) Implemented:
%   None
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

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0   10/07/2014  Original file.

% =========================================================================
% Initialize the output arrays
time10Hz = [];
data10Hz = [];

N = size(timeArray);
M = size(dataArray);

% Error-checking is far from robust but we'll trap a few conditions
if N(1) ~= M(1) || N(2) ~= 1 || M(2) ~= 1, error('Inputs must be identically-sized COLUMN vectors!'); return; end

% There is probably a better way to do this in MATLAB but for now we'll
% loop through the original data
for i = 1:N(1)-1
    % Calculate time difference and "data" difference on the current
    % interval
    tdiff = timeArray(i+1) - timeArray(i);
    ddiff = dataArray(i+1) - dataArray(i);

    % Create the 10Hz time and data interval
    intTime = linspace(timeArray(i),timeArray(i+1), 11)';
    intData = linspace(dataArray(i),dataArray(i+1), 11)';
    
    if i == 1
        time10Hz = intTime(1:11);
        data10Hz = intData(1:11);
    else
        % The left endpoint was added on the previous iteration; don't
        % include it a second time
        time10Hz = vertcat(time10Hz, intTime(2:11));
        data10Hz = vertcat(data10Hz, intData(2:11));
    end

end
    
    



