function options = ImportTestResultsTable(odbcCN,  SQL1, SQL3ectd, TestNumber, options)

global LM;

% CODES
% 1: Numeric
% 2: String
% 3: Date/Time
% 4: Date/Time Calculation
% 5: Test Cell ID

% OptionList - datastream Name, Process Utility, database field
OptionList = {'Test_Start'                      3   'Test_Start_Date_Time';
              'Test_End'                        3	'Test_End_Date_Time';
              'Test_Duration'                   4	'-';
              'Test_Cell'                       5   'Test_Cell_ID';
              'Start_Eng_Hrs'                   1	'Start_Eng_Hours';
              'Test_Tech'                       2	'Technician';
              'Customer'                        2   'Customer';
              'Engine_ID'                       2   'Engine_ID';
              'SP_P_SimBaro'                    1	'Sim_Baro_Setpt';
              'SP_T_In_Air'                     1	'Intake_Air_Setpt';
              'Particulate_On'                  2	'Include_Particulate';
              'DPF_On'                          2	'DPF_On';
              'DPF_Regen'                       2	'DPF_Regen';
              'Start_Type'                      2	'Start_Type';
              'Engine_Calibration'              2	'Engine_Calibration';
              'PreTest_Comment'                 2	'TestNotes';
              'PostTest_Comment'                2	'Test_Problems';
              'Test_Type'                       2   'Test_Type';
              'Sample_Configuration'            1	'Sample_Configuration';
              'Aftertreatment_Configuration'	1	'Aftertreatement';
              'Fuel.Specific_Gravity'           1	'spgr';
              'Fuel.Lower_Heating_Value'        1	'lhv';
              'Fuel.Name'                       2	'Fuel';
              'Fuel.w_C'                        1	'c_wf';
              'Fuel.w_H'                        1	'h_wf';
              'Fuel.w_O'                        1	'o_wf';
              'Fuel.w_S'                        1	's_wf';
              'Fuel.w_N'                        1	'n_wf';
              'REPS_Setup_File'                 2	'REPS_Setup_File';
              'Cert_Test_Flag'                  1	'Cert_Test';
              'Engine_Bench_Sample_Position'    1	'SampPos_EngBench';
              'Mid_Bench_Sample_Position'       1	'SampPos_MidBench';
              'Flex_Bench_Sample_Position'      1	'SampPos_FlexBench';
              'Tailpipe_Bench_Sample_Position'  1   'SampPos_TPBench';
              'Smoke_Meter_Sample_Position'     1	'SampPos_SmokeMeter';
              'MSS_Sample_Position'             1	'SampPos_MSS';
              'FTIR_Sample_Position'            1	'SampPos_FTIR';
              'Void_Flag'                       1   'TestResult'
              'ProfileFile'                     2   'ProfileFile'
              'PlaybackFile'                    2   'PlaybackFile'
              'ECCS_Ver'                        2   'EccsVersion'};
          

