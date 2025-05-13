function StrA = rmSettingsReadFcn(nnp,nodes)
% Sames as ReadRMSettings.m except write to a single string for copy
% Assumes that the network is turned on.
% Read the revision number first, then read and display the
% PG settings accordingly.
% For now assume we are comparing revisions 151, 154, 158
% The subindices of concern for now are: 2800, 2801, and 3210
% subindices:
% Ver   2800    2801    3210
% 146   3       0       5
% 151   6       0       5
% 154   12      0       5
% 158   6       5       9

% Probably the easiest method is to create three separate cases, rather
% than trying to mix them together.   <151, 151-153, 154 and >=158
% nodes=[1,2,3,4,5,6,9];
%  nodes=[9];
StrA=strings;%str = strings returns a string with no characters.
%PtID=125;
% should add date and time here
dstr=datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss');
%StrA=sprintf('\nP%s %s\n',PtID,dstr);
StrA=sprintf('\n %s\n',dstr);
% read network voltage
 % 3010.0, uns8, 0x55, Network Voltage *10
    resp=double(nnp.read(7,'3010',0,1,'uint8')); % Vnet*10
    if(length(resp)==1) %valid packet
       networkVoltage=resp/10;
       StrA=[StrA sprintf('\nNetwork Voltage %3.1f\n',networkVoltage)];
    end
    StrA = [StrA sprintf('\n**** PM EMG Config *******\n')];
    resp=nnp.read(7, '1F57', 5); % D5High
    if(length(resp)==1) %valid packet
        D5High = double(resp)*10;
       StrA=[StrA sprintf('\nD5High \t\t\t\t%d', D5High)];
    end
    respL=nnp.read(7, '1F57', 1); % PropOffset
    if(length(respL)==1) %valid packet
       StrA=[StrA sprintf('\nEMG Lower Threshold \t%d', respL)];
    end
    resp=nnp.read(7, '1F57', 2); % PropUpper
    if(length(resp)==1) %valid packet
       PUpper = 255/(double(resp)/10)+respL;
       StrA=[StrA sprintf('\nEMG Upper Threshold \t%d\n', PUpper)];
    end
