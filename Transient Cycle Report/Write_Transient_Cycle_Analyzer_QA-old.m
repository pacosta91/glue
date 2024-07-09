function Write_Transient_Cycle_Analyzer_QA(Excel, filename, datastream, ModeSegregation, ModeNumber)
% Updates the Analyzer Check section in the Transient Cycle Report 
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
%   None. Updates the Analyzer Check section in the Excel object (see
%   above)
%   
% Example: 
%   Write_Transient_Cycle_Analyzer_QA(Excel, datastream, ModeSegregation, k);
%   (as called from Write_Transient_Cycle_Report.m)
%
% Other m-files required: 
%   None
%
% Subfunctions: 
%   The Excel, datastream, and ModeSegregation inputs are objects which
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
% File Version:     1.1
% Revision History:   
% 1.0               Original file created by Jared Stewart.
% 1.1   09/19/2014  Added standard header.  
% 2.0   07/01/2015  Recoded to accommodate template changes.

% =========================================================================

% Grab the engine number 
temp = stringread(filename, '_');
engineID = temp{2};
testnumber = temp{4};

% Initialize the analyzer cell arrays
Analyzer = {}; PPM_or_Pct = {}; PreTest_Zero = {}; PreTest_Span = {};
PostTest_Zero = {}; PostTest_Span = {}; MaxConc = {}; ZeroDriftPct = {};
SpanDriftPct = {};

% Initialize FEL limits from database
PM = 0; NOx = 0; NMHC = 0; NOx_NMHC = 0; CO = 0;
    
try
    NET.addAssembly('System.Data'); %this imports the library into MATLAB
    connString = 'DSN=ETRE';
    odbcCN = System.Data.Odbc.OdbcConnection(connString);
    odbcCN.Open(); % connects to the SQL Server (must have DSN) - if no DSN give some barebones values
    
    % Grab the dilute bench test results
    stmt = ['SELECT ISNULL(Analyzer, ''-'') AS Analyzer, ISNULL(PPM_or_Pct, -999) AS PPM_or_Pct, ' ...
        'ISNULL(PreTest_Zero, -999) AS PreTest_Zero, ISNULL(PreTest_Span, -999) AS PreTest_Span, ' ...
        'ISNULL(PostTest_Zero, -999) AS PostTest_Zero, ISNULL(PostTest_Span, -999) AS PostTest_Span, ' ...
        'ISNULL(MaxConc, -999) AS MaxConc, ISNULL(SpanConc, -999) AS SpanConc, ' ...
        'ISNULL(ZeroDriftPct, -999) AS ZeroDriftPct, ISNULL(SpanDriftPct, -999) AS SpanDriftPct, ' ...
        'ISNULL(Range, -999) AS Range FROM tblVZS_Results WHERE Bench = 0 AND Test_Number = ''%s'''];
    sql = sprintf(stmt, num2str(testnumber));
    odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
    res = odbcCOM.ExecuteReader();    
    while (res.Read())
        Analyzer = [Analyzer strtrim(char(res.GetValue(0)))];
        PPM_or_Pct = [PPM_or_Pct strtrim(char(res.GetValue(1)))];
        PreTest_Zero = [PreTest_Zero res.GetValue(2)];
        PreTest_Span = [PreTest_Span res.GetValue(3)];
        PostTest_Zero = [PostTest_Zero res.GetValue(4)];
        PostTest_Span = [PostTest_Span res.GetValue(5)];
        MaxConc = [MaxConc res.GetValue(6)];
        ZeroDriftPct = [ZeroDriftPct res.GetValue(8)];
        SpanDriftPct = [SpanDriftPct res.GetValue(9)];
    end      

    % Now use the engine number to pull the FEL limits from the ETRE database.   
    % Grab a single row; assumes Test_Number is unique 
    sql = sprintf('SELECT b.PM, b.NOx, b.NMHC, b.NOx_NMHC, b.CO FROM engine AS a, tblFEL AS b WHERE (a.FEL = b.FEL_Name OR a.FEL = b.FEL_Code) AND a.control = ''%s''',num2str(engineID));   
    odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
    res = odbcCOM.ExecuteReader();
    res.Read();    
    if res.FieldCount == 5,
        if ~isa(res.GetValue(0),'System.DBNull'), PM = double(res.GetValue(0)); end  
        if ~isa(res.GetValue(1),'System.DBNull'), NOx = double(res.GetValue(1)); end
        if ~isa(res.GetValue(2),'System.DBNull'), NMHC = double(res.GetValue(2)); end
        if ~isa(res.GetValue(3),'System.DBNull'), NOx_NMHC = double(res.GetValue(3)); end
        if ~isa(res.GetValue(4),'System.DBNull'), CO = double(res.GetValue(4)); end
    end
    
    res.Close();
    
