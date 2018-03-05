function dataOut = NMT_Command( port, node, command, param1, param2 )
%  dataOut = NMT_Command( port, node, command, param1, param2 )
%  dataOut = NMT_Command( port, node, command, param1 )
%  dataOut = NMT_Command( port, node, command )
% 
% port:       serial port for access point
% node:       8 for CT, 7 for PM or 1-15 for RM
% command:    NMT command specified as 1-2 charachter hex string, (e.g. 'A' or '0A') 
%             or as decimal numerical value (e.g. 10) 
% param1:     decimal value
% param2:     decimal value
% dataOut:    command echoed (in decimal) if occured with no errors
%
% Joris Lambrecht - 20170202

    if nargin < 5
        param2 = [];
        if nargin < 4
            param1 = [];
            if nargin <3
                error('needs at least 3 inputs')
            end
        end
    end
        
    % check for valid NMT
    if ischar(command)
        if length(command) > 2
            error('command string type: must be specified as <=2 letter (hex) string');
        else
            command = hex2dec(command);
        end
    else
        if command > 255 || command < 0
            error('command numerical type: subindex must be between 0 and 255');
        end
    end
    

    
    %check for valid param1 and/or param2
    if isempty(param1) && ~isempty(param2)
        error('param2 cannot be provided if param1 is empty');
    elseif ~isempty(param1) && (param1 > 255 || param1 < 0)
        error('param1 must be between 0 and 255 if not empty, []');
    elseif ~isempty(param2) && (param2 > 255 || param2 < 0)
        error('param1 must be between 0 and 255 if not empty, []');
    end
    
    if  isempty(param1) && isempty(param2) 
        data = zeros(1,5, 'uint8');
        data(4) = 1;
        data(5) = command;
    elseif  isempty(param2)
        data = zeros(1,6, 'uint8');
        data(4) = 2;
        data(5) = command;
        data(6) = param1;
    else
        data = zeros(1,7, 'uint8'); 
        data(4) = 3;
        data(5) = command;
        data(6) = param1;
        data(7) = param2;
    end
    [dataRX, err]= TransmitData(port, node, data, 0, hex2dec('34'));
    if err == 0
        dataOut = dataRX(2:end);
    end
    %endfunction

