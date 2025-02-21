%% 1. Create NNP handle
nnp = NNPAPI('COM8');

%% 2. Setup Radio
nnp.refresh;
r = nnp.getRadioSettings();
r.rxTimeout = 100; %don't make less than 80
   %occasionally PM could respond later than expected resulting in "pm does not echo response" errors
r.retries = 2;
r.worInt = 20;
nnp.timeout = 0.4; 
nnp.setRadioSettings(r)

%% 3. Test Scan
timestamp=sprintf('_%02.0f',datevec(now));
fid = fopen(['testscan_' timestamp '.txt'], 'w');
 nodelist = [1 2 3 4 5 6 9]; %NNP4
%nodelist = [1 2 3 9]; % NNP6
%Expected PCB serial numbers for each node for NNP #4
 SNlist =  [223 225 227 229 230 231 143];  % SN for NNP4 modules
%SNlist =  [5022 5023 5024 3001];  % SN for NNP6 modules
%SNlist =  [1122 1126 1120 1092 1058 1059 307];  % SN for 7 Test modules
%SNlist =  [1122 1126 1120 307];  % SN for 4 Test modules 
nodetype = [1 1 1 1 1 1 0]; % 1 is Stim, 0 is BP
%nodetype = [1 1 1 0]; % NNP6 1 is Stim, 0 is BP
VNETlist = 9.6:-0.1:5.7;  %full range = 9.6:-0.1:4.7;
ScanCount = 5;  %10 in Saltman test
nodescan(nnp, fid, 'App', nodelist, SNlist, nodetype, VNETlist, ScanCount, 'test');


%% Nodescan Function ( run by section above )
function quit = nodescan(nnp, fid, scantype, node, SN, nodetype, VNET, X, folder)

quit = false;

n=length(node);
v=length(VNET);

NETERR = nan(v,n); %network error count (by node)
EXTERR = nan(v,n); %external error count (by node)
NODEERR = nan(v,n); %node response mismatch error count (by node) - Not for Old Bootloader
SNERR = nan(v,n);  %serial number error count (by node)
OTHERERR = nan(v,n); %other error count (by node)
BLERR = nan(v,n);  %bootloader scan count (by node)
CNT = nan(v,n);    %scan success count (by node)
POWER = nan(v,1);  %average power (mW)
PMCANERR = nan(v,14);  %PM CAN Error (Total, Bit, stuff, Form, Other, RX, TX, BEI, RXcnt, TXcnt, IntEn, RXResetCnt, TXResetCnt, NSResetCnt)
PMBAT = nan(v, 3);  %battery voltage per cell
PMBAT1 = nan(v,16); %fuel gauge data (including temp in raw byte form)
PMBAT2 = nan(v,16);
PMBAT3 = nan(v,16);
PMTEMP = nan(v,1); %PM thermistor temp (degC)
ADPOWER = nan(v,1); %instantaneous power (mW)
ADVSYS = nan(v,1); %PM measured system voltage (V)
ADVNET = nan(v,1); %PM measured network voltage (V)
ADVREC = nan(v,1); %PM measured NF received voltage (V)
SETUPERR = nan(v,1); %1: failed to enter waiting mode 
                     %2: failed to turn off network
                     %3: failed to set network voltage
                     %4: failed to turn on network
                     %5: failed to enter app mode
                     %6: failed to set stim parameters
                     %7: failed to enter stim mode
                     %8: failed to clear PM CAN error counter
RSSI = nan(v,2);
LQI  = nan(v,2);
MODETABLE  = cell(v, 1);
                   


%RM data by node and scan 
VIN = cell(v,n);    %VIN array of X scans (V)
VIC = cell(v,n);   %VIC array of X scans (raw)
RMTEMP = cell(v,n); %temperature array of X scans (degC)
ACCEL = cell(v,n);  %array of X scans by 4 (X,Y,Z,CNT)
COMP = cell(v,n);   %array of X scans by 4 channels
VOSMIN = cell(v,n);  %Min Compliance Voltage (V) 
RAWDATA = cell(v,n); % by 1008 x 4 (emg1, emg2, off1, off2)
RMCANERR = cell(v,n); %array of X scans by 10 (Total=0, Bit, stuff, Form, Other, RXErr, TXErr, BEI, RXCnt, TXCnt)



