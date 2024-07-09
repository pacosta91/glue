function [aAndB aInds bInds] = d_uIntersect(A,B)
% Finds the unsorted intersection between two sets. This works the same way
% as the MATLAB intersect function with the 'stable' flag supported as of
% MATLAB version 2012b. 
%
% Downloaded from MATLAB File Exchange
% Author: Don Vaughn

[orderedAAndB orderedAInds orderedBInds] = intersect(A,B);
[aInds sortToUnsortedMap]= sort(orderedAInds);
bInds = orderedBInds(sortToUnsortedMap);
aAndB = A(aInds);