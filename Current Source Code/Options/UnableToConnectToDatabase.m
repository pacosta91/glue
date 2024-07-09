function options = UnableToConnectToDatabase(datastream)
    global LM SPECIES BENCHES
    options = datastream('Options');

    inputR = 0;
    while ~any(inputR == 1:8)
        if ~inputR==0
            disp('The value enterred was recognized please enter a value between 1 and 8')
        else
            inputR = input(['To continue processing this data please select one of the following by entering the corresponding fuel number between 1 and 8:\n' ...
                '======================================================================================================\n' ...
                'Fuel Number      Fuel Name                        w_C            w_H            w_O       Density(g/L)\n' ...
                '------------------------------------------------------------------------------------------------------\n' ...
                '     1           Gasoline                        0.8654         0.1346         0.0000         740     \n' ...
                '     2           #2 Diesel                       0.8685         0.1315         0.0000         840     \n' ...
                '     3           #1 Diesel                       0.8604         0.1396         0.0000         840     \n' ...
                '     4           Liquified Petroleum Gas         0.8183         0.1817         0.0000         490     \n' ...
                '     5           Natural Gas                     0.7467         0.2374         0.0159         128     \n' ...
                '     6           Ethanol                         0.5213         0.1315         0.3472         789     \n' ...
                '     7           Methanol                        0.3747         0.1261         0.4992         792     \n' ...
                '     8           Terminate Test                                                                       \n\n']);
        end
        switch inputR
            case 1 %Gasoline
                options.Fuel.Name = 'Gasoline';
                options.Fuel.w_C = 0.8654;
                options.Fuel.w_H = 0.1346;
                options.Fuel.w_O = 0;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.740;
            case 2 %#2 Diesel
                options.Fuel.Name = '#2 Diesel';
                options.Fuel.w_C = 0.8685;
                options.Fuel.w_H = 0.1315;
                options.Fuel.w_O = 0;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.840;
            case 3 %#1 Diesel
                options.Fuel.Name = '#1 Diesel';
                options.Fuel.w_C = 0.8604;
                options.Fuel.w_H = 0.1396;
                options.Fuel.w_O = 0;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.840;
            case 4 %Liquified Petroleum Gas
                options.Fuel.Name = 'Liquified Petroleum Gas';
                options.Fuel.w_C = 0.8183;
                options.Fuel.w_H = 0.1817;
                options.Fuel.w_O = 0;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.490;
            case 5 %Natural Gas
                options.Fuel.Name = 'Natural Gas';
                options.Fuel.w_C = 0.7467;
                options.Fuel.w_H = 0.2374;
                options.Fuel.w_O = 0.0159;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.128;
            case 6 %Ethanol
                options.Fuel.Name = 'Ethanol';
                options.Fuel.w_C = 0.5213;
                options.Fuel.w_H = 0.1315;
                options.Fuel.w_O = 0.3472;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.789;
            case 7 %Methanol
                options.Fuel.Name = 'Methanol';
                options.Fuel.w_C = 0.3747;
                options.Fuel.w_H = 0.1261;
                options.Fuel.w_O = 0.4992;
                options.Fuel.w_N = 0;
                options.Fuel.w_S = 0;
                options.Fuel.Specific_Gravity = 0.792;
            case 8 %Quit Glue
                options = -1;
                LM.DebugPrint(2,'No fuel was selected - test was abandoned')
                return;
        end
        LM.DebugPrint(2,'%s was the selected fuel.',options.Fuel.Name);
    end
    
    options.Bag_Dilute_Bench = 0;
    options.Engine_Bench = 0;
    options.Tailpipe_Bench = 0;
    
    for k = 1:10
        for m = 1:3
            AnalyzerName = [SPECIES{k} '_' BENCHES{m}];
            if isKey(datastream, AnalyzerName) % Analyzers are assumed to be on if they are available
                switch m
                    case 1
                        options.Bag_Dilute_Bench = 1;
                    case 2
                        options.Engine_Bench = 1;
                    case 3
                        options.Tailpipe_Bench = 1;
                end
                datastream(AnalyzerName).IsOn = 2;
                datastream(AnalyzerName).Ambient.Part86PreTest = 0;
                datastream(AnalyzerName).Ambient.Part86PostTest = 0;
                datastream(AnalyzerName).Ambient.Part86Average = 0;
                datastream(AnalyzerName).VZS(1).PreTestZero = 0;
                datastream(AnalyzerName).VZS(1).PreTestSpan = 100;
                datastream(AnalyzerName).VZS(1).PreTestZeroCheck = 0;
                datastream(AnalyzerName).VZS(1).MaximumConcentration = 100;
                datastream(AnalyzerName).VZS(1).ReferenceZero = 0;
                datastream(AnalyzerName).VZS(1).ReferenceConcentration = 100;
                datastream(AnalyzerName).VZS(1).PostTestZero = 0;
                datastream(AnalyzerName).VZS(1).PostTestSpan = 100;
            end
        end
    end
    
    if datastream.isKey('CH4_Bag_Dilute') && datastream('CH4_Bag_Dilute').ison
        datastream('NMHC_Bag_Dilute') = Analyzer_Channel(datastream, 'NMHC_Bag_Dilute', 'Analyzer', 0, 'ppm');
        datastream('NMHC_Bag_Dilute').IsOn = 2;
    end
    
    if strcmp(datastream('Options').CO2_dildry, 'Ambient')
        options.CO2_dildry = options.CO2_Bag_Dilute(1).Ambient/100;
    end

    if strcmp(datastream('Options').CO2_intdry, 'Ambient')
        options.CO2_intdry = options.CO2_Bag_Dilute(1).Ambient/100;
    end

    options.Particulate_On = 1;
end