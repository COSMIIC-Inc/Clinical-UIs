function [ dataOut ] = Read_File( s, file, address, len, print, fileOut)
%READ_FILE Summary of this function goes here
%   Detailed explanation goes here
dataOut = [];

if nargin < 6
    fileOut = [];
    fid = 1;
    disp('fileOut parameter not included, so printing to command line')
    if nargin < 5
        print = false;
        if nargin < 4
            error('needs at least 4 inputs')
        end
    end
end

switch print
    case {true, 'ascii', 'ASCII', 1}
        print = 1;
    case {'bin', 'binary','Bin','Binary', 2}
        print = 2;
    case {'hex', 'Hex', 3}
        print = 3;    
    case {false, 0}  
        print = 0;
end
switch file
    case {'log', 'Log', 1}
        counter = hex2dec('D0') + 1; %log file init
    case {'param', 'odrestore', 'OD Restore', 2}
        counter = hex2dec('D0') + 2; %OD restore file init
    otherwise
        error('Not a valid file ID')
end
%counter = hex2dec('D0') + hex2dec('0E'); %remaining file

if ~isempty(fileOut)
    fid = fopen(fileOut, 'w+');  %open or create file for writing and discard existing contents 
end

if strcmp(len, 'all')
    len = double(SDO_Read(s,7,'a200', 3, 'uint32'));
    if isempty(len)
        error('len could not be determined')
    elseif len == 0
        disp('no data in log');
        return;
    end
end

%len = uint16(len);
%lenBytes = typecast(len, 'uint8'); %Note: currently len cannot exceed 
msgsize = 48; %msgsize should not exceed 48

address = uint32(address);
while len > 0
    if len > msgsize
        n = uint16(msgsize);
    else
        n = uint16(len);
    end
    lenBytes = typecast(n, 'uint8');
    addressBytes = typecast(address, 'uint8');
    data = [0 0 0 6 addressBytes lenBytes];
    [dataRX, err] = TransmitData(s, 7, data, counter, hex2dec('26'));
    if err == 0
        if length(dataRX) < 4
            disp('response contains no data')
            continue;
        end
        %remaining = dataRX(2:3)
        dataFile = dataRX(4:end)';
        dataOut = [dataOut; dataFile];
        switch print
            case 1
                %print as formatted text
                fprintf(fid, '%s', char(dataFile));
            case 2
                %binary file, no formatting
                fwrite(fid, dataFile);
            case 3
                %up to 16 bytes per line.  Note only woks if msgsize is intefer multiple of 16
                fprintf(fid, '%02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X\n', dataFile);
        end
    else
        %retry
        continue;
    end
    len = len - double(n);
    address = address + uint32(n);
    pause(0.01)
end

if ~isempty(fileOut)
    fclose(fid);
end

