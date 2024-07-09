function [fSSmax98_lo, fSSmax98_hi, fntest, fPmax98_lo, fPmax98_hi, fnPmax, SS] = findMaxTestSpeed(f,P,retType)
% Determines the maximum test speed for variable speed engines
%
% Syntax:
%   [fSSmax98_lo, fSSmax98_hi, fntest, fPmax98_lo, fPmax98_hi, fnPmax, SS] = findMaxTestSpeed(f,P,retType)
%
% Inputs:
%   f - (dbl) An n-by-1 vector of speeds (rpm)
%   P - (dbl) An n-by-1 vector of powers (kW)
%   retType - (int) A flag indicating how the engine speeds corresponding
%   to 98% Pmax are identified.
%
% Outputs:
%   fSSmax98_lo - (dbl) The minimum test speed corresponding to 98% of the max normalized power and speed
%   SSmax98_hi - (dbl) The maximum test speed corresponding to 98% of the max normalized power and speed
%   fntest -    (dbl) The "maximum test speed" defined as the "average" speed
%               corresponding to 98% of the max normalized power and speed sum-of-squares  (RPM); also the mean of SSmax98_lo and SSmax98_hi
%   fPmax98_lo - (dbl) The minimum test speed corresponding to 98% of the max of power (RPM)
%   fPmax98_hi - (dbl) The maximum test speed corresponding to 98% of the max of power (RPM)
%   fnPmax - (dbl) The "average" speed corresponding to 98% of the max of power (RPM)
%   SS - (dbl) An n-by-1 vector the sum of squares of normalized speed and
%   power
%
% CFR Requirement(s) Implemented:
%   1065.610(a)
%
% Example:
%   [fSSmax98_lo, fSSmax98_hi, fntest, fPmax98_lo, fPmax98_hi, fnPmax, SS] = findMaxTestSpeed(f,P,retType)
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

% Make sure f and P are both the same size and not empty
if length(f) ~= length(P) || isempty(f) || isempty(P), fntest = NaN; return; end

% Set the default value of retType to 0 
if ~exist('retType','var'), retType = 0; end

% 1065.610(a)(1)(i)
Pmax = findMaxPower(P,f);
Pmax98 = Pmax * 0.98;

% 1065.610(a)(1)(ii)
fPmax98 = abscissaInterp(f,P,Pmax98);
fPmax98_length = length(fPmax98);

if fPmax98_length == 0
    error('Unable interpolate the speed at 98%% max power! Power, %0.2f kW, not found!', Pmax98); % This should never happen
else
    % We have traditionally determined the "lowest" and "highest" engine
    % speeds corresponding to 98% of Pmax by taking the first and last
    % values returned. It can be debated what "lowest" and "highest"
    % actually means. We are interpreting it to mean "leftmost" and
    % "rightmost" on the speed axis, which, in cases when the speed values
    % are increasing is the same thing as "smallest" and "largest", i.e.,
    % min and max. Since "lowest" and "highest" can be interpreted as
    % "smallest" and "largest" without regard for how the speed values are
    % ordered along the x-axis, the retType flag can be used to return
    % these values.
    if (retType == 1)        
        fPmax98_lo = min(fPmax98);
        fPmax98_hi = max(fPmax98);       
    else       
        fPmax98_lo = fPmax98(1);
        fPmax98_hi = fPmax98(end);        
    end

    if fPmax98_length == 1
        warning('There is only one value of speed associated with 98%% max power, %0.2f kW: %f. This value will be used for BOTH the hi and lo speed value!', Pmax98, fPmax98);
    elseif fPmax98_length > 2
        fPmax98_disp = sprintf('%f, ', fPmax98);
        fPmax98_disp = fPmax98_disp(1:end-2);
        warning('More than two speed values found at 98%% max power, %0.2f kW: %s. The first and last values were chosen!', Pmax98, fPmax98_disp);
    end
end

% 1065.610(a)(1)(iii)
fnPmax = mean([fPmax98_lo fPmax98_hi]);

% 1065.610(a)(1)(iv)
Pnorm = P / Pmax;
fnorm = f / fnPmax;
SS = fnorm.^2 + Pnorm.^2;

% 1065.610(a)(1)(v)
SSmax98 = max(SS) * 0.98;

% 1065.610(a)(1)(vi)
% EDS 2/4/2016: We'll do the same thing here (see above).
fSSmax98 = abscissaInterp(f,SS,SSmax98);
fSSmax98_length = length(fSSmax98);

if fSSmax98_length == 0
    error('Unable interpolate the speed at 98%% sum of squares (SS) of normalized speed and power! SS, %0.2f, not found!', SSmax98); % This should never happen
else
    % See above for an explanation of retType and why it is being used
    % here.
    if (retType == 1)
        fSSmax98_lo = min(fSSmax98);
        fSSmax98_hi = max(fSSmax98); 
    else        
        fSSmax98_lo = fSSmax98(1);
        fSSmax98_hi = fSSmax98(end);
    end
    
    if fSSmax98_length == 1
        warning('There is only one value of speed associated with 98%% sum of squares (SS) of normalized speed and power, %0.2f: %f. This value will be used for BOTH the hi and lo speed value!', SSmax98, fSSmax98);
    elseif fSSmax98_length > 2
        fSSmax98_disp = sprintf('%f, ', fSSmax98);
        fSSmax98_disp = fSSmax98_disp(1:end-2);
        warning('More than two speed values found at 98%% sum of squares (SS) of normalized speed and power, %0.2f: %s. The first and last values were chosen!', SSmax98, fSSmax98_disp);
    end
end

% 1065.610(a)(1)(vii)
fntest = mean([fSSmax98_lo fSSmax98_hi]);
