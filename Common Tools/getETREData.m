function getETREData(testnumber, ws)

    if ~exist('testnumber','var') || ~strcmpi(class(testnumber),'double'), testnumber = 0; end
    if ~exist('ws','var'), ws = 'base'; end    
    
    % Grab the test data from the database and place in the workspace
    assignin(ws, 'ETRE_Test_Results', getDBTable('ETRE','tblTestResults',testnumber,1));
    assignin(ws, 'ETRE_VZS_Results', getDBTable('ETRE','tblVZS_Results',testnumber));
    assignin(ws, 'ETRE_Engine_Data', getDBTable('ETRE','engine',testnumber,1));
    assignin(ws, 'ETRE_Fuel_Data', getDBTable('ETRE','tblFuel',testnumber,1));

    % Include a flag indicating that this function was executed and the
    % user can expect the above structures to be in the workspace.
    assignin(ws, 'ETREDataAvailable', testnumber);
    
end