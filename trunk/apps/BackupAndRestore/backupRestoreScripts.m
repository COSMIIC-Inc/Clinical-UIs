function result = backupRestoreScripts(nnp, varargin)
% result = BACKUPRESTORESCRIPTS(nnp)
%  reads script and application settings space (sectors 10-16 of onboard flash).  
%  result is vector of length 57344
%
% result = BACKUPRESTORERM(nnp, scriptData)
%   writes scriptData (entire sector10-16) to PM
% result is success (1) or failure empty []
%
% Note the PM gets reset, put into bootloader mode, read or written, and
% then exits bootloader mode.  If this function is interrupted the AP radio
% settings may still be set to BL settings

pageSize = 512;
pagesPerSector = 16; %sectors 10-16 are all 16 pages
sectorSize = pagesPerSector*512; 
scriptSectors = 7; %sectors 10-16
result = [];
read = true;

if nargin > 2
    error('too many arguments')
elseif nargin == 2
    data = varargin{1};
    if length(data) == 7*sectorSize
        read = false;
    else
        error(['data should be vector of length:' num2str(7*sectorSize)])
    end
end
    
       
    

%% Enter Bootloader
%Reset PM
if nnp.nmt(7, '9E') == hex2dec('9E')
    %msgbox('Reset successful', 'PM Bootloader', 'help')
else
    msgbox('Could not trigger PM reset.')
end
            
%Store current radio settings and change to BL settings 
savedSettings = nnp.getRadioSettings();

settings = struct('addrAP', hex2dec('BC'), 'addrPM', hex2dec('BC'), 'chan', 5, ...
                'txPower', 20, 'worInt', 0, 'rxTimeout', 50, 'retries', 5);
settingsOut = nnp.setRadioSettings(settings);
if ~isequal(settings, settingsOut)
    msgbox('Could not configure AP for radio communication with PM bootloader', 'AP Configuration', 'error')
end

pause(1)

%enter bootloader
resp = double(nnp.pmboot('14'));
         
if length(resp) == 8 && resp(1) == hex2dec('24')
    %success
else
    disp('could not enter bootloader')
end



%%
startAddress = hex2dec('30000');
endAddress = hex2dec('3DFFF');

if read
    address = startAddress;
    lenRead = 59;
    data = [];

    while address <= endAddress

        if address + lenRead >  endAddress
            lenRead = endAddress - address + 1;
        end

        addr = uint32(address);
        addrBytes = [rem(bitshift(addr, -24), 256), rem(bitshift(addr, -16), 256), rem(bitshift(addr, -8), 256), rem(addr, 256)];
        szBytes = [floor(lenRead/256), rem(lenRead, 256)];

        resp = nnp.pmboot('13', [addrBytes, szBytes]);
        if length(resp) == lenRead+1 && resp(1) == hex2dec('23') %expected response from bootloader
            data = [data resp(2:end)];
            disp(['0x' dec2hex(address), ':' , sprintf('%02X ', resp(2:end))])
        else
            disp(['retrying at 0x' dec2hex(address)])
            %retry without incrementing address
            continue
        end

        address = address + lenRead;   

    end
    
    result = data;
    %end read routine