for n=nodes
    % Product code is 1018.2 where 1=CT, 2=PM, 4=PG, 5=BP
    resp=nnp.read(n,'1018',2,1,'uint8');
    if length(resp)==1
        RMtype=resp;
        if RMtype==4 %PG4 node
            % version is 1018.3
            PGver=double(nnp.read(n,'1018',3,1,'uint32'));
            %    NOTE: Cannot use block read for any index that has arrays included
            if ~isempty(PGver)
                StrA=[StrA sprintf('\n**** PG Node %d, Version %d *******\n',n,PGver)];
                if PGver>166 % Accel Setting added in version 167
                     StrA=[StrA sprintf('\n2012 \n')];
                     rx=nnp.read(n,'2012',1,1,'uint8'); % Accel settings
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Accel Settings     %d\n',rx)];
                    end
                end
                if PGver<154  %146 included in this case
                    StrA=[StrA sprintf('\n2800 \n')];
                    rx=nnp.read(n,'2800',1,1,'uint8'); %Setup Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Setup Timing     %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'2800',2,1,'uint8'); %Stim Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('2 Stim Timing      %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'2800',3,1,'uint8'); %Sync Inerval [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('3 Sync Interval     %d %d %d %d\n',rx)];
                    end
                    if PGver>150  % versions 151, 153
                        rx=nnp.read(n,'2800',4,3,'uint8'); %SyncPush, SetupVOS with Chan, SetupAnode
                        if ~isempty(rx)
                            StrA=[StrA sprintf('4 SyncPush            %d\n',rx(1))];
                            StrA=[StrA sprintf('5 Setup VOS with Chan %d\n',rx(2))];
                            StrA=[StrA sprintf('6 Setup Anode         %d\n',rx(3))];
                        end
                    end
                    StrA=[StrA sprintf('\n3210 \n')];
                    rz=double(nnp.read(n,'3210',3,2,'uint16')); %StimVOS
                    if ~isempty(rz)
                        rz=rz/60;
                        StrA=[StrA sprintf('3 StimVOS                %3.1f\n',rz(1))];
                        StrA=[StrA sprintf('4 MinVOS                 %3.1f\n',rz(2))];
                    end
                    rx=nnp.read(n,'3210',5,1,'uint8'); %InRegulation[4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('5 InReg                  %d %d %d %d\n',rx)];
                    end
                    
                elseif PGver==154 % only 154 used in this range
                    StrA=[StrA sprintf('\n2800 \n')];
                    rx=nnp.read(n,'2800',1,1,'uint8'); %Actual Stim Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Actual Stim Timing  %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'2800',2,1,'uint8'); %Stim Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('2 Stim Timing         %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'2800',3,1,'uint8'); %Sync Inerval [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('3 Sync Interval       %d %d %d %d\n',rx)];
                    end
                    
                    rx=nnp.read(n,'2800',4,6,'uint8'); %SyncPush, SetupVOS Steps, SetupAnode,AutoSync Time, MaxAS, Autosync
                    if ~isempty(rx)
                        StrA=[StrA sprintf('4 SyncPush            %d\n',rx(1))];
                        StrA=[StrA sprintf('5 Setup VOS Steps     %d\n',rx(2))];
                        StrA=[StrA sprintf('6 Setup Anode         %d\n',rx(3))];
                        StrA=[StrA sprintf('7 AutoSync Time       %d\n',rx(4))];
                        StrA=[StrA sprintf('8 MaxAutosync Cnt     %d\n',rx(5))];
                        StrA=[StrA sprintf('9 Autosync count     %d\n',rx(6))];
                    end
                    ry=nnp.read(n,'2800',10,2,'uint16'); %
                    if ~isempty(ry)
                        StrA=[StrA sprintf('10 TotalAutoSyncCnt    %d\n',ry(1))];
                        StrA=[StrA sprintf('11 MaxAutoSyncExceeded %d\n',ry(2))];
                    end
                    rx=nnp.read(n,'2800',12,1,'uint8'); %MaxStimTiming[4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('12 MaxStimTiming       %d %d %d %d\n',rx)];
                    end
                    StrA=[StrA sprintf('\n3210 \n')];
                    rz=double(nnp.read(n,'3210',3,2,'uint16')); %StimVOS
                    if ~isempty(rz)
                        rz=rz/60;
                        StrA=[StrA sprintf('3 StimVOS              %3.1f\n',rz(1))];
                        StrA=[StrA sprintf('4 MinVOS               %3.1f\n',rz(2))];
                    end
                    rx=nnp.read(n,'3210',5,1,'uint8'); %InRegulation[4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('5 InReg                 %d %d %d %d\n',rx)];
                    end
                    
                elseif PGver>=158 %ignore case 156, 157
                    StrA=[StrA sprintf('\n2800 \n')];
                    rx=nnp.read(n,'2800',1,1,'uint8'); %Stim Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Stim Timing        %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'2800',2,1,'uint8'); %Sync Inerval [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('2 Sync Interval       %d %d %d %d\n',rx)];
                    end
                    
                    rx=nnp.read(n,'2800',3,4,'uint8'); %SyncPush, SetupVOS Steps, SetupAnode,AutoSync Time, MaxAS, Autosync
                    if ~isempty(rx)
                        StrA=[StrA sprintf('3 SyncPush            %d\n',rx(1))];
                        StrA=[StrA sprintf('4 AutoSync Time       %d\n',rx(2))];
                        StrA=[StrA sprintf('5 MaxAutosync Cnt     %d\n',rx(3))];
                        StrA=[StrA sprintf('6 MinDischarge Time   %d\n',rx(4))];
                    end
                    StrA=[StrA sprintf('\n2801 \n')];
                    rx=nnp.read(n,'2801',1,1,'uint8'); %Actual Stim Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Actual Stim Timing   %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'2801',2,1,'uint8'); %Max Stim Timing [4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Max Stim Timing      %d %d %d %d\n',rx)];
                    end
                    ry=nnp.read(n,'2801',3,3,'uint8'); %Autosynccnt, Total, MaxAutoExceeded
                    if ~isempty(ry)
                        StrA=[StrA sprintf('3 AutoSyncCount         %d\n',ry(1))];
                        StrA=[StrA sprintf('4 MaxAutoSyncCount      %d\n',typecast(ry(2:3),'uint16'))];
                        StrA=[StrA sprintf('5 MaxAutoSyncExceeded   %d\n',typecast(ry(4:5),'uint16'))];
                    end
                    StrA=[StrA sprintf('\n3210 \n')];
                    rz=double(nnp.read(n,'3210',3,2,'uint16')); %StimVOS
                    if ~isempty(rz)
                        rz=rz/60;
                        StrA=[StrA sprintf('3 StimVOS          %3.1f\n',rz(1))];
                        StrA=[StrA sprintf('4 MinVOS           %3.1f\n',rz(2))];
                    end
                    rx=nnp.read(n,'3210',5,1,'uint8'); %InRegulation[4]
                    if ~isempty(rx)
                        StrA=[StrA sprintf('5 InReg            %d %d %d %d\n',rx)];
                    end
                    rx=nnp.read(n,'3210',6,4,'uint8');
                    if ~isempty(rx)
                        StrA=[StrA sprintf('6 Setup VOS Steps  %d\n',rx(1))];
                        StrA=[StrA sprintf('7 MinVOS steps     %d\n',rx(2))];
                        StrA=[StrA sprintf('8 Setup Anode      %d\n',rx(3))];
                        StrA=[StrA sprintf('9 Channel IPI      %d\n',rx(4))];
                    end
                    
                end
            end
        end
        if RMtype==5 %BP node
            % version is 1018.3
            PGver=double(nnp.read(n,'1018',3,1,'uint32'));
            if ~isempty(PGver)
                StrA=[StrA sprintf('\n**** BP Node %d, Version %d *******\n',n,PGver)];
                if PGver>134 % Accel Setting added in version 135
                     StrA=[StrA sprintf('\n2012 \n')];
                     rx=nnp.read(n,'2012',1,1,'uint8'); % Accel settings
                    if ~isempty(rx)
                        StrA=[StrA sprintf('1 Accel Settings     %d\n',rx)];
                    end
                end
                StrA=[StrA sprintf('\n2800 \n')];
                rx=nnp.read(n,'2800',1,1,'uint8'); %Sync Timing [23]
                if ~isempty(rx)
                    StrA=[StrA sprintf('1 Sync Timing  ')];
                    StrA=[StrA sprintf('%d ',rx)];
                    StrA=[StrA sprintf('\n')];
                end
                rx=nnp.read(n,'2800',2,1,'uint8'); %Sync Interval
                if ~isempty(rx)
                    StrA=[StrA sprintf('2 Sync Interval  %d\n',rx)];
                end
                StrA=[StrA sprintf('\n3411 \n')];
                Lencfg=4;
                if PGver>=131
                    Lencfg=7;
                end
                rx=nnp.read(n,'3411',1,Lencfg,'uint8');
                if ~isempty(rx)
                    StrA=[StrA sprintf('1 Ch1 Cfg:  ')];
                    StrA=[StrA sprintf('%d ',rx)];
                    StrA=[StrA sprintf('\n')];
                end
                StrA=[StrA sprintf('\n3412 \n')];
                rx=nnp.read(n,'3412',6,1,'uint8');
                if ~isempty(rx)
                    StrA=[StrA sprintf('6 Ch1 Features  %d\n',rx)];
                end
                StrA=[StrA sprintf('\n3511 \n')];
                rx=nnp.read(n,'3511',1,Lencfg,'uint8');
                if ~isempty(rx)
                    StrA=[StrA sprintf('1 Ch2 Cfg:  ')];
                    StrA=[StrA sprintf('%d ',rx)];
                    StrA=[StrA sprintf('\n')];
                end
                StrA=[StrA sprintf('\n3512 \n')];
                rx=nnp.read(n,'3512',6,1,'uint8');
                if ~isempty(rx)
                    StrA=[StrA sprintf('6 Ch2 Features  %d\n',rx)];
                end
                
            end
        end
    end
end

end