for iV = 1:v
    vnet = VNET(iV);
    fprintf(fid, '\n%s VNET = %3.1f\n', scantype, vnet);
    fprintf('\n%s VNET = %3.1f\n', scantype, vnet);
    SETUPERR(iV) = 0;
        
    % Prepare system state
    if setupEnterWaiting(nnp, fid)
        SETUPERR(iV) = 1;
        continue;
    end
    
    if setupNetworkOff(nnp, fid)
        SETUPERR(iV) = 2;
        continue;
    end
    pause(5); %give RM power capacitors time to discharge (10 in Saltman test)

     %Set network voltage to default
    if setupNetworkVoltage(nnp, fid, 7.5)
        SETUPERR(iV) = 3;
        continue;
    end
    
    if setupNetworkOn(nnp, fid)
        SETUPERR(iV) = 4;
        continue;
    end
    pause(0.5);
    
    %Set network voltage
    if setupNetworkVoltage(nnp, fid, vnet)
        SETUPERR(iV) = 3;
        continue;
    end
    pause(0.5);

    
    %Wake nodes if not a Bootloader scan
    if ~isequal(scantype, 'BL')
        if setupWakeNodes(nnp, fid)
            SETUPERR(iV) = 5;
            continue;
        end
    end
    pause(1);
    
    %Set stim parameters and enter stim mode if Stim Modes
    if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMed')
        if isequal(scantype, 'StimMax')
            pwamp =  [255 200];
        elseif isequal(scantype, 'StimMed')
            pwamp =  [255 100];
        end
        for iN=1:n %for each node
            if nodetype(iN)==1 %only for stim nodes
                if setupStimParams(nnp, fid, node(iN), pwamp)
                    SETUPERR(iV) = 6;
                    continue;
                end
            end
        end
    end
    
    if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMed') || isequal(scantype, 'StimMin')
        if setupEnterStim(nnp, fid)
            SETUPERR(iV) = 7;
            continue;
        end
    end

    if setupClearErrorsCAN(nnp, fid)
        SETUPERR(iV) = 8;
        %keep going anyway, not a fatal error
    end
    
    fprintf(fid, 'Getting Power... ');
    fprintf('Getting Power');
    % allow power measurement to stabilize over 12 s
    for iP = 1:12
        fprintf('.');
        pause(1); 
    end
    
    resp = nnp.getPower();
    if isempty(resp)
        power = NaN;
    else
        power = resp;
    end
    fprintf(fid, '%5.1f mW\n', power);
    fprintf( '%5.1f mW\n', power)
    
    [modeTable, ~, ~, ~, rssi, lqi] = nnp.getStatus([]);
    fprintf('RSSI: %3.0f %3.0f | LQI: %3.0f %3.0f\n', nnp.RSSI, rssi, nnp.LQI, lqi );
    fprintf(fid, 'RSSI: %3.0f %3.0f | LQI: %3.0f %3.0f\n', nnp.RSSI, rssi, nnp.LQI, lqi );
    RSSI(iV,:) = [nnp.RSSI, rssi];    
    LQI(iV,:) = [nnp.LQI, lqi];
    MODETABLE{iV}=modeTable;
    
    %Read A/D
    resp = double(nnp.read(7, '3000', 7, 'uint16', 4)); %VREC,VSYS,VNET,LOAD
    if length(resp)==4
        ADPOWER(iV) = resp(2)*resp(4)/10;
        ADVSYS(iV) = resp(2)/10;
        ADVNET(iV) = resp(3)/10;
        ADVREC(iV) = resp(1)/10;
    end
    
    nodeErr = zeros(1,n);
    netErr = zeros(1,n);   %Network Communication error
    extErr = zeros(1,n);   %Radio/USB error
    snErr = zeros(1,n);    %Wrong SN reporting
    otherErr = zeros(1,n); %Unknown error
    blErr = zeros(1,n);    %Node that should be in App Mode is in BL (brown out)
    cnt = zeros(1,n);      %Successful Scan  

    %initialize variables
    for iN = 1:n
        VIN{iV, iN} = nan(X,1);    %VIN array of X scans (V)
        VIC{iV, iN} = nan(X,1);   %VIC array of X scans (raw)
        RMTEMP{iV, iN} = nan(X,1);%temperature array of X scans (degC)
        ACCEL{iV, iN} = nan(X,4);  %array of X scans by 4 (X,Y,Z,CNT)
        COMP{iV, iN} = nan(X,4);  %compliance array of X scans by 4 ch
        RMCANERR{iV, iN} = nan(X,10);  %array of X scans by 10 error types
    end

    for iX=1:X % scan X times
        
        for iN = 1:n %scan across number of nodes

            [resp, err] = nnp.transmit(7, uint8([0, 0, node(iN), 1, 0]), 0, hex2dec('3c'));
            fprintf(fid, '%3.1f #%3.0f node%1.0f: ', vnet, iX, node(iN));
            fprintf(fid, '%02X ', resp);
            fprintf(fid, 'ERR=%1.0f ', err);
            fprintf('%3.1f #%3.0f node%1.0f: ', vnet, iX, node(iN));
            fprintf('%02X ', resp);
            fprintf('ERR=%1.0f ', err);
            if err>0
                if err == 1
                    netErr(iN) = netErr(iN)+1;
                else
                    extErr(iN) = extErr(iN)+1;
                end
            else

                if length(resp)>=8  %EMC modules have old bootloader rev which does not report node back
                    if length(resp)>=9  %EMC modules have old bootloader rev which does not report node back
                        nodeResp = resp(8);
                    else
                        nodeResp = node(iN); %assume no error
                    end
                    sn = double(resp(5))*256+double(resp(4));
                    if nodeResp ~= node(iN) %node Mismatch
                        nodeErr(iN) = nodeErr(iN)+1;
                    elseif sn ~= SN(iN) %serial Mismatch
                        snErr(iN) = snErr(iN) + 1;
                    else
                        if (isequal(scantype, 'BL') && resp(3)==0) ||  (~isequal(scantype, 'BL') && resp(3)==2)
                            cnt(iN) = cnt(iN) + 1;
                            
                            %if in App mode, read VIN, VIC, and Temperature
                            if ~isequal(scantype, 'BL')
                                %VIN (in V)
                                resp = double(nnp.read(node(iN), '3000', 2, 'uint8'));
                                if length(resp)==1
                                    vin = resp*3.3/256*4;
                                    fprintf(fid, ' | VIN: %4.2f', vin);
                                    fprintf(' | VIN: %4.2f', vin);
                                    VIN{iV,iN}(iX) = vin;
                                else
                                    fprintf(fid, ' | VIN: ????');
                                    fprintf(' | VIN: ????');
                                end
                                
                                %VIC (raw)
                                resp = double(nnp.read(node(iN), '3000', 3, 'uint8'));
                                if length(resp)==1
                                    vic = resp;
                                    fprintf(fid, ' | VIC: %3.0f', vic);
                                    fprintf(' | VIC: %3.0f', vic);
                                    VIC{iV,iN}(iX) = vic;
                                else
                                    fprintf(fid, ' | VIC: ???');
                                    fprintf(' | VIC: ???');
                                end
                                
                                %Temp (degC)
                                resp = double(nnp.read(node(iN), '2003', 1, 'uint16'));
                                if length(resp)==1
                                    rmtemp = resp/10;
                                    fprintf(fid, ' | Temp: %3.1f', rmtemp);
                                    fprintf(' | Temp: %3.1f', rmtemp);
                                    RMTEMP{iV,iN}(iX)= rmtemp;
                                else
                                    fprintf(fid, ' | Temp: ???');
                                    fprintf(' | Temp: ???');
                                end
                                
                                %Accel
                                resp = double(nnp.read(node(iN), '2011', 1, 'uint8'));
                                if length(resp)==4
                                    accel = resp;
                                    fprintf(fid, ' | Acc: %3.0f %3.0f %3.0f %3.0f', accel);
                                    fprintf(' | Acc: %3.0f %3.0f %3.0f %3.0f', accel);
                                    ACCEL{iV,iN}(iX,:) = accel;
                                else
                                    fprintf(fid, ' | Acc: ??? ??? ??? ???');
                                    fprintf(' | Acc: ??? ??? ??? ???');
                                end
                                
                                %RM CAN errors
                                resp = double(nnp.read(node(iN), '2500', 1, 5, 'uint16'));
                                if length(resp)==5
                                    fprintf(fid, ' | CANERR: %5.0f %5.0f %5.0f %5.0f %5.0f', resp);
                                    fprintf(' | CANERR: %5.0f %5.0f %5.0f %5.0f %5.0f', resp);
                                    RMCANERR{iV,iN}(iX,1:5) = resp;
                                else
                                    fprintf(fid, ' | CANERR: ????? ????? ????? ????? ?????');
                                    fprintf(' | CANERR: ????? ????? ????? ????? ?????');
                                end
                                %RM CAN errors 2
                                resp = double(nnp.read(node(iN), '2500', 6, 5, 'uint16'));
                                if length(resp)==5
                                    fprintf(fid, ' %5.0f %5.0f %5.0f %5.0f %5.0f', resp);
                                    fprintf(' %5.0f %5.0f %5.0f %5.0f %5.0f', resp);
                                    RMCANERR{iV,iN}(iX,6:10) = resp;
                                else
                                    fprintf(fid, ' ????? ????? ????? ????? ?????');
                                    fprintf(' ????? ????? ????? ????? ?????');
                                end
                            end
                            
                            %If simulating, find minimum compliance voltage
                            if nodetype(iN)==1 %only for stim nodes
                                if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMed')
                                    resp = double(nnp.read(node(iN), '3210', 5, 'uint8'));
                                    if length(resp)==4
                                        comp = resp;
                                        fprintf(fid, ' | Comp: %1.0f %1.0f %1.0f %1.0f', comp);
                                        fprintf(' | Comp: %3.0f %1.0f %1.0f %1.0f', comp);
                                        COMP{iV,iN}(iX,:) = comp;
                                    else
                                        fprintf(fid, ' | Comp: ? ? ? ?');
                                        fprintf(' | Comp: ? ? ? ?');
                                    end
                                end
                            end
                        elseif ~isequal(scantype, 'BL') && resp(3)==0
                            blErr(iN) = blErr(iN) + 1; 
                            fprintf(fid, ' | BOOTLOADER!');
                            fprintf(' | BOOTLOADER!');
                        else
                            otherErr(iN) = otherErr(iN) + 1;
                        end
                    end
                else
                    otherErr(iN) = otherErr(iN) + 1;
                end
            end
            fprintf(fid, '\n');
            fprintf('\n');
        end % node loop
    end %scan iteration loop
    
    NETERR(iV,:) = netErr;
    EXTERR(iV,:) = extErr;
    NODEERR(iV,:) = nodeErr;
    SNERR (iV,:)= snErr;
    OTHERERR(iV,:) = otherErr;
    BLERR(iV,:) = blErr;
    CNT(iV,:) = cnt;
    POWER(iV,:) = power;

    
    %Get CAN error count from scans
    resp = double(nnp.read(7, '2500', 1,14, 'uint16'));
    if isempty(resp)
        PMCANERR(iV,:) = nan(1,14);
    else
        PMCANERR(iV,:) = resp;
    end
    fprintf('\nPM CAN Errors: %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f\n', PMCANERR(iV,:));
    fprintf(fid, '\nPM CAN Errors: %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f %5.0f\n', PMCANERR(iV,:));
    
    %Get battery voltages and PM Temperature
    resp = double(nnp.read(7, '3000', 13, 'uint8'));
    if isempty(resp)
        PMBAT(iV,:) = nan(1,3);
        PMTEMP(iV) = nan;
    else
        PMBAT(iV,:)= [resp(8)*256+resp(7) resp(10)*256+resp(9) resp(12)*256+resp(11)];
        PMTEMP(iV) =(resp(4)*256+resp(3))/10;
    end
    fprintf('\nBattery Cells: %4.0f mV | %4.0f mV  | %4.0f mV \n', PMBAT(iV,:));
    fprintf(fid, '\nBattery Cells: %4.0f mV | %4.0f mV  | %4.0f mV \n', PMBAT(iV,:));

    %Get fuel gauge data
    resp = double(nnp.read(7, '3001', 1, 'uint8'));
    if isempty(resp)
        PMBAT1(iV,:) = nan(1,16);
    else
        PMBAT1(iV,:) = resp;
    end
    resp = double(nnp.read(7, '3002', 1, 'uint8'));
    if isempty(resp)
        PMBAT2(iV,:) = nan(1,16);
    else
        PMBAT2(iV,:) = resp;
    end
    resp = double(nnp.read(7, '3003', 1, 'uint8'));
    if isempty(resp)
        PMBAT3(iV,:) = nan(1,16);
    else
        PMBAT3(iV,:) = resp;
    end

    for iN=1:n
        if nodetype(iN)==1 %only for stim nodes
            if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMed')
                fprintf(fid, '\nGetting Minimum VOS... ');
                fprintf('\nGetting Minimum VOS... ');
                vos = findMinVOS(nnp, node(iN));
                fprintf(fid, 'Node: %1.0f | Minimum VOS: %2.0f\n', node(iN), vos);
                fprintf('Node: %1.0f | Minimum VOS: %2.0f\n', node(iN), vos);
                VOSMIN{iV,iN} = vos;
            end
        else %only for mes nodes
            %Get EMG for channels and offsets
            if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMed') || isequal(scantype, 'StimMin')
                fprintf(fid, '\nGetting Raw Data... ');
                fprintf('\nGetting Raw Data... ');
                for k=1:4
                    setupEnterWaiting(nnp, fid);

                    if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMed')
                        if isequal(scantype, 'StimMax')
                            pwamp =  [255 200];
                        elseif isequal(scantype, 'StimMed')
                            pwamp =  [255 100];
                        end
                        for iNN=1:n
                            if nodetype(iNN)==1 %only for stim nodes
                                if setupStimParams(nnp, fid, node(iNN), pwamp)
                                    SETUPERR(iV) = 9;
                                end
                            end
                        end
                    end
                    
                    if k>2
                        if setupMeasurement(nnp, fid, node(iN), 2)
                            SETUPERR(iV) = 10;
                        end
                        ch = k-2;
                        pause(.25)
                    else
                        if setupMeasurement(nnp, fid, node(iN), 0)
                            SETUPERR(iV) = 10;
                        end
                        ch = k;
                        pause(.25)
                    end
                    setupEnterRaw(nnp, fid, node(iN), ch);

                    RAWDATA{iV,iN}(:,k) = getRawData(nnp);
                    plot(RAWDATA{iV,iN})
                end
            end
        end
    end
    

