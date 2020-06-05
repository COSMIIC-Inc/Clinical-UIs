classdef assembler < handle
    %ASSEMBLER Parses *.nnpscript and assembles NNP PM script download images
    % asm = ASSEMBLER(scriptID, scriptP, file, scriptName, Figure, SED) createas an assembler object (asm)
    %
    %    scriptID  : 1-25 (0 will not allow download, if empty a inputdialog will display) 
    %    scriptP   : 1-255 (0 will not allow download)
    %    file      : full path to .nnpscript file (if empty a file select dialog will open)
    %    scriptName: optional name of script. (if empty, gets set to *, in *.nnpscript)
    %    Figure    : optional handle to Figure, so new FIgure is not created.  (use asm.Figure, to get the figure handle)
    %    SED       : handle to scriptedit app to support download functions and get handle to NNP to support debugging 
    %
    % For use without scriptedit app:
    % asm = ASSEMBLER() - opens a file select dialog to choose file and includes input dialog to select ID
    % asm = ASSEMBLER(scriptID, scriptP, file, scriptName, Figure)
    %
    % The download image is asm.downloadImage
    % See public properties for more information on other 
    % see also: debugger
    %
    % JML 20200227
    % NOTES
    %  1. This file uses HTML formatting to color code/bold/italicize text using deprecated uicontrol ListBox
    %  2. This is not built in AppDesigner, because there is not yet support for HTML 
    %     formatting within UIListBoxes or UITables
    
    properties  (Constant) 
       %This is accessible without creating an insance of the class!
       

        opcodelist = { ... %(assembler.opcodelist) opcode name, opcode byte, min operands, max operands, description, result,jump result, result is also operand
            'NOP',0,0,0, 'NOP - skip',0,0,0;...
            'MOV',1,1,1, 'Move (From - To-> Result)',1,0,0;...
            'NMT0',2,2,2 'NMT command - node, cmd',0,0,0;...
            'NMT1',3,3,3 'NMT cmd - node, cmd, param',0,0,0;...
            'NMT2',4,4,4 'NMT cmd - node, cmd, 2 par',0,0,0;...
            'CATMOV',5,1,5, 'Operand0 + Operand1 + ... -> Move to Result',1,0,0;...
            'CATMOV0',80,1,5, 'Operand0 + Operand1 + ... -> Move to Result with Null',1,0,0;...
            'CATMOVCR',81,1,5, 'Operand0 + Operand1 + ... -> Move to Result with CR',1,0,0;...
            'SUBSTR',42,3,3, 'Substring: string index; size -> result str.',1,0,0;...
            'ITS',6,2,2, 'IntToString Op0; Field size Op1',1,0,0;...
            'UTS',7,2,2, 'UIntToString Op0; Field size Op1',1,0,0;...
            'ITS0',8,2,2, 'IntToString Op0; Field size Op1 -> Result is null terminated',1,0,0;...
            'UTS0',9,2,2, 'UIntToString Op0; Field size Op1 -> Result is null terminated',1,0,0;...
            'ADD',10,2,5, 'Add Op0, Op1, Opn',1,0,0;...
            'SUB',11,2,2, 'Subtract Op0 to Op1',1,0,0;...
            'MUL',12,2,5, 'Multiply Op0, Op1, Opn',1,0,0;...
            'DIV',13,2,2, 'Integer Divide Op0 to Op1',1,0,0;...
            'ADDS',75,2,5, 'Saturate Add Op0, Op1, Opn',1,0,0;...
            'SUBS',76,2,2, 'Saturate Subtract Op0 to Op1',1,0,0;...
            'MULS',77,2,5, 'Saturate Multiply Op0, Op1, Opn',1,0,0;...
            'DIFF',14,2,2, 'ABS of difference',1,0,0;...
            'INC',15,0,0, 'Increment Results Op - No ops',1,0,1;...
            'DEC',16,0,0, 'Decrement Results Op - No ops',1,0,1;...
            'INCS',78,0,0, 'Saturate Increment Results Op - No ops',1,0,1;...
            'DECS',79,0,0, 'Saturate Decrement Results Op - No ops',1,0,1;...
            'MAX',17,2,2, 'Max Value of Op0 and Op1',1,0,0;...
            'MIN',18,2,2, 'Min Value of Op0 and Op1',1,0,0;...
            'SRGT',19,2,2, 'Op0 >> Op1',1,0,0;...
            'SLFT',20,2,2, 'Op0 << Op1',1,0,0;...
            'ABS',21,1,1, 'ABS(Op0) -> Result',1,0,0;...
            'BITON',22,2,2, 'Bit ON in Op0; Bitx in Op1; ->Result',1,0,0;...
            'BITOFF',23,2,2, 'Bit OFF in Op0; Bitx in Op1... ->Result',1,0,0;...
            'ITQ',24,1,1, 'IntToFixPt Op0 -> Result',1,0,0;...
            'UTQ',25,1,1, 'UIntToFixPt Op0 -> Result',1,0,0;...
            'ADDQ',26,2,2, 'FixPt Addition Op0 by Op1 -> Result',1,0,0;...
            'SUBQ',27,2,2, 'FixPt Subtraction Op0 by Op1 -> Result',1,0,0;...
            'MULQ',28,2,2, 'FixPt mulitiplication Op0 by Op1 -> Result',1,0,0;...
            'DIVQ',29,2,2, 'FixPt division Op0 by Op1 -> Result',1,0,0;...
            'SQRTQ',30,1,1, 'Square Rt Op0 -> Result',1,0,0;...
            'QTI',31,1,1, 'FixP To Int Op0 -> Result',1,0,0;...
            'QTU',32,1,1, 'FixP to UInt Op0 -> Result',1,0,0;...
            'QTS',33,2,2, 'FixP to String Op0; Field size (width) Op1',1,0,0;...
            'CHS',34,0,0, 'Change Sign -> Result',1,0,1;...
            'SIL',35,2,2, 'Arithmetic shift left',1,0,0;...
            'SIR',36,2,2, 'Arithmetic shift right',1,0,0;...
            'AND',37,2,2, 'Bitwise AND',1,0,0;...
            'OR',38,2,2, 'Bitwise OR',1,0,0;...
            'MODD',39,2,2, 'Modulo divsion -> remainder',1,0,0;...
            'XOR',40,2,2, 'Bitwise Exclusive OR -> result',1,0,0;...
            'COMP',41,1,1, 'Bitwise Complements Op0 -> Op1',1,0,0;...
            'SIN',43,1,1, 'Sin(x-degrees) -> result',1,0,0;...
            'COS',44,1,1, 'Cos(x-degrees) -> result',1,0,0;...
            'TAN',45,1,1, 'Tan(x-degrees) -> result',1,0,0;...
            'ASIN',46,1,1, 'ArcSin(x) -> result (degrees)',1,0,0;...
            'ACOS',47,1,1, 'ArcCos(x) -> result (degrees)',1,0,0;...
            'ATAN',48,1,1, 'Arctan(x) -> result(degrees)',1,0,0;...
            'ATAN2',49,2,2, 'Arctan2(y, x) -> result(degrees)',1,0,0;...
            'SIGN',50,1,1, 'Return +1, 0, -1',1,0,0;...
            'PACK',51,4,4, 'Op[0], Op[1], Op[n] -> Result UInt32',1,0,0;...
            'UNPACK',52,4,4, 'UInt32 -> UNS8 Array[4]',1,0,0;...
            'BLT',60,2,2, 'Branch if item1 < item2',1,1,0;...
            'BGT',61,2,2, 'Branch if >',1,1,0;...
            'BEQ',62,2,2, 'Branch if =',1,1,0;...
            'BNE',63,2,2, 'Branch if !=',1,1,0;...
            'BGTE',64,2,2, 'Branch if >=',1,1,0;...
            'BLTE',65,2,2, 'Branch if <=',1,1,0;...
            'BNZ',66,1,1, 'Branch if not 0',1,1,0;...
            'BZ',67,1,1, 'Branch if 0',1,1,0;...
            'GOTO',68,0,0, 'GoTo - Label',1,1,0;...
            'BBITON',69,2,2, 'Branch if bit Op1 in Op0 is ON',1,1,0;...
            'TDEL',70,1,1, 'TimeDelay in msecs',0,0,0;...
            'GNS',71,1,1, 'Get Node Status Op0 = Node -> Status',1,0,0;...
            'BBITOFF',72,2,2, 'Branch if bit Op1 in Op0 is OFF',1,1,0;...
            'BITSET',73,2,2, 'Set or Clear Bit X (Op1) if Op0 =/ne 0 -> in Result',1,0,1;...
            'BITCNT',74,1,1, 'Counts the number of bits set in the input value.',1,0,0;...
            'FREAD',82,3,3, 'Read From File - File ID, Index, Number of bytes - byte data',1,0,0;...
            'FWRITE',83,3,3, 'Write To File Op[0]=File ID, Op[1]=index, Op[2]=data -> Number of bytes - byte data',1,0,0;...
            'FRESET',84,1,1, 'Reset - clears file: Op[0] = FileID',0,0,0;...
            'FSIZE',85,1,1, 'Op[0] = FileID, -> size in bytes',1,0,0;...
            'FGETPTR',86,1,1, 'Op[0] = FileID, -> position',1,0,0;...
            'FSETPTR',87,2,2, 'Op[0] = FileID, Op[1] sets position',0,0,0;...
            'BITCPY',88,4,4, 'UInt32 Source; SourceStart; ResultStart; Length -> UInt32 Result ',1,0,0;...
            'FCLOSE',89,1,1, 'Op[0] = FileID closes log file',0,0,0;...
            'STARTSCPT',90,1,1, 'Start Script Pointer',0,0,0;...
            'STOPSCPT',91,1,1, 'Stop Script Pointer',0,0,0;...
            'RUNONCE',92,1,1, 'Run Script Pointer Once',0,0,0;...
            'RUNIMM',93,1,1, 'Run Script Pointer Immediate',0,0,0;...
            'RUNNEXT',94,1,1, 'Run Script Pointer Next',0,0,0;...
            'RUNMULT',95,1,1, 'Decode operand for starting scripts',0,0,0;...
            'RESETGLOBALS',96,1,1, 'Reset Global Vars for script (0 == all)',0,0,0;...
            'NODESCAN',97,1,1, 'Scan for Node (node)',1,0,0;...
            'INTERPOL',100,3,3, 'Interpolate X(Op0) in table Op1 (Xvalues) - Op2 (Yvalues) -> Result(FP)',1,0,0;...
            'MAVG',101,2,2, 'Moving Average - Source, Array[] -> Result',1,0,0;...
            'IIR',102,2,2, 'IIR - Source, Array -> Result',1,0,0;...
            'FIFO',104,1,1, 'FirstIn-FirstOut buffer.  Buf[i] = Buf[i-1], Buf[0]=NewValue -> Buf',1,0,0;...
            'VECMOV',105,4,4, 'Vector Move - SourceArray, Source Starting Index, Dest Staring Index, Number of Indices -> DestArray',1,0,0;...
            'VECMAX',106,1,1, 'Vector->Vector Maximum',1,0,0;...
            'VECMAXI',107,1,1, 'Vector->Index of Vector Maximum',1,0,0;...
            'VECMIN',108,1,1, 'Vector->Vector Minimum',1,0,0;...
            'VECMINI',109,1,1, 'Vector->Index of Vector Minimum',1,0,0;...
            'VECMED',110,1,1, 'Vector->Median',1,0,0;...
            'VECMEDI',111,1,1, 'Vector->Index of Median',1,0,0;...
            'VECMEAN',112,1,1, 'Vector->Mean',1,0,0;...
            'VECSUM',113,1,1, 'Vector->Sum',1,0,0;...
            'VECPROD',114,1,1, 'Vector->Product',1,0,0;...
            'VECMAG',115,1,1, 'Vector->Magnitude',1,0,0;...
            'VECMAG2',116,1,1, 'Vector->Magnitude(Squared)',1,0,0;...
            'VECADD',121,2,2, 'VectorA + VectorB(or scalar)-> Vector',1,0,0;...
            'VECSUB',122,2,2, 'VectorA - VectorB (or scalar)->Vector',1,0,0;...
            'VECMUL',123,2,2, 'VectorA (elementwise*) VectorB (or scalar)->Vector',1,0,0;...
            'VECDIV',124,2,2, 'VectorA (elementwise/) VectorB (or scalar)->Vector',1,0,0;...
            'EXIT',255,0,0, 'Terminate Script',0,0,0};         
        
        vartypelist = {'uint8','int8','uint16','int16','uint32','int32','string','ba','fixp'}; %(assembler.vartypelist) variable types
        varscopelist = {'stack', 'global', 'const'}; %(assembler.vartscopelist) variable scopes
    end
    
    properties  (Access = private) 
        i_var = 0; %current index into var struct array
        i_def = 0; %current index into def struct array
        i_operation = 0; %current index into operation struct array
        i_label = 0; %current index into label array
    end
    
    properties  (Access = public) 
        %JML: these properties don't all need to be public, but they are kept that way to simplify debugging
        downloadImage = []; %The downloadImage for PM 
        scriptName = []; %short script name (usually filename without ".nnpscript" extension)
        scriptID = 0;    %script unique Identifier (1-255)
        scriptP = 0;     %script pointer (download location, #)
        scriptRev = 0;   %script revison (software version number)
        scriptCRC = [];
        Figure = [];     %handle to Assembler Figure
        file = [];       %full filepath to *.nnpscript
        assemblerLogs = struct('operations', [], 'vartables', [], 'scriptbody', [], 'download', [], 'lines', []); %relative filepaths to assembler logging outputs
        
        var = struct('name','','line', [],'type','','scope','', 'initStr', '', 'init', [], 'array', [], 'pointer',[],'endpointer',[]); %struct array of variables (in order as declared in script)
        def = struct('name','','line',[],'replace',''); %struct array of defines (in order as defined in script)
        operation = struct('index',[],'line', [],'opCodeName','','opCodeByte','','operand', [], 'result',[], 'address', []);  %struct array of operations (in order as used in script)
        label = []; %list of labels used in script

        
        SL = {}; %scriptlines (cell array)
        SLF = {}; %scriptlines - HTML formatted (cell array)
        
        ListBox = []; %handle to ListBox that displays HTML formatted script lines
        FontSizeLabel = []; %handle to FontSizeLabel UI element
        FontSizeEditField = []; %handle to FontSizeEditFIeld UI element
        EditButton =[]; %handle to EditButton UI element 
        ReassembleButton =[]; %handle to Reassemble UI element
        DownloadDebugButton = []; %handle to DownloadDebugButton UI element (only appears if SED is passed as argument)
        DBG = []; %handle to debugger
        SED = []; %handle to scripteditor
        
        StackTable = []; %Stack variable table in bytes (included downloadImage)
        ConstTable = []; %Constants variable table in bytes (included downloadImage)
        GlobalTable = []; %GLobal variable table in bytes (included downloadImage)
        
        warnStr = []; %warning string built for each line
        errStr = []; %error string built for each line
        strPosOperand = []; %stored start and end indices within HTML-formatted text for operands so debugger can insert operand value information
        strPosResult = []; %stored start and end indices within HTML-formatted text for results so debugger can insert result value information
        strPosComment =[]; %stored start index within HTML-formatted text for comments so warnings and errors can be inserted ahead of comments
        varUsage = []; %list of variable indexes (into var struct array) to determine variable order for variable tables
        
    end
    
    
    methods
        function app = assembler(scriptID, scriptP, file, scriptRev, scriptName, Figure, SED)
            %ASSEMBLER Parses *.nnpscript and assembles NNP PM script download images
            % asm = ASSEMBLER(scriptID, scriptP, file, scriptName, Figure, SED) constructs an assembler object (asm)
            %
            %    scriptID  : 1-25 (0 will not allow download, if empty a inputdialog will display) 
            %    scriptP   : 1-255 (0 will not allow download)
            %    file      : full path to .nnpscript file (if empty a file select dialog will open)
            %    scriptRev : optional revision number for script to help track it
            %    scriptName: optional name of script. (if empty, gets set to *, in *.nnpscript)
            %    Figure    : optional handle to Figure, so new FIgure is not created.  (use asm.Figure, to get the figure handle)
            %    SED       : handle to scriptedit app to support download functions and get handle to NNP to support debugging 

            if nargin <7
                SED = [];
                if nargin <6
                    Figure = [];
                    if nargin<5
                        scriptName = [];
                        if nargin < 4
                            scriptRev = str2double(inputdlg('scriptRev'));
                            if isnan(scriptRev) || scriptRev > 65535 || scriptRev < 0
                               scriptRev = 0;
                            end
                            if nargin<3
                                [filename, pathname ] = uigetfile('*.nnpscript', 'Choose Script File');
                                if filename == 0 
                                    return
                                else
                                    file = [pathname filename];
                                end
                                if nargin<2
                                   scriptP = 0;

                                    if nargin<1
                                       scriptID = str2double(inputdlg('scriptID'));
                                       if isnan(scriptID) || ~ismember(scriptID , 0:255)
                                           scriptID = 0;
                                       end
                                    end
                                end
                            else
                                iSlash = strfind(file, '\');
                                filename = file(iSlash(end)+1:end);
                            end
                        end
                    end
                end
            end
            if isempty(scriptName) 
                if length(filename) > length('.nnpscript') 
                    scriptName = filename(1:end-length('.nnpscript'));
                else
                    scriptName = 'UnnamedScript';
                end
            end
            
            %push input arguments into class variables
            app.file = file;
            app.scriptID = scriptID;
            app.scriptP = scriptP;
            app.scriptRev = scriptRev;
            app.scriptName = scriptName;
            app.SED = SED;
            app.Figure = Figure;
                       
            app.scanScriptFile();
            app.openAssemblerLogs();
            app.parseScriptLines();
            app.createFigure();
            app.addStartEndLabels();
            app.createVariableTables();
    
            if ~isempty(app.errStr)
                msgbox('Quitting assembly - fix errors and try again' );
                disp('Quitting assembly - fix errors and try again' ); %TODO: remove
                app.closeAssemblerLogs();
                return;
            end
            
            app.createDownloadImage();
            disp('Finished Assembly')
            app.closeAssemblerLogs();

        end %assembler (constructor)
                
        function createDownloadImage(app)
            %CREATEDOWNLOADIMAGE 
            
            nOps = app.i_operation;
            if nOps == 0
                msgbox('No operations in script!')
                app.downloadImage = [];
                app.scriptCRC = [];
            else
            
                nLabels = length(app.label);

                jump = zeros(nOps,1);
                opBytes = cell(nOps,1);
                address=0;
                for k=1:nOps
                    copyResult = app.opcodelist{app.operation(k).index, 8};
                    try 
                        [opBytes{k}, jump(k)] = app.assembleOperation(k, copyResult);
                    catch
                        msgbox(['Quitting assembly.  Could not assemble operation ' num2str(k) ', Line: ' num2str(app.operation(k).line)]);
                        disp(['Quitting assembly.  Could not assemble operation ' num2str(k) ', Line: ' num2str(app.operation(k).line)]);
                        return;
                    end
                    app.operation(k).address = address;
                    address = address + length(opBytes{k});
                end

                opBytes{nOps+1} = uint8([2 255]);  %add EXIT as last operation
                app.operation(nOps+1).address = address;
                app.operation(nOps+1).opCodeName = 'EXIT';
                app.operation(nOps+1).opCodeByte= 255;
                app.operation(nOps+1).line = app.operation(nOps).line+1;
            end
            
            if length(app.var)>1 || any(structfun(@(x) ~isempty(x), app.var))
                for v=1:length(app.var)
                    if ~ismember(v, app.varUsage)
                        line = app.var(v).line;
                        if isempty(line) || line > length(app.ListBox.String)
                            warning('variable %u: %s line invalid', v, app.var(v).name);
                        else
                            str = app.ListBox.String{line};
                            formattedtext = '<FONT COLOR="purple"><small><i><u> ~unused Variable </i></u></small>';
                            app.ListBox.String{line}=[str(1:app.strPosComment(line)-1), formattedtext, str(app.strPosComment(line):end)];
                        end
                    end
                end
            end

            if nOps == 0
                return
            end
            
            if sum(jump>0) < nLabels
                %warning('label unused')
            end

            % count bytes from jumps to labels

            for k=1:length(jump)
                if jump(k)>0
                    %find first operation following label (may be on a following line)
                    jumpOp = length(app.operation);
                    for j = length(app.operation):-1:1
                        if app.operation(j).line >= jump(k)
                            jumpOp = j;
                        else
                            break;
                        end
                    end
                        
                    sumBytes = 0; 
                    if jumpOp>k
                        jumpDir = 0; %forward
                        for j = k:jumpOp-1
                            sumBytes = sumBytes + length(opBytes{j});
                        end
                        jumpBytes = sumBytes;
                    elseif jumpOp<k
                        jumpDir = 1; %backward
                        for j = k-1:-1:jumpOp
                            sumBytes = sumBytes + length(opBytes{j});
                        end
                        jumpBytes = sumBytes;
                    else
                        warning('jump goes to its own label')
                        jumpDir = 1; %backward
                        jumpBytes = 0;
                    end

                    jumpBytes = typecast(uint16(jumpBytes), 'uint8');
                    opBytes{k}(end-3:end) = [jumpBytes,0,jumpDir];
                end
            end

            %build script body and output opcode list in same format as CE for comparison
            scriptbody = [];


            fprintf(app.assemblerLogs.scriptbody, 'Opcode list...');
            for k = 1: length(opBytes)
                fprintf(app.assemblerLogs.scriptbody,'\r\n');
                fprintf(app.assemblerLogs.scriptbody,'%02X ', opBytes{k});
                scriptbody = [scriptbody opBytes{k}];
            end


            H = 10; %header length
            B = length(scriptbody);
            G = length(app.GlobalTable);
            S = length(app.StackTable);
            C = length(app.ConstTable);
            E = 1; %end, 1 byte for script ID.  Note in future this could contain rev byte, CRC, or additional bytes
            D = H+B+G+S+C+E;

            dBytes = typecast(uint16(D),'uint8');
            gPointerBytes = typecast(uint16(H+B),'uint8');
            sPointerBytes = typecast(uint16(H+B+G),'uint8');
            cPointerBytes = typecast(uint16(H+B+G+S),'uint8');
            RevBytes = typecast(uint16(app.scriptRev),'uint8');
            % add header and variable tables
            % Header
            % start   |#bytes|description
            %       0 | 2    | script download size (D)
            %       2 | 2    | pointer to Global Var Table
            %       4 | 2    | pointer to Stack Var Table
            %       6 | 2    | pointer to Constant Var Table
            %       8 | 2    | script Revision number
            %      10 | B    | Script Body
            %    10+B | G    | global var bytes
            %  10+B+G | S    | stack var bytes
            % 10+B+G+S| C    | const var bytes
            %      D-1| 1    | script ID
            %        D| 2    | CRC16

            %scriptID = str2double(inputdlg('scriptID'))
            header = [dBytes, gPointerBytes, sPointerBytes, cPointerBytes, RevBytes];
            download = [header, scriptbody, app.GlobalTable, app.StackTable, app.ConstTable, app.scriptID];  
            crc = app.calculateCRC16(download);
            crcBytes = typecast(crc,'uint8');
            app.downloadImage = [download, crcBytes];
            app.scriptCRC = double(crc);
            if app.scriptCRC==0 || app.scriptCRC==65535
                msgbox(sprintf('CRC = 0x%04X. You should change the Rev or bytes in the script so that the CRC is nonzero!', app.scriptCRC)); 
            end
            
            %output download bytes list in same format as CE for comparison
            fprintf(app.assemblerLogs.download, 'Download image...');
            for i=1:16:length(app.downloadImage)
                ei = min(i+16-1, length(app.downloadImage));
                fprintf(app.assemblerLogs.download, '\r\n%04X:   %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X %02X ', i-1, app.downloadImage(i:ei));
            end
        end %createDownloadImage
        

        
        function [opBytes, jumpLine] = assembleOperation(app, i_op, copyResult)
            % ASSEMBLEOPERATION
            op = app.operation(i_op);
            
            jumpLine =0;
            opBytes = [];
            nOperands = length(op.operand);
            nResult = length(op.result);
            for j = 1:nOperands + nResult
                if j<= nOperands
                    operand = op.operand(j);
                else
                    operand = op.result;
                end

                if bitget(operand.typeScope, 7) %Bit 6 if 0-indexed
                    if isempty(operand.network)
                        error('network field should not be empty')
                    end

                    port = operand.network.port;
                    netId = operand.network.netID;
                    odIndexBytes = typecast(uint16(operand.network.odIndex), 'uint8');
                    nSubIndices = uint8(operand.network.nSubIndices);
                    node = uint8(operand.network.node);
                    subIndex = operand.network.subIndex;

                    %non-literal
                    if ~isempty(operand.iVarPair)   
                        pointer = app.var(operand.iVarPair).pointer;
                        pointer = typecast(uint16(pointer), 'uint8');
                        operand.bytes = [4, operand.typeScopePair, pointer, 8 ,operand.typeScope,port,netId,node,odIndexBytes,nSubIndices]; 

                    else
                        %literal but multiple subindices  
                        if nSubIndices > 1 
                            operand.bytes = [4, operand.typeScopePair, subIndex,0, 8 ,operand.typeScope,port,netId,node,odIndexBytes,nSubIndices]; 

                        %literal and single subindex 
                        else 
                            operand.bytes = [8, operand.typeScope, port,netId,node,odIndexBytes,subIndex]; 
                        end
                    end 

                else
                    scope = bitand(operand.typeScope, 48);  %bits 4 and 5

                    %literal or jump
                    if scope==0 
                        if isempty(operand.literal) || any(isnan(operand.literal))
                            error('literal not defined')
                        elseif j<= nOperands
                            operand.bytes = [length(operand.literal)+2, operand.typeScope, operand.literal];
                        else %result, must be a jump
                            [isLabel, iLabel] = ismember(operand.literal, app.label(:,1));
                            if ~isLabel
                                error(['label at line#' num2str(op.line) ' "' operand.literal '" not start, end, or defined label'])
                            end
                            jumpLine = app.label{iLabel,2};
                            operand.bytes = [6, operand.typeScope, 0,0,0,0]; %need to replace final 4 zeros with correct values
                        end

                    %variable (if paired, may include a literal)   
                    else
                        if isempty(operand.iVar)
                            error('variable not defined')
                        elseif length(operand.iVar)~=1 || operand.iVar<1 || operand.iVar>length(app.var)
                            operand.iVar
                            error('variable invalid')

                        else
                            pointer = app.var(operand.iVar).pointer;
                            pointer = typecast(uint16(pointer), 'uint8');

                            nEl = app.var(operand.iVar).array;

                            %array
                            if nEl>0
                                nElBytes = typecast(uint16(nEl), 'uint8');
                                if isempty(operand.typeScopePair)
                                    error('typescope not defined for array element')
                                else
                                    scopePair = bitget(operand.typeScopePair, 5:6); %matlab bit indexing is 1-based

                                    %array with literal element index
                                    if scopePair==0 
                                        if length(operand.literalPair)~=2 
                                            error('literal array indexer must be 2 bytes')
                                        else
                                            operand.bytes = [4, operand.typeScopePair, operand.literalPair, 6, operand.typeScope, pointer, nElBytes];
                                        end

                                    %array with variable element index    
                                    else
                                        if isempty(operand.iVarPair)
                                            error('variable for array element not defined')
                                        else
                                            pointerPair = app.var(operand.iVarPair).pointer;
                                            pointerPair = typecast(uint16(pointerPair), 'uint8');
                                            operand.bytes = [4, operand.typeScopePair, pointerPair, 6, operand.typeScope, pointer, nElBytes];
                                        end
                                    end
                                end

                            %non-array    
                            else
                                operand.bytes = [4, operand.typeScope, pointer];
                            end
                        end

                    end
                end
                if copyResult && j>nOperands  %special case: copy result as last operand
                    opBytes = uint8([opBytes operand.bytes operand.bytes]);
                else
                    opBytes = uint8([opBytes operand.bytes]);
                end
            end %for operand
            if copyResult
                opBytes = uint8([length(opBytes)+3, op.opCodeByte, nResult*16+nOperands+1, opBytes]); %add length, opcode, and nResult:nOperand+1
            else
                opBytes = uint8([length(opBytes)+3, op.opCodeByte, nResult*16+nOperands, opBytes]); %add length, opcode, and nResult:nOperand
            end
        end %assembleOperation

        function createVariableTables(app)
            % CREATEVARIABLETABLES
            
            stacktable = [];
            consttable = [];
            globaltable = [];

            varOrder = unique(app.varUsage, 'stable');


            for j = 1:length(varOrder)
                app.warnStr = [];
                k = varOrder(j);
                initStr = app.var(k).initStr;
                
                if app.isNumericType(app.var(k).type)

                    %array
                    if app.var(k).array > 0 
                        app.var(k).init = zeros(1,app.var(k).array);
                        
                        if ~isempty(initStr)
                            if length(initStr)<=2 || initStr(1)~='[' || initStr(end)~=']'
                                app.addWarning('invalid array initializer, initializing all elements to zero'); 
                            else
                                initStrSep = regexp(initStr, '((0x[0-9abcdefABCDEF]+)|(0b[01]+)|(-*\d+))','match');
                                init = zeros(1, length(initStrSep));
                                for i=1:length(initStrSep)
                                    initHex = sscanf(initStrSep{i}, '0x%X');
                                    if ~isempty(initHex)
                                        init(i) = initHex;
                                    else
                                        initBinStr = regexp(initStrSep{i},'0b[01]+','match');
                                        if ~isempty(initBinStr)
                                            init(i) = bin2dec(initBinStr{1}(3:end));  %convert cell to string and remove '0b'
                                        else
                                            init(i) = str2double(initStrSep{i});
                                        end
                                    end
                                end
                                if length(init)>app.var(k).array
                                    app.var(k).init = init(1:app.var(k).array);
                                    app.addWarning('ignoring extra array initializer elements'); 
                                else
                                    app.var(k).init(1:length(init)) = init;
                                    if length(init)<app.var(k).array
                                        app.addWarning( 'setting some uninitialized elements to zero'); 
                                    end
                                end
                            end  
                        end

                    %non-array (uninitialized)   
                    elseif isempty(initStr)
                       app.var(k).init = 0;

                    %non-array (initialized)     
                    else
                        app.var(k).init = str2double(initStr);
                        if isnan(app.var(k).init) || ~isreal(app.var(k).init)
                            initHex = sscanf(initStr, '0x%X');
                            if length(initHex)==1
                                app.var(k).init = initHex;
                            else
                                initBinStr = regexp(initStr,'0b[01]+','match');
                                if length(initBinStr)==1
                                    app.var(k).init = bin2dec(initBinStr{1}(3:end));  %convert cell to string and remove '0b'
                                else
                                    app.addWarning('invalid variable initializer, initializing to zero'); 
                                    app.var(k).init = 0;
                                end
                            end   
                        end
                    end
                    varCast = cast(app.var(k).init, app.var(k).type);
                    if ~isequal(varCast,app.var(k).init)
                        app.addWarning('initializer value exceeds range for variable type (may saturate)'); 
                    end
                    varBytes = typecast(varCast, 'uint8');

                elseif isequal(app.var(k).type, 'string')
                    if initStr(1)=='#'
                        strLen = str2double(initStr(2:end));
                        if isnan(strLen) || ~isreal(strLen) || strLen < 1 || strLen > 50
                            app.addWarning( 'string length initializer should be 1-50'); 
                            app.var(k).init = [];
                        else
                            app.var(k).init = char(zeros(1, strLen)); %all null
                        end
                    else
                        strLen = length(initStr)-2;
                        if strLen <= 0
                            app.addWarning( 'zero length string'); 
                            app.var(k).init = [];
                        elseif strLen > 50
                            app.addWarning( 'string cannot be longer than 50 characters'); 
                        else
                            app.var(k).init = initStr(2:end-1);
                        end
                    end

                    varBytes = [strLen, uint8(app.var(k).init)]; %indcate string length


               elseif isequal(app.var(k).type, 'ba')
                    if length(initStr)<=2
                        app.addWarning( 'zero length bytearray'); 
                        app.var(k).init = [];
                    else
                        app.var(k).init = hex2dec(regexp(initStr(2:end-1), '[0-9abcdefABCDEF]{2}','match'))';
                    end
                    varBytes = uint8(app.var(k).init);
                end

                %add variable table warnings to warnings
                if ~isempty(app.warnStr)
                    formattedtext=['<FONT COLOR="purple"><small><i><u>' app.warnStr '</i></u></small>'];
                    line = app.var(k).line;
                    str = app.ListBox.String{line};
                    app.ListBox.String{line} = [str(1:app.strPosComment(line)-1), formattedtext, str(app.strPosComment(line):end)];
                end


                switch app.var(k).scope 
                    case 'stack'
                        app.var(k).pointer = length(stacktable);
                        stacktable = [stacktable varBytes]; 
                        app.var(k).endpointer = length(stacktable)-1;
                    case 'const'
                        app.var(k).pointer = length(consttable);
                        consttable = [consttable varBytes];
                        app.var(k).endpointer = length(consttable)-1;
                    case 'global'
                        app.var(k).pointer = length(globaltable);
                        globaltable = [globaltable varBytes];  
                        app.var(k).endpointer = length(globaltable)-1;
                end

            end
            
            app.StackTable = stacktable;
            app.ConstTable = consttable;
            app.GlobalTable = globaltable;

            fprintf(app.assemblerLogs.vartables, '------- Stack Table (%d bytes)----------------\n', length(stacktable));
            for j=1:length(varOrder)
                k=varOrder(j);
                if isequal(app.var(k).scope, 'stack')
                    fprintf(app.assemblerLogs.vartables, '\n%3d-%3d: %s (line %d)', app.var(k).pointer, app.var(k).endpointer, app.var(k).name, app.var(k).line);
                end
            end
            fprintf(app.assemblerLogs.vartables, '\n\n------- Global Table (%d bytes)----------------\n', length(globaltable));
            for j=1:length(varOrder)
                k=varOrder(j);
                if isequal(app.var(k).scope, 'global')
                    fprintf(app.assemblerLogs.vartables, '\n%3d-%3d: %s (line %d)', app.var(k).pointer, app.var(k).endpointer, app.var(k).name, app.var(k).line);
                end
            end
            fprintf(app.assemblerLogs.vartables, '\n\n------- Constants Table (%d bytes)----------------\n',  length(consttable));
            for j=1:length(varOrder)
                k=varOrder(j);
                if isequal(app.var(k).scope, 'const')
                    fprintf(app.assemblerLogs.vartables, '\n%3d-%3d: %s (line %d)', app.var(k).pointer, app.var(k).endpointer, app.var(k).name, app.var(k).line);
                end
            end

            %NOTE not actually part of variable tables
            % Operation lines
            for op=1:length(app.operation)
                fprintf(app.assemblerLogs.operations,'%d: %s(line %d)\n', op,  app.operation(op).opCodeName, app.operation(op).line);
            end

        end %createVariableTables
        
        function addStartEndLabels(app)
            % ADDSTARTENDLABELS
            if ~isempty(app.operation)
                if isempty(app.label) || ~ismember('start', app.label(:,1)) 
                    app.label = [{'start', app.operation(1).line};app.label];
                end
                if isempty(app.label) || ~ismember('end', app.label(:,1)) 
                    app.label = [app.label;{'end', app.operation(end).line}];
                end
            end
        end %addStartEndLabels
        
        function createFigure(app)
            % CREATEFIGURE
            if isempty(app.Figure) || ~isgraphics(app.Figure)
                app.Figure = figure();
                w = 1000;
                h = 800;
                app.Figure.Position =[100 100 w h];
            else
                w = app.Figure.Position(3);
                h = app.Figure.Position(4);
                %flahsh visibility to bring to top
                app.Figure.Visible = 'off';
                clf(app.Figure);
            end
            
            app.Figure.Name = ['Assembler: ', app.scriptName, ' (scriptID:', num2str(app.scriptID), ', #', num2str(app.scriptP), ')'];
            app.Figure.NumberTitle = 'off';
            app.Figure.MenuBar = 'none';
            app.Figure.ToolBar = 'none';
            
            %Create ListBox with formatted script 
            app.ListBox = uicontrol(app.Figure, 'Style','listbox','String',app.SLF, 'FontName', 'monospaced', 'FontSize', 12, 'Position', [10 10 w-150 h-20]);
            app.ListBox.UserData = app.ListBox.String; %store the current version of string into UserData
            
            %Create FontSize control
            app.FontSizeLabel = uicontrol(app.Figure, 'Style', 'text', 'String', 'Fontsize:','Position', [w-130 h-45 80 20]);
            app.FontSizeEditField = uicontrol(app.Figure, 'Style', 'edit',  'String', '12','Value', 12,'Position', [w-50 h-40 40 20]);
            app.FontSizeEditField.Callback = {@app.onFontSizeChanged};
            
            app.EditButton = uicontrol(app.Figure, 'Style', 'pushbutton', 'String', 'Edit', 'Position', [w-130 h-100 120 40]);
            app.EditButton.Callback = {@app.onEditClick};
            app.ReassembleButton = uicontrol(app.Figure, 'Style', 'pushbutton', 'String', 'Reassemble', 'Position', [w-130 h-150 120 40]);
            app.ReassembleButton.Callback = {@app.onReassembleClick};
            
            if ~isempty(app.SED)
                app.DownloadDebugButton = uicontrol(app.Figure, 'Style', 'pushbutton', 'String', 'Download & Debug', 'Position', [w-130 h-200 120 40]);
                app.DownloadDebugButton.Callback = {@app.onDownloadDebugClick}; 
                if isempty(app.SED.nnp)
                    app.DownloadDebugButton.Enable = 'off';
                else
                    app.DownloadDebugButton.Enable = 'on';
                end
            end
            
            app.Figure.SizeChangedFcn = {@app.onWindowSizeChanged};
            app.Figure.CloseRequestFcn = {@app.onCloseFigure};
            app.Figure.Visible = 'on';

        end %createFigure
        
        function openAssemblerLogs(app)
             % OPENASSEMBLERLOGS Create Assembler Log folder, subfolder with script name, and log files
            if ~isfolder('AssemblerLogs')
                mkdir('AssemblerLogs');
            end
            if ~isfolder(['AssemblerLogs\' app.scriptName])
                mkdir(['AssemblerLogs\' app.scriptName]);
            end
            path = ['AssemblerLogs\' app.scriptName '\'];

            app.assemblerLogs.operations = fopen([path 'operations.txt'], 'w');
            app.assemblerLogs.vartables = fopen([path 'variables.txt'], 'w');
            app.assemblerLogs.scriptbody = fopen([path 'opcodelist.txt'], 'w');
            app.assemblerLogs.download  = fopen([path 'downloadImage.txt'], 'w');
            app.assemblerLogs.lines = fopen([path 'lines.txt'], 'w');
        end %openAssemblerLogs
        
        function closeAssemblerLogs(app)
            % CLOSEASSEMBLERLOGS
            fclose(app.assemblerLogs.operations);
            fclose(app.assemblerLogs.vartables );
            fclose(app.assemblerLogs.scriptbody);
            fclose(app.assemblerLogs.download);
            fclose(app.assemblerLogs.lines);
        end %closeAssemblerLogs
        
        
        function scanScriptFile(app)
            % SCANSCRIPTFILE - Scan *.nnpscript file into cell array, A
            fid = fopen(app.file, 'r');
            if fid == -1
                error(['Could not open NNP Script file: "' app.file '" for reading']);
            end
            i = 1;
            tline = fgetl(fid);

            app.SL{i} = tline;
            while ischar(tline)
                i = i+1;
                tline = fgetl(fid);
                app.SL{i} = [tline ' '];
            end
            fclose(fid);
        end %scanScriptFile
            
        function [si, ei, strOut] = findComment(app, str)
            %FINDCOMMENT finds starting and ending indices in str of comments (%) if any
            %     and adds space at end of line, or prior to % so last operand is detected
            
            [si, ei] = regexp(str, '\".*?\"|\s*%.*'); %comment: optional whitespace, '%', anything
            keep = (str(si)~='"');
            si = si(keep);
            ei = ei(keep);
            if ~isempty(ei) && si == 1 %comment begins at beginning, don't do further parsing
                strOut = str;
            else
                if ~isempty(si)
                    strOut=[str(1:si-1) ' ' str(si:end)]; %add a space prior to comment '%' - required to detect final operand
                    si = si + 1;
                    ei = ei + 1;
                else
                    strOut=[str ' ']; %add a space at the end of the line - required to detect final operand
                end
            end
        end %findComment
        
        function [si, ei, si_symbol, ei_symbol, strOut] = findResult(app, str)
            %FINDRESULT finds starting and ending indices in str of results and symbol (=>) if any
            %     and adds space prior to result symbol (=>) so last operand is detected
           
            [si, ei] = regexp(str, '\".*?\"|=>.+'); %result: '=>' followed by anything. Don't include optional whitespace before '>' (will go to preceding opcode/operand)
            keep = str(si)~='"';
            si = si(keep);
            ei = ei(keep);
            if ~isempty(si)
                strOut=[str(1:si-1) ' ' str(si:end)]; %add a space prior to resultsymbol '=>' - required to detect final operand
                si_symbol = si + 1;
                ei_symbol = si + 2;
                si = si + 3;
            else
                strOut = str;
                si_symbol = [];
                ei_symbol = [];
            end
        end %findResult
        
        function [si, ei, strOut] = findVarInit(app, str)
            %FINDVARINIT finds starting and ending indices in str of variable initialzer (=) if any
            %     and adds space prior to = so last operand is detected
            
            [si, ei] = regexp(str, '\".*?\"|=[^>].*'); % '=' followed by anything except >
            keep = str(si)~='"';
            si = si(keep);
            ei = ei(keep);
            if ~isempty(ei)
                strOut=[str(1:si-1) ' ' str(si:end )]; %add a space prior to initializer '='  - required to detect final operand
                si = si + 1;
                ei = ei + 1;
            else
                strOut = str;
            end
        end %findVarInit
        
        function [si, ei] = findLabel(app, str, line)
            %FINDLABEL finds starting and ending indices of labels {} if any
            %       and checks uniqueness of label 
            [si, ei] = regexp(str, '\".*?\"|\s*{\s*\w+\s*}\s*'); %optional whitespace followed by '{', optional whitespace, at least one charachter, optional whitespace, '}'
            keep = str(si)~='"';
            si = si(keep);
            ei = ei(keep);
            if ~isempty(ei)
                newLabel = strtrim(str(si:ei)); %trim whitespace outside {}
                newLabel = strtrim(newLabel(2:end-1)); %trim the {} and any whitespace inside
                if ~isempty(app.label) 
                    [isLabel, iLabel] = ismember(newLabel, app.label(:,1));
                else
                    isLabel = false;
                end
                if isLabel
                    app.addError( ['Label already used at line:' num2str(app.label{iLabel,2})]); 
                else
                    app.i_label = app.i_label + 1;
                    app.label{app.i_label,1} = newLabel;
                    app.label{app.i_label,2} = line;
                end
            end
        end %findLabel
                
        function [si_opcode, ei_opcode, si_vartypescope, ei_vartypescope, si_var, ei_var, ...
                 si_operand, ei_operand, si_unknown, ei_unknown, si_unused, ei_unused] ...
                    = parseOperation(app, str, line, strVarInit, strResult)
            %FINDOPERATION find opcode, operand, variable type/scope, name, or define, define name
            % these are seperated by whitespace. However, we want to ignore whitespace contained within "", [], !!
            % ? . * [ ] { } ( ) ^ + | are used in regular expressions.  To use literally, preface with \
            %Variable declaration
            % VARTYPE VARSCOPE VAR
            % VARSCOPE VARTYPE VAR
            % VARTYPE VAR
            % VARSCOPE VAR
            %
            %define
            % DEFINE DEF
            %
            %Opcode and operands
            % OPCODE (OPERANDS)

            si_opcode = []; 
            ei_opcode = [];
            si_vartypescope = []; %variable type or scope
            ei_vartypescope = [];
            si_var = []; %variable name
            ei_var = [];
            si_operand = []; %operands
            ei_operand = [];
            si_unknown = []; %skipped opcodes or variable definitions
            ei_unknown = [];
            si_unused = []; %skipped operands
            ei_unused = [];
            
            %optional whitespace, followed by literal that may include spaces ("...", [...], !...!), or  at least one non whitespace, and ending in at least one whitespace
            [si, ei] = regexp(str, '\s*((".*?")|(<.*?>)|(\[.*?\])|(!.*?!)|\S+)\s+'); 
            if isempty(ei)
                return  %No operation
            end

            opStr = strtrim(str(si(1):ei(1)));
            % Check if the first element is OpCode, vartype/varscope, or define
            [isOp, whichOp] = ismember(opStr, app.opcodelist(:,1));
            isVar = ismember(opStr, app.vartypelist) || ismember(opStr, app.varscopelist);
            isDef = isequal(opStr, 'define'); 

            if isDef
                app.i_def=app.i_def+1;
                app.def(app.i_def).line = line;
                si_vartypescope = si(1); %add define color?
                ei_vartypescope = ei(1);

            elseif isOp
                app.i_operation = app.i_operation + 1;
                app.operation(app.i_operation).index = whichOp;
                app.operation(app.i_operation).line = line;
                si_opcode = si(1);
                ei_opcode = ei(1);

                app.operation(app.i_operation).opCodeName = opStr;
                app.operation(app.i_operation).opCodeByte = app.opcodelist{app.operation(app.i_operation).index , 2};

            elseif isVar
                app.i_var=app.i_var+1;
                app.var(app.i_var).line = line;
                si_vartypescope = si(1);
                ei_vartypescope = ei(1);
                if ismember(opStr, app.vartypelist)
                    app.var(app.i_var).type = opStr;
                else
                    app.var(app.i_var).scope = opStr;
                end

            else
                app.addWarning( 'unknown opCode or variable definition, line ignored');
                si_unknown = si(1);
                ei_unknown = ei(end);
                ei = [];
                si = [];
            end

            % Check for valid second element
            if length(si) > 1
                opStr = strtrim(str(si(2):ei(2)));
                if isDef
                    if ~isempty(strVarInit)
                        if app.i_def > 0
                            defnames = arrayfun(@(x) x.name, app.def(1:end-1), 'UniformOutput', false);
                        else
                            defnames = [];
                        end
                        if ismember(opStr, defnames)
                            app.def(app.i_def) = [];
                            app.i_def=app.i_def-1;
                            app.addWarning( 'define name previously used, ignored');
                        else
                            app.def(app.i_def).name = opStr;
                            app.def(app.i_def).replace = strtrim(strVarInit); %scrap '=' and trim white space
                        end
                    else
                        app.def(app.i_def) = [];
                        app.i_def=app.i_def-1;
                        app.addWarning( 'define has no definition, ignored');
                    end
                    si_var = si(2); %add color type for def?
                    ei_var = ei(2);
                    if length(si) > 2
                        app.addWarning('ignoring extra content');
                        si_unknown = si(3);
                        ei_unknown = ei(end);
                    end
                %variable must have at least scope or type, but can have one or both
                elseif isVar && (ismember(opStr, app.vartypelist) || ismember(opStr, app.varscopelist))
                    if ismember(opStr, app.vartypelist)
                        if isempty(app.var(app.i_var).type)
                            app.var(app.i_var).type = opStr;
                        else
                            app.addWarning( 'second type definition ignored');
                        end
                    else
                        if isempty(app.var(app.i_var).scope)
                            app.var(app.i_var).scope = opStr;
                        else
                            app.addWarning( 'second scope definition ignored');
                        end

                    end
                    %change endindex to include second variable type/scope entry
                    ei_vartypescope = ei(2);

                    % Check for valid third element
                    if length(si) > 2
                        opStr = strtrim(str(si(3):ei(3)));
                        %>> section copy/pasted to case where length(op)==2
                        %consider combining
                        iArray = regexp(opStr,'\[.*\]');
                        if isempty(iArray)
                            app.var(app.i_var).name = opStr;
                            app.var(app.i_var).array = 0;
                        else
                            app.var(app.i_var).name = opStr(1:iArray-1);
                            nEl = str2double(opStr(iArray+1:end-1));
                            if isnan(nEl) || length(nEl) ~=1 || ~isreal(nEl)
                                 app.addError('invalid number of elements' ); 
                            else
                                app.var(app.i_var).array = nEl;
                            end
                        end
                        if ~isempty(strVarInit)
                            app.var(app.i_var).initStr = strtrim(strVarInit);
                            %Note: init string is converted to type and checked in assembleoperation
                        end
                        %<<
                        si_var = si(3);
                        ei_var = ei(3);

                        if length(si) > 3
                            app.addWarning('ignoring extra content');
                            si_unknown = si(4);
                            ei_unknown = ei(end);
                        end
                    else
                        app.addWarning( 'No variable name, ignored');
                    end
                else %either variable name or operand
                    if isVar
                        if isempty(app.var(app.i_var).type)
                            app.var(app.i_var).type = 'uint8';
                            app.addWarning('default type: uint8');
                        end
                        if isempty(app.var(app.i_var).scope)
                            app.var(app.i_var).scope = 'stack';
                            app.addWarning('default scope: stack');
                        end
                        %>> section copy/pasted to case where length(op)>2
                        %consider combining
                        iArray = regexp(opStr,'\[.*\]');
                        if isempty(iArray)
                            app.var(app.i_var).name = opStr;
                            app.var(app.i_var).array = 0;
                        else
                            app.var(app.i_var).name = opStr(1:iArray-1);
                            nEl = str2double(opStr(iArray+1:end-1));
                            if isnan(nEl) || length(nEl) ~=1 || ~isreal(nEl)
                                 app.addError('invalid number of elements' ); 
                            else
                                app.var(app.i_var).array = nEl;
                            end
                        end
                        if ~isempty(strVarInit)
                           app. var(app.i_var).initStr = strtrim(strVarInit);
                             %Note: init string is converted to type and checked in assembleoperation
                        end
                        %<<
                        si_var = si(2);
                        ei_var = ei(2);

                        if length(si) > 2
                            app.addWarning('ignoring extra content');
                            si_unknown = si(3);
                            ei_unknown = ei(end);
                        end

                    elseif isOp
                        %check number of operands
                        minOperands = app.opcodelist{app.operation(app.i_operation).index,3};
                        maxOperands = app.opcodelist{app.operation(app.i_operation).index,4};


                        nOperands = length(si)-1;

                        if nOperands < minOperands
                            if minOperands==maxOperands
                                app.addError( sprintf('requires %1.0f operands', minOperands)); 
                            else
                                app.addError( sprintf('requires %1.0f-%1.0f operands', minOperands,maxOperands)); 
                            end
                            si_operand = ei(1)+1;
                            ei_operand = endparse;

                        elseif nOperands > maxOperands
                            si_operand = ei(1)+1;
                            ei_operand = ei(maxOperands+1);
                            app.addWarning( 'ignoring operands'); 
                            si_unused = ei(maxOperands+1)+1;
                            ei_unused = length(str);
                            nOperands = maxOperands;
                        else
                            si_operand = ei(1)+1;
                            ei_operand = length(str);
                        end



                        for j=1:nOperands
                            if isempty(app.operation(app.i_operation).operand)
                                app.operation(app.i_operation).operand = struct('str', '', 'bytes',[],'typeScope',[],'iVar', [], 'literal', [], ...
                                    'typeScopePair',[],'iVarPair', [], 'literalPair', [], 'network', []);
                            end
                            app.operation(app.i_operation).operand(j).str = strtrim(str(si(j+1):ei(j+1)));
                        end
                    else
                        disp('why here?')
                    end
                end
            else %Operand or Variable definition but nothing further
                if isDef
                    app.addWarning('No define name, ignored');
                    app.def(app.i_def) = [];
                    app.i_def=app.i_def-1;
                elseif isVar
                    app.addWarning('No variable name, ignored');
                    app.var(app.i_var) = [];
                    app.i_var = app.i_var - 1;
                elseif isOp
                     %check if OK to have no operands based on opCode
                     minOperands = app.opcodelist{app.operation(app.i_operation).index,3};
                     maxOperands = app.opcodelist{app.operation(app.i_operation).index,4};
                     if minOperands > 0
                         if minOperands==maxOperands
                           app.addError( sprintf('requires %1.0f operands', minOperands)); 
                         else
                            app.addError( sprintf('requires %1.0f-%1.0f operands', minOperands,maxOperands));
                         end
                     end
                end

            end

            if isOp
                nResult = app.opcodelist{app.operation(app.i_operation).index,6};

                if nResult>0 
                    jumpResult = app.opcodelist{app.operation(app.i_operation).index,7}==1;
                    if isempty(strResult)
                        app.warnStr = [];
                        app.addWarning('opcode requires a result - ignoring operation'); 
                        %ignore this operation
                        si_unknown = startparse;
                        ei_unknown = endparse;
                        si_unused = [];
                        ei_unused = [];
                        si_operand = [];
                        ei_operand = [];
                        si_opcode = [];
                        ei_opcode = [];
                        app.operation(app.i_operation) = [];
                        app.i_operation = app.i_operation-1;
                    else
                        app.operation(app.i_operation).result = struct('str', '', 'bytes',[],'typeScope',[],'iVar', [],'literal', jumpResult,...
                            'typeScopePair',[],'iVarPair', [],  'literalPair', [], 'network', []);
                        app.operation(app.i_operation).result.str = strtrim(strResult);
                    end
                end
                
                app.checkOperands();    
            end
            
        end %parseOperation
        
        function parseScriptLines(app)
            % PARSESCRIPTLINES iterate through all lines and parse the strings
            % 1. look for comments - moves endparse (% followed by anything) 
            % 2. look for result - moves endparse (=> followed by text) 
            % 3. look for variable initializer (=) - moves endparse  
            % 4. look for label ({ }) - moves startparse  
            % 5. look for opcode or variable definition (keywords) and subsequent operands or variable definition
            %
            % Note for steps 1-4 we check for "..." OR the special characters (%, =, =>, {}).  This way we can make exceptions
            % for usage of the special characters inside strings.
            nLines = length(app.SL)-1;
            
            %These are used to track the string positino of the HTML formatted text for use by 
            %the error/warnings DBG
            % errors/warning are placed before comments
            % ( currentValue ) is palced after each non-literal operand/result during debugging
            app.strPosOperand = nan(nLines, 2); 
            app.strPosResult = nan(nLines, 2); 
            app.strPosComment = nan(nLines); 
            
            app.def = struct('name','','line',[],'replace','');
            app.def(1).name = 'log';     app.def(1).replace = 'N<L,0>7:A000.1'; %log without timestamp
            app.def(2).name = 'timelog'; app.def(2).replace = 'N<L,1>7:A000.1'; %log with timestamp
            %Can add additional predefined things here
            app.i_def = length(app.def);

            for i = 1:nLines

                app.errStr = [];
                app.warnStr = [];

                fprintf(app.assemblerLogs.lines, '\nLine %3.0f: ', i);

                % LABEL ... VARINIT RESULTS (COMMENT)
                [si_comment, ei_comment, strOut] = app.findComment(app.SL{i});
                app.SL{i} = strOut; 
                if ~isempty(si_comment)
                    endparse = si_comment-1;
                else
                    endparse = length(strOut);
                end

                startparse = 1;
                % LABEL ... VARINIT (RESULTS)
                [si_result, ei_result, si_resultsymbol, ei_resultsymbol, strOut] = app.findResult(app.SL{i}(startparse:endparse));
                app.SL{i} = [strOut app.SL{i}(endparse+1:end)];
                if ~isempty(si_resultsymbol)
                    endparse = si_resultsymbol-1;
                end

                % LABEL ... (VARINIT)
                [si_varinit, ei_varinit, strOut] = app.findVarInit(app.SL{i}(startparse:endparse)); 
                app.SL{i} = [strOut app.SL{i}(endparse+1:end)];
                if ~isempty(si_varinit)
                    endparse = si_varinit-1;
                end

                % (LABEL) ...
                [si_label, ei_label] = app.findLabel(app.SL{i}(startparse:endparse), i); 

                if ~isempty(ei_label)
                    startparse = ei_label + 1;
                end

                % (...)
                strVarInit =  app.SL{i}(si_varinit+1:ei_varinit); %trim leading "="
                strResult = app.SL{i}(si_result:ei_result);
                
                [si_opcode, ei_opcode, si_vartypescope, ei_vartypescope, si_var, ei_var, ...
                  si_operand, ei_operand, si_unknown, ei_unknown, si_unused, ei_unused] ...
                        = app.parseOperation(app.SL{i}(startparse:endparse), i,strVarInit, strResult);
                if startparse > 1 %shift start/end indices
                    si_opcode = si_opcode + startparse - 1;
                    ei_opcode = ei_opcode + startparse - 1; 
                    si_vartypescope = si_vartypescope + startparse - 1;
                    ei_vartypescope = ei_vartypescope + startparse - 1;
                    si_var = si_var + startparse - 1;
                    ei_var = ei_var + startparse - 1;
                    si_operand = si_operand + startparse - 1;
                    ei_operand = ei_operand + startparse - 1;
                    si_unknown = si_unknown + startparse - 1;
                    ei_unknown = ei_unknown + startparse - 1;
                    si_unused = si_unused + startparse - 1;
                    ei_unused = ei_unused + startparse - 1;
                end


                formattedtext = ['<HTML><pre><FONT COLOR="black">' sprintf('%03u  ', i)]; %use <pre> tag to prevent deleting whitespace in HTML

                if ~isempty(ei_label)
                    formattedtext=[formattedtext '<FONT COLOR="800040"><i>' app.SL{i}(si_label:ei_label) '</i>'];
                end

                if ~isempty(ei_vartypescope)
                    formattedtext=[formattedtext '<FONT COLOR=#48D1CC><b>' app.SL{i}(si_vartypescope:ei_vartypescope) '</b>'];
                end

                if ~isempty(ei_var)
                    formattedtext=[formattedtext '<FONT COLOR=#FF00FF><b>' app.SL{i}(si_var:ei_var) '</b>'];
                end

                if ~isempty(ei_opcode)
                    formattedtext=[formattedtext '<FONT COLOR="blue"><b>' app.SL{i}(si_opcode:ei_opcode) '</b>'];
                end

                if ~isempty(ei_unknown)
                    formattedtext=[formattedtext '<FONT COLOR="purple"><i><u>' app.SL{i}(si_unknown:ei_unknown) '</i></u>'];
                end

                if ~isempty(ei_operand)
                    str = app.formatHTML(app.SL{i}(si_operand:ei_operand));
                    formattedtext=[formattedtext '<FONT COLOR="black">'];
                    app.strPosOperand(i, 1) = length(formattedtext)+1;
                    formattedtext=[formattedtext str];
                    app.strPosOperand(i, 2) = length(formattedtext);
                end

                if ~isempty(ei_unused)
                    formattedtext=[formattedtext '<FONT COLOR="purple"><i><u>' app.SL{i}(si_unused:ei_unused) '</i></u>'];
                end

                if ~isempty(ei_varinit)
                    str = app.formatHTML(app.SL{i}(si_varinit:ei_varinit));
                    formattedtext=[formattedtext '<FONT COLOR=#FF8000><b>' str '</b>'];
                end

                if ~isempty(ei_resultsymbol)
                    formattedtext=[formattedtext '<FONT COLOR="blue"><b>' app.SL{i}(si_resultsymbol:ei_resultsymbol) '</b>'];
                end

                if ~isempty(ei_result)
                    formattedtext=[formattedtext '<FONT COLOR="black">'];
                    app.strPosResult(i, 1) = length(formattedtext)+1;
                    formattedtext=[formattedtext app.SL{i}(si_result:ei_result) ];
                    app.strPosResult(i, 2) = length(formattedtext);
                end

                %put errors, then warnings, then comments
                if ~isempty(app.errStr)
                    formattedtext=[formattedtext '<FONT COLOR="red"><small><i><u>' app.errStr '</i></u></small>'];
                end

                if ~isempty(app.warnStr)
                    formattedtext=[formattedtext '<FONT COLOR="purple"><small><i><u>' app.warnStr '</i></u></small>'];
                end

                app.strPosComment(i)= length(formattedtext)+1;
                if ~isempty(ei_comment)    
                    formattedtext=[formattedtext '<FONT COLOR="green"><i>' app.SL{i}(si_comment:ei_comment) '</i>'];
                end

                formattedtext=[formattedtext '</pre></HTML>'];
                
                app.SLF{i} = formattedtext;

            end %end looping through all lines
        end %parseText
        
        function checkOperands(app)
            % CHECKOPERANDS checks if operands are valid and opulates operand/result information in operation struct array 
              
                % 1. existing define (recursively get to root of definition)
                % 2. literal
                %    A. string: " "
                %    B. bytearray: ! ! (hex)
                %    C. numeric scalar or numerical array [ ] (decimal)
                % 3. existing scalar variable
                % 4. existing array
                % 5. existing array element
                %    A. array with literal index (scalar numeric < array length)
                %    B. array with variable index (existing scalar numeric)
                % 6. network address (starts with N, but not an existing variable)
                %    A. address with literal subindex (scalar numeric) 
                %    B. address with variable subindex (existing scalar numeric)



                if app.i_var>0
                    varnames = arrayfun(@(x) x.name, app.var, 'UniformOutput', false);
                else
                    varnames = [];
                end
                if app.i_def > 0
                    defnames = arrayfun(@(x) x.name, app.def, 'UniformOutput', false);
                else
                    defnames = [];
                end

                nOperands = length(app.operation(app.i_operation).operand);
                nResult = length(app.operation(app.i_operation).result);
                for j=1:nOperands+nResult 
                    iDefinedVar = [];
                    iDefinedVarEl = [];
                    operand = [];
                    el = [];
                    typemod = 0;
                    type = [];
                    scope = [];
                    typemodEl = 0;
                    typeEl = [];
                    scopeEl = [];
                    network = [];


                    if j<=nOperands
                        operandStr = app.operation(app.i_operation).operand(j).str;
                    else
                        operandStr = app.operation(app.i_operation).result.str;
                        if app.operation(app.i_operation).result.literal
                            app.operation(app.i_operation).result.literal = operandStr;
                            app.operation(app.i_operation).result.typeScope = app.typeStr2Code('uint16');
                            break;
                        end
                    end

                    %First look for literals, then replace any defines.
                    %Then look for literals again
                    %
                    loop = true;
                    checkedDefines = false;
                    while loop
                        loop = false;
                        operand = str2double(operandStr);
                        %Literals
                        if ~isnan(operand) && isreal(operand) %numeric decimal literal (scalar)
                            scope = app.scopeStr2Code('literal');
                            if operand<0
                                type = app.typeStr2Code('int32');
                                operand = typecast(int32(operand), 'uint8');
                            else
                                type = app.typeStr2Code('uint32');
                                operand = typecast(uint32(operand), 'uint8');
                            end
                        elseif length(operandStr)>2 && isequal(operandStr(1:2), '0b') %numeric binary literal (scalar)
                            try
                                operand = bin2dec(operandStr(3:end));
                                scope = app.scopeStr2Code('literal');
                                type = app.typeStr2Code('uint32');
                                operand = typecast(uint32(operand), 'uint8');
                            catch
                                app.addError('invalid binary literal: 0b...');  
                            end
                        elseif length(operandStr)>2 && isequal(operandStr(1:2), '0x') %numeric hex literal (scalar)
                            try
                                operand = hex2dec(operandStr(3:end));
                                scope = app.scopeStr2Code('literal');
                                type = app.typeStr2Code('uint32');
                                operand = typecast(uint32(operand), 'uint8');
                            catch
                                app.addError('invalid hex literal: 0x..."');  
                            end

                        %string literal
                        elseif length(operandStr)>2 && operandStr(1) == '"' && operandStr(end) == '"' 
                            operand = operandStr(2:end-1);
                            operand = [uint8(operand) uint8(0)]; %null terminate string
                            scope = app.scopeStr2Code('literal');
                            type = app.typeStr2Code('string');

                        %bytearray literal
                        elseif length(operandStr)>2 && operandStr(1) == '!' && operandStr(end) == '!' 
                            operand = hex2dec(regexp(operandStr(2:end-1), '[0-9abcdefABCDEF]{2}','match'))';
                            scope = app.scopeStr2Code('literal');
                            type = app.typeStr2Code('ba');

                        %array literal
                        elseif length(operandStr)>2 && operandStr(1) == '[' && operandStr(end) == ']' 
                            varCast = regexp(operandStr, '(\(\w+\))|(\|\w+)', 'match'); %allow (type) or |type
                            if isempty(varCast)
                               varCast ='uint8';
                               app.addWarning('assuming uint8 type for literal array');
                            else
                                operandStr = strrep(operandStr, varCast{1}, ''); %remove cast string from operand string 
                                if varCast{1}(1) == '|'
                                    varCast = varCast{1}(2:end); %remove | and convert cell to string
                                else 
                                    varCast = varCast{1}(2:end-1); %remove ( ) and convert cell to string
                                end
                                if ~app.isNumericType(varCast)
                                    varCast ='uint8';
                                    app.addWarning('invalid literal array cast type, assuming uint8');
                                end
                            end
                            
                            % support mixed hex and decimal and binary types
                            operandStrSep = regexp(operandStr(2:end-1), '((0x[0-9abcdefABCDEF]+)|(0b[01]+)|(\d+))','match');
                            operand = nan(1, length(operandStrSep));
                            for i=1:length(operandStrSep)
                                operandHex = sscanf(operandStrSep{i}, '0x%X');
                                if ~isempty(operandHex)
                                    operand(i) = operandHex;
                                else
                                    operandBinStr = regexp(operandStrSep{i},'0b[01]+','match');
                                    if ~isempty(operandBinStr)
                                        operand(i) = bin2dec(operandBinStr{1}(3:end));  %convert cell to string and remove '0b'
                                    else
                                        operand(i) = str2double(operandStrSep{i});
                                    end
                                end
                            end

                            scope = app.scopeStr2Code('literal');
                            type = app.typeStr2Code('ba');
                            operand = typecast(cast(operand, varCast), 'uint8');
                            %typemod = 0;
                            %typemodEL = app.modifierStr2Code('array'); %0x80 array modifier
                            %typemod = app.modifierStr2Code('array'); %0x80 array modifier

                        else

                            %if we haven't yet replaced defines, do that
                            if ~checkedDefines
                                if isempty(defnames)
                                    checkedDefines = true;
                                else
                                    %break up the operand string at delimiters used in network and array operands
                                    [operandSplitStr, delimiterMatch] = strsplit(operandStr, {':','|','.','^','[',']','<','>'});

                                    %find if any of the strings are present in list of defines
                                    [isDefine, iDefine ]= ismember(operandSplitStr, defnames);

                                    %replace those strings with their definition
                                    for d=find(isDefine)
                                        operandSplitStr{d} = app.def(iDefine(d)).replace;
                                        fprintf(app.assemblerLogs.lines, '\n  replaced "%s" with "%s"', app.def(iDefine(d)).name, app.def(iDefine(d)).replace);
                                    end

                                    %put the operand string back together
                                    operandStr = strjoin(operandSplitStr, delimiterMatch);


                                    if any(isDefine)
                                        loop = true;
                                        continue; %go back to beinning of while loop
                                    else
                                        checkedDefines = true;
                                    end
                                end
                            end

                            %continue looking for network, variable, and arrays

                            %network
                            if length(operandStr)>=9 && isequal(regexp(operandStr, '(\(\w+?\))?N(<.*?>)?\d{1,2}:[0-9abcdefABCDEF]{4}\.[^\.\:]*'),1) 
                                %N followed by 1 or 2 digits followed by : followed by 4 hex deigts followed by . without any further . or :
                                operand = []; 
                                %type, scope, and typemod refer to how subindex will be reported 
                                %(scope always 0, type mod always 0x40, and iDefinedVar always empty)
                                %typeEl, scopeEl, and typemodEl, and iDefinedVarEl refer to the variable subindex
                                %if the subIndex is literal AND there are not multiple subindices,
                                %typeEl, scopeEl will be empty and typemodEl = 0;
                                scope = app.scopeStr2Code('literal'); 
                                typemod = app.modifierStr2Code('network'); %0x40
                                type = app.typeStr2Code('null');
                                subIndex = []; 
                                nSubIndices = 0;
                                odIndex = [];

                                %Get NODE
                                nodeStr = regexp(operandStr, '\d{1,2}:', 'match'); 
                                if ~isempty(nodeStr)
                                    nodeStr = nodeStr{1}(1:end-1); %convert to string  and scrap trailing : 
                                    node = str2double(nodeStr); 
                                    if isnan(node) || node>15 ||~isreal(node)
                                        app.addWarning( 'node should be 15 or lower'); 
                                    end
                                else
                                    error('should not get here, because expression already matched')
                                end

                                %Get OD INDEX  - literal (hex) only - required
                                indexStr = regexp(operandStr, '\:[0-9abcdefABCDEF]{4}\.', 'match');  
                                if ~isempty(indexStr)
                                    indexStr = indexStr{1}(2:end-1); %convert to string  and scrap leading : and trailing .
                                    odIndex = hex2dec(indexStr); 
                                else
                                    error('should not get here, because expression already matched')
                                end

                                %Get OD SUBINDEX  - literal (hex) or variable -required
                                subIndexStrHex = regexp(operandStr, '\.[0-9abcdefABCDEF]+', 'match'); %find . followed by 1 or more hex digits
                                if ~isempty(subIndexStrHex) %literal subIndex 
                                    subIndexStrHex = subIndexStrHex{1}(2:end); %convert to string and remove .
                                    if length(subIndexStrHex)>2
                                        app.addError( 'Literal subindex must be hex 0-ff/FF');
                                        %subIndex = 255; %avoid further errors
                                    else
                                        subIndex = hex2dec(subIndexStrHex);
                                    end
                                else  %non literal subIndex or no subindex 
                                    subIndexStrVar = regexp(operandStr, '\.\(\w+?\)', 'match'); %find .( followed by word followed by )  Use lazy ?
                                    if ~isempty(subIndexStrVar) %variable subindex
                                        subIndexStrVar = subIndexStrVar{1}(3:end-1); %convert to string and remove .(  )
                                        subIndex = [];
                                        [isDefinedVarEl, iDefinedVarEl] = ismember(subIndexStrVar, varnames);
                                        if isDefinedVarEl
                                            if app.isNumericType(app.var(iDefinedVarEl).type) && app.var(iDefinedVarEl).array == 0
                                                fprintf(app.assemblerLogs.lines, '\n  found usage of "%s" as variable subindex' , varnames{iDefinedVarEl});
                                                app.varUsage = [app.varUsage; iDefinedVarEl];
                                                scopeEl = app.scopeStr2Code(app.var(iDefinedVarEl).scope);
                                                typeEl = app.typeStr2Code(app.var(iDefinedVarEl).type);
                                                typemodEl = app.modifierStr2Code('networkmulti'); %0xC0
                                            else
                                                app.addError( 'Variable subindex must be a numeric scalar type'); 
                                            end
                                        else
                                            app.addError( 'Variable for subindex does not exist'); 
                                        end
                                    else %no subindex
                                       app.addError( 'OD Index must be followed by .XX in hex or .(var) where var is numeric scalar variable'); 
                                    end

                                end

                                %Get NUMBER OF SUBINDICES - optional, default 1
                                nSubIndicesStr = regexp(operandStr, '\^\d{1,2}', 'match'); %find ^ followed by word
                                if ~isempty(nSubIndicesStr)
                                    nSubIndicesStr = nSubIndicesStr{1}(2:end); %convert to string and scrap '^'
                                    nSubIndices = str2double(nSubIndicesStr); 
                                    if isnan(nSubIndices) || ~isreal(nSubIndices) || nSubIndices > 50 && nSubIndices > 0
                                         app.addError(['invalid number of subindices ^' nSubIndicesStr] ); 
                                    elseif nSubIndices > 1
                                        typemodEl = app.modifierStr2Code('networkmulti'); %0xC0
                                        typeEl = app.typeStr2Code('uint8');
                                        if isempty(scopeEl) %only set scopeEl if it has not been set by variable subindex
                                            scopeEl = app.scopeStr2Code('literal');
                                        end
                                    end
                                end

                                %Get TYPE OF SUBINDEX - optional, default uint8
                                typeStr = regexp(operandStr, '\(\w+?\)N', 'match'); %find ( followed by word followed by )N
                                if isempty(typeStr)
                                    typeStr = regexp(operandStr, '\|\w+', 'match'); %find | followed by word (type)
                                    if isempty(typeStr)
                                        type = app.typeStr2Code('uint8');  
                                        app.addWarning( 'assuming uint8 type for network operand');
                                    else
                                        typeStr = typeStr{1}(2:end); %convert to string and scrap '|'
                                        type = app.typeStr2Code(typeStr); 
                                        if isempty(type)
                                            app.addWarning( 'invalid type for network operand, assuming uint8'); 
                                            type = app.typeStr2Code('uint8');
                                        end
                                    end
                                else
                                    typeStr = typeStr{1}(2:end-2); %convert to string and scrap ( )N 
                                    type = app.typeStr2Code(typeStr); 
                                    if isempty(type)
                                        app.addWarning( 'invalid type for network operand, assuming uint8'); 
                                        type = app.typeStr2Code('uint8');
                                    end
                                end
                                
                                

                                %Get PORT/NETID - optional, 
                                %default use r,R,or 2 : port = 2, netID = 1
                                %for PM logging use l,L,or 4 port = 4, netID = 1
                                %S, C, and T ports are only relevant for ControlTower
                                port = 2;
                                netID = 1;

                                if regexp(operandStr, '<.*?>')  %use "lazy" (?) modifier to find closest >
                                    portnetStr = regexp(operandStr, '<[1Rr4Ll],\d>', 'match'); %find < followed by 0-9 followed by , followed by digit followed by > with optional whitespace 
                                    if ~isempty(portnetStr)
                                        portnetStr = portnetStr{1}(2:end-1); %convert to string and scrap  '<' and '>'
                                        portnetStr = strsplit(portnetStr, ','); %convert back to cell array split by comma
                                        portStr = strtrim(portnetStr{1});
                                        switch portStr
                                            case {'r','R','2'}
                                                port = 1;
                                            case {'l','L','4'}
                                                port = 4;       
                                        end
                                        netID = str2double(portnetStr{2});
                                    else
                                       app.addWarning( 'invalid port/netID specifier, ignoring'); 
                                    end
                                else
                                    fprintf(app.assemblerLogs.lines, '\n   (using default port/netID)');
                                end
                                fprintf(app.assemblerLogs.lines, '\n  found Network, node %2.0f, port %2.0f, netID %2.0f, odIndex %4X.%2.0f (%2.0f)', node, port, netID, odIndex, subIndex, nSubIndices);
                                network = struct('node', node, 'port', port, 'netID', netID, 'odIndex', odIndex, 'subIndex', subIndex, 'nSubIndices', nSubIndices);

                            %non-literal (array and scalar)
                            else
                                %if it is an array we need to strip the
                                %array indexer [...]
                                operand = [];
                                [iEl, elStr] = regexp(operandStr, '\[.*?\]','start','match'); %use "lazy" (?) modifier to find closest ]

                                if ~isempty(iEl)
                                    operandStr = operandStr(1:iEl-1);
                                end

                                [isDefinedVar, iDefinedVar] = ismember(operandStr, varnames);

                                % defined variable 
                                if isDefinedVar 
                                    type = app.typeStr2Code(app.var(iDefinedVar).type);
                                    scope = app.scopeStr2Code(app.var(iDefinedVar).scope);
                                    maxEl = app.var(iDefinedVar).array;

                                    if maxEl > 0 %array
                                        typemod = 0; 
                                        typemodEl = app.modifierStr2Code('array'); % 0x80
                                        scopeEl = app.scopeStr2Code('literal');
                                        typeEl = app.typeStr2Code('uint16');
                                        el = 65534; %0xFFFE: code for entire array
                                    else %scalar
                                        typemod = 0;
                                        typemodEl = [];
                                        scopeEl = [];
                                        typeEl = [];
                                        el = [];
                                    end

                                    if ~isempty(elStr)
                                        elStr = elStr{1}(2:end-1); %convert cell to string and strip [ ] 
                                        if app.var(iDefinedVar).array == 0 
                                            app.addError( 'attempting to index non-array variable');  
                                        else
                                            el = str2double(elStr);
                                            if ~isnan(el) && isreal(el)
                                                if el > maxEl-1
                                                    app.addError( 'exceeds array bounds');  
                                                else
                                                     %scalar literal array element
                                                    typeEl = app.typeStr2Code('uint16');
                                                    scopeEl = app.scopeStr2Code('literal');

                                                end
                                            else
                                                elStr = strtrim(elStr);
                                                if isempty(elStr)
                                                    el = 65534; %0xFFFE: code for entire array
                                                else
                                                    el = [];
                                                    [isDefinedVarEl, iDefinedVarEl] = ismember(elStr, varnames);
                                                    if isDefinedVarEl
                                                        if app.var(iDefinedVarEl).array >0
                                                            app.addError( 'array variable used as array index');  
                                                        else
                                                            %verify that variable is valid as an index (scalar
                                                            %numeric)
                                                            typeElStr = app.var(iDefinedVarEl).type;
                                                            if app.isNumericType(typeElStr)
                                                                typeEl = app.typeStr2Code(typeElStr);
                                                                scopeEl = app.scopeStr2Code(app.var(iDefinedVarEl).scope);
                                                                fprintf(app.assemblerLogs.lines, '\n  found usage of "%s" as array element',  varnames{iDefinedVarEl});
                                                                app.varUsage = [app.varUsage; iDefinedVarEl];
                                                            else
                                                                app.addError( 'non-numeric variable used as array index');  
                                                            end
                                                        end

                                                    else
                                                         app.addError( 'undefined variable used as array index');  
                                                    end
                                                end
                                            end
                                        end

                                    end
                                    fprintf(app.assemblerLogs.lines, '\n  found usage of "%s"', varnames{iDefinedVar});
                                    app.varUsage = [app.varUsage; iDefinedVar];
                                    el = typecast(uint16(el), 'uint8');                             %undefined variable
                                else
                                    if operandStr(1) == 'N'
                                        app.addWarning( 'possible wrong Network format');
                                    end
                                    if j<=nOperands
                                        app.addError( ['undefined variable in operand' num2str(j)]);  
                                    else
                                        app.addError( 'undefined variable in result');
                                    end
                                end


                            end %end non-literals (else case)
                        end 
                    end %end while


                    if j<=nOperands
                        app.operation(app.i_operation).operand(j).typeScope = typemod+scope+type;
                        app.operation(app.i_operation).operand(j).typeScopePair = typemodEl+scopeEl+typeEl;
                        app.operation(app.i_operation).operand(j).iVar = iDefinedVar;
                        app.operation(app.i_operation).operand(j).literal = operand;
                        app.operation(app.i_operation).operand(j).literalPair = el;
                        app.operation(app.i_operation).operand(j).iVarPair = iDefinedVarEl;
                        app.operation(app.i_operation).operand(j).network = network;
                    else
                        app.operation(app.i_operation).result.typeScope = typemod+scope+type;
                        app.operation(app.i_operation).result.typeScopePair = typemodEl+scopeEl+typeEl;
                        app.operation(app.i_operation).result.iVar = iDefinedVar;
                        if ~isempty(operand)
                            disp('no literal allowed for result unless jump label')
                        end
                        app.operation(app.i_operation).result.literalPair = el;
                        app.operation(app.i_operation).result.iVarPair = iDefinedVarEl;
                        app.operation(app.i_operation).result.network = network;
                    end
                end %end for operands
        end  %checkOperands

        function addWarning(app, newStr)
            %ADDWARNING
            if isempty(app.warnStr)
                app.warnStr = [' ~' newStr];
            else
                app.warnStr = [app.warnStr, ' | ' newStr];
            end
        end  %addWarning

        function addError(app, newStr)
            %ADDERROR
            if isempty(app.errStr)
                app.errStr = [' ~' newStr];
            else
                app.errStr = [app.errStr, ' | ' newStr];
            end
        end %addWarning

        function generateKeyWordList(app)
            % GENERATEKEYWORDLIST For generating Noptepad++ UDL keywords
            opcodelistStr = [];
            for i=1:length(app.opcodelist)
                opcodelistStr = [opcodelistStr ' ' app.opcodelist{i,1}];
                disp(opcodelistStr);
            end
        end %generateKeyWordList
        
        
        %--------------UI Callbacks ------------------
        function onCloseFigure(app, src, event)
            %ONCLOSEFIGURE closes associated figures with main figure
            try
                if ~isempty(app.DBG)
                    app.DBG.closeMonitors()
                end
            catch
                disp('assembler handle deleted?');
            end
            delete(src);
        end %onCloseFiure
        
        function onFontSizeChanged(app, src, event)
            % ONFONTSIZECHANGED
            
            f = str2double(src.String);
            if ~isnan(f)
                app.ListBox.FontSize = f;
                src.Value = f;
            else
                src.String = num2str(src.Value);
            end    
        end %onFontSizeChanged

        function onWindowSizeChanged(app, src, event)
            %ONWINDOWSIZECHANGED Scales ListBox and other UI elemnts appropriately
            %     and limits how small user can make window
            
            w = src.Position(3);
            h = src.Position(4);

            if w < 250
                src.Position(3) = 250;
                w = 250;
            end
            if h < 280
                src.Position(4) = 280;
                h = 280;
            end

            app.ListBox.Position = [10 10 w-150 h-20]; %ListBox
            app.FontSizeLabel.Position = [w-130 h-45 80 20]; %FontSize Label
            app.FontSizeEditField.Position = [w-50 h-40 40 20]; %FontSize Edit
            app.EditButton.Position = [w-130 h-100 120 40];
            app.ReassembleButton.Position = [w-130 h-150 120 40];
            if ~isempty(app.SED)
                app.DownloadDebugButton.Position = [w-130 h-200 120 40];
            end
            
            if ~isempty(app.DBG)
                app.DBG.redrawControls();
            end
        end %onWindowSizeChanged
        
        function onEditClick(app, src, event)
            %ONEDITCLICK
            winopen(app.file);
        end %onEditClick
        
        function onReassembleClick(app, src, event)
            %ONREASSEMBLECLICK
            if ~isempty(app.SED)
                app.SED.assembleScriptByID(app.scriptID);
            else
                msgbox('not yet supported without using scriptedit');
            end
        end %onReassembleClick
        
        function onDownloadDebugClick(app, src, event)
            %ONDOWNLOADDEBUGCLICK uses scriptedit app to download script to PM
            if ~isempty(app.SED)
                app.SED.downloadScriptByID(app.scriptID);
            end
            if isempty(app.DBG)
                app.DBG = debugger(app.SED.nnp, app);
            end
        end %onDownloadDebugClick
        
    end %non-static methods
    
    methods(Static)   
       function crc = calculateCRC16(data)
            %CALCULATECRC16 - CRC-16/CCITT-FALSE
            %https://crccalc.com/
            % test (0x29B1): dec2hex(assembler.calculateCRC16(uint8('123456789')))
            
            x = uint16(0);
            crc = uint16(65535); %0xFFFF
            
            for i = 1:length(data)
                x = bitxor(bitshift(crc, -8), uint16(data(i)));
                x = bitxor(x, bitshift(x, -4));
                
                crc = bitxor(bitshift(crc,8),...
                        bitxor(bitshift(x,12),...
                           bitxor(bitshift(x,5), x)));
            end
        end
        
        function result = isNumericType(type)
            %ISNUMERICTYPE
            result = ismember(type, {'uint8', 'int8', 'uint16', 'int16', 'uint32','int32'});
        end %isNumericType
    
        function code = typeStr2Code(str)
            % TYPESTR2CODE converts type string to code (low nibble of typescope byte)
            % 0x00	null	 
            % 0x01	boolean	- not used
            % 0x02	INT8	 
            % 0x03	INT16	 
            % 0x04	INT32	default for negative literal numeric values
            % 0x05	UNS8	 
            % 0x06	UNS16   default for literal array indices	 
            % 0x07	UNS32	default for positive literal numeric values
            % 0x08	string	 
            % 0x0A	byte array	only constant
            % 0x0B	fixed point
            switch str
                case 'null' 
                    code = 0;
                case 'boolean' 
                    code = 1;
                case 'int8' 
                    code = 2;
                case 'int16'
                    code = 3;
                case 'int32'
                    code = 4;
                case 'uint8' 
                    code = 5;
                case 'uint16'
                    code = 6;
                case 'uint32'
                    code = 7;
                case 'string'
                    code = 8;
                case 'ba'
                    code = 10;
                case 'fixp'
                    code = 11;
                otherwise 
                    code = [];
            end
        end %typeStr2Code

        function str = typeCode2Str(code)
            % TYPECODE2STR converts type code to string (low nibble of typescope byte)
            % 0x00	null	 
            % 0x01	boolean	- not used
            % 0x02	INT8	 
            % 0x03	INT16	 
            % 0x04	INT32	default for negative literal numeric values
            % 0x05	UNS8	 
            % 0x06	UNS16   default for literal array indices	 
            % 0x07	UNS32	default for positive literal numeric values
            % 0x08	string	 
            % 0x0A	byte array	only constant
            % 0x0B	fixed point
            switch code
                case 0
                    str = 'null';
                case 1
                    str = 'boolean'; 
                case 2
                    str = 'int8'; 
                case 3
                    str = 'int16';
                case 4
                    str = 'int32';
                case 5
                    str = 'uint8'; 
                case 6
                    str='int32';
                case 7
                    str='uint32';
                case 8
                    str = 'string';
                case 10
                    str = 'ba';
                case 11
                    str = 'fixp';
                otherwise 
                    str = [];
            end
        end %typeCode2Str

        function code = scopeStr2Code(str)
            %SCOPESTR2CODE converts scope string to code (bits 5:4 of typescope byte)
            switch str
                case 'literal'
                    code = 0;
                case 'const'
                    code = 16; %0x10
                case 'stack'
                    code = 32; %0x20
                case 'global'
                    code = 48; %0x30
            end
        end %scopeStr2Code
        
        function str = scopeCode2Str(code)
            %SCOPECODE2STR converts scope code to string (bits 5:4 of typescope byte)
            switch code
                case 0
                    str = 'literal';
                case 16  %0x10
                    str = 'const';
                case 32 %0x20
                    str = 'stack';
                case 48 %0x30
                    str = 'global';
            end
        end %scopeCode2Str
        
        function code = modifierStr2Code(str)
            %MODIFIERSTR2CODE converts modifier string to code (bits 7:6 of typescope byte)
            %Type Modifiers
            % 0x40	CANopen Address	(8 or 4+8)
            % 0x80	Array	(4+6)
            % 0xC0	CANopen address with multiple subindices (4+8)
            switch str
                case 'none'
                    code = 0;
                case 'network'
                    code = 64; %0x40
                case 'array'
                    code = 128; %0x80
                case 'networkmulti'
                    code = 192; %0xC0
            end
        end %smodifierCode2Str
        
        function str = modifierCode2Str(code)
            %MODIFIERCODE2STR converts modifier code to string (bits 7:6 of typescope byte)
            %Type Modifiers
            % 0x40	CANopen Address	(8 or 4+8)
            % 0x80	Array	(4+6)
            % 0xC0	CANopen address with multiple subindices (4+8)
            switch code
                case 0
                    str = 'none';
                case 64 %0x40
                    str = 'network';
                case 128  %0x80
                    str = 'array';
                case 192 %0xC0
                    str = 'networkmulti';
            end
        end %modifierCode2Str
        

        function htmlStr = formatHTML(str)
            % FORMATHTML converts < and > to HTML codes 
            htmlStr = strrep(str, '<', '&#60');
            htmlStr = strrep(htmlStr, '>', '&#62');
        end
        
    end %static methods
end