% Complete command
for k = 1:length(OptionList)
    try
        switch OptionList{k,2}
            case 1 %Numeric Value
                sql = [SQL1 OptionList{k,3} SQL3ectd]; % This makes sense, but have a map which switches from database name to preferred name
                odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
                res = odbcCOM.ExecuteReader();
                % Read returned values
                count = 0;
                while (res.Read())
                    count = count+1;
                    if ~isempty(strfind(OptionList{k,1},'.')) % If we want segregated values
                        [Heading, SubHeading] = strtok(OptionList{k,1},'.');
                        SubHeading = right(SubHeading,length(SubHeading)-1);
                        options.(Heading).(SubHeading) = double(res.GetValue(0));
                    else
                        options.(OptionList{k,1}) = double(res.GetValue(0)); % converts every value to standard double
                    end
                end
                if count == 0
                    LM.DebugPrint(1, 'ALARM: No records were detected for Test Number %i, ''%s''', TestNumber, OptionList{k,1});
                elseif count > 1
                    LM.DebugPrint(1, 'ALARM: Multiple records were detected for Test Number %i, the last record found will be used', TestNumber);
                end
                res.Close; % This prevents the communications with the database from failing and causing errors
            case 2 %String Value
                sql = [SQL1 OptionList{k,3} SQL3ectd]; % This makes sense, but have a map which switches from database name to preferred name
                odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
                res = odbcCOM.ExecuteReader();
                % Read returned values
                count = 0;
                while (res.Read())
                    count = count+1;
                    if ~isempty(strfind(OptionList{k,1},'.')) % If we want segregated values
                        [Heading, SubHeading] = strtok(OptionList{k,1},'.');
                        SubHeading = right(SubHeading,length(SubHeading)-1);
                        options.(Heading).(SubHeading) = char(res.GetValue(0));
                    else
                        options.(OptionList{k,1}) = char(res.GetValue(0)); % converts every value to standard double
                    end
                end
                if count == 0
                    LM.DebugPrint(1, 'ALARM: No records were detected for Test Number %i, ''%s''', TestNumber, OptionList{k,1});
                elseif count > 1
                    LM.DebugPrint(1, 'ALARM: Multiple records were detected for Test Number %i, the last record found will be used', TestNumber);
                end
                res.Close; % This prevents the communications with the database from failing and causing errors
            case 3 %DateTime Value
                sql = [SQL1 OptionList{k,3} SQL3ectd]; % This makes sense, but have a map which switches from database name to preferred name
                odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
                res = odbcCOM.ExecuteReader();
                % Read returned values
                count = 0;
                while (res.Read())
                    count = count+1;
                    dvec(1) = double(res.GetValue(0).Year);
                    dvec(2) = double(res.GetValue(0).Month);
                    dvec(3) = double(res.GetValue(0).Day);
                    dvec(4) = double(res.GetValue(0).Hour);
                    dvec(5) = double(res.GetValue(0).Minute);
                    dvec(6) = double(res.GetValue(0).Second);
                    options.(OptionList{k,1}) = datestr(dvec);
                end
                if count == 0
                    LM.DebugPrint(1, 'ALARM: No records were detected for Test Number %i, ''%s''', TestNumber, OptionList{k,1});
                elseif count > 1
                    LM.DebugPrint(1, 'ALARM: Multiple records were detected for Test Number %i, the last record found will be used', TestNumber);
                end
                res.Close; % This prevents the communications with the database from failing and causing errors
            case 4 %DateTime Calculation
                switch OptionList{k,1}
                    case 'Test_Duration'
                        options.(OptionList{k,1}) = sec2timestr((datenum(options.Test_End)-datenum(options.Test_Start))*24*3600);
                end
            case 5 %TestCell Expansion
                sql = [SQL1 OptionList{k,3} SQL3ectd]; % This makes sense, but have a map which switches from database name to preferred name
                odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
                res = odbcCOM.ExecuteReader();
                res.Read();
                try
                    dbCellID = char(res.GetValue(0));
                catch %#ok % I have no faith that the cell ID will return as a System.String type 
                    dbCellID = double(res.GetValue(0));
                    dbCellID = num2str(dbCellID);
                end
                switch dbCellID
                    case 'W1', cell = 'EW1';
                    case 'W2', cell = 'EW2';
                    case 'W3', cell = 'EW3';
                    case 'W4', cell = 'EW4';
                    case 'W5', cell = 'EW5';
                    case 'E1', cell = 'OE1';
                    case 'E2', cell = 'OE2';
                end
                options.(OptionList{k,1}) = cell;
                res.Close();
        end
    catch %#ok - should only come into play when there is a DBNull item amongst the regulars
        LM.DebugPrint(1,'WARNING: An irregularity was detected in the data coming from the database for the input %s',OptionList{k,1})
        res.Close;
    end
end