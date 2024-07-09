function epsilon = machineEpsilon()
% Calculates machine epsilon for the current machine 
%
% SYNTAX:
%
% e = machineEpsilon()   
%
% INPUTS:
%
% none
%
% REQUIREMENTS:     
%
% N/A
%
% OUTPUTS:
%
% e               (dbl) machine epsilon.
% 
% OTHER FILES REQUIRED:
%
% none
%
% NOTES:
%
% none

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0               Original file created by Eric Simon

% =========================================================================

%% Validate Input
% TBD: Should make sure vectors are as expected and size(channeldata) =
% size(channelranges)

%% Estimate machine epsilon

epsilon = 1.0;

while (1.0 + 0.5 * epsilon) ~= 1.0
    epsilon = 0.5 * epsilon;
end

end