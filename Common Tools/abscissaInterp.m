function xValues = abscissaInterp(xData,yData,findOrdinateValue)
% Returns the set of abscissa values corresponding to the value of findOrdinateValue using linear interpolation as necessary
% 
% Syntax:   
%   xValues = abscissaInterp(xData,yData,findOrdinateValue)       
%
% Inputs:
%   xData - (dbl) An n-by-1 vector of x-values
%   yData - (dbl) An n-by-1 vector of y-values
%   findOrdinateValue - (dbl) The ordinate or y-value to find
%
% Outputs:
%   xValues - (dbl) A 1-by-n vector of (possibly interpolated) x-values
%   corresponding to the value of findOrdinateValue
%
% CFR Requirement(s) Implemented:
%   None. This function was written as a generic function to satisfy a 
%   portion of the calculations required to satisfy 1065.610(a)(1)(ii) 
%
% Example: 
%   xValues = abscissaInterp(xData,yData,findOrdinateValue)
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
% 1.0   09/23/2014  Original file.

% =========================================================================

% Initialize the return vector
xValues = [];

% First, find all cases when findOrdinateValue is included in the yData
% vector and interpolation isn't necessary. 
xValues = xData(yData == findOrdinateValue);

% Next, divide the remaining yData into a series of open intervals and use
% linear interpolation in cases when the value of findOrdinateValue lies
% inside the interval.
for i = 1:length(yData)-1
    if yData(i+1) >= yData(i)
        if findOrdinateValue > yData(i) && findOrdinateValue < yData(i+1)
            xValues(end+1) = interp1([yData(i) yData(i+1)],[xData(i) xData(i+1)],findOrdinateValue);  
        end
    else
        if findOrdinateValue > yData(i+1) && findOrdinateValue < yData(i)
            xValues(end+1) = interp1([yData(i+1) yData(i)],[xData(i+1) xData(i)],findOrdinateValue);  
        end
    end
end