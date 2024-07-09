function [c cIndsInA] = d_uSetdiff(a,b)
% Finds the unsorted difference between two sets. This works the same way
% as the MATLAB setdiff function with the 'stable' flag supported as of
% MATLAB version 2012b. 
%
% Downloaded from MATLAB File Exchange
% Author: Don Vaughn

[cSorted,idx] = setdiff(a,b);
cIndsInA = sort(idx);
c = a(cIndsInA);