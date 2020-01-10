function [result] = loadscript(nnp, SP, data)
%result = LOADSCRIPT(nnp, SP, data)
%   Detailed explanation goes here

T = 32; %up to 48, SE uses 32 (max bytes to transfer per radio packet)
N = length(data);
nPackets = floor(N/T) + double(rem(N,T)>0);
result = [];

counter = nPackets -1;
address = 0;

settings = nnp.getRadioSettings;
if settings.rxTimeout<100
    warning('Radio Timeout may not be sufficient')
end

for i=1:nPackets
    addrBytes = typecast(uint16(address), 'uint8');
    
    if i==nPackets
        pktN = rem(N,T);
        if pktN==0
            pktN = T;
        end
    else
        pktN = T;
    end
    
    pktData = data(address+1:address+pktN);
    if size(pktData, 1)>1
        pktData = pktData'; % change column vector to row vector
    end
    %counter = 0;
    message = [hex2dec('50'), hex2dec('1f'), SP, pktN+2, addrBytes, pktData];
    [result, err]= nnp.transmit(7, message, counter, hex2dec('A4'));
    if err
        disp(nnp.lastError)
    end
    if ~isequal(result, [1 0])
        return
    end
    pause(0.1)
    address = address + T; 
    counter = counter-1;
end

