function datastream = ImportOptionsDB(TestNumber, datastream, ModeSegregation, automationMode)
%8/17/2011 options has devolved into the most confusing structure ever...

% Set the default value of automationMode to 0
if nargin == 3, automationMode = 0; end

% Error out if there is no data. Not sure this is the best place to do that
% but will do it for now.
% if isempty(datastream('Time').StreamingData)
%     ME = MException('MATLAB:NoDataExistsToBeProcessed', 'There is no streaming data to process for Test %d', TestNumber);
%     throw(ME);
% end

options = datastream('Options');

global LM SPECIES BENCHES FILENAME;

try %Connect to database - if database isn't available then have the user either quit out or select a fuel type
    NET.addAssembly('System.Data'); %this imports the library into MATLAB
    connString = 'DSN=ETRE';
    odbcCN = System.Data.Odbc.OdbcConnection(connString);
    odbcCN.Open(); % connects to the SQL Server (must have DSN)
catch %#ok<CTCH>
    LM.DebugPrint(1,'ALARM: MATLAB was unable to connect to the requested database');
    % ES added 9/21/2017
    % If running under AutoGlue we cannot pause execution. So instead we
    % will throw an error.
    if ~automationMode
        options = UnableToConnectToDatabase(datastream);
        datastream('Options') = options;
    else
        error('DBConnectionError', 'MATLAB was unable to connect to the requested database.');
    end
    return;
end

SQL1 = 'SELECT ';
SQL3ectd = [' FROM tblTestResults WHERE Test_Number = ' num2str(TestNumber)]; % Test number is supposed to be an integer so therefore this is valid.
SQL3eavt = [' * FROM tblVZS_Results WHERE Test_Number = ' num2str(TestNumber)];
SQL3brr = [' ProcedureID, Gas, Phase_Num, Range, RangeSize, ISNULL(AmbientConc, -999) AS AmbientConc ' ...
    'FROM Bag_Read_Details WHERE Test_Number = ' num2str(TestNumber) ...
    ' ORDER BY Gas, Range DESC, Phase_Num ASC'];
SQL3ebr = [' * FROM tblVZS_Results WHERE Test_Number = ' num2str(TestNumber) ' AND Bench ='];

options = ImportTestResultsTable(odbcCN, SQL1, SQL3ectd, TestNumber, options);
[datastream, options] = ImportVZSResultsTable(odbcCN, SQL1, SQL3eavt, SQL3brr, SQL3ebr, datastream, options, TestNumber);

% ES - Not sure why this is being done.
options.Tailpipe_CO_l_InUse = ones(1,ModeSegregation.nModes);
options.Engine_CO_l_InUse = zeros(1,ModeSegregation.nModes); %This pacifies some procedures used in the chemical balance
options.Bag_Dilute_CO_l_InUse = ones(1,ModeSegregation.nModes);

% ES - Let's try initializing the above based on whether or not they actually exist.
if datastream.isKey('CO_l_Bag_Dilute')
    options.Bag_Dilute_CO_l_InUse = ones(1,ModeSegregation.nModes);
else
    options.Bag_Dilute_CO_l_InUse = zeros(1,ModeSegregation.nModes);
end

if datastream.isKey('CO_l_Tailpipe')
    options.Tailpipe_CO_l_InUse = ones(1,ModeSegregation.nModes);
else
    options.Tailpipe_CO_l_InUse = zeros(1,ModeSegregation.nModes);
end

