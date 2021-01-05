function result = backupRestoreRM(nnp, nodes, varargin)
% result = BACKUPRESTORERM(nnp, nodes)
%  reads restoredata (entire EEPROM) for nodes.  
%  result is cell array where index is node, and array at index is the
%  restoredata for that node, or empty if not included or could not be
%  obtained
%
% result = BACKUPRESTORERM(nnp, nodes, restoreData)
%   writes restoreData (partial or entire EEPROM) to specified nodes
% result is success for each node
%

    nnp.networkOff;
    pause(.5);
    nnp.networkOnBootloader;
    pause(1);
    %
    % startAddress = 0;
    % endAddress= 4096;
    %SerialNumber = 201;
    
    restoreData = [];
    
    if nargin > 3
        warning('more input arguments than expected')
    elseif nargin == 3
        restoreData = varargin{:};
        if iscell(restoreData) && size(restoreData,1)>=max(nodes) && size(restoreData,2)==1
            %correct
        else
            disp('restore data should be a cell array with indices matching nodes to restore')
            return;
        end
    end

    result = cell(max(nodes),1);
    
    for node = nodes
        %get SN
        disp(['Node: ' num2str(node)])
        snBytes = uint8([0 0]);

        %get SN
        [resp, err] = nnp.transmit(7, uint8([snBytes, node, 1, 0]), 0, hex2dec('3c'));
        if err == 1
            %CAN error, probably not on network
            disp('not found on network')
        elseif err == 0
            if resp(6) > 56  && resp(8)~= node
                disp('wrong node responding')
            end
            if length(resp)>=8
                snBytes = resp(4:5);

                %select node
                [resp, err] = nnp.transmit(7, uint8([snBytes, node, 1, 0]), 0, hex2dec('3c'));
                if err==0 && length(resp) >= 8 
                    if resp(6) > 56  && resp(8)~= node
                        disp('wrong node responding')
                    end

                    if resp(3) == 1 
                        if isempty(restoreData)
                            result{node} =  readEeprom(nnp);
                        else
                            result{node} = writeEeprom(nnp, restoreData{node});
                        end

                        %deselect node
                        [resp, err] = nnp.transmit(7, uint8([snBytes, node, 1, 0]), 0, hex2dec('3c'));
                        if err==0 && length(resp) >= 8 
                            if resp(6) > 56  && resp(8)~= node
                                disp('wrong node responding')
                            end
                            if resp(3) ~= 0
                                disp('node not deselected')
                            end
                        else
                            disp(['error: ',  nnp.lastError]);   
                        end

                    elseif resp(3) == 2
                        disp('running app, enter BL first')
                    elseif resp(3) == 0
                        disp('node not selected')
                    else
                        disp('unknown err')
                    end
                else
                    disp(['error: ',  nnp.lastError]);
                end
            end
        else
            disp(['error: ',  nnp.lastError]);
        end   
    end
end

%%



function eepromData =  readEeprom(nnp)
%% eepromData = READEEPROM(nnp)
% reads entire EEPROM space from selected bootloader node.  
    packetSize = 44;
    startAddress = 0;
    endAddress = 0;

    pageCommand = 1; %EEPROM
    sizeEeprom = 4096;
    endEeprom = sizeEeprom - 1;
    eepromData = nan(sizeEeprom, 1);
    attempt = 0;
    maxAttempts = 5;
    
    while endAddress < endEeprom 
        endAddress = startAddress + packetSize - 1;
        if endAddress > endEeprom
            endAddress = endEeprom;
            packetSize = endAddress - startAddress + 1;
        end

        addrBytes = [floor(startAddress/256), rem(startAddress, 256), floor(endAddress/256), rem(endAddress, 256) ];

        [resp, err] = nnp.transmit(7, uint8([0, 0, pageCommand, 6, 5, addrBytes, packetSize]), 0, hex2dec('3c'));
        if err > 0 || length(resp) ~= packetSize+1 || resp(1)~=packetSize
            nnp.lastError
            attempt = attempt + 1;
            if attempt > maxAttempts
                disp(['failed' num2str(maxApttempts)  'retries'])
                break 
            else
                continue %retry
            end
        else
            fprintf( '%02X ',resp(2:end));
            fprintf('\n')
            eepromData((startAddress:endAddress)+1) = resp(2:end);
            startAddress = startAddress + packetSize;
            attempt = 0;
        end
    end
end

function success =  writeEeprom(nnp, data)
%% success = WRITEEEPROM(nnp, data)
% writes EEPROM space on selected bootloader node with data (must be <=4096 bytes.

    success = false;
    
    packetSize = 44;
    startAddress = 0;
    endAddress = 0;

    pageCommand = 1; %EEPROM
    sizeEeprom = 4096;
    
    if length(data)>sizeEeprom
        disp('data longer than EEPROM')
        return
    end
    
    endEeprom = sizeEeprom - 1;
    endData = length(data)-1;

    attempt = 0;
    maxAttempts = 5;
    
    h = waitbar(0,'Writing EEPROM...');
    
    while endAddress < endData 
        endAddress = startAddress + packetSize - 1;
        if endAddress > endData 
            endAddress = endData ;
            packetSize = endAddress - startAddress + 1;
        end

        addrBytes = [floor(startAddress/256), rem(startAddress, 256), floor(endAddress/256), rem(endAddress, 256) ];

        packet = data((startAddress:endAddress)+1)';
        
        [resp, err] = nnp.transmit(7, uint8([0, 0, pageCommand, packetSize + 5, 2, addrBytes, packet]), 0, hex2dec('3c'));
        if err > 0 
            nnp.lastError
            attempt = attempt + 1;
            if attempt > maxAttempts
                disp(['failed' num2str(maxAttempts)  'retries'])
                break 
            else
                continue %retry
            end
        else
            if ~isvalid(h) %if waitbar was closed, reopen it
                resp = questdlg('Are you sure you want to cancel writing to EEPROM?', 'Write EEPROM');
                if isequal(resp, 'Yes')
                    return;
                else
                    h = waitbar(endAddress/endData, 'Writing EEPROM...'); %recreate waitbar
                end
            end
            waitbar(endAddress/endData, h);
            
            if ~isequal(resp, [1 0])
                fprintf( '%02X ',resp);
                fprintf('\n')
            end

            startAddress = startAddress + packetSize;
            attempt = 0;
        end
    end
    close(h);
    success = true;
end