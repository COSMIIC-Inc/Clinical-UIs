%demo.m
% remember to open the NNPAPI before starting the demo

%% Save all RM EEPROM data to a file 
% Uses RM Bootloader mode
backupRM(nnp, 'backupRM.mat')

%% Save PM OD Restore Data to a file
% Uses PM App mode
backupPM(nnp, 'backupPM.mat')

%% Save PM Script and Application Settings to a file
% Uses PM Bootloader mode
backupScripts(nnp, 'backupScripts2.mat')

%% Restore all RM EEPROM data from file created previously
% Uses RM Bootloader mode
restoreRM(nnp, 'backupRM.mat')

%% Restore all PM OD Restore Data from file created previously
% Uses PM App mode
restorePM(nnp, 'backupPM.mat')

%% Restore all PM Script and Application Settings from file created previously
% Uses PM Bootloader mode
restoreScripts(nnp, 'backupScripts2.mat')

%% Update the date to the current date and time
setPMDateTime(nnp); % 

%% Helper functions to call main functions in other files

function backupRM(nnp, file)
    if isempty(file)
        file = 'RM_backup.mat';
    end
    restoreData = backupRestoreRM(nnp, [1:6 9]);
    save(file, 'restoreData');
end

function restoreRM(nnp, file)
    d = load(file);
    try
        backupRestoreRM(nnp, [1:6 9], d.restoreData);
    catch
        disp('could not open restoreData from file')
    end
end

function backupPM(nnp, file)
    if isempty(file)
        file = 'PM_backup.mat';
    end
    restoreData = backupRestorePM(nnp);
    save(file, 'restoreData');
end

function restorePM(nnp, file)
    d = load(file);
    try
         backupRestorePM(nnp, d.restoreData);
    catch
        disp('could not open restoreData from file')
    end
end

function backupScripts(nnp, file)
    if isempty(file)
        file = 'Script_backup.mat';
    end
    scriptData = backupRestoreScripts(nnp);
    save(file, 'scriptData');
end

function restoreScripts(nnp, file)
    d = load(file);
    try
        backupRestoreScripts(nnp, d.scriptData);
    catch
        disp('could not open restoreData from file')
    end
end