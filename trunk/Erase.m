function [ out ] = Erase( s,  var)
%ERASE Summary of this function goes here
%   Detailed explanation goes here

cnt = SDO_Read(s,7,'2010',18, 'uint16');
if cnt > 0
    fprintf('block counter at %u, try again\n', cnt);
    return;
end
switch var
    case {'all', 'All', 'FFFF'}
        NMT_Command(s,7,'BB', 255, 255);
    case {'log', 'Log', 'FFFE'}
        NMT_Command(s,7,'BB', 255, 254);
    otherwise
        error('unknown');
end
pause(3);
cnt = 1;
while cnt > 0
    cnt = SDO_Read(s,7,'2010',18, 'uint16');
    pause(1);
    fprintf('Erase at %u\n', cnt);
end

