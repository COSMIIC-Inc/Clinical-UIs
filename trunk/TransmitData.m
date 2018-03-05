function [dataRX, errOut]= TransmitData(s, node, data, counter, protocol)
    
errOut = 7;
dataRX = [];
rssioffset = 74;

if length(data) + 7 >  62 %Maximum bytes on Access Point CHECK THIS! <<TODO
    error('data to write is too long');
end

%if netID = 0, then response is always 7 
if node == 7,  
    netID = 1;
else
    netID = 1;
end

fwrite(s, uint8([255, 71, length(data)+7  protocol, counter, netID, node, data]), 'uint8');
if s.BytesAvailable
    if s.UserData.verbose
        disp('Data in buffer - will be flushed');
    end
    fread(s, s.BytesAvailable); %clear buffer
end

t = tic;
while s.BytesAvailable == 0 && toc(t)< s.UserData.timeout
    %delay loop
    %disp('delaying')
end
if s.BytesAvailable
    resp = uint8(fread(s, s.BytesAvailable, 'uint8')');
    if s.UserData.verbose
        disp(['Response: ' num2str(resp,' %02X')]);
    end
    
    %radio response on AccessPoint
    if resp(1)==255 && length(resp)==resp(3) && length(resp)>=3 && resp(2)==6 
        
        %if message is long enough to include RSSI/LQI/CRC, calculate it
        if length(resp) >= 7 %minimum usb header (3) + radio addr, len, rssi, lqi
             rssiraw = resp(end-1);
             lqiraw = resp(end);
             if rssiraw < 128
                 s.UserData.RSSI = double(rssiraw)/2 - rssioffset;
             else
                 s.UserData.RSSI = (double(rssiraw)-256)/2 - rssioffset;
             end
             if lqiraw >= 128
                s.UserData.LQI = lqiraw - 128;
             else
                 disp(['Bad CRC:' num2str(resp(1:end), ' %02X')]');
                 errOut = 7;
                 return;
             end
             
             if s.UserData.verbose
                disp(['RSSI: ', num2str(s.UserData.RSSI), 'dB | LQI: ', num2str(s.UserData.LQI)]);
             end
        end
                       
        if length(resp) >= 13 
            %PM flagged response as error message     
            if resp(7) > 127 
               disp(['PM Internal/CAN error: ', num2str(resp(12:end-2),' %02X')]); 
               errOut = 1;
            
            %PM response doesn't match request
            %JML TODO: not sure all message types echo these 4 elements!
            elseif resp(4)~= protocol || resp(5)~=counter || resp(6)~=netID || resp(7)~=node
                disp(['PM response does not echo request: ' num2str(resp(1:end-2), ' %02X')])
                errOut = 6;

            %Expected response!
            else 
                dataRX = resp(11:end-2);
                errOut = 0; 
            end
        else
            disp(['Short message: ', num2str(resp(1:end-2), ' %02X')]);
            errOut = 2;
        end

    %Radio timeout on AccessPoint    
    elseif resp(1)==255 && length(resp)==resp(3) && length(resp)==3 && resp(2)==13 
        disp('Radio Timeout')
        errOut = 3;
    
    %Unknown response from AccessPoint
    else 
        disp(['Bad Response: ', num2str(resp(1:end-2), ' %02X')]);
        errOut = 4;
    end
    
%No response from AccessPoint
else
    disp('No Response'); 
    errOut = 5;
end
        
%endfunction TransmitData
