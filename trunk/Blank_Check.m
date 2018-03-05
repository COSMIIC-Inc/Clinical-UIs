function [ address ] = Blank_Check(s)
NMT_Command(s, 7, 'BC');
pause(3);
response = uint32(SDO_Read(s, 7, '2010', 19, 'uint32'));
address = bitand(response, hex2dec('FFFFFF'));
if bitget(response, 32)
    fprintf('non blank value found at %06x\n', address);
elseif bitget(response, 31)
    fprintf('blank check error at %06x\n', address);
else
    fprintf('All blank\n');
end

