%%
% The following settings should be saved in the OD:
% PM: sync period 50ms
% RM: schedule 1ms apart across all channels (no simultaneous stim),
% MinVOS=StimVOS=34V (2040)
%PM Should be running off battery! 
nnp = NNPAPI;
%%
node = [   3    4       9];
n=length(node);
nnp.setVNET(8);
nnp.enterWaiting;
nnp.networkOn;
pause(2)
%%
for j=1:length(node)
    %confirm VOS
    nnp.read(node(j), '3210', 3, 2, 'uint16')
    nnp.read(node(j), '2800', 1)
    
end

%confirm 20Hz
nnp.getSync
%% Write Schedule and Sync Period
for j=1:length(node)
    nnp.write(node(j), '2800', 1, [20 22 24 26]+(j-1)*8)
    %nnp.write(node(j), '2800', 1, [20 21 22 23]+(j-1)*4)
    nnp.saveOD(node(j));
end
%% 

nnp.setSync(50)
nnp.saveOD(7)

%% Setup Radio
% r = nnp.getRadioSettings();
% r.rxTimeout = 50;
% r.retries = 2;
% nnp.timeout = 0.2;
% nnp.setRadioSettings(r);

r = nnp.getRadioSettings();
r.rxTimeout = 300;
r.retries = 2;
nnp.timeout = 1.2;
nnp.setRadioSettings(r);