catch %#ok
    try
        res.Close();
    catch %#ok
    end
end

species = {'CO2' 'CO_l' 'NOx' 'N2O' 'HC' 'CH4' 'NMHC' 'NOx_NMHC'};
species_FEL = [0 CO NOx 0 0 0 NMHC NOx_NMHC];
Analyzer(find(ismember(Analyzer,'CO(l)'))) = {'CO_l'};

for row = 1:length(species)
    specie = species{row};
    name = [specie '_Bag_Dilute'];
    name_FEL = [specie '_Analyzer_FEL'];    
        
    % Set FEL limit
    set(Range(Excel,name_FEL),'Value',species_FEL(row));  
   
    % Set proper name
    if strcmp(specie,'HC'), if datastream('Options').Use_HC, name = 'HC_Bag_Dilute'; else name = 'HHC_Bag_Dilute'; end; end
    
    % Fill in the pre- and post-test zero and span values
    idx = find(ismember(Analyzer,specie));
    
    if length(idx) > 1
        % This usually means the more than one range was used
        Excel.Range([specie '_Analyzer_Msg']).MergeCells = true;
        set(Range(Excel,[specie '_Analyzer_Msg']),'Value','Contains more than one entry the database!');
        analyzer_check = false; continue;       
    elseif isempty(idx) % length(idx) == 0
        % No data    
    else        
        if PreTest_Zero{idx} ~= -999, set(Range(Excel,[specie '_Analyzer_Pretest_Zero']),'Value',PreTest_Zero{idx}); end
        if PreTest_Span{idx} ~= -999, set(Range(Excel,[specie '_Analyzer_Pretest_Span']),'Value',PreTest_Span{idx}); end
        if PostTest_Zero{idx} ~= -999, set(Range(Excel,[specie '_Analyzer_Posttest_Zero']),'Value',PostTest_Zero{idx}); end
        if PostTest_Span{idx} ~= -999, set(Range(Excel,[specie '_Analyzer_Posttest_Span']),'Value',PostTest_Span{idx}); end
    end
    
    if isKey(datastream,name)
        
        if ~strcmp(specie,'NMHC'), range = datastream(name).Ranges(ModeNumber); else range = -1; end
        
        if datastream('Options').Part_1065.IsOn
           % Set the Range 
            if ~strcmp(specie,'NMHC') && range ~= -1, set(Range(Excel,[specie '_Analyzer_Range']),'Value',datastream(name).VZS(range).MaximumConcentration); end
           
            % Set proper names
            if strcmp(specie,'HC'), if datastream('Options').Use_HC, name = 'HC_Bag_Dilute_Corrected'; else name = 'HHC_Bag_Dilute_Corrected'; end; end
            if strcmp(specie,'CH4'), name = 'CH4_Bag_Dilute_Corrected'; end
            
            % Set the Maximum and Average Concentration according to Part 1065
            if ModeSegregation.nModes >= ModeNumber
                set(Range(Excel,[specie '_Analyzer_Peak_Conc']),'Value',max(datastream(name).StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(ModeNumber)==1)));
                set(Range(Excel,[specie '_Analyzer_Avg_Conc']),'Value',mean(datastream(name).StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(ModeNumber)==1)));
            end
            
            % Set the Drift Percent according to Part 1065. Note that the
            % BrakeSpecificMass is the raw value or measured (true) value
            if ~isnan((datastream(name).ModeCompositeData.Part1065BrakeSpecificMass(ModeNumber) - ...
                datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber))/datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber)),            
                set(Range(Excel,[specie '_Analyzer_Drift_Pct']),'Value',(datastream(name).ModeCompositeData.Part1065BrakeSpecificMass(ModeNumber) - ...
                    datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber))/datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber)); 
            else 
                set(Range(Excel,[specie '_Analyzer_Drift_Pct']),'Value','NaN');
            end
            
            % Compare the Drift to the applicable emissions standard (FEL)
            % if it exists
            if species_FEL(row) ~= 0 && ~isnan((datastream(name).ModeCompositeData.Part1065BrakeSpecificMass(ModeNumber) - ...
                datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber))/species_FEL(row)),
                    set(Range(Excel,[specie '_Analyzer_Drift_Pct_FEL']),'Value',(datastream(name).ModeCompositeData.Part1065BrakeSpecificMass(ModeNumber) - ...
                        datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber))/species_FEL(row)); 
            elseif species_FEL(row) ~= 0,
                set(Range(Excel,[specie '_Analyzer_Drift_Pct_FEL']),'Value','NaN');
            else 
                % Remove conditional formatting for the Drift% if no FEL exists
                % REVISIT!!! Excel.Range(sprintf('%s',['P' num2str(row)])).FormatConditions.Delete
            end                

        else
            % Set the Range according to Part 86
            if range ~= -1
                set(Range(Excel,[specie '_Analyzer_Range']),'Value',datastream(name).VZS(range).MaximumConcentration);
            end
            
            % Set the Maximum and Average Concentration according to Part 86
            if ModeSegregation.nModes >= ModeNumber
                set(Range(Excel,[specie '_Analyzer_Peak_Conc']),'Value',max(datastream(name).StreamingData.Part86Concentration(ModeSegregation.getModeIndices(ModeNumber)==1)));
                set(Range(Excel,[specie '_Analyzer_Avg_Conc']),'Value',mean(datastream(name).StreamingData.Part86Concentration(ModeSegregation.getModeIndices(ModeNumber)==1)));
            end
            
            % Set the Drift Percent according to Part 86
            if ~isnan((datastream(name).ModeCompositeData.Part86BrakeSpecificMass(ModeNumber) - ...
                datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber))/datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber)),            
                set(Range(Excel,[specie '_Analyzer_Drift_Pct']),'Value',(datastream(name).ModeCompositeData.Part86BrakeSpecificMass(ModeNumber) - ...
                    datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber))/datastream(name).ModeCompositeData.BrakeSpecificMass(ModeNumber));
            else
                set(Range(Excel,[specie '_Analyzer_Drift_Pct']),'Value','NaN');
            end             
            
        end % end if datastream('Options').Part_1065.IsOn
        
    else
        % Deal with NOx + NMHC. We won't set a range or report on pre- or
        % post-test zeros and spans. We'll only report the peak
        % concentration, avg. concentration, drift%, and drift% with
        % respect to the FEL.
        if datastream('Options').Part_1065.IsOn % Part 1065
            
            % Set Peak and Avg Concentration values for NOx + NMHC according to Part 1065
            if ModeSegregation.nModes >= ModeNumber
                NOx_NMHC_Analyzer_Peak_Conc = max(datastream('NOx_Bag_Dilute').StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(ModeNumber)==1) + ...
                    datastream('NMHC_Bag_Dilute').StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(ModeNumber)==1));
                NOx_NMHC_Analyzer_Avg_Conc = mean(datastream('NOx_Bag_Dilute').StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(ModeNumber)==1) + ...
                    datastream('NMHC_Bag_Dilute').StreamingData.Part1065Concentration(ModeSegregation.getModeIndices(ModeNumber)==1));                   
                set(Range(Excel,'NOx_NMHC_Analyzer_Peak_Conc'),'Value',NOx_NMHC_Analyzer_Peak_Conc);
                set(Range(Excel,'NOx_NMHC_Analyzer_Avg_Conc'),'Value',NOx_NMHC_Analyzer_Avg_Conc);
            end   
            
            % Set the Drift Percent according to Part 1065
            NOx_NMHC_1065_BSM = (datastream('NOx_Bag_Dilute').ModeCompositeData.Part1065BrakeSpecificMass(ModeNumber) + ...
                datastream('NMHC_Bag_Dilute').ModeCompositeData.Part1065BrakeSpecificMass(ModeNumber));
            NOx_NMHC_uncorrected_BSM = (datastream('NOx_Bag_Dilute').ModeCompositeData.BrakeSpecificMass(ModeNumber) + ...
                datastream('NMHC_Bag_Dilute').ModeCompositeData.BrakeSpecificMass(ModeNumber));            
            NOx_NMHC_1065_Drift = (NOx_NMHC_1065_BSM - NOx_NMHC_uncorrected_BSM) / NOx_NMHC_uncorrected_BSM;
            if ~isnan(NOx_NMHC_1065_Drift)
                set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct'),'Value',NOx_NMHC_1065_Drift);
            else
                set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct'),'Value','NaN');
            end
                       
            % Compare the Drift to the applicable emissions standard (FEL)
            % if it exists
            if species_FEL(row) ~= 0                        
                NOx_NMHC_1065_Drift_FEL = (NOx_NMHC_1065_BSM - NOx_NMHC_uncorrected_BSM) / species_FEL(row);  
                if ~isnan(NOx_NMHC_1065_Drift_FEL)
                    set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct_FEL'),'Value',NOx_NMHC_1065_Drift_FEL);
                else
                    set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct_FEL'),'Value','NaN');
                end                
            end   
             
        else % Part 86
           
            % Set Peak and Avg Concentration values for NOx + NMHC
            % according to Part 86
            if ModeSegregation.nModes >= ModeNumber
                NOx_NMHC_Analyzer_Peak_Conc = max(datastream('NOx_Bag_Dilute').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(ModeNumber)==1) + ...
                    datastream('NMHC_Bag_Dilute').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(ModeNumber)==1));
                NOx_NMHC_Analyzer_Avg_Conc = mean(datastream('NOx_Bag_Dilute').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(ModeNumber)==1) + ...
                    datastream('NMHC_Bag_Dilute').StreamingData.Part86Concentration(ModeSegregation.getModeIndices(ModeNumber)==1));                   
                set(Range(Excel,'NOx_NMHC_Analyzer_Peak_Conc'),'Value',NOx_NMHC_Analyzer_Peak_Conc);
                set(Range(Excel,'NOx_NMHC_Analyzer_Avg_Conc'),'Value',NOx_NMHC_Analyzer_Avg_Conc);
            end   
            
            % Set the Drift Percent according to Part 86
            NOx_NMHC_86_BSM = (datastream('NOx_Bag_Dilute').ModeCompositeData.Part86BrakeSpecificMass(ModeNumber) + ...
                datastream('NMHC_Bag_Dilute').ModeCompositeData.Part86BrakeSpecificMass(ModeNumber));
            NOx_NMHC_uncorrected_BSM = (datastream('NOx_Bag_Dilute').ModeCompositeData.BrakeSpecificMass(ModeNumber) + ...
                datastream('NMHC_Bag_Dilute').ModeCompositeData.BrakeSpecificMass(ModeNumber));            
            NOx_NMHC_86_Drift = (NOx_NMHC_86_BSM - NOx_NMHC_uncorrected_BSM) / NOx_NMHC_uncorrected_BSM;
            if ~isnan(NOx_NMHC_86_Drift)
                set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct'),'Value',NOx_NMHC_86_Drift);
            else
                set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct'),'Value','NaN');
            end
                       
            % Compare the Drift to the applicable emissions standard (FEL)
            % if it exists
            if species_FEL(row) ~= 0                        
                NOx_NMHC_86_Drift_FEL = (NOx_NMHC_86_BSM - NOx_NMHC_uncorrected_BSM) / species_FEL(row);  
                if ~isnan(NOx_NMHC_86_Drift_FEL)
                    set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct_FEL'),'Value',NOx_NMHC_86_Drift_FEL);
                else
                    set(Range(Excel,'NOx_NMHC_Analyzer_Drift_Pct_FEL'),'Value','NaN');
                end                
            end               
            
        end % end if isKey(datastream,name)
        
    end
        
end 