% ES 2/7/2017 - The old way of determining whether or not any ranges were
% active was by looking at datastream(AnalyzerName).VZS.keys. These keys
% represent the ranges used (zeroed and spanned) for the analyzer. Since
% the VZS table is used the same way as before this remains a valid check.
% The remaining code is used to determine which range was used for each
% mode.
for k = 1:length(SPECIES)
    for m = 1:length(BENCHES)
        AnalyzerName = [SPECIES{k} '_' BENCHES{m}];
        if datastream.isKey(AnalyzerName)
            tempChannel = datastream(AnalyzerName);
            tempChannel.Ranges = zeros(1,ModeSegregation.nModes);
            if isempty(cell2mat(datastream(AnalyzerName).VZS.keys))
                LM.DebugPrint(1,'The %s analyzer doesn''t seem to have any active ranges', AnalyzerName);
                datastream(AnalyzerName) = tempChannel;
                tempChannel.IsOn = 0;
                continue;
            end

            % ES 2/7/2017 - For the dilute bag bench analyzers, newer files
            % may include a channel describing the range at each point in
            % the streaming file. This data gets stored as an array in
            % datastream(AnalyzerName).StreamingData.Range. This is the
            % most accurate way to determine which range was used and in
            % cases when this array is non-empty it will be used to
            % determine which range was used for that datapoint. To keep
            % things consistent, we can use this same idea in cases when
            % these columns don't exist. In the past, ranges were
            % determined on a mode-by-mode basis in cases when ranges were
            % not locked. So we'll use this same logic (below) with the
            % only difference being that we'll use these results to
            % populate the datastream(AnalyzerName).StreamingData.Range
            % array in cases when the
            % datastream(AnalyzerName).StreamingData.Range is empty. This
            % will allow us to use this same array regardless of how it was
            % populated.

            % ---------------------------------------------------------
            % Ranges lockes
            % ---------------------------------------------------------

            % Have fun figuring this out - essentially you loop through
            % each range and try to determine if the maximum concentration
            % recorded is less than the range maximum concentration times
            % the range change level - if the technique fails then check if
            % this is a paired CO_l CO_h analyzer or if the maximum
            % concentration is underneath the ceiling of the final range
            % (not the wisest done, I know) otherwise the analyzer is
            % pegged and you need to set a message.
            if options.Bag_Dilute_Ranges_Locked
                VZS_keys = [];
                try
                    VZS_keys = cell2mat(tempChannel.VZS.keys);
                catch % do nothing
                end
                for p = 1:length(VZS_keys)
                    range = VZS_keys(p);
                    if max(tempChannel.StreamingData.Part86Concentration) < tempChannel.VZS(range).MaximumConcentration*options.Range_Change_Level
                        tempChannel.Ranges = range*ones(1,ModeSegregation.nModes);
                        break;
                    end                    
                end                