%% Run the Scans 
fid = fopen(['fullscan_' timestamp '.txt'], 'w');
fopen(fid);
% nodelist = [   3    4    5    6    9];
% SNlist =    [1123 1150  226 1051 1040]; % serial number list by node
nodelist = [   3    4   9];
SNlist =    [1123 1150  1040]; % serial number list by node
VNETlist = 9.6:-0.1:4.7;
ScanCount = 10;
scantypelist = {'App';'StimMin';'StimMax'}; %{'BL';
tic
for i=1:length(scantypelist)
    nodescan(nnp, fid, scantypelist{i}, nodelist, SNlist, VNETlist, ScanCount);
end
toc
fclose(fid);
%%
function nodescan(nnp, fid, scantype, node, SN, VNET, X)



n=length(node);

NETERR = [];
EXTERR = [];
SNERR = [];
OTHERERR = [];
BLERR = [];
CNT = [];
POWER = [];
VIN = [];
PMCANERR = [];
PMBAT = [];
PMTEMP = [];
COMP = [];
ADPOWER = [];
ADVSYS = [];
ADVNET = [];
ADVREC = [];

for vnet = VNET
    % Prepare system state
    attempt = 0;
    while ~isequal(nnp.enterWaiting, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to enter Waiting mode\n');
            fprintf('Failed to enter Waiting mode\n');
            break
        end
    end
    attempt = 0;
    while ~isequal(nnp.networkOff, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to turn off Network\n');
            fprintf('Failed to turn off Network\n');
            break
        end
    end
    
    pause(0.2);
    
    %Set Network Voltage
    attempt = 0;
    while ~isequal(nnp.setVNET(vnet), true)
        vnetread = nnp.getVNET;
        if ~isequal(vnetread, vnet)
            attempt = attempt+1;
            if attempt>3
                fprintf(fid, 'Failed to set VNET\n');
                fprintf('Failed to set VNET\n');
                break;
            end
        else
            break;
        end
    end
    
    %Turn on Network 
    attempt = 0;
    while ~isequal(nnp.networkOnBootloader, true)
        attempt = attempt + 1;
        if attempt>3
            fprintf(fid, 'Failed to turn on Network\n');
            fprintf('Failed to turn on Network\n');
            break;
        end
    end
    pause(0.5);
    
    %Wake nodes if not a Bootloader Scan
    fprintf(fid, '%s VNET = %3.1f\n', scantype, vnet);
    fprintf('%s VNET = %3.1f\n', scantype, vnet);
    if ~isequal(scantype, 'BL')
        attempt = 0;
        while ~isequal(nnp.enterApp, true)
            attempt = attempt + 1;
            if attempt>3
                fprintf(fid, 'Failed to send Enter App\n');
                fprintf('Failed to send Enter App\n');
                break;
            end
        end
    end
    pause(1);
    
    %Set stim parameters and enter stim mode if Stim Modes
    if isequal(scantype, 'StimMax')
        for j=1:n
            for ch=1:4
                attempt = 0;
                while ~isequal(nnp.write(node(j), '3212', ch, [255 200]), 0)
                    if ~isequal(nnp.read(node(j), '3212', ch), [255 200])
                        attempt = attempt + 1;
                        if attempt>3
                            fprintf(fid, 'Failed to set pw/amp node %1.0f, ch %1.0f\n', node(j), ch);
                            fprintf('Failed to set pw/amp node %1.0f, ch %1.0f\n', node(j), ch);
                            break;
                        end
                    else
                        break;
                    end
                end
            end
        end
    end
    if isequal(scantype, 'StimMax') || isequal(scantype, 'StimMin')
        attempt = 0;
        while ~isequal(nnp.enterTestStim, true)
            attempt = attempt + 1;
            if attempt>3
                fprintf(fid, 'Failed to enter Stim Mode\n');
                fprintf('Failed to enter Stim Mode\n');
                break
            end
        end
    end
    
                        
    while ~isequal(nnp.nmt(7, '98'), hex2dec('98')) %clear CAN errors
       attempt = attempt + 1;
       if attempt>3
           fprintf(fid, 'Failed to clear CAN Errors\n');
           fprintf('Failed to clear CAN Errors\n');
           break;
       end
    end
    fprintf(fid, 'Getting Power... ');
    fprintf('Getting Power... ');
    
    pause(12); % allow power measurement to stabilize
    
    resp = nnp.getPower();
    if isempty(resp)
        power = NaN;
    else
        power = resp;
    end
    fprintf(fid, '%5.1f mW\n', power);
    fprintf( '%5.1f mW\n', power)
    
    %Read A/D
    resp = double(nnp.read(7, '3000', 7, 'uint16', 4)); %VREC,VSYS,VNET,LOAD
    if length(resp)==4
        ADPOWER = [ADPOWER resp(2)*resp(4)/10];
        ADVSYS = [ADVSYS resp(2)/10];
        ADVNET = [ADVNET resp(3)/10];
        ADVREC = [ADVREC resp(1)/10];
%         fprintf(fid, '%5.1f mW\n', power); %TODO JML
%         fprintf( '%5.1f mW\n', power)
    else
        ADPOWER = [ADPOWER nan];
        ADVSYS = [ADVSYS nan];
        ADVNET = [ADVNET nan];
        ADVREC = [ADVREC nan];
    end
    
    netErr = zeros(1,n);   %Network Communication error
    extErr = zeros(1,n);   %Radio/USB error
    snErr = zeros(1,n);    %Wrong SN reporting
    otherErr = zeros(1,n); %Unknown error
    blErr = zeros(1,n);    %Node that should be in App Mode is in BL (brown out)
    cnt = zeros(1,n);      %Successful Scan  
    vinAll = nan(X,n);     %VIN for each scan for each node
    compAll = nan(X,n);    %All stim channels in compliance for each scan for each node
    
    for i=1:X % scan X times
        
        for j = 1:n
            pause(0.2); %remove this!
            [resp, err] = nnp.transmit(7, uint8([0, 0, node(j), 1, 0]), 0, hex2dec('3c'));
            fprintf(fid, '%3.1f #%3.0f node%1.0f: ', vnet, i, node(j));
            fprintf(fid, '%02X ', resp);
            fprintf(fid, 'ERR=%1.0f ', err);
            fprintf('%3.1f #%3.0f node%1.0f: ', vnet, i, node(j));
            fprintf('%02X ', resp);
            fprintf('ERR=%1.0f ', err);
            if err>0
                if err == 1
                    netErr(j) = netErr(j)+1;
                else
                    extErr(j) = extErr(j)+1;
                end
            else
                if length(resp)>=8  %EMC modules have old bootloader rev which does not report node back
                    sn = double(resp(5))*256+double(resp(4));
                    if sn ~= SN(j)
                        snErr(j) = snErr(j) + 1;
                    else
                        if (isequal(scantype, 'BL') && resp(3)==0) ||  (~isequal(scantype, 'BL') && resp(3)==2)
                            cnt(j) = cnt(j) + 1;
                            
                            %if in App mode, read VIN
                            if ~isequal(scantype, 'BL')
                                pause(0.2) %remove this!
                                resp = double(nnp.read(node(j), '3000', 2, 'uint8'));
                                if length(resp)==1
                                    vin = resp*3.3/256*4;
                                    fprintf(fid, 'VIN: %4.2f', vin);
                                    fprintf('VIN: %4.2f', vin);
                                    vinAll(i, j) = vin;
                                end
                            end
                            
                            %If simulating, check if in compliance
                            if isequal(scantype, 'StimMax')
                                pause(0.2) %remove this!
                                resp = double(nnp.read(node(j), '3210', 5, 'uint8'));
                                if length(resp)==4
                                    fprintf(fid, ' Compliance: %1.0f %1.0f %1.0f %1.0f', resp);
                                    fprintf(' Compliance: %1.0f %1.0f %1.0f %1.0f', resp);
                                    if isequal(resp, [1 1 1 1])
                                        compAll(i, j) = 1;
                                    else
                                        compAll(i, j) = 0;
                                    end
                                else
                                    fprintf(fid, ' Compliance: ? ? ? ?');
                                    fprintf(' Compliance: ? ? ? ?');
                                    compAll(i, j) = NaN;
                                end
                            end
                        elseif ~isequal(scantype, 'BL') && resp(3)==0
                            blErr(j) = blErr(j) + 1;
                        else
                            otherErr(j) = otherErr(j) + 1;
                        end
                    end
                else
                    otherErr(j) = otherErr(j) + 1;
                end
            end
            fprintf(fid, '\n');
            fprintf('\n');
        end % node loop
    end %scan iteration loop
    NETERR = [NETERR; netErr];
    EXTERR = [EXTERR; extErr];
    SNERR = [SNERR; snErr];
    OTHERERR = [OTHERERR; otherErr];
    BLERR = [BLERR; blErr];
    CNT = [CNT; cnt];
    POWER = [POWER; power];
    VIN = [VIN; nanmean(vinAll)];
    COMP = [COMP; nanmean(compAll)];
    
    resp = double(nnp.read(7, '2500', 1,5, 'uint16'));
    if isempty(resp)
        PMCANERR = [PMCANERR; nan(1,5)];
    else
        PMCANERR = [PMCANERR; resp];
    end
    %Get battery voltages and PM Temperature
    resp = double(nnp.read(7, '3000', 13, 'uint8'));
    if isempty(resp)
        PMBAT = [PMBAT; nan(1,3)];
        PMTEMP = [PMTEMP; nan];
    else
        PMBAT = [PMBAT; [resp(8)*256+resp(7) resp(10)*256+resp(9) resp(12)*256+resp(11)]];
        PMTEMP =[PMTEMP; (resp(4)*256+resp(3))/10];
    end
    
end %net voltage loop
save(['Scan' scantype '_' timestamp '.mat'],'NETERR','EXTERR','SNERR','OTHERERR','BLERR','CNT','POWER','VNET','VIN','COMP','PMCANERR','PMBAT','PMTEMP','ADPOWER','ADVREC','ADVNET','ADVSYS')
end