end %net voltage loop

bat = mean(mean(PMBAT(end-5:end,:), 'omitnan'), 'omitnan');
fprintf('\nBattery Check: %4.0f mV\n', bat);
%if battery state could not be determined or is low.  
%Used to determine by calling program if another scan should be run. 
if isnan(bat) || bat <3550 %DISCHARGE LIMIT 
    quit = true;
end
timestamp=sprintf('_%02.0f',datevec(now));
try
    save([folder '\Scan' scantype '_' timestamp '.mat'],'NETERR','EXTERR','NODEERR','SNERR','OTHERERR','BLERR','CNT',...
        'SETUPERR','POWER','VNET','VIN','COMP','VOSMIN','PMCANERR','PMBAT','PMBAT1','PMBAT2','PMBAT3','PMTEMP',...
        'RMTEMP','ACCEL','ADPOWER','ADVREC','ADVNET','ADVSYS','RAWDATA','RSSI','LQI','RMCANERR','MODETABLE')
catch
    save(['Scan' scantype '_' timestamp '.mat'],'NETERR','EXTERR','NODEERR','SNERR','OTHERERR','BLERR','CNT',...
        'SETUPERR','POWER','VNET','VIN','COMP','VOSMIN','PMCANERR','PMBAT','PMBAT1','PMBAT2','PMBAT3','PMTEMP',...
        'RMTEMP','ACCEL','ADPOWER','ADVREC','ADVNET','ADVSYS','RAWDATA','RSSI','LQI','RMCANERR','MODETABLE')