%                 for p = min(cell2mat(tempChannel.VZS.keys)):max(cell2mat(tempChannel.VZS.keys))
%                     if max(tempChannel.StreamingData.Part86Concentration) < tempChannel.VZS(p).MaximumConcentration*options.Range_Change_Level
%                         tempChannel.Ranges = p*ones(1,ModeSegregation.nModes);
%                         break;
%                     end
%                 end
                % ES - Check the range associated with the first mode. If
                % it's 0 that means none of the ranges were set above so we
                % check to see if the max concentration is less then the
                % maximum range (in this case p corresponds to the maximum
                % range since we will have finished the above loop without
                % success).
                if tempChannel.Ranges(1) == 0 && max(tempChannel.StreamingData.Part86Concentration) < tempChannel.VZS(range).MaximumConcentration
                    tempChannel.Ranges = range*ones(1,ModeSegregation.nModes);
                end
                % ES - We again check the range associated with the first
                % mode to see if they've been set. In this case we verify
                % the analyzier isn't CO_l and conclude that the analyzer
                % was pegged.
                if tempChannel.Ranges(1) == 0 && ~strcmp(SPECIES{k}, 'CO_l')
                    unitstring = 'ppm';
                    if strcmp(tempChannel.Current_Units,'%'), unitstring = 'pct'; end;
                    LM.DebugPrint(1,['The %s analyzer has been pegged;\n' ...
                        '   the maximum concentration of the analyzer was %5.1f %s and the peak concentration recorded was %5.1f %s'], ...
                        AnalyzerName, tempChannel.VZS(range).MaximumConcentration, unitstring, ...
                        max(tempChannel.StreamingData.Part86Concentration), unitstring);
                    tempChannel.Ranges = range*ones(1,ModeSegregation.nModes);
                % ES - If the range associated with the first mode isn't
                % set and the analayzer is CO_l and there is no CO_h
                % analayzer, we note the analyzer is pegged. If CO_h does
                % exist, set *_CO_l_InUse to 0 for every mode.
                elseif tempChannel.Ranges(1) == 0 && strcmp(SPECIES{k}, 'CO_l')
                    unitstring = 'ppm';
                    if strcmp(tempChannel.Current_Units,'%'), unitstring = 'pct'; end;
                    if ~datastream.isKey(['CO_h_' BENCHES{m}]) % No CO_h analyzer exists; peg analyzer
                        LM.DebugPrint(1,['The %s analyzer has been pegged;\n' ...
                            '   the maximum concentration of the analyzer was %5.1f %s and the peak concentration recorded was %5.1f %s'], ...
                            AnalyzerName, tempChannel.VZS(range).MaximumConcentration, unitstring, ...
                            max(tempChannel.StreamingData.Part86Concentration), unitstring);
                        tempChannel.Ranges = range*ones(1,ModeSegregation.nModes);
                    else
                        tempChannel.Ranges = range*ones(1,ModeSegregation.nModes);
                        options.([BENCHES{m} '_CO_l_InUse']) = zeros(1,ModeSegregation.nModes);
                    end
                end

            % -----------------------------------------------------
            % Ranges not locked
            % -----------------------------------------------------

            else
                for n = 1:ModeSegregation.nModes
                    VZS_keys = [];
                    try
                        VZS_keys = cell2mat(tempChannel.VZS.keys);
                    catch % do nothing
                    end

                    for p = 1:length(VZS_keys)
                        range = VZS_keys(p);
                        if max(tempChannel.StreamingData.Part86Concentration(ModeSegregation.getModeIndices(n)==1)) ...
                                < tempChannel.VZS(range).MaximumConcentration*options.Range_Change_Level
                            tempChannel.Ranges(n) = range;
                            break;
                        end                     

%                         for p = min(cell2mat(tempChannel.VZS.keys)):max(cell2mat(tempChannel.VZS.keys))
%                             if max(tempChannel.StreamingData.Part86Concentration(ModeSegregation.getModeIndices(n)==1)) ...
%                                     < tempChannel.VZS(p).MaximumConcentration*options.Range_Change_Level
%                                 tempChannel.Ranges(n) = p;
%                                 break;
%                             end
%                         end

                        if tempChannel.Ranges(n) == 0 && max(tempChannel.StreamingData.Part86Concentration(ModeSegregation.getModeIndices(n)==1)) ...
                            < tempChannel.VZS(range).MaximumConcentration
                                tempChannel.Ranges(n) = range;
                        end

                        if tempChannel.Ranges(n) == 0 && ~strcmp(SPECIES{k}, 'CO_l')
                            unitstring = 'ppm';
                            if strcmp(tempChannel.Current_Units,'%'), unitstring = 'pct'; end;
                            LM.DebugPrint(1,['The %s analyzer has been pegged for Mode %i;' ...
                                '   the maximum concentration of the analyzer was %5.1f %s and the peak concentration recorded was %5.1f %s'], ...
                                AnalyzerName, n, tempChannel.VZS(range).MaximumConcentration, unitstring, ...
                                max(tempChannel.StreamingData.Part86Concentration(ModeSegregation.getModeIndices(n)==1)), unitstring);
                            tempChannel.Ranges(n) = range;
                        elseif tempChannel.Ranges(n) == 0 && strcmp(SPECIES{k}, 'CO_l')
                            unitstring = 'ppm';
                            if strcmp(tempChannel.Current_Units,'%'), unitstring = 'pct'; end;
                            if ~datastream.isKey(['CO_h_' BENCHES{m}])
                                LM.DebugPrint(1,['The %s analyzer has been pegged for Mode %i;' ...
                                    '   the maximum concentration of the analyzer was %5.1f %s and the peak concentration recorded was %5.1f %s'], ...
                                    AnalyzerName, n, tempChannel.VZS(range).MaximumConcentration, unitstring, ...
                                    max(tempChannel.StreamingData.Part86Concentration(ModeSegregation.getModeIndices(n)==1)), unitstring);
                                tempChannel.Ranges(n) = range;
                            else
                                tempChannel.Ranges(n) = range;
                                options.([BENCHES{m} '_CO_l_InUse'])(n) = 0;
                            end
                        end
                    end
                end
            end

            % At this point we should have tempChannel.Ranges set for
            % each mode. So we'll use these to set the range at each
            % point in the streaming data.

            % Check to see if the point-by-point range array is already
            % populated with ranges and if not, use the old logic to
            % populate it.
            if isempty(datastream(AnalyzerName).StreamingData.Range)
                for i = 1:length(tempChannel.Ranges)
                    tempChannel.StreamingData.Range(ModeSegregation.getModeIndices(i)==1) = tempChannel.Ranges(i);
                end
            else
                % Values read from the database are 1 less than the range
                % used by SuperGlue.
                tempChannel.StreamingData.Range = datastream(AnalyzerName).StreamingData.Range + 1;
            end

        end % if datastream.isKey(AnalyzerName)
    end % for m = 1:length(BENCHES)
