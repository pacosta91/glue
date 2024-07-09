function [datastream, options] = ImportVZSResultsTable(odbcCN, SQL1, SQL3eavt, SQL3ebr, datastream, options, testnumber)
% Imports the VZS Results Table from the database, also responsible for correcting ambient measurements for drift, HC initial contamination, and HC
% penetration/response factors

global LM;

% Set the default value of testnumber to 0 
if nargin == 6, testnumber = 0; end

% This cell array includes the column name and number.
VZSPhrasing = {1 'MaximumConcentration'       5;
               1 'ReferenceConcentration'     6;
               1 'RawPreTestZero'             8;
               1 'RawPreTestSpan'             9;
               1 'CorrectedPreTestZeroCheck' 10;
               1 'CorrectedPostTestZero'     11;
               1 'CorrectedPostTestSpan'     12;
               0 'Part86PreTest'             15;
               0 'Part86PostTest'            16;
               0 'BagConc'                   17};

% ES - This code simply performs a query to determine if any records exist
% for each bench 0 = Bag_Dilute_Bench, 1 = Engine_Bench, 2 =
% Tailpipe_Bench. Specifically, it counts how many records exist for each
% bench and sets the bench to off if count = 0.
options.Engine_Modal_Amb_Bag_Test = 0;
options.Bag_Dilute_Bench = 1;
options.Engine_Bench = 1;
options.Tailpipe_Bench = 1;

for k = 0:2 % k is the bench 0, 1, 2
    sql = [SQL1 SQL3ebr num2str(k)];
    odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
    res = odbcCOM.ExecuteReader();
    count = 0;
    while (res.Read())
        count = count+1;
    end
    if count == 0
        switch k
            case 0
                options.Bag_Dilute_Bench = 0;
                LM.DebugPrint(2,'Bag Dilute Bench off');
            case 1
                options.Engine_Bench = 0;
                LM.DebugPrint(2,'Engine Bench off');
            case 2
                options.Tailpipe_Bench = 0;
                LM.DebugPrint(2,'Tailpipe Bench off');
        end
    end
end

sql = [SQL1 SQL3eavt];
odbcCOM = System.Data.Odbc.OdbcCommand(sql, odbcCN);
res = odbcCOM.ExecuteReader();
NumberOfReads = 0;
while (res.Read())
    NumberOfReads = NumberOfReads+1;
    specie = char(res.GetValue(2));
    bench = res.GetValue(3);
    switch bench
        case 0
            bench = 'Bag_Dilute';
        case 1
            bench = 'Engine';
        case 2
            bench = 'Tailpipe';
        otherwise
            LM.DebugPrint(1,'ALARM: Unrecognized bench in VZS information.');
    end
    Range = double(res.GetValue(4))+1;
    Writer = [specie '_' bench]; % or a modified variant of bench
    Writer = strrep(Writer,'(','_'); %These two lines insure good behavior of channel name processor
    Writer = strrep(Writer,')','_');
    Writer = ProcessChannelNameb(Writer);
    if datastream.isKey(Writer)
        tempChannel = datastream(Writer);
        VZS.ReferenceZero = 0; %Default refzero - can customize later
        for k = 1:size(VZSPhrasing,1)
            try
                if VZSPhrasing{k,1}
                    VZS.(VZSPhrasing{k,2}) = double(res.GetValue(VZSPhrasing{k,3}));
                elseif strcmp(VZSPhrasing{k,2}, 'BagConc')
                    BagConc = double(res.GetValue(VZSPhrasing{k,3}));
                     if ~isempty(tempChannel.Ambient) && ~isempty(tempChannel.Ambient.BagConc) 
                         if BagConc ~= -999, Ambient.BagConc = [tempChannel.Ambient.BagConc, max(BagConc, 0)]; options.Engine_Modal_Amb_Bag_Test = 1; else Ambient.BagConc = [tempChannel.Ambient.BagConc, -999]; end
                     else
                         if BagConc ~= -999, Ambient.BagConc = max(double(res.GetValue(VZSPhrasing{k,3})), 0); options.Engine_Modal_Amb_Bag_Test = 1; else Ambient.BagConc = -999; end 
                     end
                else
                    Ambient.(VZSPhrasing{k,2}) = max(double(res.GetValue(VZSPhrasing{k,3})), 0);
                end
            catch %#ok
                LM.DebugPrint(1,'WARNING: ImportOptionsDB failed to acquire the %s for %s Range %i, it may be a null value in the database',VZSPhrasing{k,2}, Writer, Range);
            end

        end
        Ambient.Range = Range;
        Ambient.Part86Average = (Ambient.Part86PreTest+Ambient.Part86PostTest)/2;

        % We want the uncorrected background emissions. If we assume that the background emissions
        % change in a linear fashion, the average emissions over the test interval is simply the
        % mean of the pre- and post-test ambient reads, which we are calling the 
        % Ambient.Part86Pretest and Ambient.Part86PostTest. 
        Ambient.PreTest = Ambient.Part86PreTest;
        Ambient.PostTest = Ambient.Part86PostTest;
        Ambient.Average = Ambient.Part86Average; 

        % Calculate the Part 1065 ambient concentrations to include analyzer drift
        refzero = VZS.ReferenceZero;
        refspan = VZS.ReferenceConcentration;
        prezero = refzero; % 1065.672(d)(5)
        prespan = refspan; % 1065.672(d)(5)
        postzero = VZS.CorrectedPostTestZero;
        postspan = VZS.CorrectedPostTestSpan;

        Ambient.Part1065PreTest = refzero + (refspan - refzero) * (2 * Ambient.Part86PreTest - (prezero + postzero)) / (prespan + postspan - prezero - postzero);
        Ambient.Part1065PostTest = refzero + (refspan - refzero) * (2 * Ambient.Part86PostTest - (prezero + postzero)) / (prespan + postspan - prezero - postzero);
        Ambient.Part1065Average = (Ambient.Part1065PreTest+Ambient.Part1065PostTest)/2;
        
        % ES 2/8/2017 - I changed the query to order the results by range
        % in descending order and by phase in ascending order. Thus the
        % ambients-- with the exception of BagConc which is an array--
        % represent the values associated with the lowest range.

%         if isempty(tempChannel.Ambient) || tempChannel.Ambient.Range > Range
%             tempChannel.Ambient = Ambient;
%         end
        tempChannel.Ambient = Ambient;
        
        % This check should really be broadened to verify that all of the
        % VZS fields exist and were assigned a realistic value. I'll leave
        % it for now since error-checking in general is a big issue.
        if isfield(VZS,'CorrectedPostTestSpan') && VZS.CorrectedPostTestSpan == 0
            tempChannel.VZS(Range) = VZS;
            LM.DebugPrint(2,'The %s analyzer was in operation, but it appears that a pre or post test zero span was skipped',Writer);
        elseif isfield(VZS,'CorrectedPostTestSpan')       
            tempChannel.VZS(Range) = VZS;
        else
            LM.DebugPrint(2,'The %s analyzer was not in operation, but is included in the data',Writer);
        end %If pre test span = 0 then that particular range has been disabled for this test
    else
        LM.DebugPrint(1,'WARNING: VZS results indicate that the analyzer %s was used, but that analyzer was not included\n   in the exported data',Writer)
    end
    clear VZS Ambient;
end
LM.DebugPrint(2,'Imported %i analyzer ranges',NumberOfReads);
res.Close; % Prevents Error #HY0000