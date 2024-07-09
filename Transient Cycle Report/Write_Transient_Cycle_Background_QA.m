function Write_Transient_Cycle_Background_QA(Excel, filename, datastream, ModeSegregation, ModeNumber)
% Updates the Background Check section in the Transient Cycle Report 
%
% Syntax:   
%   Called from Write_Transient_Cycle_Report.m       
%
% Inputs:
%   Excel - (obj) A handle to an Excel COM server's default interface
%   filename (str) - The name of the file being processed
%   datastream - (obj) A SuperGlue Channels object
%   ModeSegregation - (obj) A SuperGlue Mode object
%   ModeNumber - (int) The current mode
%
% Outputs:
%   None. Updates the Background section in the Excel object (see
%   above)
%   
% Example: 
%   Write_Transient_Cycle_Background_QA(Excel, datastream, ModeSegregation, k);
%   (as called from Write_Transient_Cycle_Report.m)
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   The Excel, datastream, and ModeSegregation inputs are objects which
%   contain many of their own methods utilized in the code below. For
%   example, isKey is a method of the MATLAB containers.Map class which is 
%   parent to the Channels class in SuperGlue, but there are numerous other
%   examples.

%
% MAT-files required: 
%   None
%
% See also: http://www.mathworks.com/help/matlab/ref/actxserver.html

% Author:           Eric Simon
% File Version:     1.0
% Revision History:   
% 1.0               Original file based on concepts by NB.

% =========================================================================

species = {'CO2' 'CO_l' 'NOx' 'N2O' 'HC' 'HHC' 'CH4' 'NMHC' 'NOx_NMHC'};

for row = 1:length(species)
    specie = species{row};
    name = [specie '_Bag_Dilute'];
    
    % Set proper name
    if strcmp(specie,'HC'), if datastream('Options').Use_HC, name = 'HC_Bag_Dilute'; else name = 'HHC_Bag_Dilute'; end; end
       
    if isKey(datastream,name) || strcmp(name,'NOx_NMHC_Bag_Dilute')
        if ~ismember(specie, {'NMHC','NOx_NMHC'}), range = datastream(name).Ranges(ModeNumber); else range = -1; end
        if datastream('Options').Part_1065.IsOn

            % Set proper names
            if strcmp(specie,'HC'), if datastream('Options').Use_HC, name = 'HC_Bag_Dilute_Corrected'; else name = 'HHC_Bag_Dilute_Corrected'; end; end
            if strcmp(specie,'CH4'), name = 'CH4_Bag_Dilute_Corrected'; end
            
            % Set Pre- and Post-Test Ambient values according to Part 1065
            if strcmp(name,'NOx_NMHC_Bag_Dilute')
                PreTestAmbient = datastream('NOx_Bag_Dilute').Ambient.Part1065PreTest + datastream('NMHC_Bag_Dilute').Ambient.Part1065PreTest;
                PostTestAmbient = datastream('NOx_Bag_Dilute').Ambient.Part1065PostTest + datastream('NMHC_Bag_Dilute').Ambient.Part1065PostTest;
            else
                PreTestAmbient = datastream(name).Ambient.Part1065PreTest;
                PostTestAmbient = datastream(name).Ambient.Part1065PostTest;
            end
            
            set(Range(Excel,[specie '_Pretest_Ambient']),'Value',PreTestAmbient);
            set(Range(Excel,[specie '_Posttest_Ambient']),'Value',PostTestAmbient);  
            
        else
            
            % Set Pre- and Post-Test Ambient values according to Part 86
            if strcmp(name,'NOx_NMHC_Bag_Dilute')
                PreTestAmbient = datastream('NOx_Bag_Dilute').Ambient.Part86PreTest + datastream('NMHC_Bag_Dilute').Ambient.Part86PreTest;
                PostTestAmbient = datastream('NOx_Bag_Dilute').Ambient.Part86PostTest + datastream('NMHC_Bag_Dilute').Ambient.Part86PostTest;
            else
                PreTestAmbient = datastream(name).Ambient.Part86PreTest;
                PostTestAmbient = datastream(name).Ambient.Part86PostTest;
            end
            
            set(Range(Excel,[specie '_Pretest_Ambient']),'Value',PreTestAmbient);
            set(Range(Excel,[specie '_Posttest_Ambient']),'Value',PostTestAmbient);  
                 
        end
    end 
end