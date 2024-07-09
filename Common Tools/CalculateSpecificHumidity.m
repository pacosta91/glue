function q = CalculateSpecificHumidity(DewTempAir, DewTempAir_units, Baro, Baro_units)
% Returns the specific humidity from dew temperature (K) and barometric pressure (kPa) 
%
% SYNTAX:
%
% q = CalculateSpecificHumidity(DewTempAir, DewTempAir_units, Baro, Baro_units)   
%
% INPUTS:
%
% DewTempAir        (dbl) An n-by-1 vector of dry air temperatures (Kelvin).
%
% DewTempAir_units  (str) The units associated with DryTemp. Acceptable
%                   units are: '°F', 'F°', 'deg F', 'K', 'R', '°C', 'C°', 'deg C' 
%
% Baro              (dbl) An n-by-1 vector of barometric pressure (kPa).
%
% 
%
% REQUIREMENTS:     
%
% N/A
%
% OUTPUTS:
%
% q                  (dbl) The specific humidity (g/kg).
% 
% OTHER FILES REQUIRED:
%
% constants.mat
% CalculateSaturationVaporPressure.m
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

%% Load constants
load('constants.mat');

%% Convert DewTempAir to Kelvin
[DewTempAir_K, success] = unitConversionVehicleGlue('DewTempAir', DewTempAir, DewTempAir_units, 'K');
if ~success, error('%s: Unable to convert the dew temperature of air to from %s to units Kelvin!', FunctionAndLineNumber(), units); end

%% Convert Baro to kPa
[Baro_kPa, success] = unitConversionVehicleGlue('Baro', Baro, Baro_units, 'kPa');
if ~success, error('%s: Unable to convert the barometric pressure to from %s to units Kelvin!', FunctionAndLineNumber(), units); end

%% Calculate the relative humidity

c = constants.meteorological.M_wet / constants.meteorological.M_dry;
P_ws = CalculateSaturationVaporPressure(DewTempAir_K, 'K'); 
Pd = Baro_kPa * 10 - P_ws; % Concert to hPa
q = (P_ws .* c) ./ (P_ws .* c + Pd);

end