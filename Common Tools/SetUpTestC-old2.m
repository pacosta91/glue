function [datastream status] = SetUpTestC(filename, pathname)
    global LM;
    fileName = fullfile(pathname, filename);
    status = 1;
    
    % Import the data into a cell array
    temp = mImport(fileName, 1);    
    A.colheaders = temp(1,:); % The first row is assumed to contain the data headers
    A.data = temp(2:end,:); % All subsequent rows are assumed to contain the data for that header
    datastream = Channels;
    
    for i = 1:length(A.colheaders)
        benchl = 0;
        dname = A.colheaders{i}; % set the datastream name equal to the ith column of A.colheaders
        
        % If there is no character data, convert the datastream data to a
        % normal array of doubles
        if ~ischar([A.data{:,i}])
            ddata = zeros(length(A.data(:,i)),1);
            for k = 1:length(ddata)
                try 
                    ddata(k) = A.data{k,i};
                catch
                    % Set failed status
                    status = 0;
                    LM.DebugPrint(1,'ALARM: The "%s" datastream is missing data! Missing data points have been replaced with zeros.', dname);
                end
            end
        else
            % Define the datastream data as a cell array
            ddata = A.data(:,i); % set the datasream data equal to the ith column of A.data
        end    

        % Determine the channel type and units and populate the datastream
        % with the relevant data. 
        
        % Grab the current next index to be added to the datastream,
        % separate the name and units from the ECCS input file and format
        % accordingly.
        count = datastream.Count + 1;
        [name, units] = Segregate(dname);  
        sname = ProcessChannelNameb(name);        
                
        % Analyzer Channel
        if instr(dname,'Bench') && ~instr(dname,'°') 
            benchl = 1;
            if datastream.isKey(sname)
                b = datastream(sname);
                if strcmp(units,'ppm') || strcmp(units,'%')
                    b.StreamingData.Part86Concentration = ddata;
                    b.Current_Units{1} = units;
                elseif strcmp(units,'g')
                    b.StreamingData.Part86Mass = ddata;
                    b.Current_Units{2} = units;
                end
            else
                b = Analyzer_Channel(datastream, name, 'Analyzer', units, count);
                if strcmp(units,'ppm') || strcmp(units,'%')
                    b.StreamingData.Part86Concentration = ddata;
                elseif strcmp(units,'g')
                    b.StreamingData.Part86Mass = ddata;
                end
            end

        % Temperature Channel
        elseif strcmp(left(dname,2),'T_') || strcmp(left(dname,3),'DT_') 
            b = Temperature_Channel(datastream, name, 'Temperature', units, ddata, count);      
            
        % Pressure CHannel
        elseif strcmp(left(dname,2),'P_') || strcmp(left(dname,3),'DP_') 
            b = Pressure_Channel(datastream, name, 'Pressure', units, ddata, count);

        % Flow Channel
        elseif strcmp(left(dname,2),'Q_') 
            b = Flow_Channel(datastream, name, 'Flow', units, ddata, count);

        % Volume Channel
        elseif strcmp(left(dname,2),'V_') 
            b = Volume_Channel(datastream, name, 'Volume', units, ddata, count);

        % Microsoot Sensor Channel
        elseif strcmp(left(dname,4),'MSS_') 
            b = MSS_Channel(datastream, name, 'MSS', units, ddata, count);
            
        % Soot Meter Channel
        elseif strcmp(left(dname,3),'SM_') 
            b = SM_Channel(datastream, name, 'SM', units, ddata, count);
            
        % Voltage Channel
        elseif strcmp(left(dname,4),'VLT_') 
            b = Voltage_Channel(datastream, name, 'Voltage', units, ddata, count);
            
        % INCA Channel
        elseif strcmp(left(dname,4),'INCA') 
            b = INCA_Channel(datastream, name, 'INCA', units, ddata, count);
            
        % Combustion Analysis System Channel
        elseif strcmp(left(dname,4),'CAS') 
            b = CAS_Channel(datastream, name, 'CAS', units, ddata, count);

        % Miscellaneous Channel    
        else 
            b = Miscellaneous_Channel(datastream, name, 'Miscellaneous', units, ddata, count);
        end

        if datastream.isKey(sname) && benchl == 0
            LM.DebugPrint(1,'ALARM: Illegal channel name, %s, this channel has been removed from the data.', name);
            continue;
        end
        
        % ES added 4/18/2017
        if datastream.isKey(sname) && instr(dname,'Range')
            LM.DebugPrint(1,'ALARM: Illegal channel name, %s, this channel has been removed from the data.', name);
            continue;
        end
        
        datastream(sname) = b; %#ok<AGROW>

    end

    LM.DebugPrint(2, 'Imported %i channels of data', length(datastream));
end