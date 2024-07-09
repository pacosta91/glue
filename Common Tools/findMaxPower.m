function [Pmax fnPmax] = findMaxPower(P,f)
% Determines the maximum power, Pmax, and the speed at which maximum power occurs, fnPmax.  
%
% Syntax:   
%   [Pmax fnPmax] = findMaxPower(P,f)       
%
% Inputs:
%   P - (dbl) An n-by-1 vector of powers (kW)
%   f - (dbl) An n-by-1 vector of speeds (rpm)   
%
% Outputs:
%   Pmax - (dbl) Maximum power
%   fnPmax - (dbl) Speed corresponding to maximum power
%
% CFR Requirement(s) Implemented:
%   1065.610(b)(1)
%
%   Note: The requirements for calculating fnPmax are a bit abstruse:
%
%   1065.610(a)(1)(iii) states: "Determine the engine speed corresponding 
%   to maximum power, fnPmax, by calculating the average of the two speed 
%   values from paragraph (a)(1)(ii) of this section." But these values are
%   the highest and lowest engine speeds corresponding to 98% of Pmax.
%
%   1065.610(b)(1) states: "Based on the map, determine maximum power, 
%   Pmax, and the speed at which maximum power occurs, fnPmax. If maximum 
%   power occurs at multiple speeds, take fnPmax as the lowest of these 
%   speeds."
%
%   Since 1065.610(b)(1) seems to make the most sense, that is the
%   requirement implemented here. Note that for the purpose of calculating
%   the maximum test speed {1065.610(a)}, this function should not be used!
%   
% Example: 
%   [P_max f_nPmax] = findMaxPower(P,f)
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

% Make sure f and P are both the same size and not empty
if length(f) ~= length(P) || isempty(f) || isempty(P), Pmax = NaN; fnPmax = NaN; return; end

% Find P_max
Pmax = max(P);

% Find the lowest speed corresponding to P_max
fnPmax = min(f(P == Pmax));