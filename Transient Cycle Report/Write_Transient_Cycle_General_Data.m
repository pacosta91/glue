function Write_Transient_Cycle_General_Data(Excel, datastream, ModeNumber)
% Updates the General Data section in the Transient Cycle Report 
%
% Syntax:   
%   Called from Write_Transient_Cycle_Report.m       
%
% Inputs:
%   Excel - (obj) A handle to an Excel COM server's default interface
%   datastream - (obj) A SuperGlue Channels object
%   ModeNumber - (int) The current mode
%
% Outputs:
%   None. Updates the General Data section in the Excel object (see
%   above)
%   
% Example: 
%   Write_Transient_Cycle_General_Data(Excel, datastream, k);
%   (as called from Write_Transient_Cycle_Report.m)
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   The Excel and datastream inputs are objects which
%   contain many of their own methods utilized in the code below. For
%   example, isKey is a method of the MATLAB containers.Map class which is 
%   parent to the Channels class in SuperGlue, but their are numerous other
%   examples.

%
% MAT-files required: 
%   None
%
% See also: http://www.mathworks.com/help/matlab/ref/actxserver.html

% Author:           Eric Simon
% File Version:     2.0
% Revision History:   
% 1.0               Original file created by Jared Stewart.
% 1.1   09/22/2014  Added standard header. 
% 2.0   07/01/2015  Recoded to accommodate template changes. 

% =========================================================================

% Populate the General Data section. For the most part these are
% self-explanatory since the variable names are quite descriptive and the
% Excel template utilizes named ranges that are also descriptive.
set(Range(Excel,'Report_Title'),'Value',[datastream('Options').Test_Type ' Test Report']);
set(Range(Excel,'Test_Name'),'Value',datastream('Options').Test_Name);
set(Range(Excel,'Mode_Number'),'Value',ModeNumber);

set(Range(Excel,'Test_Date'),'Value',datastream('Options').Test_Start);
set(Range(Excel,'Test_Duration'),'Value',datastream('Options').Test_Duration);

set(Range(Excel,'Test_Cell'),'Value',datastream('Options').Test_Cell);
set(Range(Excel,'Technician'),'Value',datastream('Options').Test_Tech);

if datastream('Options').Cert_Test_Flag, Value = 'Yes'; else Value = 'No'; end
set(Range(Excel,'Certification_Test'),'Value',Value); 
if ModeNumber > 1, Value = 'Hot'; else Value = datastream('Options').Start_Type; end
set(Range(Excel,'Start'),'Value',Value);
set(Range(Excel,'Regen'),'Value',datastream('Options').DPF_Regen);

set(Range(Excel,'Intake_Air_Temp'),'Value',datastream('T_In_Air').ModeCompositeData(ModeNumber));
set(Range(Excel,'Absolute_Humidity'),'Value',datastream('Abs_Hum_CAir').ModeCompositeData(ModeNumber)/7); % grains/lb to g/kg
set(Range(Excel,'Barometric_Pressure'),'Value',datastream('P_SimBaro').ModeCompositeData(ModeNumber));

set(Range(Excel,'Customer'),'Value',datastream('Options').Customer);
set(Range(Excel,'Engine_ID'),'Value',datastream('Options').Engine_ID);

set(Range(Excel,'Engine_Hours'),'Value',datastream('Options').Start_Eng_Hrs);
set(Range(Excel,'Fuel'),'Value',datastream('Options').Fuel.Name);

% Decode the Aftertreatment_Configuration to determine each aftertreatment
hexString = num2str(dec2hex(datastream('Options').Aftertreatment_Configuration));

% Make sure the hexString length is 4 by adding the appropriate number of
% trailing zeros
while length(hexString) < 4, hexString = [hexString '0']; end 
if ~strcmp(hexString(1),'0'), Aftertreatment1 = AftertreatmentComponent(hexString(1)); else Aftertreatment1 = '-'; end
if ~strcmp(hexString(2),'0'), Aftertreatment2 = AftertreatmentComponent(hexString(2)); else Aftertreatment2 = '-'; end
if ~strcmp(hexString(3),'0'), Aftertreatment3 = AftertreatmentComponent(hexString(3)); else Aftertreatment3 = '-'; end
if ~strcmp(hexString(4),'0'), Aftertreatment4 = AftertreatmentComponent(hexString(4)); else Aftertreatment4 = '-'; end
set(Range(Excel,'Aftertreatment1'),'Value',Aftertreatment1);
set(Range(Excel,'Aftertreatment2'),'Value',Aftertreatment2);
set(Range(Excel,'Aftertreatment3'),'Value',Aftertreatment3);
set(Range(Excel,'Aftertreatment4'),'Value',Aftertreatment4);

% Get the name of the Playback File if applicable
 if ~strcmp(datastream('Options').('PlaybackFile'),'(n/a)')
    [~, Value, ext] = fileparts(datastream('Options').('PlaybackFile'));
    Value = [Value ext]; 
else
    Value = 'n/a';
end   
set(Range(Excel,'Playback_File'),'Value',Value);

set(Range(Excel,'Engine_Calibration'),'Value',datastream('Options').Engine_Calibration);

end