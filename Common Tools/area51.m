function n_pref = area51(speed, torque, Nidle, N95h)
% Determines the engine speed where the integral of maximum mapped torque 
% from Nidle to n_pref is 51 percent of the whole integral between Nidle 
% and N95h.
%
% Syntax:   
%   n_pref = area51(speed, torque, Nidle, N95h)       
%
% Inputs:
%   speed - (dbl) An n-by-1 vector of speeds (rpm)
%   torque - (dbl) An n-by-1 vector of torques (N.m)  
%   Nidle - (dbl) The idle speed (often the mean engine speed in mode 2)
%   N95h - (dbl) The speed corresponding to 95% of max power
%
% Outputs:
%   n_pref -    (dbl) The speed such that the integral of maximum mapped
%               torque from Nidle to n_pref is 51% of the integral from
%               Nidle to N95h.
%
% Stage V Requirement(s) Implemented:
%   E/ECE/TRANS/505/Rev.1/Add.48/Rev.6 Annex 4 Figure 5: Definition of
%   n_pref
%
%   Note: There are various issues related to the calculation of n_pref
%
%   It isn't guaranteed that the speeds are necessarily increasing during the interval
%   from Nidle to n_pref. This can lead to erroneous results. For the time being
%   this script will throw an error in such cases.
%   
% Example: 
%   n_pref = area51(speed, torque, 1000, 2200)
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
% 1.0   01/10/2017  Original file.

% =========================================================================

n_pref = 0;

% -------------------------------------------------------------------------
% Find the index where Nidle belongs and insert it in the speed array.
% Remove all points prior. 
% -------------------------------------------------------------------------

% Grab the torque at Nidle. If Nidle exists in the speed array we'll just
% grab that torque value. If not, we'll interpolate. This is handled by the
% abscissaInterp function.
torque_at_Nidle = max(abscissaInterp(torque, speed, Nidle));
    
% Next, we'll eliminate all points less than Nidle and add Nidle as the
% first element in the array. Note that this approach eliminates some of
% the noise we might observe at idle speeds and can help to avoid negative
% values of delta speed.
temp = find(speed < Nidle);
if ~isempty(temp)
    Nidle_idx = max(temp);
    try
        speed = [Nidle; speed(Nidle_idx+1:end)];
        torque = [torque_at_Nidle; torque(Nidle_idx+1:end)];
    catch ME
        warning('World Harmonized npref calculation error! There was an error trying to adjust the speed and torque arrays to include Nidle. %s: %s', ME.identifier, ME.message);
        return
    end
else
    warning('World Harmonized npref calculation error! There was an error trying to adjust the speed and torque arrays to include Nidle. %s: %s', ME.identifier, ME.message);
    return
end 


% Grab the torque at N95h. If N95h exists in the speed array we'll just
% grab that torque value. If not, we'll interpolate.
torque_at_N95h = max(abscissaInterp(torque, speed, N95h));
    
% Next, we'll eliminate all points greater than N95h and add N95h as
% the last element in the array. 
temp = find(speed > N95h);
if ~isempty(temp)
    N95h_idx = min(temp);
    try
        speed = [speed(1:N95h_idx-1); N95h];
        torque = [torque(1:N95h_idx-1); torque_at_N95h];
    catch ME
        warning('World Harmonized npref calculation error! There was an error trying to adjust the speed and torque arrays to include N95h. %s: %s', ME.identifier, ME.message);
        return
    end
else
    warning('World Harmonized npref calculation error! There was an error trying to adjust the speed and torque arrays to include N95h. %s: %s', ME.identifier, ME.message);
    return
end   

% Estimate the total area beneath the curve
totalarea = 0;
midpoints = torque(1:end-1) + diff(torque)/2;
dx = diff(speed);
totalarea = dot(midpoints,dx);

N = length(midpoints);

if N > 0
    area(1) = 0;
    for i = 2:N
        area(i) = area(i-1)+ midpoints(i-1)*dx(i-1);
    end    
end

pctarea = area' / totalarea;
n_pref = abscissaInterp(speed, pctarea, 0.51);