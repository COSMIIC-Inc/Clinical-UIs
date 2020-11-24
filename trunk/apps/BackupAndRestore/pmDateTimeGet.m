function pmDateString = pmDateTimeGet(nnp)
% read date and time from power module and put it into text format to display
%
% % read data and time
resp=nnp.read(7,'2004',1,'uint32');
if isempty(resp)
        pmDateString=1;% error
        disp('Error reading');
        return;
else
    pmDate=resp;
end
resp=nnp.read(7,'2004',2,'uint32');
if isempty(resp)
        pmDateString=1;% error
        disp('Error reading time');
        return;
else
    pmTime=resp;
end
pause(.4); 

% % % convert these into the components needed for PM
% date is four bytes
% byte 0 = DOM day of month.  4 bits
% byte 1 = month, 4 bits
% bytes 2-3 = year, 12 bits
pmDate16=typecast(pmDate,'uint16'); %first need 2nd word for year
pmDate8=typecast(pmDate16,'uint8'); % divide into bytes
% could assume that unused bits are 0, but added for clarity
pmDay=bitand(pmDate8(1),0b11111); % DOM day of month.  5 bits
pmMonth=bitand(pmDate8(2),0b1111); % month, 4 bits
pmYear=bitand(pmDate16(2), 0b111111111111);  % year, 12 bits


% Convert pcTime to time elements
% time is four bytes
% byte 0 = sec, 6 bits
% byte 1 = min, 6 bits
% byte 2 = hour, 5 bits
% byte 3 = DOW day of week, 4 bits,  
% Matlab DOW 1 based starting Sunday, NNP zero based?
pmTime8=typecast(pmTime,'uint8'); %convert to bytes
pmSec=pmTime8(1); % sec, 6 bits
pmMin=pmTime8(2); % min, 6 bits
pmHour=pmTime8(3); % hour, 5 bits
pmDOW=pmTime8(4); % DOW day of week, 4 bits,

% % Assemble into string
% datevector=year, month, day, hour, minute, and second 
pmDateVector=double([pmYear, pmMonth, pmDay, pmHour,pmMin,pmSec]);
% the year has to be >= 1500 or the string returns six rows
if pmYear<2000
    pmDateString=sprintf('Invalid, datevec=[%d,%d,%d,%d,%d,%d]',pmDateVector);
else
pmDateString = datestr(pmDateVector,'mmmm dd, yyyy, HH:MM:SS.FFF AM');
end


