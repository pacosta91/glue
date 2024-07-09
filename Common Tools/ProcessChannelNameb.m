function sname = ProcessChannelNameb(source)
    if instr(source,'Bench') && ~instr(source,'°') && strcmp(left(source,3),'MF_'), source = right(source,length(source)-3); end;
    source = strrep(source,'(l)','_l_');
    source = strrep(source,'(h)','_h_');
    source = strrep(source,'(Tr)','_Tr_');
    source = strrep(source,'(egr)','_egr_');
    %trim the units from the channel name
    Ropen = strfind(source,'(');
    Rclose = strfind(source,')');
    if ~isempty(Ropen)
        source = strtrim([source(1:Ropen(1)-1),' ',strtrim(source(Rclose(end)+1:length(source)))]);
    end
    source = strrep(source,'Range',''); % EDS added 2/6/2017
    source = strrep(source,'Bench','');
    source = strrep(source,'((none))','');
    source = strrep(source,'\','_');
    source = strrep(source,'/','_');
    source = strrep(source,'[','_');
    source = strrep(source,']','_');
    source = strrep(source,'(','_');
    source = strrep(source,')','_');
    source = strrep(source,'°','_');
    source = strrep(source,'%','_');
    source = strrep(source,'”','_');
    source = strrep(source,'-','_');
    source = strrep(source,' ','_');
    source = strrep(source,'.','_');
    source = strrep(source,'$','_');
    source = strrep(source,'''','_');
    % Remove double, trailing, and leading subscores
    while ~isempty(strfind(source,'__'))
        source = strrep(source,'__','_');
    end
    while strcmp(left(source,1),'_')
        source = right(source,length(source)-1);
    end
    while strcmp(right(source,1),'_')
        source = left(source,length(source)-1);
    end
    if ~isnan(str2double(left(source,1))) %if the leading character is a number (which is illegal)
        source = strcat('A_',source); % A is for Arbitrary
    end
    sname = source;
end