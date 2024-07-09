function [Tmax fnTmax] = findMaxTorque(T,f)
% Determines the maximum torque, Tmax, and the speed at which maximum torque occurs, fnTmax.  
%
% Syntax:   
%   [Tmax fnTmax] = findMaxTorque(T,f)       
%
% Inputs:
%   T - (dbl) An n-by-1 vector of torques (N.m)
%   f - (dbl) An n-by-1 vector of speeds (rpm)
%
% Outputs:
%   Tmax - (dbl) The maximum torque
%   fnPmax - (dbl) The speed corresponding to the maximum torque
%
% CFR Requirement(s) Implemented:
%   None
%
%   Note: The requirement 1065.610(b)(1) describes the relationship between
%   maximum power and the speed at which it occurs, noting that: "If 
%   maximum power occurs at multiple speeds, take fnPmax as the lowest of 
%   these speeds." This same approach of using the lowest speed, fnTmax, is
%   applied here.
%
% Example: 
%   [Tmax fnTmax] = findMaxTorque(T,f)
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
% See also: http://www.ecfr.gov/cgi-bin/text-idx?SID=a1aacb2cd749e173bcfcd47709132422&node=pt40.33.1065&rgn=div5#se40.33.1065_1610

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0   09/23/2014  Original file.

% =========================================================================

% Find Tmax
Tmax = max(T);

% Find the lowest speed corresponding to Tmax
fnTmax = min(f(T == Tmax));