function [fcnList, dataFiles] = getDependencies(fcnName, createMatfile, MATLAB_install_path)
% Returns a list of dependent functions and datafiles
%
% Note: If a dependent file doesn't exist it isn't included in the list of
% dependent functions! Also, the files need to be on the current MATLAB
% path in order to be found!
% 
% Syntax:   
%   [fcnList, dataFiles] = getDependencies(fcnName, MATLAB_install_path)      
%
% Inputs:
%   fcnName - (str) The name of the function (e.g., 'SuperGlue.m')
%   createMATfile - (int) 1 = true, 0 = false
%   MATLAB_install_path -   (str) The MATLAB install path (e.g., 'C:\Program
%                           Files\MATLAB\R2012b\toolbox')
%
% Outputs:
%   fcnList - (cell) An n-by-1 cell array of dependent filenames and paths
%   dataFiles - (cell) An n-by-1 cell array of dependent datafiles and paths
%   {fcnName}_dependencies.mat -    (matfile) An optional mat file created in
%                                   the same directory as the m-file
%                                   (fcnName)
%
% CFR Requirement(s) Implemented:
%   None. 
%
% Example: 
%   None
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
% 1.0   10/13/2014  Original file.

% =========================================================================

if ~exist('MATLAB_install_path', 'var'), MATLAB_install_path = 'C:\Program Files\MATLAB\R2012b\toolbox'; end
if ~exist('createMatfile', 'var'), createMatfile = 0; end

try
    fcnList = depfun(fcnName, '-quiet');
    if strcmp(MATLAB_install_path, 'all')
        listIndex = fcnList;
    else
        listIndex = strmatch(MATLAB_install_path,fcnList);
    end
    fcnList = fcnList(setdiff(1:numel(fcnList),listIndex));
    
    % Grab any data file dependencies
    fid = fopen(fcnName,'rt');
    fcnText = fscanf(fid,'%c');
    fclose(fid);
    reg_expr = '[^\'']\''([^\''\n\r]+(?:\w\.(?:mat|txt)){1})\''[^\'']';
    dataFiles = regexp(fcnText,reg_expr,'tokens');
    dataFiles = unique([dataFiles{:}]).';    
    
    if createMatfile 
        % Grab the path to the tool and save the matfile in that directory
        [pathstr, ~, ~] = fileparts(which(fcnName));
        matfilename = strrep(fcnName,'.m','');
        filepaths = [fcnList; dataFiles];
        save([pathstr '\' matfilename '_dependencies.mat'], 'filepaths'); 
    end
    
catch ME
    fcnList = {};
    dataFiles = {};
end

