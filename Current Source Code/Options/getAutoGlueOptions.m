function runAutoGlue = getAutoGlueOptions(optionFileName)

    runAutoGlue = 1;
    
    % Open the local settings file first to find the location of the
    % network options files
    [toolpath, ~, ~] = fileparts(which('AutoGlue.m'));
    fid = fopen([toolpath, '\Settings Files\Options Panel.txt']);
    local_options = textscan(fid,'%s%s','Delimiter',',');
    fclose(fid);

    % This is based on ImportOptions3.m which relies on the order in which
    % the options are available in the file. This is OK but it would
    % probably be better to remove this restriction at a later date.
    idx = find(ismember(local_options{1},'Network_Path'));
    if ~isempty(idx) 
        try % to open the network options file
            fid = fopen([local_options{2}{idx} 'Settings Files/' optionFileName]);
            network_options = textscan(fid,'%s%s','Delimiter',',');
            fclose(fid);
            
            % Check to see if the AutoGlue option exists
            idx = find(ismember(network_options{1},'Run_AutoGlue'));
            
            % If it exists and states that AutoGlue should not be run,
            % return 0.
            if ~isempty(idx) && str2double(network_options{2}{idx}) == 0
                runAutoGlue = 0; return;
            end

        catch ME % The network options file could not be opened; assume it is OK to run AutoGlue
            return;
        end
    else
        return;
    end