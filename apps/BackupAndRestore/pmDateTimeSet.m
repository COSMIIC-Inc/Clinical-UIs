function result = pmDateTimeSet(nnp)
% set the data and time in the PM
% 1) NMT: Halt RTC so  DateTime_Date and DateTime_Time (2004.1-2) don't 
% update after trying to set them in step 2 and 3,  NMT 0x97
% 2) SDOWrite: DateTime_Date  2004.1
% 3) SDOWrite: DateTime_Time  2004.2
% 4) NMT: Set RTC (also restarts RTC) NMT 0x88

% get current date from PC
pcTime=datetime('now');
% convert these into the components needed for PM
% date is four bytes
% byte 0 = DOM day of month.  5 bits
% byte 1 = month, 4 bits
% bytes 2-3 = year, 12 bits
pmMonth=uint8(month(pcTime));
pmDay=uint8(day(pcTime));
pmYear=typecast(uint16(year(pcTime)),'uint8'); % cast this into type needed
pmDate=typecast([pmDay, pmMonth, pmYear(1), pmYear(2)],'uint32');
% Convert pcTime to time elements
% time is four bytes
% byte 0 = sec, 6 bits
% byte 1 = min, 6 bits
% byte 2 = hour, 5 bits
% byte 3 = DOW day of week, 4 bits,  
% Matlab DOW 1 based starting Sunday, NNP zero based?
pmSec=uint8(second(pcTime));
pmMin=uint8(minute(pcTime));
pmHour=uint8(hour(pcTime));
pmDOW=uint8(weekday(pcTime)-1);
pmTime=typecast([pmSec,pmMin,pmHour,pmDOW],'uint32');
% % send the update
% for function I need to check whether nmt returns nmt value
% and for write I need to check whether write returns 0
% if isequal(resp, 0)
% Halt the RTC

resp=nnp.nmt(7,'97'); 
if resp ~= hex2dec('97')
    result=1;% error
    disp('Error stopping RTC');
    return;
end
pause(.4); % added pause to make sure clock stops
% Write the data
resp=nnp.write(7,'2004',1,pmDate,'uint32');
if ~isequal(resp, 0)
        result=1;% error
        disp('Error writing date');
        return;
end
resp=nnp.write(7,'2004',2,pmTime,'uint32');
if ~isequal(resp, 0)
        result=1;% error
        disp('Error writing time');
        return;
end
pause(.4); 
% restart the RTC
resp=nnp.nmt(7,'88'); 
if resp ~= hex2dec('88')
    result=1;% error
    disp('Error starting RTC');
    return;
end
result=0; %0 means success
disp('Updated date and time');

