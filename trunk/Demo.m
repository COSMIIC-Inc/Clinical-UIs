%% This script uses Sections
%To run just a section, with cursor in section (code separated by %%'s),
%hit CTRL+ENTER

%% Open the USB port for the Access Point
%first close all ports in case we unplugged Access Point or deleted serial port
%object
try
    s = instrfind
    fclose(s); 
    delete(s); 
catch
    disp('No ports left open')
end

% Set the COM Port here to match the settings in your device manager!
s = serial('COM3', 'Baudrate', 115200);
fopen(s);

s.UserData = struct('RSSI', 0, 'LQI', 0, 'verbose', false, 'timeout', 0.5);
%%  
%Read and Write Radio settings 
settings = ReadSettings(s);

% settings.chan = 5
% settings = WriteSettings(s, settings, true); % temporary change not saved to flash
% settings = WriteSettings(s, settings); % change saved to flash

%% The following are "anonymous" functions in Matlab (replaces inline from older versions) 
% these need to be recreated if serial port object "s" is deleted
% Makes calling commonly used functions easier
networkOn      = @() NMT_Command(s, 7, '95'); %turn ON network
networkOff     = @() NMT_Command(s, 7, '96'); %turn OFF network 
worOn          = @(wakeInterval) WOR_On(s, wakeInterval);
worOff         = @() WOR_Off(s);%turn OFF WOR

enterWaiting      = @() NMT_Command(s, 0, '07'); %Enter Waiting
enterPatient      = @() NMT_Command(s, 0, '03'); %Enter Patient Mode
enterTestStim     = @(mode) NMT_Command(s, 0, '0Rea5', mode); %Enter "Y Manual" Mode
enterTestPatterns = @(pattern) NMT_Command(s, 0, '04', pattern); %Enter "X Manual" Mode 
enterTestRaw      = @(node, ch) NMT_Command(s, 0, '0C', node+(ch-1)*16); %Enter Raw MES Mode
enterTestFeatures = @() NMT_Command(s, 0, '09'); %Enter "Produce X" Mode 


getSwRev       = @(node) SDO_Read(s, node, '1018', 3, 'uint32'); %RM rev
setVNET        = @(V) SDO_Write(s, 7, '3010', 0, uint8(V), 'uint8'); %RM VNET

setMESgain1    = @(node, gain) SDO_Write(s, node, '3411', 1, uint8(gain), 'uint8'); %set MES gain.  only takes effect during waiting
setMESgain2    = @(node, gain) SDO_Write(s, node, '3511', 1, uint8(gain), 'uint8'); %set MES gain.  only takes effect during waiting

checkStacks    = @() SDO_BlockRead(s, 7, '3030', 1,9,'uint8');
saveOD         = @(node) NMT_Command(s, node, '0A');
resetPM        = @() NMT_Command(s, 7, '9E'); 
setSync        = @(T) SDO_Write(s, 7, '1006', 0, uint32(T), 'uint32'); %PM sync interval in ms

flushLog       = @() NMT_Command(s,7,'B8',1);
initDirectory  = @() NMT_Command(s,7,'B9');
getLogCursor   = @() SDO_Read(s,7,'a200', 3, 'uint32');

disp('helper functions declared')

%% PDO Settings information
%          RPDO                           TPDO
%-------------------------------------------------------------------------------------
%mapping : OD subindices to put data      OD subindices to get data
%
%id      : Source COB-ID                  COB-ID 
%
%type    : 0-240: synchronous -           0: acyclic synchronous -PDO sent when value changed AND SYNC received or on RTR
%              processed on next SYNC     1: cyclic synchronous - PDO sent when SYNC received or on RTR
%          255: asynchronous -            2-240: cyclic synchronous - PDO sent every X SYNCs or on RTR
%              processed immediately      252: synchronous RTR only - PDO sent when SYNC AND RTR received
%              when data arrives          253: asynchronous RTR only - PDO sent when RTR received
%                                         254-255: asynchronous - PDO sent when value changed 
%                                                  (can be limited by inhibit and event timer)
%
%                                         Note: we usually use 0 or 1 to
%                                         enable, and 253 to disable
%
%inhibit : not applicable (set to 0)      minimum time required between asynch PDOs (in 100us).  
%                                         Not applicable if type < 254
%
%compat  : script to run upon reception   not applicable (set to 0)
%          not applicable for RMs
%
%timer   : not applicable (set to 0)      Timer (in ms) between asynch PDOs if value changed.  Not applicable if
%                                         type < 254

%% Set up PM RPDOs
RPDO = [];

RPDO.mapping = cell(8,1);
RPDO.mapping{1} = uint32(hex2dec({'1f530108','1f530208','1f530308','1f530408','1f530508','1f530608','1f530708','1f530808'})');
RPDO.mapping{2} = uint32(hex2dec({'1f530908','1f530a08','1f530b08','1f530c08','1f530d08','1f530e08','1f530f08','1f531008'})');
RPDO.mapping{3} = uint32(hex2dec({'1f531108','1f531208','1f531308','1f531408','1f531508','1f531608','1f531708','1f531808'})');
RPDO.mapping{4} = uint32(hex2dec({'1f531908','1f531a08','1f531b08','1f531c08','1f531d08','1f531e08','1f531f08','1f531008'})');
RPDO.mapping{5} = uint32(hex2dec({'1f532108','1f532208','1f532308','1f532408','1f532508','1f532608','1f532708','1f532808'})');
RPDO.mapping{6} = uint32(hex2dec({'1f532908','1f532a08','1f532b08','1f532c08','1f532d08','1f532e08','1f532f08','1f533008'})');
RPDO.mapping{7} = uint32(hex2dec({'1f533108','1f533208','1f533308','1f533408','1f533508','1f533608','1f533708','1f533808'})');
RPDO.mapping{8} = uint32(hex2dec({'1f533908','1f533a08','1f533b08','1f533c08','1f533d08','1f533e08','1f533f08','1f533008'})');

RPDO.id = uint32(hex2dec({'00000181','00000182','00000183','00000184','00000185','00000186','00000189','0000018a'})');
RPDO.type = uint8(255); %process immediately when data received
% RPDO.type = uint8(0); %process on next SYNC
RPDO.inhibit = uint16(0); %not relevant for RPDO
RPDO.compat = uint8(0); %script pointer for script that runs when PDO is received
RPDO.timer = uint16(0); %not relevant for RPDO

%Write to OD
for i=1:8  
    SDO_BlockWrite(s, 7, ['160' num2str(i-1)], 1, 8, RPDO.mapping{i}, 'uint32');
    SDO_Write(s, 7, ['140' num2str(i-1)], 1, RPDO.id(i), 'uint32');
    SDO_Write(s, 7, ['140' num2str(i-1)], 2, RPDO.type, 'uint8');
    SDO_Write(s, 7, ['140' num2str(i-1)], 3, RPDO.inhibit, 'uint16');
    SDO_Write(s, 7, ['140' num2str(i-1)], 4, RPDO.compat, 'uint8');
    SDO_Write(s, 7, ['140' num2str(i-1)], 5, RPDO.timer, 'uint16');
end
%Read back from OD
for i=1:8
    dec2hex(SDO_BlockRead(s, 7, ['160' num2str(i-1)], 1, 8, 'uint32'))
    dec2hex(SDO_Read(s, 7, ['140' num2str(i-1)], 1, 'uint32'))
    dec2hex(SDO_Read(s, 7, ['140' num2str(i-1)], 2, 'uint8'))
    dec2hex(SDO_Read(s, 7, ['140' num2str(i-1)], 3, 'uint16'))
    dec2hex(SDO_Read(s, 7, ['140' num2str(i-1)], 4, 'uint8'))
    dec2hex(SDO_Read(s, 7, ['140' num2str(i-1)], 5, 'uint16'))
end

%% Set up PM TPDOs

TPDO = [];

TPDO.mapping = cell(8,1);
TPDO.mapping{1} = uint32(hex2dec({'30210108','30210208','30210308','30210408','30210508','30210608','30210708','30210808'})');
TPDO.mapping{2} = uint32(hex2dec({'30210908','30210a08','30210b08','30210c08','30210d08','30210e08','30210f08','30211008'})');
TPDO.mapping{3} = uint32(hex2dec({'30211108','30211208','30211308','30211408','30211508','30211608','30211708','30211808'})');
TPDO.mapping{4} = uint32(hex2dec({'30211908','30211a08','30211b08','30211c08','30211d08','30211e08','30211f08','30212008'})');
TPDO.mapping{5} = uint32(hex2dec({'30212108','30212208','30212308','30212408','30212508','30212608','30212708','30212808'})');
TPDO.mapping{6} = uint32(hex2dec({'30212908','30212a08','30212b08','30212c08','30212d08','30212e08','30212f08','30213008'})');
TPDO.mapping{7} = uint32(hex2dec({'00000000','00000000','00000000','00000000','00000000','00000000','00000000','00000000'})');
TPDO.mapping{8} = uint32(hex2dec({'00000000','00000000','00000000','00000000','00000000','00000000','00000000','00000000'})');

TPDO.id = uint32(hex2dec({'00000187','00000287','00000387','00000487','000001C7','00000247','80000000','80000000'})');
TPDO.type = uint8(1); %sent with every sync, regardless if data has changed
% TPDO.type = uint8(0);  %sent with every sync, only if data has changed
% TPDO.type = uint8(253); %disabled
TPDO.inhibit = uint16(0);  %not relevant for synchronous
TPDO.compat = uint8(0);  %not relevant for TPDO
TPDO.timer = uint16(0); %not relevant for synchronous

%Write to OD
for i=1:8
    SDO_BlockWrite(s, 7, ['1A0' num2str(i-1)], 1, 8, TPDO.mapping{i}, 'uint32');
    SDO_Write(s, 7, ['180' num2str(i-1)], 1, TPDO.id(i), 'uint32');
    SDO_Write(s, 7, ['180' num2str(i-1)], 2, TPDO.type, 'uint8');
    SDO_Write(s, 7, ['180' num2str(i-1)], 3, TPDO.inhibit, 'uint16');
    SDO_Write(s, 7, ['180' num2str(i-1)], 4, TPDO.compat, 'uint8');
    SDO_Write(s, 7, ['180' num2str(i-1)], 5, TPDO.timer, 'uint16');
end
%Read back from OD
for i=1:8
    dec2hex(SDO_BlockRead(s, 7, ['1A0' num2str(i-1)], 1, 8, 'uint32'))
    dec2hex(SDO_Read(s, 7, ['180' num2str(i-1)], 1, 'uint32'))
    dec2hex(SDO_Read(s, 7, ['180' num2str(i-1)], 2, 'uint8'))
    dec2hex(SDO_Read(s, 7, ['180' num2str(i-1)], 3, 'uint16'))
    dec2hex(SDO_Read(s, 7, ['180' num2str(i-1)], 4, 'uint8'))
    dec2hex(SDO_Read(s, 7, ['180' num2str(i-1)], 5, 'uint16'))
end

%%
%node = [1 2 3 4 5 6 9 10];
node = [4 6];
%% Set up RM TPDOs to send back Accelerometers and temperature
TPDO = [];
TPDO.mapping = uint32(hex2dec({'20110120','20030110','00000000','00000000','00000000','00000000','00000000','00000000'})');
TPDO.id = uint32(hex2dec('00000180'));
TPDO.type = uint8(1); %sent with every sync, regardless if data has changed
% TPDO.type = uint8(0);  %sent with every sync, only if data has changed
% TPDO.type = uint8(253);  %disabled
TPDO.inhibit = uint16(0); %not relevant for synchronous
TPDO.compat = uint8(0); %not relevant for RMs
TPDO.timer = uint16(0); %not relevant for synchronous


for i=1:length(node)
    %BlockWrite isnt implemented at CAN level.
    for j =1:8 
        SDO_Write(s, node(i), '1A00', j, TPDO.mapping(j), 'uint32');
    end
    %SDO_BlockWrite(s, node(i), '1A00', 1, 8, RTDO.mapping, 'uint32');
    SDO_Write(s, node(i), '1800', 1, TPDO.id+node(i), 'uint32');
    SDO_Write(s, node(i), '1800', 2, TPDO.type, 'uint8');
    SDO_Write(s, node(i), '1800', 3, TPDO.inhibit, 'uint16');
    SDO_Write(s, node(i), '1800', 4, TPDO.compat, 'uint8');
    SDO_Write(s, node(i), '1800', 5, TPDO.timer, 'uint16');
end
for i=1:length(node)
    dec2hex(SDO_BlockRead(s, node(i), '1A00', 1, 8, 'uint32'))
    dec2hex(SDO_Read(s, node(i), '1800', 1, 'uint32'))
    dec2hex(SDO_Read(s, node(i), '1800', 2, 'uint8'))
    dec2hex(SDO_Read(s, node(i), '1800', 3, 'uint16'))
    dec2hex(SDO_Read(s, node(i), '1800', 4, 'uint8'))
    dec2hex(SDO_Read(s, node(i), '1800', 5, 'uint16'))
end

%% Set up RM RPDOs for stim mapping in TestY mode
RPDO = [];

RPDO.mapping = uint32(hex2dec({'32120110','32120210','32120310','32120410','00000000','00000000','00000000','00000000'})');
RPDO.id = uint32(hex2dec({'00000187','00000287','00000387','00000487','00000207','00000307','00000407','00000507'})');
RPDO.type = uint8(255); %process immediately when data received
% RPDO.type = uint8(0); %process on next SYNC
RPDO.inhibit = uint16(0); %not relevant for RPDO
RPDO.compat = uint8(0); %not relevant for RM
RPDO.timer = uint16(0); %not relevant for RPDO

for i=1:length(node)
    %BlockWrite isnt implemented at CAN level.
    for j =1:8 
        SDO_Write(s, node(i), '1600', j, RPDO.mapping(j), 'uint32');
    end
    %SDO_BlockWrite(s, node(i), '1600', 1, 8, RPDO.mapping, 'uint32');
    SDO_Write(s, node(i), '1400', 1, RPDO.id(i), 'uint32');
    SDO_Write(s, node(i), '1400', 2, RPDO.type, 'uint8');
    SDO_Write(s, node(i), '1400', 3, RPDO.inhibit, 'uint16');
    SDO_Write(s, node(i), '1400', 4, RPDO.compat, 'uint8');
    SDO_Write(s, node(i), '1400', 5, RPDO.timer, 'uint16');
end
for i=1:length(node)
    dec2hex(SDO_BlockRead(s, node(i), '1600', 1, 8, 'uint32'))
    dec2hex(SDO_Read(s, node(i), '1400', 1, 'uint32'))
    dec2hex(SDO_Read(s, node(i), '1400', 2, 'uint8'))
    dec2hex(SDO_Read(s, node(i), '1400', 3, 'uint16'))
    dec2hex(SDO_Read(s, node(i), '1400', 4, 'uint8'))
    dec2hex(SDO_Read(s, node(i), '1400', 5, 'uint16'))
end

%%
fclose(s)

%%
s = instrfind
for i=1:length(s), fclose(s(i)); delete(s(i)); end