end % for k = 1:length(SPECIES)

try
    options.Fuel.alpha = 11.9164*options.Fuel.w_H/options.Fuel.w_C;
    options.Fuel.beta = 0.75072*options.Fuel.w_O/options.Fuel.w_C;
    options.Fuel.gamma = 0.37464*options.Fuel.w_S/options.Fuel.w_C;
    options.Fuel.delta = 0.85752*options.Fuel.w_N/options.Fuel.w_C;
    options.Molar_Mass.HC = (12.0107+options.Fuel.alpha*1.01+options.Fuel.beta*15.9994+options.Fuel.gamma*32.065+options.Fuel.delta*14.0067);
catch
end

options.Molar_Mass.CO = 28.0101;
options.Molar_Mass.CO2 = 44.0095;
options.Molar_Mass.NOx = 46.0055;
options.Molar_Mass.CH4 = 16.04;
options.Molar_Mass.O2 = 31.9989;
options.Molar_Mass.N2O = 44.01280; % ES added
options.Molar_Mass.HNOx = 46.0055;
if isempty(datastream('Time').StreamingData)
    error('The time vector is empty.');
    return
end
options.delta_T = getTimeInterval(datastream('Time').StreamingData);
% options.delta_T = datastream('Time').StreamingData(20) - datastream('Time').StreamingData(19);

if strcmp(options.Part_1065.CO2_dil, 'Ambient') && datastream.isKey('CO2_Bag_Dilute')
    if isfield(datastream('CO2_Bag_Dilute').Ambient, 'BagConc') && any(datastream('CO2_Bag_Dilute').Ambient.BagConc) ~= -999
        % Here we use the mean concentration and not by range!!! Probably
        % should be by range!!! Probably not right!!!
        options.Part_1065.CO2_dil = mean(datastream('CO2_Bag_Dilute').Ambient.BagConc / 100); % Expecting mol/mol not percent
    elseif isfield(datastream('CO2_Bag_Dilute').Ambient, 'Part1065Average') && isfield(datastream('CO2_Bag_Dilute').Ambient, 'Part86Average')
        if options.Part_1065.DriftCorrection
            options.Part_1065.CO2_dil = datastream('CO2_Bag_Dilute').Ambient.Part1065Average/100; % Expecting mol/mol not percent
        else
            options.Part_1065.CO2_dil = datastream('CO2_Bag_Dilute').Ambient.Part86Average/100; % Expecting mol/mol not percent
        end
    else
        LM.DebugPrint(1, 'WARNING: Failed to find an Ambient Measurement, 1065 Calculations have been turned off')
        options.Part_1065.IsOn = 0;
    end
end

