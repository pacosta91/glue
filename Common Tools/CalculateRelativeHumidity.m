function RH = CalculateRelativeHumidity(DryTemp, DryTemp_units, DewTempAir, DewTempAir_units)
% Returns the relative humidity from dry temperature and Dew Temperature 
%
% SYNTAX:
%
% RH = CalculateRelativeHumidity(DryTemp, DryTemp_units, DewTempAir, DewTempAir_units)   
%
% INPUTS:
%
% DryTemp           (dbl) An n-by-1 vector of dry air temperatures.
%
% DryTemp_units     (str) The units associated with DryTemp. Acceptable
%                   units are: '°F', 'F°', 'deg F', 'K', 'R', '°C', 'C°', 'deg C' 
%
% DewTempAir        (dbl) An n-by-1 vector of dew temperatures.
%
% DewTemp_units     (str) The units associated with DewTemp. Acceptable
%                   units are: '°F', 'F°', 'deg F', 'K', 'R', '°C', 'C°', 'deg C' 
%
% REQUIREMENTS:     
%
% N/A
%
% OUTPUTS:
%
% RH               (dbl) The relative humidity.
% 
% OTHER FILES REQUIRED:
%
% CalculateSaturationVaporPressure.m
% unitConversionVehicleGlue.m
% 
%
% NOTES:
%
% The dew temperature is the temperature to which the sample air must be
% cooled to reach saturation with respect to liquid water.

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0               Original file created by Eric Simon

% =========================================================================

%% Validate Input
% TBD: Should make sure vectors are as expected and size(channeldata) =
% size(channelranges)

%% Calculate the relative humidity
RH = CalculateSaturationVaporPressure(DewTempAir, DewTempAir_units) ./ CalculateSaturationVaporPressure(DryTemp, DryTemp_units) * 100;

end