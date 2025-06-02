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
                'MAX_STRING';... %20
                'OPERAND_TYPE_MISMATCH';...	%21
                'READ_SCRIPT_CONTROL';... %22
                'WRITE_SCRIPT_CONTROL';... %23
                'RESET_GLOBALS';...	%24
                'ABORTED';...%25
                'EXIT_DEBUG'};	%26
    end
    
    properties (Access = public)    
        nnp = []; %handle to NNPAPI object
        scriptP = 0; %sript pointer (download location, #)
        ASM = []; %handle to assembler 
        stackMonitor = []; %handle to variablemonitor App ('stack')
        globalMonitor = []; %handle to variablemonitor App ('global')
        odTestApp = []; %handle to odtest App
        readMemoryApp = []; %handle to readMemory App

        DebugEnableCheckbox = []; %handle to DebugEnableCheckbox UI element
        SingleStepButton = []; %handle to SingleStepButton UI element
        RunToLineButton = []; %handle to RunToLineButton UI element
        RunToEndButton = []; %handle to RunToEndButton UI element
        RunToEndXEdit = []; %handle to RunToEndX EditField UI element
        RunToEndXLabel = []; %handle to RunToEndX Text UI element
        ShowStackMonitorButton =[]; %handle to ShowStackMonitorButton UI element
        ShowGlobalMonitorButton = []; %handle to ShowGLobalMonitorButton UI element
        ResetGlobalsButton = []; %handle to ResetGlobalsButton UI element
        ShowLiteralsCheckbox = []; %handle to ShowLiteralsCheckbox UI element
        ODTestButton = []; %handle to ODTestButton UI element
        ReadMemoryButton =[]; %handle to ReadMemoryButton UI element
        showLiteralValues = false;
        verbose = 0;
        
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
            
            app.disableDebug();

        end %debugger (construtor)
        
        function disableDebug(app)
            %DISABLEDEBUG
            app.DebugEnableCheckbox.Value = false;
            app.onDebugEnableCheckboxClick(app.DebugEnableCheckbox, []);
        end %disableDebug
        
        function enableDebug(app)
            %ENABLEDEBUG
            app.DebugEnableCheckbox.Value = true;
            app.onDebugEnableCheckboxClick(app.DebugEnableCheckbox, []);
        end %enableDebug
        
        function createDebugButtons(app)
            % CREATEDEBUGBUTTONS
            pos = app.ASM.DownloadDebugButton.Position;
            
            app.DebugEnableCheckbox = uicontrol(app.ASM.Figure, 'Style', 'checkbox', 'String', 'Enable Debugging', 'Position', pos - [0 50 0 0]);
            app.DebugEnableCheckbox.Callback = {@app.onDebugEnableCheckboxClick};
            
            app.SingleStepButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Single Step', 'Position', pos - [0 100 0 0]);
            app.SingleStepButton.Callback = {@app.onSingleStepButtonClick};
            
            app.RunToLineButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Run to Line', 'Position', pos - [0 150 0 0]);
            app.RunToLineButton.Callback = {@app.onRunToLineButtonClick};
            
            app.RunToEndButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Run to End', 'Position', pos - [0 200 30 0]);
            app.RunToEndButton.Callback = {@app.onRunToEndButtonClick};
            
            app.RunToEndXEdit = uicontrol(app.ASM.Figure, 'Style', 'edit', 'String', '1', 'Position', pos - [30-pos(3) 185 pos(3)-30 pos(4)/2]);
            app.RunToEndXLabel = uicontrol(app.ASM.Figure, 'Style', 'text', 'String', 'Times', 'Position', pos - [30-pos(3) 205 pos(3)-30 pos(4)/2]);
            
            app.ShowStackMonitorButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Show Stack Variables', 'Position', pos - [0 250 0 0]);
            app.ShowStackMonitorButton.Callback = {@app.onShowStackMonitorButtonClick};
            
            app.ShowGlobalMonitorButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Show Global Variables', 'Position', pos - [0 300 0 0]);
            app.ShowGlobalMonitorButton.Callback = {@app.onShowGlobalMonitorButtonClick};
            
            app.ResetGlobalsButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Reset Global Variables', 'Position', pos - [0 350 0 0]);
            app.ResetGlobalsButton.Callback = {@app.onResetGlobalsButtonClick};
            
            app.ShowLiteralsCheckbox = uicontrol(app.ASM.Figure, 'Style', 'checkbox', 'String', 'Show Literals', 'Position', pos - [0 400 0 0]);
            app.ShowLiteralsCheckbox.Callback = {@app.onShowLiteralsCheckboxClick};
            
            app.ODTestButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Object Dictionary', 'Position', pos - [0 450 0 0]);
            app.ODTestButton.Callback = {@app.onODTestButtonClick};
            
            app.ReadMemoryButton = uicontrol(app.ASM.Figure, 'Style', 'pushbutton', 'String', 'Read Memory', 'Position', pos - [0 500 0 0]);
            app.ReadMemoryButton.Callback = {@app.onReadMemoryButtonClick};
            
            app.ASM.Figure.Name = ['Debugger: ', app.ASM.scriptName, ' (scriptID:', num2str(app.ASM.scriptID), ', #', num2str(app.ASM.scriptP), ')'];
            
        end %createDebugButtons
        
        function redrawControls(app)
            %REDRAWCONTROLS redraws UI elemtents due to resize event of assembler window
            pos = app.ASM.DownloadDebugButton.Position;
            
            app.DebugEnableCheckbox.Position = pos - [0 50 0 0];
            app.SingleStepButton.Position = pos - [0 100 0 0];
            app.RunToLineButton.Position = pos - [0 150 0 0];
            app.RunToEndButton.Position = pos - [0 200 30 0];
            app.RunToEndXEdit.Position = pos - [30-pos(3) 185 pos(3)-30 pos(4)/2];
            app.RunToEndXLabel.Position = pos - [30-pos(3) 205 pos(3)-30 pos(4)/2];
            app.ShowStackMonitorButton.Position =  pos - [0 250 0 0];
            app.ShowGlobalMonitorButton.Position =  pos - [0 300 0 0];
            app.ResetGlobalsButton.Position =  pos - [0 350 0 0];
            app.ShowLiteralsCheckbox.Position = pos - [0 400 0 0];
            app.ODTestButton.Position = pos - [0 450 0 0];
            app.ReadMemoryButton.Position = pos - [0 500 0 0];
            
        end %redrawControls
        
        function closeMonitors(app)
            %CLOSEMONITORS 
            if ~isempty(app.stackMonitor) && isvalid(app.stackMonitor)
                delete(app.stackMonitor)
            end
            if ~isempty(app.globalMonitor) && isvalid(app.globalMonitor)
                delete(app.globalMonitor)
            end
            
            %close other child apps
             if ~isempty(app.odTestApp) && isvalid(app.odTestApp)
                 delete(app.odTestApp)
             end
             if ~isempty(app.readMemoryApp) && isvalid(app.readMemoryApp)
                 delete(app.readMemoryApp)
             end
            
        end %redrawControls
        
        function onShowStackMonitorButtonClick(app, src, event)
            % ONSHOWSTACKMONITORBUTTONCLICK
            if isempty(app.stackMonitor) || ~isvalid(app.stackMonitor)
                try
                    app.stackMonitor = variablemonitor(app.nnp, 'stack', app.ASM.var);
                catch
                    msgbox('variablemonitor.mlapp not on the path')
                end
            else
                %toggle visibility to bring to front
                app.stackMonitor.UIFigure.Visible = 'off';
                app.stackMonitor.UIFigure.Visible = 'on';
            end
        end %onShowStackMonitorButtonClick
        
        function onShowGlobalMonitorButtonClick(app, src, event)
            % ONSHOWGLOBALMONITORBUTTONCLICK
            if isempty(app.globalMonitor) || ~isvalid(app.globalMonitor)
                try
                    app.globalMonitor = variablemonitor(app.nnp, 'global', app.ASM.var);
                catch
                    msgbox('variablemonitor.mlapp not on the path')
                end
            else
                %toggle visibility to bring to front
                app.globalMonitor.UIFigure.Visible = 'off';
                app.globalMonitor.UIFigure.Visible = 'on';
            end
        end %onShowGlobalMonitorButtonClick

        function onResetGlobalsButtonClick(app, src, event)
            % ONRESETGLOBALSBUTTONCLICK
            app.nnp.nmt(7,'A7',app.ASM.scriptID); %Reset globals for this script
        end %onResetGlobalsButtonClick
        
        function onShowLiteralsCheckboxClick(app, src, event)
            % ONSHOWLITERALSCHECKBOXCLICK
            app.showLiteralValues = src.Value;
        end %onShowLiteralsCheckboxClick
        
        function onODTestButtonClick(app, src, event)
            % ONODTESTBUTTONCLICK
            %TODO: allow multiple copies?
            if isempty(app.odTestApp) || ~isvalid(app.odTestApp)
                try
                    app.odTestApp = odtest(app.nnp);
                catch
                    msgbox('odtest.mlapp not on the path')
                end
            else
                %toggle visibility to bring to front
                app.odTestApp.UIFigure.Visible = 'off';
                app.odTestApp.UIFigure.Visible = 'on';
            end
        end %onODTestButtonClick
        
        function onReadMemoryButtonClick(app, src, event)
            % ONREADMEMORYBUTTONCLICK
            msgbox('not yet implemented')
        end %onReadMemoryButtonClick
        
        function onDebugEnableCheckboxClick(app, src, event)
            % ONDEBUGENABLECHECKBOXCLICK
            if src.Value
                disp('Enable Debugging')
                
                app.ASM.ListBox.String = app.ASM.ListBox.UserData;  %Remove Operand/Result Values 

                %Make sure scripts are enabled
                systemControl = app.nnp.read(7,'2001',1, 'uint32');
                if length(systemControl)==1
                    scriptsEnabled = bitget(systemControl,5);
                    if ~scriptsEnabled
                        userresp = questdlg('Scripts are not enabled, Enable them now', 'Script Debugging');
                        if isequal(userresp, 'Yes')
                            resp = app.nnp.nmt(7, '8e'); %enable scripts
                            if ~isequal(resp, hex2dec('8e'))
                                msgbox('Could not confirm scripts enabled ', 'Script Debugging');
                            end
                        else
                            app.DebugEnableCheckbox.Value = false;
                            return
                        end
                    end
                 else
                     msgbox('Error reading scripts enabled status', 'Script Debugging');
                end

                if ismember(app.ASM.scriptP, 1:25) 
                    %The script must be in script order or PDO/Alarm triggered in order to debug
                    %Get Script Order 
                    isPDOTriggered = false;
                    isAlarmTriggered = false;
                    resp = double(app.nnp.read(7, '1f56', 1, 'uint8'));
                    if length(resp)==25
                        if any(resp==app.ASM.scriptP)
                            %script is in scheduler, debug normally
                            disp('Debugging as round robin script')
                        else
                            %check if script is PDO or Alarm triggered
                            for i=1:8
                                resp = double(app.nnp.read(7, ['140' num2str(i-1)], 4, 'uint8'));
                                if length(resp)==1
                                    if resp == app.ASM.scriptP
                                        isPDOTriggered = true;
                                        disp('Debugging as PDO triggered, script will only start when PDO arrives')
                                        break;
                                    end
                                else
                                   msgbox('Error reading PDO scripts', 'Script Debugging');
                                   app.DebugEnableCheckbox.Value = false;
                                   return
                                end
                            end
                            if ~isPDOTriggered
                                for i=1:4
                                    resp = app.nnp.read(7, '2001', 1, 'uint32');
                                    if length(resp)==1
                                        sp = double(bitshift(bitand(resp, hex2dec('3E0000')), -17));
                                        if sp == app.ASM.scriptP
                                            isAlarmTriggered = true;
                                            disp('Debugging as Aalrm triggered, script will only start when alarm occurs')
                                            break;
                                        end
                                    else
                                        msgbox('Error reading alarm scripts', 'Script Debugging');
                                        app.DebugEnableCheckbox.Value = false;
                                        return
                                    end
                                end
                            end
                            if ~(isPDOTriggered || isAlarmTriggered)
                                msgbox('Script is not in scheduler, and is not PDO Triggered or Alarm Triggered.  Script must be assigned somewhere in order to debug it','Script Debugger')
                                app.DebugEnableCheckbox.Value = false;
                                return
                            end
                        end
                    else
                        msgbox('Error reading script order', 'Script Debugging');
                        app.DebugEnableCheckbox.Value = false;
                        return
                    end


                    resp = app.nnp.nmt(7, 'AB', app.ASM.scriptP, isAlarmTriggered||isPDOTriggered); 
                    if ~isequal(resp, hex2dec('AB'))
                        confirmNMT = false;
                        disp(['No Enable NMT Response: ', app.nnp.lastError])
                    else
                        confirmNMT = true;
                    end
                    resp = app.nnp.read(7, '1f52', 1, 'uint8', 2);
                    if length(resp)==2
                        %control = resp(1);
                        status = resp(2);
                        if status > 0
                            if status == 22 || status ==23 
                                msgbox(['May not have enabled script debugging.'...
                                    'If single stepping fails, disable and reenable script debugging '], 'Script Debugger')
                            end
                            if status < length(app.scripterrors)
                                msgbox(['Runtime Error: ' app.scripterrors{status+1}], 'Script Debugger')
                                return
                            else
                                msgbox(['Unknown Runtime Error: ' num2str(status)], 'Script Debugger')
                                return
                            end
                        end
                    else
                        if ~confirmNMT
                            msgbox('Could not enable Script Debugging.', 'Script Debugger')
                            %disp('Could not confirm NMT') %TODO: remove
                            return
                        end
                    end
                    operation = app.ASM.operation;
                    if ~isempty(operation)
                        app.ASM.ListBox.Value = operation(1).line;
                    end
                    app.SingleStepButton.Enable = 'on';
                    app.RunToLineButton.Enable = 'on';
                    app.RunToEndButton.Enable = 'on';
                    app.RunToEndXEdit.Enable = 'on';
                else
                    msgbox('invalid script download location', 'Script Debugger')
                    %disp('invalid script download location') %TODO: remove
                end
            else
                disp('Disable Debugging')
                resp = app.nnp.nmt(7, 'AC'); 
                pause(0.5);  %This NMT command has a 0.5s delay within the PM, so we need to wait at least 
                             %that long before sending another request to PM
                if ~isequal(resp, hex2dec('AC'))
                    confirmNMT = false;
                    disp(['No Disable NMT Response: ', app.nnp.lastError])
                else
                    confirmNMT = true;
                end
                resp = app.nnp.read(7, '1f52', 1, 'uint8', 2);
                if length(resp)==2
                    control = resp(1);
                    status = resp(2);
                    if status > 0
                        if status == 22 || status ==23  
                            msgbox('May not have disabled script debugging ', 'Script Debugging')
                        end
                        if status < length(app.scripterrors)
                            msgbox(['Runtime Error: ' app.scripterrors{status+1}], 'Script Debugging')
                            %don't return
                        else
                            msgbox(['Unknown Runtime Error: ' num2str(status)], 'Script Debugging')
                            %don't return
                        end
                    end
                else
                    if ~confirmNMT
                        msgbox('Could not disable Script Debugging')
                        return;
                        %disp('Could not confirm NMT') %TODO remove
                    end
                end
               app.SingleStepButton.Enable = 'off';
               app.RunToLineButton.Enable = 'off';
               app.RunToEndButton.Enable = 'off';
               app.RunToEndXEdit.Enable = 'off';
            end
        end %onDebugEnableCheckboxClick
        
        function enableButtons(app, enable)
            app.SingleStepButton.Enable = enable;
            app.RunToLineButton.Enable = enable;
            app.RunToEndButton.Enable = enable;
            app.RunToEndXEdit.Enable = enable;
            app.ASM.ReassembleButton.Enable = enable;
            app.ASM.DownloadDebugButton.Enable = enable;
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
                baseScriptAddress = hex2dec('30000')+(app.ASM.scriptP-1)*2048; 
                
                if ~isnan(si_operand)
                    operandStr = str(si_operand:ei_operand);

                    [si_op, ei_op] = regexp(operandStr, '\s*((".*?")|(<.*?>)|(\[.*?\])|(!.*?!)|\S+)\s+');
                    for j=1:length(ei_op)
                        typeStr = assembler.typeCode2Str(bitand(operation(i_op).operand(j).typeScope, 15));
                        if assembler.isNumericType(typeStr)
                            varCast = typecast(uint32(operands(j)), typeStr);
                            varCast = varCast(1);
                        else
                            varCast = [];
                        end

                        if isempty(operation(i_op).operand(j).literal) || app.showLiteralValues
                            
                            %inOperationRange = operands(j) > operation(i_op).address + baseScriptAddress && operands(j) < operation(i_op+1).address + baseScriptAddress;
                            %app.ASM.downloadImage(operand(j)-baseScriptAddress+1)
                            inScriptRange = operands(j) > baseScriptAddress && operands(j) < baseScriptAddress + length(app.ASM.downloadImage);

                            if operands(j) >= baseRAM || inScriptRange %may be pointer to RAM, or Download Image rather than value
                                switch app.isPointer(operation(i_op).operand(j))
                                    case 0 %not a pointer
                                        newStr = sprintf('(0x%X=%d)', operands(j), varCast);
                                    case 1 %must be a pointer
                                        if inScriptRange
                                            newStr = sprintf('(F*%d)', operands(j));
                                        else
                                            newStr = sprintf('(R*%d)', operands(j)-baseRAM);
                                        end
                                    case 2 %may be a pointer (not sure with network operands)
                                         if inScriptRange
                                            newStr = sprintf('(0x%X=%d OR F*%d)', operands(j), varCast, operands(j));
                                         else
                                            newStr = sprintf('(0x%X=%d OR R*%d)', operands(j), varCast, operands(j)-baseRAM);
                                         end
                                end
                            else %not a pointer
                                newStr = sprintf('(0x%X=%d)', operands(j), varCast);
                            end
                            
                            newStr = ['<BODY BGCOLOR=#FFFF00><b>', newStr, '</b><BODY BGCOLOR=#FFFFFF><FONT COLOR="black">'];
                            n = length(newStr);
                            
                            operandStrPreceding = operandStr(1:ei_op(j) + offset);
                            operandStrDeblanked = deblank(operandStrPreceding);
                            spacesRemoved = length(operandStrPreceding) - length(operandStrDeblanked);
                            newStr = [newStr, char(ones(1, spacesRemoved)*double(' '))]; %add removed spaces after newStr
                            
                            operandStr = [operandStrDeblanked, newStr, operandStr(ei_op(j)+offset+1:end)];
                            offset = offset + n;
                        end
                    end
                    str = [str(1:si_operand-1), operandStr, str(ei_operand+1:end)];
                end
                if ~isnan(si_result)
                    if isequal(operation(i_op).result.literal, 0) || app.showLiteralValues
                        resultStr = str((si_result:ei_result)+offset);
                        typeStr = assembler.typeCode2Str(bitand(operation(i_op).result.typeScope, 15));
                        if assembler.isNumericType(typeStr)
                            varCast = typecast(uint32(result), typeStr);
                            varCast = varCast(1);
                        else
                            varCast = [];
                        end

                        %inOperationRange = result > operation(i_op).address + baseScriptAddress && result < operation(i_op+1).address + baseScriptAddress;
                        inScriptRange = result > baseScriptAddress && result < baseScriptAddress + length(app.ASM.downloadImage);

                        if result >= baseRAM || inScriptRange %may be pointer to RAM, or Download Image rather than value
                            switch app.isPointer(operation(i_op).result)
                                case 0 %not a pointer
                                    newStr = sprintf('(0x%X=%d)', result, varCast);
                                case 1 %must be a pointer
                                    if inScriptRange
                                         newStr = sprintf('(F*%d)', result);
                                    else
                                         newStr = sprintf('(R*%d)', result-baseRAM);
                                    end
                                case 2 %may be a pointer (not sure with network operands)
                                    if inScriptRange
                                         newStr = sprintf('(0x%X=%d OR F*%d)', result, varCast, result);
                                    else
                                        newStr = sprintf('(0x%X=%d OR R*%d)', result, varCast, result-baseRAM);
                                    end
                                    
                            end
                        else %not a pointer
                            newStr = sprintf('(0x%X=%d)', result,varCast);
                        end
                        newStr = ['<BODY BGCOLOR=#FFFF00><b>', newStr, '</b><BODY BGCOLOR=#FFFFFF><FONT COLOR="black">'];
                        n = length(newStr);

                        resultStrDeblanked = deblank(resultStr);
                        spacesRemoved = length(resultStr) - length(resultStrDeblanked);
                        newStr = [newStr, char(ones(1, spacesRemoved)*double(' '))]; %add removed spaces after newStr

                        resultStr = [resultStrDeblanked, newStr];
                        
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
            if isempty(radioSettings)
                msgbox('Failed to read radio settings. Try single step again', 'Script Debugger');
                return
            else
                if radioSettings.retries > 0 
                    app.nnp.setRadio('Retries', 0)
                end
            end

            %trigger single step
            resp = app.nnp.nmt(7, 'AD'); 
            if ~isequal(resp, hex2dec('AD'))
                confirmNMT = false;
            else
                confirmNMT = true;
            end
            if ~confirmNMT 
                msgbox('Could not confirm single step received.  You may need to Single Step again', 'Script Debugger');
            end
      
            control = 1;
            attempt = 0;
            status = 0;
            done = false;
            
            while control == 1 && status == 0 % wait until debug step has completed
                
                attempt = attempt + 1;
                if attempt > 10
                    userResp = questdlg('Operation has not completed running. Try again?');
                    if isequal(userResp, 'Yes')
                        attempt = 0;
                    else
                        break;
                    end
                end
                resp = app.nnp.read(7, '1f52', 1, 'uint8', 4); %read 8-bit status/control, exec number, opcode
                if length(resp) == 4
                    control = resp(1);
                    status = resp(2);
                    exec = resp(3);
                    opcodeBytePM = resp(4);

                    opCodeNamePM = assembler.opcodelist{cell2mat(app.ASM.opcodelist(:,2))==opcodeBytePM,1};

                    if app.verbose > 1 
                        fprintf('\ncontrol: 0x%02X, status: 0x%02X, exec: %d, opcode: %d %s\n', ...
                        control, status, exec, opcodeBytePM, opCodeNamePM);
                    end
                else
                    %error
                    fprintf('\nerror reading control/status\n')
                end
             end
            
            %Display runtime errors 
            if status > 0 
                if status < length(app.scripterrors)
                    msgbox(['Runtime Error: ',  app.scripterrors{status+1}])
                    %disp(['Runtime Error: ',  app.scripterrors{status+1}]) %TODO remove
                else
                    msgbox(['Unknown Runtime Error: ', num2str(status)])
                    %disp(['Unknown Runtime Error: ', num2str(status)]) %TODO remove
                end

                %disable further debugging
                done = true;
             end
            
            if ~done
                attempt = 0;
                while true %Read operation info retry loop
                    attempt = attempt + 1;
                    if attempt > 3
                        userResp = questdlg('Could not read operation address, operand/result values. Try again?');
                        if isequal(userResp, 'Yes')
                            attempt = 0;
                        else
                            break;
                        end
                    end
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
                            if app.verbose > 1
                                fprintf('\ncurrent line %d\n', currentLine); 
                            end

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
                        if app.verbose > 1
                            fprintf('\naddress: 0x%08X, opVar0: %d, opVar1: %d, opVar2: %d, opVar3: %d, opVar4: %d, Result: %d, Timer: %d\n', resp);
                        end
                        break; %leave retry loop
                    else
                        %error
                        i_op = [];
                        fprintf('\nerror reading Operand Values\n')
                    end
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
                attempt = 0;
                while true %Read jump retry loop
                    attempt = attempt + 1;
                    if attempt > 3
                       userResp = questdlg('Could not read jump (branching) information. Try again?');
                        if isequal(userResp, 'Yes')
                            attempt = 0;
                        else
                            break;
                        end 
                    end
                    
                    resp = app.nnp.read(7, '1f52', 16, 'uint8'); %read jump value
                    if length(resp) == 1
                        jump = resp;
                        if app.verbose > 1
                            fprintf('\nJump 0x%02X\n', resp);
                        end
                        break;
                    else
                        %error
                        jump = [];
                        fprintf('\nerror reading jump\n')
                    end
                end

                if isempty(i_op) || isempty(jump)
                    userResp = questdlg('Lost in Script! Do you want to disable debugging?'); 
                    if isequal(userResp, 'Yes')
                        done = true;
                    end
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
                        if isempty(operation(i_op).result) %jump to end
                            app.ASM.ListBox.Value = length(app.ASM.ListBox.String);
                            done = true;
                        else
                            getLabel = operation(i_op).result.literal;
                        
                            [isLabel, iLabel] = ismember(getLabel, label(:,1));
                            if isLabel
                                %find first operation following label
                                nextLine = length(app.ASM.ListBox.String);
                                for j = length(operation):-1:1
                                    if operation(j).line >= label{iLabel,2}
                                        nextLine = operation(j).line;
                                    else
                                        break;
                                    end
                                end
                                if nextLine <= length(app.ASM.ListBox.String)
                                    app.ASM.ListBox.Value = nextLine;
                                    if nextLine > operation(end).line %no more operations
                                        done = true;
                                    end
                                else
                                    done = true;
                                end
                            else
                                disp('Could not find Label!')
                            end
                        end
                    end
                end
            end
            if done
                app.disableDebug();
            end

            if radioSettings.retries > 0 
                app.nnp.setRadio('Retries', radioSettings.retries)
            end

        end %onSingleStepButtonClick

        function onRunToLineButtonClick(app, src, event)
            %ONRUNTOLINEBUTTONCLICK repeatedly singlesteps until selected line is reached
            
            app.enableButtons('off');
            
            disp('Run to Line')
            line = app.ASM.ListBox.Value;
            app.onSingleStepButtonClick(src, event);
            h = msgbox('May run indefinitely - Hit OK to Cancel', 'Script Debugger');
            while app.ASM.ListBox.Value~= line && isgraphics(h) 
                drawnow
                app.onSingleStepButtonClick(src, event);
                if app.DebugEnableCheckbox.Value == false
                    msgbox('Reached end of script or error before reaching line', 'Script Debugger');
                    break;
                end
            end
            if isgraphics(h)
                close(h)
                delete(h)
            end
            
            app.enableButtons('on');
        end   %onRunToLineButtonClick
        
        function onRunToEndButtonClick(app, src, event)
            %ONRUNTOLINEBUTTONCLICK repeatedly singlesteps until last line is reached
            tic
            app.enableButtons('off');
            
            n = str2double(app.RunToEndXEdit.String);
            disp(['Run to End ' num2str(n) ' times'])

            %The current method continues where single stepping may have
            %left off which may not be at the first operation.  
            %To start from the beginning first disable and reenable debugging
            
            h = msgbox('May run indefinitely - Hit OK to Cancel');
            while n
                app.onSingleStepButtonClick(src, event);
               
                while  isgraphics(h)
                    drawnow;
                    app.onSingleStepButtonClick(src, event);
                    if  app.DebugEnableCheckbox.Value == false %reached end or error
                        n = n-1;
                        break;
                    end
                end
                if n
                    if ~isgraphics(h)
                        break;
                    end
                    app.RunToEndXEdit.String = num2str(n);
                    app.enableDebug();
                    drawnow; % needed so first operation shows as highlighted before single stepping
                    pause(0.5);
                end
            end
            if isgraphics(h)
                close(h)
                delete(h)
            end
            app.RunToEndXEdit.String ='1'; 
            toc
            
            app.enableButtons('on');
        end   %onRunToEndButtonClick
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

