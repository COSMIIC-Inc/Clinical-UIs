%% Connect to LCR Meter
instrumentVISAAddress = 'USB0::0x0957::0x0909::MY46101934::0::INSTR';
obj = visa('agilent',instrumentVISAAddress);
fopen(obj)
clrdevice(obj)


%% Take Measurements
% SEQ mode: one frequency in list only last result visible on LCR meter (unlimited frequencies)
% STEP mode: all frequencies in list, steps through list to get result (maximum 201 frequencies)

SendMeas = "RX"; %measurement type Not sure this does anything if we use complex measurement
SendFreq = [20,200,2000,20000];
n = length(SendFreq);
b = zeros(n, 2);
c = zeros(n, 1);
mode = "STEP"; %"SEQ": sequential or "STEP":step 
fprintf(obj, "*RST;*CLS"); %Reset, Clear errors/status
fprintf(obj, "TRIG:SOUR BUS"); %trigger from USB
fprintf(obj, "DISP:PAGE LIST"); %Display the list
fprintf(obj, "FORM ASC"); %ASCII format
if mode == "SEQ"
    fprintf(obj, "LIST:MODE SEQ"); %
else
    freq = sprintf("%.0f,",SendFreq(1:end-1))+SendFreq(end);
    fprintf(obj, "LIST:FREQ "+freq);
    fprintf(obj, "LIST:MODE STEP"); 
end
fprintf(obj, "INIT:CONT ON"); %Continuous
fprintf(obj, "FUNC:IMP "  + SendMeas); %Measurement type

for i=1:n
    if mode == "SEQ"
        fprintf("Freq: %5.0f\n", SendFreq(i))
        fprintf(obj, "LIST:FREQ " + num2str(SendFreq(i)) + "Hz" ); %Set Frequency
    end
    fprintf(obj, "TRIG:IMM");

    a = query(obj, "FETC?");
    %a = query(obj,'FETC:IMP:CORR?'); %fetch corrected complex impedance 
    b(i,:) = sscanf(a, '%f,%f')';
    c(i) = b(i,1) + b(i,2)*1i; 
end

%%
% C = -1/(2*pi*f*X_C)
% L = X_L/(2*pi*f)

% X_C = -1/(2*pi*f*C)  %Capacitive Reactance
% X_L = 2*pi*f*L       %Inductance Reactance
% X = X_L + X_C        %Total Reactance
% Z = R + jX


%%
% Loop through the error queue and display all errors
systemError = '';
while ~contains(lower(systemError),'no error')
    systemError = query(obj,'SYSTem:ERRor?');
    fprintf('System Error(s): %s',systemError);
end