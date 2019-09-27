function result = backupRestorePM(nnp, varargin)
% result = BACKUPRESTOREPM(nnp), result is cell array containing bytes for
% each subindex in restore list
% result = BACKUPRESTOREPM(nnp, restore), result is number of subindices
% written/skipped.  Should match length of RESTORE cell array
%
% This code reads the restore list at 2900, then loops through those OD
% indices, determines number of subindices and either reads or writes each
% subindex individually. 
% To fully back up a PM, you also need to read/write the entire on-board flash, or
% maintain the SW version and read/write sectors 10-16.  Use the PM
% bootloader to do this.
%
% NOTE: The read could be sped up significantly by using block reads,
% but then special cases would be required for cases where number of bytes
% would exceed the 50-byte limit for radio message payloads.  Block reads 
% can have different datatypes in subindices as long as data is read in
% bytes (uint8).  For Block writes, all subindices must have same data
% type.  1F57 in particular could be sped up using both block read and
% block write, since all 100 subindices have same type.
%
% There are some special cases of read-only subindices in restore list at
% 3000.  These should probably be removed in a future PM version.
% Indices 1006 and 3010 are also special cases where the 0th subindex is the
% data rather than indicating the number of subindices.
% 

    tic
    read = true;
    if nargin>1
        restoreBytes = varargin{1};
        if iscell(restoreBytes)
            read = false;
        else
            disp('second argument should be a cell array with byte arrays matching subindices')
        end  
    end

    result = [];

    k=1;
    
    
    retry = true;
    retryCount = -1;
    while retry
        retryCount = retryCount + 1;
        if retryCount > 10
           msgbox('Could not read PM OD restore list indices after several retries. Adjust antenna or radio settings and try again', 'PM backup/restore')
           return
        end
        
        resp = nnp.read(7, '2900', 1, 'uint16');
        if ~isempty(resp)
            indices = resp;
        else
            disp(['could not retrieve restore indices1:', nnp.lastError])
            continue
        end

        resp = nnp.read(7, '2900', 2, 'uint16');
        if ~isempty(resp)
            indices = [indices resp];
            retry = false;
        else
            disp(['could not retrieve restore indices2:', nnp.lastError])
            continue
        end
    end


    for i=indices
        retry = true;
        retryCount = -1;
        while retry
            retryCount = retryCount + 1;
            if retryCount > 10
                user = questdlg(['Retries Failed for index ' dec2hex(i)...
                    '.  Consider adjustting antenna, changing radio timeout settings.  Do you want to try to continue?'], 'PM Backup/Restore');
                if isequal(user, 'Yes')
                    retryCount = -1;
                    continue;
                else
                    return
                end
            end
            if i==hex2dec('1006') || i==hex2dec('3010')
                %Special Cases: subindex 0 is data, not number of subIndices, no further subindices
                if read
                    resp = nnp.read(7, dec2hex(i), 0, 'uint8');
                    if ~isempty(resp)
                        restoreBytes{k} = resp;
                        disp([dec2hex(i) '.0 = ' num2str(resp)]); 
                        k = k+1;
                        retry = false;
                    else
                        disp(['Retry retrieving data for index ', dec2hex(i), ':', nnp.lastError]) 
                        continue
                    end
                else %write
                    resp = nnp.write(7, dec2hex(i), 0, restoreBytes{k}, 'uint8');
                    if isequal(resp, 0)
                        disp([dec2hex(i) '.0 written']);
                        k = k+1;
                        retry = false;
                    else
                        disp(['Retry writing data for index ', dec2hex(i), ':', nnp.lastError]) 
                        continue
                    end
                end
            else
                %Normal Case: subindex 0 is number of subIndices.  Number of subindices is stored in
                %restoreBytes to validate number of subindices on write,
                %but isn't written (ReadOnly entry).  
                %Note: it is not stored in OffBoard Flash on PM.
                resp = nnp.read(7, dec2hex(i), 0, 'uint8');
                if length(resp)==1
                    nSubIndices = resp;
                    if read
                        disp([dec2hex(i) '.0 = ' num2str(resp)]);
                         restoreBytes{k} = resp;
                    else %write
                        if ~isequal(nSubIndices, restoreBytes{k})
                            %Corrupt restoreBytes cell array?
                            msgbox(['Number of subindices (' num2str(nSubIndices) ') does not match restoreBytes (' num2str(restoreBytes{k}) ')'])
                            return;
                        end
                    end
                    k = k+1;
                    retry = false;
                else
                    disp(['Retry retrieving number of subindices for index ', dec2hex(i), ':', nnp.lastError])
                    continue;
                end 

                for j = 1:nSubIndices
                    retrySub = true;
                    retrySubCount = -1;
                    while retrySub
                        retrySubCount = retrySubCount + 1;
                        if retrySubCount > 10
                            user = questdlg(['Retries Failed for Subindex ' dec2hex(i) '.', dec2hex(j) ...
                                '.  Consider adjustting antenna, changing radio timeout settings.  Do you want to try to continue?'], 'PM Backup/Restore');
                            if isequal(user, 'Yes')
                                retryCount = -1;
                                continue;
                            else
                                return
                            end
                        end
                        if read
                            resp = nnp.read(7, dec2hex(i), j, 'uint8');

                            if ~isempty(resp)
                                restoreBytes{k} = resp;
                                retry = false;
                                disp(['   ' dec2hex(i) '.' dec2hex(j) '= ' num2str(resp)]); 
                                k = k+1;
                                retrySub = false;
                            else
                                disp(['Retry retrieving ' dec2hex(i) '.' dec2hex(j) ':', nnp.lastError])
                            end
                        else
                            if i == hex2dec('3000') && ismember(j, [6:10 12:13 15])
                                %Special Cases: Read-only subindex
                                disp([dec2hex(i) '.' dec2hex(j) ' skipped: READ ONLY']);
                                k = k+1;
                                retrySub = false;
                            else %Normal Case: writable subindex
                                resp = nnp.write(7, dec2hex(i), j, restoreBytes{k}, 'uint8');
                                if isequal(resp, 0)
                                    disp([dec2hex(i) '.' dec2hex(j) ' written']);
                                    k = k+1;
                                    retrySub = false;
                                else
                                    disp(['Retry writing data for index ', dec2hex(i)  '.' dec2hex(j)  ':', nnp.lastError]) 
                                end
                            end
                        end

                    end
                end
            end
        end
    end
    
    if read
        result = restoreBytes;
    else
        if nnp.saveOD(7)
            result = k-1;
        end
    end
    toc
end