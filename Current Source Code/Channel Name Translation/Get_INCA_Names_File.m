function filename = Get_INCA_Names_File(TestStartDate)
global NETWORKPATH ENGINENUMBER LM;

INCA_Files = dir([NETWORKPATH 'INCA Channel Names\']);
INCA_Files = {INCA_Files(:).name};

INCA_Files = INCA_Files(instr_multiple(INCA_Files,ENGINENUMBER)==1); 

LatestDate = 100101; % January 1st, 2010
keeper = 0;

if isempty(INCA_Files)
    filename = '';
    LM.DebugPrint(1,'An INCA/CAS Channel Name file was not found for this engine');
    return;
end

for k = 1:length(INCA_Files)
    if ( str2double( INCA_Files{k}(1:6) ) > LatestDate ) && ( str2double( INCA_Files{k}(1:6) ) <= TestStartDate )
        LatestDate = str2double( INCA_Files{k}(1:6) );
        keeper = k;
    end
end

if keeper == 0
    filename = '';
    LM.DebugPrint(1,'All INCA/CAS Channel Name files are dated after this test was run, INCA/CAS Channel naming is being skipped')
    return;
end

filename = [NETWORKPATH '\INCA Channel Names\' INCA_Files{keeper}];

LM.DebugPrint(1, 'The following file is being used for INCA/CAS translation; %s', INCA_Files{keeper});