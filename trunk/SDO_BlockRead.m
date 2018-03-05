function dataOut = SDO_BlockRead(port, node, indexOD, subIndexOD, numSubIndices, readType) 
% SDO_BlockRead Read Multple Object Dictionary subindices
% dataOut = SDO_BlockRead(port, node, indexOD, subIndexOD, numSubIndices, readType) 
% dataOut = SDO_BlockRead(port, node, indexOD, subIndexOD, numSubIndices)
%  assumes readType is 'uint8'
%
% port:       serial port for access point
% node:       7 for PM or 1-15 for RM
% indexOD:    OD index specified as 4 character hex string, (e.g. '1F53')
% subIndexOD: OD subindex specified as 1-2 charachter hex string, (e.g. 'A' or '0A') 
%             or as decimal numerical value (e.g. 10) 
% numSubIndices: decimal value indicating number of subindicse to read.
%             Note: it is expected that all subindices to be read have same
%             (scalar) type.
% *readType:  'uint8', 'uint16', 'uint32', 'int8', 'int16', 'int32', or 'string'
%             use 'uint8' for bytearrays
% dataOut:    Object Dictionary entry cast to the specified readType
%
%NOTE: assumes little-endian processor for byte conversions to uint16, uint32, etc.
%use: <code> [str,maxsize,endian] = computer </code>  to check your system
%
% Joris Lambrecht - 20170202
        
    if nargin < 6
        readType = 'uint8';
        if nargin < 5
           error('needs at least 5 inputs')
        end
    end
    
    data = zeros(1,4, 'uint8');    
    dataOut = [];
    
    if node == 0 
        error('Message cannot be broadcast')
    end
    % check for valid OD Index
    if ischar(indexOD)
        if length(indexOD) ~= 4
            error('OD index must be specified as 4 letter (hex) string');
        else
            data(1) = hex2dec(indexOD(3:4)); %low byte
            data(2) = hex2dec(indexOD(1:2)); %high byte
        end
    else   
        error('index must be as a string');
    end
    % check for valid OD SubIndex
    if ischar(subIndexOD)
        if length(subIndexOD) > 2
            error('OD subindex string type: must be specified as <=2 letter (hex) string');
        else
            data(3) = hex2dec(subIndexOD);
        end
    else
        if subIndexOD > 255 || subIndexOD < 0
            error('OD subindex numerical type: subindex must be between 0 and 255');
        else
            data(3) = subIndexOD;
        end
    end
    data(4) = numSubIndices; 

    [dataRX, err] = TransmitData(port, node, data, 0, hex2dec('30'));

    if err == 0
        if strcmpi(readType, 'string')
            dataOut = char(typecast(dataRX(2:end), 'uint8')); %first byte is length byte
        else
            dataOut = typecast(dataRX(2:end), readType); %first byte is length byte
        end
    end
%endfunction SDO_BlockRead

