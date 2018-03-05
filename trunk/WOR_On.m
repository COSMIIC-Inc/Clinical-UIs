function [ output_args ] = WOR_On(s, wakeInterval )
%WORON Summary of this function goes here
%   Detailed explanation goes here
if nargin < 2
    wakeInterval = 20;
    if nargin < 1
        error('needs at least 1 input');
    end
end
settings = ReadSettings(s);
if settings.worInt ~= wakeInterval
    settings.worInt = wakeInterval;
    settingsOut = WriteSettings(s, settings, true);
    if settingsOut.worInt ~= wakeInterval
        disp(['wakeInterval set to:', num2str(settingsOut.worInt)])
    end
end

NMT_Command(s, 7, '8B', uint8(wakeInterval),0); 


%endfunction