if strcmp(options.Part_1065.CO2_int, 'Ambient') && datastream.isKey('CO2_Bag_Dilute')
    if isfield(datastream('CO2_Bag_Dilute').Ambient, 'BagConc') && an0y(datastream('CO2_Bag_Dilute').Ambient.BagConc) ~= -999
        % Here we use the mean concentration and not by range!!! Probably
        % should be by range!!! Probably not right!!!
        options.Part_1065.CO2_int = mean(datastream('CO2_Bag_Dilute').Ambient.BagConc / 100); % Expecting mol/mol not percen
    elseif isfield(datastream('CO2_Bag_Dilute').Ambient, 'Part1065Average') && isfield(datastream('CO2_Bag_Dilute').Ambient, 'Part86Average')
        if options.Part_1065.DriftCorrection && isfield(datastream('CO2_Bag_Dilute').Ambient, 'Part1065Average')
            options.Part_1065.CO2_int = datastream('CO2_Bag_Dilute').Ambient.Part1065Average/100; % Expecting mol/mol not percent
        else
            options.Part_1065.CO2_int = datastream('CO2_Bag_Dilute').Ambient.Part86Average/100; % Expecting mol/mol not percent
        end
    else
        LM.DebugPrint(1, 'WARNING: Failed to find an Ambient Measurement, 1065 Calculations have been turned off')
        options.Part_1065.IsOn = 0;
    end
end

if isfield(options,'Test_Type') && any(strcmp_multiple({'SET','8M','13M','ESC'}, options.Test_Type))
    if isfield(options,'ModalWeighting') && isfield(options.ModalWeighting,['Type_' options.Test_Type])
        ModalWeights = options.ModalWeighting.(['Type_' options.Test_Type])';
    else
        ModalWeights = [];
    end
    if min((datastream('Time').ModeCompositeData)) ~= max((datastream('Time').ModeCompositeData))
        LM.DebugPrint(1,'The times vary from mode to mode - any modal weighting factors will be neglected; if you are prompted to input modal weights because the number of modes is different it is likely that you have a void mode(s), if this is the case give that mode a weighting factor of zero');
    end
    while length(ModalWeights) ~= ModeSegregation.nModes
        LM.DebugPrint(1,'WARNING: The number of modal weights is different than the number of modes in this test');

        if automationMode == 1 % AutoGlue is running
            if length(ModalWeights) > ModeSegregation.nModes
                LM.DebugPrint(1,'WARNING: Only the first %d modal weights were used for the purpose of this test', ModeSegregation.nModes);
                ModalWeights = ModalWeights(1:ModeSegregation.nModes);
            elseif length(ModalWeights) < ModeSegregation.nModes
                LM.DebugPrint(1,'WARNING: Only the first %d modal weights were specified; the other %d were set to 1 for the purpose of this test', length(ModalWeights), ModeSegregation.nModes - length(ModalWeights));
                ModalWeights = [ModalWeights; ones(ModeSegregation.nModes - length(ModalWeights),1)];
            else
                LM.DebugPrint(1,'WARNING: The modal weights were automatically set to 1 for the purpose of this test');
                ModalWeights = ones(ModeSegregation.nModes, 1);
            end

        else % Manual execution
            ModalWeights = input(sprintf('Please enter weights for %i modes separated by all commas and no spaces or all spaces and no commas\n', ModeSegregation.nModes), 's');
            if instr(ModalWeights, ',')
                delimiter = ',';
            else
                delimiter = ' ';
            end
            ModalWeights = stringread(ModalWeights, delimiter);
            ModalWeights = cell2mat(ModalWeights)'; %This is an odd bug here - from time to time MATLAB decides to execute cell2mat before finishing stringread... by separating the commands this is prevented
        end
    end
    if min((datastream('Time').ModeCompositeData)) ~= max((datastream('Time').ModeCompositeData))
        ModalWeights = (ModalWeights ~= 0);
    end
    datastream('Modal_Weights') = Miscellaneous_Channel(datastream, 'Modal_Weights', 'Miscellaneous', '', ModalWeights, length(datastream)+1);
end

options.Test_Name = strtok(FILENAME,'.');

datastream('Options') = options;
