function dataOut = SDO_BlockWrite(port, node, indexOD, subIndexOD, numSubIndices, writeData, writeType) 
% SDO_BlockRead Write Multple Object Dictionary subindices
% dataOut = SDO_BlockWrite(port, node, indexOD, subIndexOD, numSubIndices, writeData, writeType) 
% dataOut = SDO_BlockWrite(port, node, indexOD, subIndexOD, numSubIndices, writeData)
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
% writeData:  array of values to be sent (will be converted to writeType,
%             if not already)
% *writeType:  'uint8', 'uint16', 'uint32', 'int8', 'int16', 'int32', or 'string'
%             use 'uint8' for bytearrays
% dataOut:    Object Dictionary entry cast to the specified readType
%
%NOTE: assumes little-endian processor for byte conversions to uint16, uint32, etc.
%use: <code> [str,maxsize,endian] = computer </code>  to check your system
%
% Joris Lambrecht - 20170202
        
    if nargin < 7
        writeType = 'uint8';
        if nargin < 6
           error('needs at least 6 inputs')
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
    
    if strcmpi(writeType, 'string')
        error('string is not supported for SDO_BlockWrite');
    end
    writeData = cast(writeData, writeType); % make sure data is actually assigned as specified
    writeBytes = typecast(writeData, 'uint8');
    len = length(writeBytes);
    switch writeType
        case {'uint8', 'int8'}
            mul = 1;
            data(4) = numSubIndices;
        case {'uint16', 'int16'}
            mul = 2;
            data(4) = numSubIndices + 64; %set bit6
        case {'uint32', 'int32'} 
            mul = 4;
            data(4) = numSubIndices + 128; %set bit 7
        otherwise
            error('unsupported type');
    end
    if len ~= numSubIndices*mul
        error('number of data bytes does not match numSubIndices and writeType')
    end
    
    [dataRX, err] = TransmitData(port, node, [data writeBytes], 0, hex2dec('B0'));
    if err == 0
        dataOut = dataRX(2:end);
    end
%endfunction SDO_BlockWrite

