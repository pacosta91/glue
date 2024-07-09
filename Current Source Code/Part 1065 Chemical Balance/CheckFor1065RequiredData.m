function datastream = CheckFor1065RequiredData(datastream)

global LM;

options = datastream('Options');

if ~options.Part_1065.IsOn, return; end;
if ~datastream.isKey('DT_Air_2')
    options.Part_1065.IsOn = 0; 
    LM.DebugPrint(1,'ALARM: There is insufficient data to perform the Part 1065 Chemical Balance, DT_Air_2 has not been found, this procedure will be skipped');
    datastream('Options') = options;
    return;
end
if ~datastream.isKey('P_SimBaro')
    options.Part_1065.IsOn = 0; 
    LM.DebugPrint(1,'ALARM: There is insufficient data to perform the Part 1065 Chemical Balance, P_SimBaro has not been found, this procedure will be skipped');
    datastream('Options') = options;
    return;
end

reason = 'The ';
count = 0;
if ~datastream.isKey('P_CFV'), options.Bag_Dilute_Bench = 0; reason = [reason 'P_Ex Transducer,']; count = count + 1; end
% if ~datastream.isKey('CO_l_Bag_Dilute'), options.Bag_Dilute_Bench = 0; reason = [reason 'CO_l_Bag_Dilute Analyzer,']; count = count + 1; end
if ~datastream.isKey('CO_l_Bag_Dilute') && ~datastream.isKey('CO_h_Bag_Dilute'), options.Bag_Dilute_Bench = 0; reason = [reason 'CO_l_Bag_Dilute Analyzer, CO_h_Bag_Dilute Analyzer,']; count = count + 2; end
if ~datastream.isKey('NOx_Bag_Dilute'), options.Bag_Dilute_Bench = 0; reason = [reason 'NOx_Bag_Dilute Analyzer,']; count = count + 1; end
if ~datastream.isKey('CO2_Bag_Dilute'), options.Bag_Dilute_Bench = 0; reason = [reason 'CO2_Bag_Dilute Analyzer,']; count = count + 1; end
if ~datastream.isKey('HHC_Bag_Dilute') && ~datastream.isKey('HC_Bag_Dilute'), options.Bag_Dilute_Bench = 0; reason = [reason 'HC_Bag_Dilute, HHC_Bag_Dilute_Analyzer,']; count = count + 2; end
if ~datastream.isKey('Q_CVS_Mol'), options.Bag_Dilute_Bench = 0; reason = [reason 'Q_CVS_Mol Calculation,']; count = count + 1; end
if ~datastream.isKey('DT_Dil_Air'), options.Bag_Dilute_Bench = 0; reason = [reason 'DT_Dil_Air Transducer']; count = count + 1; end

if ~options.Bag_Dilute_Bench
   if count == 1
       LM.DebugPrint(1,'WARNING: %s has not been found Part 1065 Chemical Balance will be skipped for the Bag Dilute Bench', reason);
   else
       LM.DebugPrint(1,'WARNING: %s have not been found Part 1065 Chemical Balance will be skipped for the Bag Dilute Bench', reason);
   end
end

if ~datastream.isKey('Q_Fuel_Mass_C'), options.Engine_Bench = 0; options.Tailpipe_Bench = 0; datastream('Options') = options; LM.DebugPrint(1,'WARNING: Q_Fuel_Mass_C has not been found the Part 1065 Chemical Balance will be skipped for the Engine and Tailpipe Benches'); return; end

if ~datastream.isKey('CO_h_Engine'), options.Engine_Bench = 0; end
if ~datastream.isKey('NOx_Engine'), options.Engine_Bench = 0; end
if ~datastream.isKey('CO2_Engine'), options.Engine_Bench = 0; end
if ~datastream.isKey('HC_Engine'), options.Engine_Bench = 0; end

if ~datastream.isKey('CO_h_Tailpipe'), options.Tailpipe_Bench = 0; end
if ~datastream.isKey('NOx_Tailpipe'), options.Tailpipe_Bench = 0; end
if ~datastream.isKey('CO2_Tailpipe'), options.Tailpipe_Bench = 0; end
if ~datastream.isKey('HC_Tailpipe'), options.Tailpipe_Bench = 0; end

datastream('Options') = options;