function [name, units] = Segregate(channel)
    Ropen = strfind(channel,'(');
    Rclose = strfind(channel,')');
    if ~isempty(Ropen)
        units = strtrim(channel(Ropen(end)+1:Rclose(end)-1));
        name = strtrim([channel(1:Ropen(end)-1),' ',strtrim(channel(Rclose(end)+1:length(channel)))]);
    else
        units = '';
        name = channel;
    end
    
    % Clean up units
    if strcmpi(units,'Grams'), units = 'g'; end
    if strcmpi(units, 'C°') || strcmpi(units, 'Cø'), units = '°C'; end
    if strcmp(units, 'F°'), units = '°F'; end
    if strcmpi(units,'l/m'), units = 'L/m'; end
    if strcmpi(units,'scf/hr'), units = 'scf/h'; end
    if strcmpi(units,'kg/hr'), units = 'kg/h'; end
    if strcmpi(units,'Moles/min'), units = 'mol/m'; end
    if strcmpi(units,'g/Kw.hr'), units = 'g/kW.hr'; end    
    if strcmpi(units,'n/a') || strcmpi(units,'none'), units = ''; end
end