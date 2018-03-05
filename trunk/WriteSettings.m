function [ settings ] = WriteSettings(s,  settingsIn , temp)
%WRITESETTINGS Summary of this function goes here
%   Detailed explanation goes here

settings = []; %initialize output
if s.BytesAvailable
    fread(s, s.BytesAvailable); %clear buffer
end

%optional parameter to make settings temporary.  
if nargin < 3;
    temp = false;
end
if temp == true
    cmd = 74; %temporary
else 
    cmd = 72;
end


fwrite(s, uint8([255 cmd 10 ...
               settingsIn.addrAP...
               settingsIn.addrPM ...
               settingsIn.chan ...
               settingsIn.txPower ...
               settingsIn.worInt...
               settingsIn.rxTimeout ...
               settingsIn.retries ]), 'uint8');

t = tic;
while s.BytesAvailable == 0 && toc(t)< s.UserData.timeout
    %delay loop
end
if s.BytesAvailable 
    resp = fread(s, s.BytesAvailable, 'uint8');
    if resp(1)==255 && length(resp)==resp(3) && length(resp)==10 && resp(2) == 6
        settings.addrAP  = resp(4);
        settings.addrPM  = resp(5);
        settings.chan    = resp(6);
        settings.txPower = resp(7);
        settings.worInt  = resp(8);
        settings.rxTimeout = resp(9);
        settings.retries = resp(10);
    else
        warning(['Bad Response: ' num2str(resp, '%02X')]);
    end
else
   warning('No Response');          
end


%endfunction