end
end







%%
function err = setupEnterWaiting(nnp, fid)
    nnp.lastError = [];
    err = false;
    attempt = 0;
    while ~isequal(nnp.enterWaiting, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to enter Waiting mode: %s\n', nnp.lastError);
            fprintf('Failed to enter Waiting mode: %s\n', nnp.lastError);
            err = true;
            return;
        else
            if isequal(nnp.lastError, 'AP access denied')
                nnp.refresh;
            end
            fprintf('....retrying enter Waiting mode: %s\n', nnp.lastError);
        end
    end
end

function err = setupNetworkOff(nnp, fid)
    err = false;
    attempt = 0;
    while ~isequal(nnp.networkOff, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to turn off Network: %s\n', nnp.lastError);
            fprintf('Failed to turn off Network: %s\n', nnp.lastError);
            err = true;
            return;
        else
            fprintf('....retrying Network Off: %s\n', nnp.lastError);
        end
    end
end    
    
function err = setupNetworkVoltage(nnp, fid, vnet)    
    err = false;
    attempt = 0;
    while ~isequal(nnp.setVNET(vnet), true)
        vnetread = nnp.getVNET;
        if ~isequal(vnetread, vnet)
            attempt = attempt+1;
            if attempt>3
                fprintf(fid, 'Failed to set VNET: %s\n', nnp.lastError);
                fprintf('Failed to set VNET: %s\n', nnp.lastError);
                err = true;
                return;
            else
                fprintf('....retrying set VNET: %s\n', nnp.lastError);
            end
        else
            return;
        end
    end
end

function err = setupNetworkOn(nnp, fid)
    %Turn on Network 
    err = false;
    attempt = 0;
    while ~isequal(nnp.networkOnBootloader, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to turn on Network: %s\n', nnp.lastError);
            fprintf('Failed to turn on Network\n');
            err = true;
            return;
        else
            fprintf('....retrying Network On: %s\n', nnp.lastError);
        end
    end
end
    
  
        
function err = setupWakeNodes(nnp, fid)    
    err =false;
    attempt = 0;
    while ~isequal(nnp.enterApp, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to send Enter App: %s\n', nnp.lastError);
            fprintf('Failed to send Enter App: %s\n', nnp.lastError);
            err =true;
            return;
        end
    end
end    

        
function err = setupStimParams(nnp, fid, node, pwamp)
    err = true;
    fprintf('\nStim not supported\n')
end


function err = setupEnterStim(nnp, fid)
    err = true;
    fprintf('\nStim not supported\n')
end

function err = setupEnterRaw(nnp, fid, node, ch)
    err = true;
    fprintf('\nRaw not supported\n')
end

function buf = getRawData(nnp)
    buf = [];
    fprintf('\nRaw not supported\n')
end

function err = setupClearErrorsCAN(nnp, fid)
    err = false;
    attempt = 0;                        
    while ~isequal(nnp.nmt(7, '98'), hex2dec('98')) %clear CAN errors
       attempt = attempt + 1;
       if attempt>3
           fprintf(fid, 'Failed to clear CAN Errors: %s\n', nnp.lastError');
           fprintf('Failed to clear CAN Errors: %s\n', nnp.lastError');
           err = true;
           break;
       end
    end
end

function err = setupMeasurement(nnp, fid, node, mode)
    err = true;
    fprintf('\nRaw not supported\n')
end

function vosMin = findMinVOS(nnp, node) 
    err = true;
    fprintf('\nStim not supported\n')
end