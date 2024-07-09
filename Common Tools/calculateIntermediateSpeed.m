function [fTmax98_lo, fTmax98_hi, fnTmax, intSpd] = calculateIntermediateSpeed(T,f,fntest)
% Determines the intermediate speed based on torque and speed
%
% Syntax:
%   [fTmax98_lo, fTmax98_hi, fnTmax, intSpd] = calculateIntermediateSpeed(T,f,fntest)
%
% Inputs:
%   T - (dbl) An n-by-1 vector of Torques (N.m)
%   f - (dbl) An n-by-1 vector of speeds (rpm)
%   fntest - (dbl) The maximum test speed
%
% Outputs:
%   fTmax98_lo - (dbl) The minimum test speed corresponding to 98% of max torque (RPM)
%   fTmax98_hi - (dbl) The maximum test speed corresponding to 98% of max torque (RPM)
%   fnTmax - (dbl) The "average" speed corresponding to 98% of max torque (RPM)
%   intSpd - (dbl) The calculated intermediate speed
%
% CFR Requirement(s) Implemented:
%   1065.610(c)(3)
%
% Example:
%   [fTmax98_lo, fTmax98_hi, fnTmax, intSpd] = calculateIntermediateSpeed(T,f,fntest)
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

% 1065.610(b)(3)
Tmax = max(T);
Tmax98 = 0.98 * Tmax;

fTmax98 =  abscissaInterp(f,T,Tmax98);
fTmax98_length = length(fTmax98);

if fTmax98_length == 0
    error('Unable interpolate the speed at 98%% max torque! Torque, %0.2f N.m, not found!', Tmax98); % This should never happen
else
    % EDS - For now use the first and last element.
    fTmax98_lo = fTmax98(1);
    fTmax98_hi = fTmax98(end);
    if fTmax98_length == 1
        warning('There is only one value of speed associated with 98%% max torque, %0.2f N.m: %f. This value will be used for BOTH the hi and lo speed value!', Tmax98, fTmax98);
    elseif fTmax98_length > 2
        fTmax98_disp = sprintf('%f, ', fTmax98);
        fTmax98_disp = fTmax98_disp(1:end-2);
        warning('More than two speed values found at 98%% max torque, %0.2f N.m: %s. The first and last values were chosen!', Tmax98, fTmax98_disp);
    end
end

fnTmax = mean([fTmax98_lo, fTmax98_hi]);

% Calculate the Intermediate Speed
if fnTmax < 0.60 * fntest
    intSpd = 0.60 * fntest;
elseif fnTmax <= 0.75 * fntest
    intSpd = fnTmax;
elseif fnTmax > 0.75 * fntest
    intSpd = 0.75 * fntest;
else
    intSpd = 0;
end