else
    %writing can't cross page boundaries, so split data up into appropriate
    %packets

    
    nPages = pagesPerSector*scriptSectors;
    firstPacketSize = 12;  %firstPacketSize <= 52
    packetSize = 50;       %packetSize <= 61-1
    
     % Writes should not cross page boundaries, though reads can
    if rem(pageSize-firstPacketSize, packetSize) ~= 0
        error('packetSize*n + firstPacketSize ~= pageSize')
    end
    
    nPacketsPerPage = (pageSize - firstPacketSize)/packetSize + 1;
    packetLengthsPerPage = [firstPacketSize; ones(nPacketsPerPage-1, 1)*packetSize];
    packetLengths = repmat(packetLengthsPerPage, pagesPerSector, 1);
    
    address = startAddress;
    startSector = 10;
    totalPackets = nPacketsPerPage*pagesPerSector*scriptSectors;
    
    %First Erase
    %set the AP timeouts/retries appropriately
    if ~nnp.setRadio('rxTimeout', 251, 'retries', 0)
        msgbox('Could not set AP timeout and retries', 'AP Configuration', 'error')
    end

    nnp.timeout = 2.5;

    resp = nnp.pmboot('12', uint8([startSector startSector+scriptSectors-1]));
    if length(resp)==2 && resp(1) == hex2dec('22') && resp(2) == 1
    else
        msgbox('Erase failed', 'PM Bootloader', 'error');
        return
    end
    %set the AP timeouts/retries appropriately
    if ~nnp.setRadio('rxTimeout', 25, 'retries', 5)
        msgbox('Could not set AP timeout and retries', 'AP Configuration', 'error')
    end
    nnp.timeout = 1.5;

    
    h = waitbar(0, 'Writing Script/Application Settings Space...');
    totalPacketCount = 0;
    
    sector =1;
    
    
    while sector <= scriptSectors
        
        packets = mat2cell(data((1:sectorSize) + (sector-1)*sectorSize)', packetLengths);
        
        retrySector = false;
        resetTotalPacketCount = totalPacketCount;
        
        for i=1:length(packets)
            while true
                if isvalid(h)
                    waitbar(totalPacketCount/totalPackets, h)
                else
                    resp = questdlg('Are you sure want to quit?', 'Writing App');
                    if isequal(resp, 'Yes')
                        return;
                    else
                        h = waitbar(totalPacketCount/totalPackets, 'Writing App...');
                    end
                end
                totalPacketCount = totalPacketCount+1;
                            
                if rem(i-1, nPacketsPerPage) == 0 %first packet of page
                    addr = uint32(address);
                    addrBytes = [rem(bitshift(addr, -24), 256), rem(bitshift(addr, -16), 256), rem(bitshift(addr, -8), 256), rem(addr, 256)];                        
                    pgszBytes = [floor(pageSize/256), rem(pageSize, 256)];

                    resp = double(nnp.pmboot('10', uint8([addrBytes, pgszBytes, sector+startSector-1, packets{i}'])));
                    if length(resp) == 2 && resp(1) == hex2dec('20')
                        if resp(2) ~= 1
                            errStr = '"Bad parameters" response to write COMMAND.  Make sure there are no interfering radios';
                        else
                            address = address + pageSize;
                            break; % good response
                        end
                    else

                        errStr =sprintf('Error writing first packet of page, sector %u, address 0x%06X ', sector, address);

                    end
                else
                    resp = nnp.pmboot('11', uint8(packets{i}'));
                    if length(resp) == 2 && resp(1) == hex2dec('21')
                        if resp(2) ~= 1
                            errStr = '"Bad parameters" response to write DATA.  Make sure there are no interfering radios';
                        else
                            break; % good response
                        end
                    else
                        errStr = sprintf('Error writing packet #%u of page, sector %u, address 0x%06X ', rem(i-1, nPacketsPerPage), sector, address);
                    end
                end
                %if we're here an error has occurred
                resp = questdlg([errStr, ' Do you want to retry? If "Beginning of Sector" the Sector will be erased before rewriting'], 'PM Bootloader', 'Last Address', 'Beginning of Sector', 'No', 'Last Address');
                if isequal(resp, 'No')
                    if isvalid(h)
                        close(h)
                    end
                    return
                elseif isequal(resp, 'Beginning of Sector')
                    retrySector = true;
                    break;
                else
                    %continue in retry loop
                end
            end %end retry while loop
            pause(0.01); %it seems we cannot send the following radio message too soon, or we run into occasional errors
            if retrySector
                break;
            end
        end %end packet for loop

        if retrySector
            %First Erase
            %set the AP timeouts/retries appropriately
            if ~nnp.setRadio('rxTimeout', 251, 'retries', 0)
                msgbox('Could not set AP timeout and retries', 'AP Configuration', 'error')
            end

            nnp.timeout = 2.5;

            
            resp = nnp.pmboot('12', uint8([startSector+sector-1 startSector+sector-1]));
            if length(resp)==2 && resp(1) == hex2dec('22') && resp(2) == 1
            else
                msgbox('Erase failed', 'PM Bootloader', 'error');
                return
            end
            %set the AP timeouts/retries appropriately
            if ~nnp.setRadio('rxTimeout', 25, 'retries', 5)
                msgbox('Could not set AP timeout and retries', 'AP Configuration', 'error')
            end
            nnp.timeout = 1.5;

            totalPacketCount = resetTotalPacketCount;
        else
            sector = sector + 1;
        end

    end %end sector for loop
    if isvalid(h)
        close(h)
        result = true;
    end

    
end % end Write routine

%%

%exit bootloader
waittime = 18;

resp = double(nnp.pmboot('15'));
if length(resp)==1 && resp == hex2dec('25')
    h=waitbar(0, 'Waiting for PM Application to Start...');
    for i = 1:waittime
        if isvalid(h)
            waitbar(i/waittime, h)
            pause(1);
        end
    end
    if isvalid(h)
        close(h);
    end
end

settingsOut = nnp.setRadioSettings(savedSettings);
if ~isequal(savedSettings, settingsOut)
    msgbox('Could not configure AP for radio communication with PM App', 'AP Configuration', 'error')
end