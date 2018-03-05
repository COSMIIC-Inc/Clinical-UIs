function [ output_args ] = WOR_Off( s )
%WOR_OFF Summary of this function goes here
%   Detailed explanation goes here
if nargin < 1
    error('needs at least 1 input');
end

NMT_Command(s, 7, '8C'); 

settings = ReadSettings(s);
if settings.worInt ~= 0
    settings.worInt = 0;
    settingsOut = WriteSettings(s, settings, true);
    if settingsOut.worInt ~= 0
        disp(['wakeInterval set to:', num2str(settingsOut.worInt)])
    end
end

%endfunction

