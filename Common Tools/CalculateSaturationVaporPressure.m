function P_ws = CalculateSaturationVaporPressure(AirTemp, units, method)
% Returns the saturation vapor pressure  
%
% SYNTAX:
%
% P_ws = CalculateSaturationVaporPressure(DewTemp, method)   
%
% INPUTS:
%
% AirTemp           (dbl) An n-by-1 vector consisting of temperatures. 
%
% units             (str) The units associated with AirTemp. Acceptable
%                   units are: '°F', 'F°', 'deg F', 'K', 'R', '°C', 'C°', 'deg C'
%
% method            (str) 'Murphy&Koop2005' or 'Bolton1980'
%
% REQUIREMENTS:     
%
% N/A
%
% OUTPUTS:
%
% P_ws               (dbl) The vapor pressure (Pa).
% 
% OTHER FILES REQUIRED:
%
% None
%
% NOTES:
%
% Based on the convert_humidity toolbox available at 
% <https://www.mathworks.com/matlabcentral/fileexchange/30553-converthumidity/content/convert_humidity/convert_humidity.m>
% Copyright (c) 2011, Felipe G. Nievinski

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0               Original file created by Eric Simon

% =========================================================================

%% Initialize Variables
if ~exist('method','var'), method = 'Murphy&Koop2005'; end

%% Validate Input
% TBD: Should make sure vectors are as expected and size(channeldata) =
% size(channelranges)

%% Convert AirTemp to Kelvin
[AirTemp, success] = unitConversionVehicleGlue('AirTemp', AirTemp, units, 'k');
if ~success, error('%s: Unable to convert the dew temperature of air to from %s to units Kelvin!', FunctionAndLineNumber(), units); end

%% Calculate the output based on the method

switch method
    
    case 'Bolton1980'
        temp = AirTemp - 273.15;
        P_ws = (0.6112 .* exp(17.67 .* temp ./ (temp + 243.5))) * 1000;
        % The AMS Glossary gives [1] the simplified formula above, 
        % accordingly to Bolton (1980, eq. 10).
        % 
        % AMS Glossary. <http://amsglossary.allenpress.com/glossary/search?id=clausius-clapeyron-equation1>
        % Bolton, D., 1980: The computation of equivalent potential temperature. Mon. Wea. Rev., 108, 1046-1053. <http://dx.doi.org/10.1175/1520-0493(1980)108<1046:TCOEPT>2.0.CO;2>

    case 'Murphy&Koop2005'
        if ~all(123 < AirTemp & AirTemp < 332), warning('%s: Temperature out of range [123-332] K!', FunctionAndLineNumber()); return; end

        temp = 54.842763 - 6763.22 ./ AirTemp - 4.210 .* log(AirTemp) + 0.000367 .* AirTemp + ...
            tanh(0.0415 * (AirTemp - 218.8)) .* ...
            (53.878 - 1331.22 ./ AirTemp - 9.44523 .* log(AirTemp) + 0.014025 .* AirTemp);
        P_ws = exp(temp);
        % D. M. MURPHY and T. KOOP
        % Review of the vapour pressures of ice and supercooled water for
        % atmospheric applications
        % Q. J. R. Meteorol. Soc. (2005), 131, pp. 1539-1565 
        % doi: 10.1256/qj.04.94
        % <http://dx.doi.org/10.1256/qj.04.94>
        % 
        % "Widely used expressions for water vapour (Goff and Gratch 1946; Hyland and Wexler 1983) are being applied outside the ranges of data used by the original authors for their fits. This work may be the first time that data on the molar heat capacity of supercooled water [i.e., at temperatures below its freezing temperature] have been used to constrain its vapour pressure.
    
    otherwise
        error('%s: Unknown method ''%s''!', FunctionAndLineNumber(), method);
       
end

end