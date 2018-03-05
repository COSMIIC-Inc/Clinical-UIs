function [ dataOut ] = Read_Memory( s, node, memSelect, address, len, print)
%READ_MEMORY Summary of this function goes here
%   Detailed explanation goes here
dataOut = [];

if nargin < 6
    print = false;
    if nargin < 5
        error('needs at least 5 inputs')
    end
end

if node == 0 
    error('Message cannot be broadcast')
end
switch memSelect
    case{'flash', 'Flash', 1}
        memSelect = 1;
    case{'remoteflash', 'remote flash', 'Remote Flash', 2}
        if node ~= 7
            disp('No Remote Flash on RMs')
        end
        memSelect = 2;
    case{'remoteram', 'remote ram',  'Remote RAM', 3}
        if node ~= 7
            disp('No Remote RAM on RMs')
        end
        memSelect = 3;
    case{'eeprom', 'EEPROM', 4}
        if node == 7
            disp('No EEPROM on PM')
        end
        memSelect = 4;
    otherwise
        error('Bad memory selection')
end

while len > 0    
    SDO_Write(s, node, '2020', 1, address, 'uint32');   %set address
    SDO_Write(s, node, '2020', 4, memSelect, 'uint8');  %select memory
    SDO_Write(s, node, '2020', 5, 1, 'uint8');          %trigger read
    if node ~= 7
        pause(0.1); %<<TODO why don't i need pause here.  PM is updating only
    end
    %at 100ms
    err = SDO_Read(s, node, '2020', 7, 'uint8');              %check for errors
    if err == 0
        dataRX = SDO_Read(s, node, '2020', 2, 'uint8');
    else
        disp(['error on memory read: ' num2str(err)]);
        continue;
    end
    if length(dataRX)<4
        disp('no address back')
        continue;
    end
    addressback = typecast(dataRX(end-3:end), 'uint32');
    if addressback ~=  address
        disp('address back does not match')
        continue;
    end
    mem = dataRX(1:end-4)';
    if length(mem) > len
        mem = mem(1:len); %cut 
    end
    if(print) %up to 32 bytes per line
        fprintf('%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X\n', mem)
        %fprintf('%08X : %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X\n', address, mem)
    end
    dataOut = [dataOut; mem];
    len = len - length(mem);
    address = address + length(mem);
end




