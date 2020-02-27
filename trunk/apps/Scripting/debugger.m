classdef debugger < handle
    %DEBUGGER Supports single stepping and other debugging capability within the assembler figure
    % dbg = DEBUGGER(nnp, ASM) creates a debug object (dbg)
    %   nnp : handle to NNPAPI object (if empty, NNPAPI is called)
    %   ASM : handle to assembler object (if empty, assembler is called)
    %
    % JML 20200227
    
    properties (Constant)
        scripterrors = ... %(debugger.scripterrors) list of runtime script errors
                {'';   ...                 %0
                'INVALID_OPCODE';  ...    %1
                'ARRAYINDEX';  ...        %2
                'ODSUBINDEX'; ...    	   %3
                'UNUSED_4';  ...          %4
                'RESULT_IS_IMMEDIATE';... %5
                'RESULT_IS_CONSTANT'; ... %6
                'TOO_MANY_STACK_VARIABLES';... %7
                'DESTINATIONARRAY';...	%8
                'DESTINATIONSTRING'; ...%9
                'JUMPOPERAND';...	%10
                'OPERAND_TYPE';	...%11
                'OPERAND_OUT_OF_RANGE';...%12
                'SCALAR_TO_POINTER'; ...%13
                'POINTER_TO_SCALAR';... %14
                'INVALID_CHILD_SCRIPT';... %15
                'UNUSED_16';... %16
                'DIVIDEBYZERO'; ...	%17
                'GETNETWORKDATA';...	%18
                'SETNETWORKDATA';...	%19
                'UNUSED_20';... %20
                'OPERAND_TYPE_MISMATCH';...	%21
                'UNUSED_22';... %22
                'UNUSED_23';... %23
                'RESETGLOBALS_FAILED';...	%24
                'ABORTED'};	%25
    end
    
    properties (Access = public)    
        nnp = []; %handle to NNPAPI object
        scriptP = 0; %sript pointer (download location, #)
        ASM = []; %handle to assembler 
        stackMonitor = []; %handle to variablemonitor App ('stack')
        globalMonitor = []; %handle to variablemonitor App ('global')

        DebugEnableCheckbox = []; %handle to DebugEnableCheckbox UI element
        SingleStepButton = []; %handle to SingleStepButton UI element
        RunToLineButton = []; %handle to RunToLineButton UI element
        ShowStackMonitorButton =[]; %handle to ShowStackMonitorButton UI element
        ShowGlobalMonitorButton = []; %handle to ShowGLobalMonitorButton UI element
        
        
    end
    
    methods
        function app = debugger(nnp, ASM)
            %DEBUGGER constructs debugger object
            % dbg = DEBUGGER(nnp, ASM) constructs a debugger object (dbg)
            % nnp : handle to NNPAPI object
            % ASM : handle to assembler object
            if nargin<2
                ASM = assembler();
                if nargin<1
                   nnp = NNPAPI;
                end
            end
            app.nnp = nnp;
            app.ASM = ASM;
            
            app.ASM.DBG = app;
            app.createDebugButtons();
        end %debugger (construtor)
        
        function createDebugButtons(app)
            % CREATEDEBUGBUTTONS
            pos = app.ASM.DownloadDebugButton.Position;
            
            app.DebugEnableCheckbox = uicontrol(app.ASM.Figure, 'Style', 'checkbox', 'String', 'Enable Debugging', 'Position', pos - [0 50 0 0]);
            app.DebugEnableCheckbox.Callback = {@app.onDebugEnableCheckboxClick};
            
            app.SingleStepButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Single Step', 'Position', pos - [0 100 0 0]);
            app.SingleStepButton.Callback = {@app.onSingleStepButtonClick};
            
            app.RunToLineButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Run to Line', 'Position', pos - [0 150 0 0]);
            app.RunToLineButton.Callback = {@app.onRunToLineButtonClick};
            
            app.ShowStackMonitorButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Show Stack Variables', 'Position', pos - [0 200 0 0]);
            app.ShowStackMonitorButton.Callback = {@app.onShowStackMonitorButtonClick};
            
            app.ShowGlobalMonitorButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Show Global Variables', 'Position', pos - [0 250 0 0]);
            app.ShowGlobalMonitorButton.Callback = {@app.onShowGlobalMonitorButtonClick};
            
            app.ASM.Figure.Name = ['Debugger: ', app.ASM.scriptName, ' (scriptID:', num2str(app.ASM.scriptID), ', #', num2str(app.ASM.scriptP), ')'];
            %TODO: include network test and memory read buttons
            
        end %createDebugButtons
        
        function redrawControls(app)
            %REDRAWCONTROLS redraws UI elemtents due to resize event of assembler window
            pos = app.ASM.DownloadDebugButton.Position;
            
            app.DebugEnableCheckbox.Position = pos - [0 50 0 0];
            app.SingleStepButton.Position = pos - [0 100 0 0];
            app.RunToLineButton.Position = pos - [0 150 0 0];
            app.ShowStackMonitorButton.Position =  pos - [0 200 0 0];
            app.ShowGlobalMonitorButton.Position =  pos - [0 250 0 0];
            
        end %redrawControls
        

        
        function onShowStackMonitorButtonClick(app, src, event)
            % ONSHOWSTACKMONITORBUTTONCLICK
            if isempty(app.stackMonitor) || ~isvalid(app.stackMonitor)
                app.stackMonitor = variablemonitor(app.nnp, 'stack', app.ASM.var);
            else
                %toggle visibility to bring to front
                app.stackMonitor.UIFigure.Visible = 'off';
                app.stackMonitor.UIFigure.Visible = 'on';
            end
        end %onShowStackMonitorButtonClick
        
        function onShowGlobalMonitorButtonClick(app, src, event)
            % ONSHOWGLOBALMONITORBUTTONCLICK
            if isempty(app.globalMonitor) || ~isvalid(app.globalMonitor)
                app.globalMonitor = variablemonitor(app.nnp, 'global', app.ASM.var);
            else
                %toggle visibility to bring to front
                app.globalMonitor.UIFigure.Visible = 'off';
                app.globalMonitor.UIFigure.Visible = 'on';
            end
        end %onShowGlobalMonitorButtonClick

        function onDebugEnableCheckboxClick(app, src, event)
            if src.Value
                disp('Enable Debugging')
                if ismember(app.ASM.scriptP, 1:25) 
                    resp = app.nnp.nmt(7, 'AB', app.ASM.scriptP, 0); %TODO: support PDO/Alarm enabled scripts (Param2=1)
                    if ~isequal(resp, hex2dec('AB'))
                        confirmNMT = false;
                    else
                        confirmNMT = true;
                    end
                    resp = app.nnp.read(7, '1f52', 1, 'uint8', 2);
                    if length(resp)==2
                        control = resp(1);
                        disp(control)
                        status = resp(2);
                        if status > 0
                            if status ==19 %TODO: fix this when PM script errors are corrected
                                msgbox('May not have enabled script debugging ')
                                disp('May not have enabled script debugging ') %TODO: remove
                            end
        %                     if status < length(scripterrors)
        %                         msgbox(['Runtime Error: ' scripterrors{status+1}])
        %                     else
        %                         msgbox(['Unknown Runtime Error: ' num2str(status)])
        %                     end
                        end
                    else
                        if ~confirmNMT
                            msgbox('Could not confirm NMT')
                            disp('Could not confirm NMT') %TODO: remove
                        end
                    end
                    operation = app.ASM.operation;
                    if ~isempty(operation)
                        app.ASM.ListBox.Value = operation(1).line;
                    end
                    app.SingleStepButton.Enable = 'on';
                    app.RunToLineButton.Enable = 'on';
                else
                    msgbox('invalid script download location')
                    disp('invalid script download location') %TODO: remove
                end
            else
                %Remove Operand/Result Values 
                app.ASM.ListBox.String = app.ASM.ListBox.UserData; 
                disp('Disable Debugging')
                resp = app.nnp.nmt(7, 'AC'); 
                if ~isequal(resp, hex2dec('AC'))
                    confirmNMT = false;
                else
                    confirmNMT = true;
                end
                resp = app.nnp.read(7, '1f52', 1, 'uint8', 2);
                if length(resp)==2
                    control = resp(1);
                    disp(control)
                    status = resp(2);
                    if status > 0
                        if status ==19 %TODO: fix this when PM script errors are corrected
                            msgbox('May not have enabled script debugging ')
                            disp('May not have enabled script debugging ') %TODO remove
                        end
                        %msgbox(['Error: ' num2str(status)])
                    end
                else
                    if ~confirmNMT
                        msgbox('Could not confirm NMT')
                        disp('Could not confirm NMT') %TODO remove
                    end
                end
                app.SingleStepButton.Enable = 'off';
               app.RunToLineButton.Enable = 'off';
            end
        end

        function showOperandResultValues(app, i_op, currentLine, operands, result)
            %SHOWOPERANDRESULTVALUES
                operation = app.ASM.operation;
                
                baseRAM = hex2dec('40000000');
                str = app.ASM.ListBox.UserData{currentLine}; %User Data contains original (assemble/ not debug) String for ListBox
                si_operand = app.ASM.strPosOperand(currentLine, 1);
                ei_operand = app.ASM.strPosOperand(currentLine, 2);
                si_result = app.ASM.strPosResult(currentLine, 1);
                ei_result = app.ASM.strPosResult(currentLine, 2);
                offset = 0;
                if ~isnan(si_operand)
                    operandStr = str(si_operand:ei_operand);

                    [si_op, ei_op] = regexp(operandStr, '\s*((".*?")|(<.*?>)|(\[.*?\])|(!.*?!)|\S+)\s+');
                    for j=1:length(ei_op)
                        typeStr = assembler.typeCode2Str(bitand(operation(i_op).operand(j).typeScope, 15));
                        if assembler.isNumericType(typeStr)
                            varCast = typecast(uint32(operands(j)), typeStr);
                            varCast = varCast(1);
                        end

                        if isempty(operation(i_op).operand(j).literal)
                            if operands(j) >= baseRAM %may be pointer to RAM rather than value
                                switch app.isPointer(operation(i_op).operand(j))
                                    case 0 %not a pointer
                                        newStr = sprintf(' (0x%X=%d) ', operands(j), varCast);
                                    case 1 %must be a pointer
                                        newStr = sprintf(' (*%d) ', operands(j)-baseRAM);
                                    case 2 %may be a pointer (not sure with network operands)
                                        newStr = sprintf(' (0x%X=%d OR *%d) ', operands(j), varCast, operands(j)-baseRAM);
                                end
                            else %not a pointer
                                newStr = sprintf(' (0x%X=%d) ', operands(j), varCast);
                            end

                            operandStr = [operandStr(1:ei_op(j)+offset), newStr, operandStr(ei_op(j)+offset+1:end)];
                            offset = offset + length(newStr);
                        end
                    end
                    str = [str(1:si_operand-1), operandStr, str(ei_operand+1:end)];
                end
                if ~isnan(si_result)
                    if operation(i_op).result.literal==0 %not a jump type
                        resultStr = str((si_result:ei_result)+offset);
                        typeStr = assembler.typeCode2Str(bitand(operation(i_op).result.typeScope, 15));
                        if assembler.isNumericType(typeStr)
                            varCast = typecast(uint32(result), typeStr);
                            varCast = varCast(1);
                        end

                        if result >= baseRAM %may be pointer to RAM rather than value
                            switch isPointer(operation(i_op).result)
                                case 0 %not a pointer
                                    newStr = sprintf(' (0x%X=%d) ', result, varCast);
                                case 1 %must be a pointer
                                    newStr = sprintf(' (*%d) ', result-baseRAM);
                                case 2 %may be a pointer (not sure with network operands)
                                    newStr = sprintf(' (0x%X=%d OR *%d) ', result, varCast, result-baseRAM);
                            end
                        else %not a pointer
                            newStr = sprintf(' (0x%X=%d) ', result,varCast);
                        end
                        resultStr = [resultStr, newStr];
                        str = [str(1:si_result+offset-1), resultStr, str(ei_result+offset+1:end)];
                    end
                end
                app.ASM.ListBox.String{currentLine} = str;
        end %showOperandResultValues
        
        function onSingleStepButtonClick(app, src, event)
            % ONSINGLESTEPBUTTONCLICK singlesteps on PM and updates relevant OD values

            operation = app.ASM.operation;
            label = app.ASM.label;
            
            %Need to make sure that the NMT command is not retried automatically if it does not get response
            radioSettings = app.nnp.getRadioSettings();
            if radioSettings.retries > 0 
                app.nnp.setRadio('Retries', 0)
            end

            resp = app.nnp.nmt(7, 'AD'); 
            if ~isequal(resp, hex2dec('AC'))
                confirmNMT = false;
            else
                confirmNMT = true;
            end
      
            control = 1;
            attempt = 1;
            status = 0;
            done = false;
            
             while control==1 && status == 0 % wait until debug step has completed
                attempt = attempt + 1;
                if attempt > 10
                    fprintf('\nscript line has not completed running.  may be at end\n')
                    break;
                end
                 resp = app.nnp.read(7, '1f52', 1, 'uint8', 4); %read 8-bit status/control, exec number, opcode
                if length(resp) == 4
                    control = resp(1);
                    status = resp(2);
                    exec = resp(3);
                    opcodeBytePM = resp(4);

                    opCodeNamePM = assembler.opcodelist{cell2mat(app.ASM.opcodelist(:,2))==opcodeBytePM,1};

                    fprintf('\ncontrol: 0x%02X, status: 0x%02X, exec: %d, opcode: %d %s\n', ...
                        control, status, exec, opcodeBytePM, opCodeNamePM);
                else
                    %error
                    fprintf('\nerror reading control/status\n')
                end
             end
            if status > 0
                if status < length(app.scripterrors)
                    msgbox(['Runtime Error: ',  app.scripterrors{status+1}])
                    disp(['Runtime Error: ',  app.scripterrors{status+1}]) %TODO remove
                else
                    msgbox(['Unknown Runtime Error: ', num2str(status)])
                    disp(['Unknown Runtime Error: ', num2str(status)]) %TODO remove
                end
                %disable further debugging
                done = true;
            end
            
            if ~done
                resp = app.nnp.read(7, '1f52', 5, 'uint32', 8);  %read 32-bit  types (opAddress, operands, result, timer)
                if length(resp) == 8
                    baseaddress = hex2dec('30000')+(app.ASM.scriptP-1)*2048+10; 
                    address = resp(1);
                    scriptBodyAddress = address - baseaddress; 
                    i_op = find(arrayfun(@(x) x.address == scriptBodyAddress, operation), 1); %find operation matching current address
                    if isempty(i_op)
                        msgbox(sprintf('PM pointing to unknown operation. No operation has address 0x%04X (%d)',...
                            scriptBodyAddress, scriptBodyAddress));
                    else
                        currentLine = operation(i_op).line;
                        fprintf('\ncurrent line %d\n', currentLine); 

                        if opcodeBytePM ~= operation(i_op).opCodeByte
                            if i_op<2
                                disp ('why here?')
                            else
                                msgbox(sprintf('opCode from PM (%d - %s) does not match opCode (%d - %s) at current line %d, address 0x%04X (%d)', ...
                                    opCodeBytePM, opCodeNamePM,  operation(i_op-1).opCodeByte), operation(i_op-1).opCodeName, currentLine, scriptBodyAddress, scriptBodyAddress);
                            end
                        end

                        if currentLine > length(app.ASM.ListBox.UserData)
                            if isequal(operation(i_op).opCodeName, 'EXIT')
                                done = true;
                            else
                                msgbox(sprintf('Line %d for operation (%d) matching address 0x%04X (%d) exceeds ListBox String length', ...
                                    currentLine, i_op, scriptBodyAddress, scriptBodyAddress));
                            end
                        else
                            operands = resp(2:6);
                            result = resp(7);
                            app.showOperandResultValues(i_op, currentLine, operands, result);
                        end

                    end

                     fprintf('\naddress: 0x%08X, opVar0: %d, opVar1: %d, opVar2: %d, opVar3: %d, opVar4: %d, Result: %d, Timer: %d\n', resp);
                else
                    %error
                    i_op = [];
                    fprintf('\nerror reading Operand Values\n')
                end

                if ~isempty(app.stackMonitor) && isvalid(app.stackMonitor)
                    app.stackMonitor.populateTable();
                end
                if ~isempty(app.globalMonitor) && isvalid(app.globalMonitor)
                    app.globalMonitor.populateTable();
                end
            end

    %Don't really need to read this every time - not particularly useful
    %             resp = app.nnp.read(7, '1f52', 15, 'uint8'); %read 10 variable table info table
    %             if length(resp) == 10
    %                 fprintf('\n VarTableInfo:');
    %                 fprintf('%02X ', resp);
    %                 fprintf('\n');
    %             else
    %                 %error
    %                 fprintf('\nerror reading Var Table Info\n')
    %             end

            if ~done
                resp = app.nnp.read(7, '1f52', 16, 'uint8'); %read jump value
                if length(resp) == 1
                    jump = resp;
                    fprintf('\nJump 0x%02X\n', resp);
                else
                    %error
                    jump = [];
                    fprintf('\nerror reading jump\n')
                end

                
                if isempty(i_op)
                    disp('Lost!')
                else
                    if jump < 2
                        if (i_op+1)<=length(operation)
                            nextLine = operation(i_op+1).line;
                            if nextLine <= length(app.ASM.ListBox.String)
                                app.ASM.ListBox.Value = nextLine;
                            else
                                done = true;
                            end
                        else
                            done = true;
                        end
                    else
                        getLabel = operation(i_op).result.literal;
                        [isLabel, iLabel] = ismember(getLabel, label(:,1));
                        if isLabel
                            %find first operation following label
                            for j = length(operation):-1:1
                                if operation(j).line >= label{iLabel,2}
                                    nextLine = operation(j).line;
                                else
                                    break;
                                end
                            end
                            if nextLine <= length(app.ASM.ListBox.String)
                                app.ASM.ListBox.Value = nextLine;
                            else
                                done = true;
                            end
                        else
                            disp('Could not find Label!')
                        end
                    end
                end
            end
            if done
                    app.DebugEnableCheckbox.Value = false;
                    app.onDebugEnableCheckboxClick(app.DebugEnableCheckbox, []);
            end

            if radioSettings.retries > 0 
                app.nnp.setRadio('Retries', radioSettings.retries)
            end

        end %onSingleStepButtonClick

        function onRunToLineButtonClick(app, src, event)
            %ONRUNTOLINEBUTTONCLICK repeatedly singlesteps until selected line is reached
            
            disp('Run to Line')
            line = app.ASM.ListBox.Value;
            app.onDebugSingleStep(src, event);
            h = msgbox('May run indefinitely - Hit OK to Cancel');
            while app.ASM.ListBox.Value~= line && isgraphics(h)
                drawnow
                app.onDebugSingleStep(src, event);
                if app.ASM.ListBox.Value == length(app.ASM.ListBox.String)
                    break;
                end
            end
            if isgraphics(h)
                close(h)
                delete(h)
            end
        end   %onRunToLineButtonClick
    end
    
    methods(Static)
        function result = isPointer(operand)
        % returs 0 if not a pointer, 1 if must be a pointer, and 2 for ambiguous
        % multi-subindex network operands must be pointer, but all other network operands are ambiguous, because they could be
        % arrays or strings
            if isempty(operand.typeScopePair) %network with single literal subindex (2), variable (0 or 1), or literal (0 or 1)  
                if ~isempty(operand.network) 
                    result = 2;
                else
                    type = bitand(operand.typeScope, 15);
                    if assembler.isNumericType(assembler.typeCode2Str(type)) %scalar numeric type
                        result = 0;
                    else %string or bytearray
                        result = 1;
                    end
                end
            else %network with variable or multiple subindices (1 or 2), array (1), or array element (0) 
                if isempty(operand.network) %array
                    if isequal(operand.literalPair, [254 255]) %0xFFFE
                        result = 1;
                    else
                        result = 0;
                    end
                else %network
                    if operand.network.nSubIndices > 1
                        result = 1;
                    else
                        result = 2;
                    end
                end
            end
        end

    end
end

