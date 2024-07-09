function [Ttest SS] = findMaxTestTorque(T,f,P)
% Determines the maximum test torque for constant-speed engines
% 
% Syntax:   
%   [Ttest SS] = findMaxTestTorque(T,f,P)       
%
% Inputs:
%   T - (dbl) An n-by-1 vector of Torques (N.m)
%   f - (dbl) An n-by-1 vector of speeds (rpm) 
%   P - (dbl) An n-by-1 vector of powers (kW)
%
% Outputs:
%   Ttest - maximum test torque
%   SS - (dbl) An n-by-1 vector the sum of squares of normalized speed and
%   power
%
% CFR Requirement(s) Implemented:
%   1065.610(b)
%
% Example: 
%   [Ttest SS] = findMaxTestTorque(T,f,P)
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   findMaxPower
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

% Make sure T, f and P are all the same size and not empty
if length(T) ~= length(f) || length(f) ~= length(P) || isempty(f) || isempty(f) || isempty(P), Ttest = NaN; SS = NaN; return; end

% Calculate Power if it is not provided
if nargin < 3
    P = (f .* T) * pi/30000;
end

% 1065.610(b)(1)
[Pmax fnPmax] = findMaxPower(P,f);

Pnorm = P / Pmax;
fnorm = f / fnPmax;
SS = fnorm.^2 + Pnorm.^2;

% Find SSmax
SSmax = max(SS);

% Find the lowest speed corresponding to P_max
Ttest = max(T(SS == SSmax));
