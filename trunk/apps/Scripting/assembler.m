close all

fid = fopen('logdata_2.nnps', 'r');


%%
% load the text file into a cell array with each index representing a line
% iterate through all lines and parse the strings
% 1. look for comments - moves endparse (% followed by anything) TODO: exception inside string
% 2. look for result - moves endparse (=> followed by text) TODO: what about <> brackets in network notation?
% 3. look for variable initializer (=) - moves endparse  TODO: exception inside string
% 4. look for label ({ }) - moves startparse  TODO: exception inside string
% 5. look for opcode or variable definition (keywords) and subsequent operands or variable definition
%
% variable naming notes
% si_... starting index
% ei_... ending index

vartypelist = {'uint8','int8','uint16','int16','uint32','int32','string','ba','fixp'};
varscopelist = {'stack', 'global', 'const'};

%opcode name, opcode byte, min operands, max operands, description,
%result,jump result, result is also operand
opcodelist = { ...
    'NOP',0,0,0, 'NOP - skip',0,0,0;
    'MOV',1,1,1, 'Move (From - To-> Result)',1,0,0;
    'NMT0',2,2,2 'NMT command - node, cmd',0,0,0;
    'NMT1',3,3,3 'NMT cmd - node, cmd, param',0,0,0;
    'NMT2',4,4,4 'NMT cmd - node, cmd, 2 par',0,0,0;
    'CATMOV',5,1,5, 'Operand0 + Operand1 + ... -> Move to Result',1,0,0;
    'CATMOV0',80,1,5, 'Operand0 + Operand1 + ... -> Move to Result with Null',1,0,0;
    'CATMOVCR',81,1,5, 'Operand0 + Operand1 + ... -> Move to Result with CR',1,0,0;
    'SUBSTR',42,3,3, 'Substring: string; index; size -> result str.',1,0,0;
    'ITS',6,2,2, 'IntToString Op0; Field size Op1',1,0,0;
    'UTS',7,2,2, 'UIntToString Op0; Field size Op1',1,0,0;
    'ITS0',8,2,2, 'IntToString Op0; Field size Op1 -> Result is null terminated',1,0,0;
    'UTS0',9,2,2, 'UIntToString Op0; Field size Op1 -> Result is null terminated',1,0,0;
    'ADD',10,2,5, 'Add Op0, Op1, Opn',1,0,0;
    'SUB',11,2,2, 'Subtract Op0 to Op1',1,0,0;
    'MUL',12,2,5, 'Multiply Op0, Op1, Opn',1,0,0;
    'DIV',13,2,2, 'Integer Divide Op0 to Op1',1,0,0;
    'ADDS',75,2,5, 'Saturate Add Op0, Op1, Opn',1,0,0;
    'SUBS',76,2,2, 'Saturate Subtract Op0 to Op1',1,0,0;
    'MULS',77,2,5, 'Saturate Multiply Op0, Op1, Opn',1,0,0;
    'DIFF',14,2,2, 'ABS of difference',1,0,0;
    'INC',15,0,0, 'Increment Results Op - No ops',1,0,1;
    'DEC',16,0,0, 'Decrement Results Op - No ops',1,0,1;
    'INCS',78,0,0, 'Saturate Increment Results Op - No ops',1,0,1;
    'DECS',79,0,0, 'Saturate Decrement Results Op - No ops',1,0,1;
    'MAX',17,2,2, 'Max Value of Op0 and Op1',1,0,0;
    'MIN',18,2,2, 'Min Value of Op0 and Op1',1,0,0;
    'SRGT',19,2,2, 'Op0 >> Op1',1,0,0;
    'SLFT',20,2,2, 'Op0 << Op1',1,0,0;
    'ABS',21,1,1, 'ABS(Op0) -> Result',1,0,0;
    'BITON',22,2,2, 'Bit ON in Op0; Bitx in Op1; ->Result',1,0,0;
    'BITOFF',23,2,2, 'Bit OFF in Op0; Bitx in Op1; ->Result',1,0,0;
    'ITQ',24,1,1, 'IntToFixPt Op0 -> Result',1,0,0;
    'UTQ',25,1,1, 'UIntToFixPt Op0 -> Result',1,0,0;
    'ADDQ',26,2,2, 'FixPt Addition Op0 by Op1 -> Result',1,0,0;
    'SUBQ',27,2,2, 'FixPt Subtraction Op0 by Op1 -> Result',1,0,0;
    'MULQ',28,2,2, 'FixPt mulitiplication Op0 by Op1 -> Result',1,0,0;
    'DIVQ',29,2,2, 'FixPt division Op0 by Op1 -> Result',1,0,0;
    'SQRTQ',30,1,1, 'Square Rt Op0 -> Result',1,0,0;
    'QTI',31,1,1, 'FixP To Int Op0 -> Result',1,0,0;
    'QTU',32,1,1, 'FixP to UInt Op0 -> Result',1,0,0;
    'QTS',33,2,2, 'FixP to String Op0; Field size (width) Op1',1,0,0;
    'CHS',34,0,0, 'Change Sign -> Result',1,0,1;
    'SIL',35,2,2, 'Arithmetic shift left',1,0,0;
    'SIR',36,2,2, 'Arithmetic shift right',1,0,0;
    'AND',37,2,2, 'Bitwise AND',1,0,0;
    'OR',38,2,2, 'Bitwise OR',1,0,0;
    'MODD',39,2,2, 'Modulo divsion -> remainder',1,0,0;
    'XOR',40,2,2, 'Bitwise Exclusive OR -> result',1,0,0;
    'COMP',41,1,1, 'Bitwise Complements Op0 -> Op1',1,0,0;
    'SIN',43,1,1, 'Sin(x-degrees) -> result',1,0,0;
    'COS',44,1,1, 'Cos(x-degrees) -> result',1,0,0;
    'TAN',45,1,1, 'Tan(x-degrees) -> result',1,0,0;
    'ASIN',46,1,1, 'ArcSin(x) -> result (degrees)',1,0,0;
    'ACOS',47,1,1, 'ArcCos(x) -> result (degrees)',1,0,0;
    'ATAN',48,1,1, 'Arctan(x) -> result(degrees)',1,0,0;
    'ATAN2',49,2,2, 'Arctan2(y, x) -> result(degrees)',1,0,0;
    'SIGN',50,1,1, 'Return +1, 0, -1',1,0,0;
    'PACK',51,4,4, 'Op[0], Op[1], Op[n] -> Result UInt32',1,0,0;
    'UNPACK',52,4,4, 'UInt32 -> UNS8 Array[4]',1,0,0;
    'BLT',60,2,2, 'Branch if item1 < item2',1,1,0;
    'BGT',61,2,2, 'Branch if >',1,1,0;
    'BEQ',62,2,2, 'Branch if =',1,1,0;
    'BNE',63,2,2, 'Branch if !=',1,1,0;
    'BGTE',64,2,2, 'Branch if >=',1,1,0;
    'BLTE',65,2,2, 'Branch if <=',1,1,0;
    'BNZ',66,1,1, 'Branch if not 0',1,1,0;
    'BZ',67,1,1, 'Branch if 0',1,1,0;
    'GOTO',68,0,0, 'GoTo - Label',1,1,0;
    'BBITON',69,2,2, 'Branch if bit Op1 in Op0 is ON',1,1,0;
    'TDEL',70,1,1, 'TimeDelay in msecs',0,0,0;
    'GNS',71,1,1, 'Get Node Status Op0 = Node -> Status',1,0,0;
    'BBITOFF',72,2,2, 'Branch if bit Op1 in Op0 is OFF',1,1,0;
    'BITSET',73,2,2, 'Set or Clear Bit X (Op1) if Op0 =/ne 0 -> in Result',1,0,1;
    'BITCNT',74,1,1, 'Counts the number of bits set in the input value.',1,0,0;
    'FREAD',82,3,3, 'Read From File - File ID, Index, Number of bytes - byte data',1,0,0;
    'FWRITE',83,3,3, 'Write To File Op[0]=File ID, Op[1]=index, Op[2]=data -> Number of bytes - byte data',1,0,0;
    'FRESET',84,1,1, 'Reset - clears file: Op[0] = FileID',0,0,0;
    'FSIZE',85,1,1, 'Op[0] = FileID, -> size in bytes',1,0,0;
    'FGETPTR',86,1,1, 'Op[0] = FileID, -> position',1,0,0;
    'FSETPTR',87,2,2, 'Op[0] = FileID, Op[1] sets position',0,0,0;
    'BITCPY',88,4,4, 'UInt32 Source; SourceStart; ResultStart; Length -> UInt32 Result ',1,0,0;
    'FCLOSE',89,1,1, 'Op[0] = FileID closes log file',0,0,0;
    'STARTSCPT',90,1,1, 'Start Script Pointer',0,0,0;
    'STOPSCPT',91,1,1, 'Stop Script Pointer',0,0,0;
    'RUNONCE',92,1,1, 'Run Script Pointer Once',0,0,0;
    'RUNIMM',93,1,1, 'Run Script Pointer Immediate',0,0,0;
    'RUNNEXT',94,1,1, 'Run Script Pointer Next',0,0,0;
    'RUNMULT',95,1,1, 'Decode operand for starting scripts',0,0,0;
    'RESETGLOBALS',96,1,1, 'Reset Global Vars for script (0 == all)',0,0,0;
    'NODESCAN',97,1,1, 'Scan for Node (node)',1,0,0;
    'INTERPOL',100,3,3, 'Interpolate X(Op0) in table Op1 (Xvalues) - Op2 (Yvalues) -> Result(FP)',1,0,0;
    'MAVG',101,2,2, 'Moving Average - Source, Array[] -> Result',1,0,0;
    'IIR',102,2,2, 'IIR - Source, Array -> Result',1,0,0;
    'FIFO',104,1,1, 'FirstIn-FirstOut buffer.  Buf[i] = Buf[i-1], Buf[0]=NewValue -> Buf',1,0,0;
    'VECMOV',105,4,4, 'Vector Move - SourceArray, Source Starting Index, Dest Staring Index, Number of Indices -> DestArray',1,0,0;
    'VECMAX',106,1,1, 'Vector->Vector Maximum',1,0,0;
    'VECMAXI',107,1,1, 'Vector->Index of Vector Maximum',1,0,0;
    'VECMIN',108,1,1, 'Vector->Vector Minimum',1,0,0;
    'VECMINI',109,1,1, 'Vector->Index of Vector Minimum',1,0,0;
    'VECMED',110,1,1, 'Vector->Median',1,0,0;
    'VECMEDI',111,1,1, 'Vector->Index of Median',1,0,0;
    'VECMEAN',112,1,1, 'Vector->Mean',1,0,0;
    'VECSUM',113,1,1, 'Vector->Sum',1,0,0;
    'VECPROD',114,1,1, 'Vector->Product',1,0,0;
    'VECMAG',115,1,1, 'Vector->Magnitude',1,0,0;
    'VECMAG2',116,1,1, 'Vector->Magnitude(Squared)',1,0,0;
    'VECADD',121,2,2, 'VectorA + VectorB(or scalar)-> Vector',1,0,0;
    'VECSUB',122,2,2, 'VectorA - VectorB (or scalar)->Vector',1,0,0;
    'VECMUL',123,2,2, 'VectorA (elementwise*) VectorB (or scalar)->Vector',1,0,0;
    'VECDIV',124,2,2, 'VectorA (elementwise/) VectorB (or scalar)->Vector',1,0,0;
    'EXIT',255,0,0, 'Terminate Script',0,0,0};

%% For Noptepad++ keywords
opcodelistStr = [];
for i=1:length(opcodelist)
    opcodelistStr = [opcodelistStr ' ' opcodelist{i,1}];
end
%opcodelistStr


i = 1;
tline = fgetl(fid);
A= {};
A{i} = tline;
while ischar(tline)
    i = i+1;
    tline = fgetl(fid);
    A{i} = [tline ' '];
end
fclose(fid)

figure('Name','fig','Position',[100 100 1200 800]);

nLines = length(A)-1;

B = cell(nLines,1);
operation = struct('index',[],'line', [],'opCodeName','','opCodeByte','','operand', [], 'result',[]);
i_op = 0;
var = struct('name','','line', [],'type','','scope','', 'initStr', '', 'init', [], 'array', [], 'pointer',[]);
i_var = 0;

def = struct('name','','line',[],'replace','');
def(1).name = 'log';     def(1).replace = 'N7<L,0>:A000.1'; %log without timestamp
def(2).name = 'timelog'; def(2).replace = 'N7<L,1>:A000.1'; %log with timestamp
%Can add additional predefined things here
i_def = length(def);


label = {};
i_label = 0;



for i = 1:nLines
    fprintf('\nLine %3.0f: ', i)
    nOperands = 0;
    nResult = 0;
    warnStr = [];
    
    formattedtext = ['<HTML><pre><FONT COLOR="black">' sprintf('%03u  ', i)]; %use <pre> tag to prevent dleteing whitespace in HTML
    
    [si_comment, ei_comment] = regexp(A{i}, '\s*%.*'); %comment: optional whitespace, '%', anything
    if ~isempty(ei_comment) && si_comment == 1 %comment begins at beginning, don't do further parsing
        formattedtext=[formattedtext '<FONT COLOR="green"><i>' A{i} '</i></HTML>'];
    else
        if ~isempty(si_comment)
            A{i}=[A{i}(1:si_comment-1) ' ' A{i}(si_comment:end)]; %add a space prior to comment '%' - required to detect final operand
            endparse = si_comment - 1 + 1; %include added space
            si_comment = si_comment + 1;
            ei_comment = ei_comment + 1;
        else
            A{i}=[A{i} ' ']; %add a space at the end of the line - required to detect final operand
            endparse = length(A{i});
        end
        
        startparse = 1;
        
        %find result, if any
        [si_result, ei_result] = regexp(A{i}(startparse:endparse), '=>.+'); %result: '=>' followed by anything. Don't include optional whitespace before '>' (will go to preceding opcode/operand)
        if ~isempty(si_result)
            A{i}=[A{i}(1:si_result-1) ' ' A{i}(si_result:end )]; %add a space prior to resultsymbol '=>' - required to detect final operand
            endparse = si_result - 1+1; %include added space
            si_resultsymbol = si_result + 1;
            ei_resultsymbol = si_result + 2;
            si_result = si_result + 3;
            
        else
            si_resultsymbol = [];
            ei_resultsymbol = [];
        end
        
        
        %find a variable initializer, if any
        [si_varinit, ei_varinit] = regexp(A{i}(startparse:endparse), '=[^>].*'); % '=' followed by anything except >
        if ~isempty(ei_varinit)
            A{i}=[A{i}(1:si_varinit-1) ' ' A{i}(si_varinit:end )]; %add a space prior to initializer '='  - required to detect final operand
            endparse = si_varinit - 1 + 1; %include added space
            si_varinit = si_varinit + 1;
            ei_varinit = ei_varinit + 1;

        end
        
        
        %find a label, if any
        [si_label, ei_label] = regexp(A{i}(startparse:endparse), '\s*{\s*\w+\s*}\s*'); %optional whitespace followed by '{', optional whitespace, at least one charachter, optional whitespace, '}'
        if ~isempty(ei_label)
            startparse = ei_label+1;
            newLabel = strtrim(A{i}(si_label:ei_label)); %trim whitespace outside {}
            newLabel = strtrim(newLabel(2:end-1)); %trim the {} and any whitespace inside
            if ~isempty(label) 
                [isLabel, iLabel] = ismember(newLabel, label(:,1));
            else
                isLabel = false;
            end
            if isLabel
                warnStr = addText(warnStr, ['Label already used at line:' num2str(label{iLabel,2})]); %TODO: change to errstr
            else
                i_label = i_label + 1;
                label{i_label,1} = newLabel;
                label{i_label,2} = i;
            end
            
        end
        
        
        %find opcode, operand, variable type/scope, name, or define, define name
        % these are seperated by whitespace. However, we want to ignore whitespace contained within "", [], !!
        
        % ? . * [ ] { } ( ) ^ + | are used in regular expressions.  To use literally, preface with \
        
        %optional whitespace, followed by literal that may include spaces ("...", [...], !...!), or  at least one non whitespace, and ending in at least one whitespace
        [si_op, ei_op] = regexp(A{i}(startparse:endparse), '\s*((".*?")|(<.*?>)|(\[.*?\])|(!.*?!)|\S+)\s+'); 
        si_op = startparse-1+si_op;
        ei_op = startparse-1+ei_op;
        
        
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
        
        
        
        if ~isempty(ei_op)
            opStr = strtrim(A{i}(si_op(1):ei_op(1)));
            [isOp, whichOp] = ismember(opStr, opcodelist(:,1));
            isVar = ismember(opStr, vartypelist) || ismember(opStr, varscopelist);
            isDef = isequal(opStr, 'define'); 
            
            if isDef
                i_def=i_def+1;
                def(i_def).line = i;
                si_vartypescope = si_op(1); %add define color?
                ei_vartypescope = ei_op(1);
                
            elseif isOp
                i_op = i_op + 1;
                operation(i_op).index = whichOp;
                operation(i_op).line = i;
                si_opcode = si_op(1);
                ei_opcode = ei_op(1);
                
                operation(i_op).opCodeName = opStr;
                operation(i_op).opCodeByte = opcodelist{operation(i_op).index , 2};
                
            elseif isVar
                i_var=i_var+1;
                var(i_var).line = i;
                si_vartypescope = si_op(1);
                ei_vartypescope = ei_op(1);
                if ismember(opStr, vartypelist)
                    var(i_var).type = opStr;
                else
                    var(i_var).scope = opStr;
                end
                
            else
                warnStr=addText(warnStr, 'unknown opCode or variable definition, line ignored');
                si_unknown = si_op(1);
                ei_unknown = ei_op(end);
                ei_op = [];
                si_op = [];
            end
            if length(si_op) > 1
                opStr = strtrim(A{i}(si_op(2):ei_op(2)));
                if isDef
                    if ~isempty(ei_varinit)
                        if i_def > 0
                            defnames = arrayfun(@(x) x.name, def(1:end-1), 'UniformOutput', false);
                        else
                            defnames = [];
                        end
                        if ismember(opStr, defnames)
                            def(i_def) = [];
                            i_def=i_def-1;
                            warnStr=addText(warnStr, 'define name previously used, ignored');
                        else
                            def(i_def).name = opStr;
                            def(i_def).replace = strtrim(A{i}(si_varinit+1:ei_varinit)); %scrap '=' and trim white space
                        end
                    else
                        def(i_def) = [];
                        i_def=i_def-1;
                        warnStr=addText(warnStr, 'define has no definition, ignored');
                    end
                    si_var = si_op(2); %add color type for def?
                    ei_var = ei_op(2);
                    if length(si_op) > 2
                        warnStr=addText(warnStr,'ignoring extra content');
                        si_unknown = si_op(3);
                        ei_unknown = ei_op(end);
                    end
                %variable must have at least scope or type, but can have one or both
                elseif isVar && (ismember(opStr, vartypelist) || ismember(opStr, varscopelist))
                    if ismember(opStr, vartypelist)
                        if isempty(var(i_var).type)
                            var(i_var).type = opStr;
                        else
                            warnStr=addText(warnStr, 'second type definition ignored');
                        end
                    else
                        if isempty(var(i_var).scope)
                            var(i_var).scope = opStr;
                        else
                            warnStr=addText(warnStr, 'second scope definition ignored');
                        end
                        
                    end
                    %change endindex to include second variable type/scope entry
                    ei_vartypescope = ei_op(2);
                    if length(si_op) > 2
                        opStr = strtrim(A{i}(si_op(3):ei_op(3)));
                        %>> section copy/pasted to case where length(op)==2
                        %consider combining
                        iArray = regexp(opStr,'\[.*\]');
                        if isempty(iArray)
                            var(i_var).name = opStr;
                            var(i_var).array = 0;
                        else
                            var(i_var).name = opStr(1:iArray-1);
                            nEl = str2double(opStr(iArray+1:end-1));
                            if isnan(nEl) || length(nEl) ~=1
                                 warnStr=addText(warnStr,'invalid number of elements' ); %todo change to errStr
                            else
                                var(i_var).array = nEl;
                            end
                        end
                        if ~isempty(ei_varinit)
                            var(i_var).initStr = strtrim(A{i}(si_varinit+1:ei_varinit));
                            %TODO: convert init string to type and check
                            %that number of elements match expected
                        end
                        %<<
                        si_var = si_op(3);
                        ei_var = ei_op(3);

                        if length(si_op) > 3
                            warnStr=addText(warnStr,'ignoring extra content');
                            si_unknown = si_op(4);
                            ei_unknown = ei_op(end);
                        end
                    else
                        warnStr=addText(warnStr, 'No variable name, ignored');
                    end
                else %either variable name or operand
                    if isVar
                        if isempty(var(i_var).type)
                            var(i_var).type = 'uint8';
                            warnStr=addText(warnStr,'default type: uint8');
                        end
                        if isempty(var(i_var).scope)
                            var(i_var).scope = 'stack';
                            warnStr=addText(warnStr,'default scope: stack');
                        end
                        %>> section copy/pasted to case where length(op)>2
                        %consider combining
                        iArray = regexp(opStr,'\[.*\]');
                        if isempty(iArray)
                            var(i_var).name = opStr;
                            var(i_var).array = 0;
                        else
                            var(i_var).name = opStr(1:iArray-1);
                            nEl = str2double(opStr(iArray+1:end-1));
                            if isnan(nEl) || length(nEl) ~=1
                                 warnStr=addText(warnStr,'invalid number of elements' ); %todo change to errStr
                            else
                                var(i_var).array = nEl;
                            end
                        end
                        if ~isempty(ei_varinit)
                            var(i_var).initStr = strtrim(A{i}(si_varinit+1:ei_varinit));
                            %TODO: convert init string to type and check
                            %that number of elements match expected
                        end
                        %<<
                        si_var = si_op(2);
                        ei_var = ei_op(2);

                        if length(si_op) > 2
                            warnStr=addText(warnStr,'ignoring extra content');
                            si_unknown = si_op(3);
                            ei_unknown = ei_op(end);
                        end
                        
                    elseif isOp
                        %check number of operands
                        minOperands = opcodelist{operation(i_op).index,3};
                        maxOperands = opcodelist{operation(i_op).index,4};
                        
                        
                        nOperands = length(si_op)-1;
                        
                        if nOperands < minOperands
                            if minOperands==maxOperands
                                warnStr=addText(warnStr, sprintf('requires %1.0f operands', minOperands)); %TODO:change to errStr
                            else
                                warnStr=addText(warnStr, sprintf('requires %1.0f-%1.0f operands', minOperands,maxOperands)); %TODO:change to errStr
                            end
                            si_operand = ei_op(1)+1;
                            ei_operand = endparse;
                            
                        elseif nOperands > maxOperands
                            si_operand = ei_op(1)+1;
                            ei_operand = ei_op(maxOperands+1);
                            warnStr=addText(warnStr, 'ignoring operands'); 
                            si_unused = ei_op(maxOperands+1)+1;
                            ei_unused = endparse;
                            nOperands = maxOperands;
                        else
                            si_operand = ei_op(1)+1;
                            ei_operand = endparse;
                        end
                        
                        
                        
                        for j=1:nOperands
                            if isempty(operation(i_op).operand)
                                operation(i_op).operand = struct('str', '', 'bytes',[],'typeScope',[],'iVar', [], 'literal', [], ...
                                    'typeScopePair',[],'iVarPair', [], 'literalPair', [], 'network', []);
                            end
                            operation(i_op).operand(j).str = strtrim(A{i}(si_op(j+1):ei_op(j+1)));
                        end
   
                        
                        
                    else
                        disp('why here?')
                    end
                end
            else %Operand or Variable definition but nothing further
                if isDef
                    warnStr=addText(warnStr,'No define name, ignored');
                    def(i_def) = [];
                    i_def=i_def-1;
                elseif isVar
                    warnStr=addText(warnStr,'No variable name, ignored');
                    var(i_var) = [];
                    i_var = i_var - 1;
                elseif isOp
                     nOperands = 0;
                     %check if OK to have no operands based on opCode
                     minOperands = opcodelist{operation(i_op).index,3};
                     maxOperands = opcodelist{operation(i_op).index,4};
                     if minOperands > 0
                         if minOperands==maxOperands
                                warnStr=addText(warnStr, sprintf('requires %1.0f operands', minOperands)); %TODO:change to errStr
                        else
                            warnStr=addText(warnStr, sprintf('requires %1.0f-%1.0f operands', minOperands,maxOperands)); %TODO:change to errStr
                         end
                     end
                end
                
            end
            
            if isOp
                nResult = opcodelist{operation(i_op).index,6};
                
                if nResult>0 
                    jumpResult = opcodelist{operation(i_op).index,7}==1;
                    if isempty(ei_result)
                        warnStr = [];
                        warnStr=addText(warnStr,'opcode requires a result - ignoring operation'); %todo: change to errStr
                        %ignore this operation
                        nResult = 0;
                        nOperands = 0;
                        si_unknown = startparse;
                        ei_unknown = endparse;
                        si_unused = [];
                        ei_unused = [];
                        si_operand = [];
                        ei_operand = [];
                        si_opcode = [];
                        ei_opcode = [];
                        operation(i_op) = [];
                        i_op = i_op-1;
                    else
                        operation(i_op).result = struct('str', '', 'bytes',[],'typeScope',[],'iVar', [],'literal', jumpResult,...
                            'typeScopePair',[],'iVarPair', [],  'literalPair', [], 'network', []);
                        operation(i_op).result.str = strtrim(A{i}(si_result:ei_result));
                    end
                end
            end



  % -------------- start check if operands are valid  --------------------%
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

            %Types
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

            %Type Modifiers
            % 0x40	CANopen Address	(8 or 4+8)
            % 0x80	Array	(4+6)
            % 0xC0	CANopen address with multiple subindices (4+8)

            if i_var>0
                varnames = arrayfun(@(x) x.name, var, 'UniformOutput', false);
            else
                varnames = [];
            end
            if i_def > 0
                defnames = arrayfun(@(x) x.name, def, 'UniformOutput', false);
            else
                defnames = [];
            end

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
                    operandStr = operation(i_op).operand(j).str;
                else
                    operandStr = operation(i_op).result.str;
                    if operation(i_op).result.literal
                        operation(i_op).result.literal = operandStr;
                        operation(i_op).result.typeScope = 6;
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
                    if ~isnan(operand) %numeric decimal literal (scalar)
                        scope = 0;
                        if operand<0
                            type = 4;
                            operand = typecast(int32(operand), 'uint8');
                        else
                            type = 7;
                            operand = typecast(uint32(operand), 'uint8');
                        end
                    elseif length(operandStr)>2 && isequal(operandStr(1:2), '0b') %numeric binary literal (scalar)
                        try
                            operand = bin2dec(operandStr(3:end));
                            scope = 0;
                            type = 7;
                            operand = typecast(uint32(operand), 'uint8');
                        catch
                            warnStr=addText(warnStr, 'invalid binary literal: 0b...');  %TODO: change to errStr
                        end
                    elseif length(operandStr)>2 && isequal(operandStr(1:2), '0x') %numeric hex literal (scalar)
                        try
                            operand = hex2dec(operandStr(3:end));
                            scope = 0;
                            type = 7;
                            operand = typecast(uint32(operand), 'uint8');
                        catch
                            warnStr=addText(warnStr, 'invalid hex literal: 0x..."');  %TODO: change to errStr
                        end

                    %string literal
                    elseif length(operandStr)>2 && operandStr(1) == '"' && operandStr(end) == '"' 
                        operand = operandStr(2:end-1);
                        operand = [uint8(operand) uint8(0)]; %null terminate string
                        scope = 0;
                        type = 8;

                    %bytearray literal
                    elseif length(operandStr)>2 && operandStr(1) == '!' && operandStr(end) == '!' 
                        operand = hex2dec(regexp(operandStr(2:end-1), '[A-Fa-f0-9]{2}','match'));
                        scope = 0;
                        type = 8;

                    %array literal
                    elseif length(operandStr)>2 && operandStr(1) == '[' && operandStr(end) == ']' 
                        operand = str2double(regexp(operandStr(2:end-1), '\d+','match'));
                        scope = 0;
                        if all(operand>0)
                            type = 7;
                            operand = typecast(uint32(operand), 'uint8');
                        else
                            type = 4; 
                            operand = typecast(int32(operand), 'uint8');
                        end
                        typemod = 0;
                        typemodEL = 128; %0x80 array modifier

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
                                    operandSplitStr{d} = def(iDefine(d)).replace;
                                    fprintf('replaced "%s" with "%s"\n', def(iDefine(d)).name, def(iDefine(d)).replace);
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
                        if length(operandStr)>=9 && isequal(regexp(operandStr, 'N\d{1,2}(<.*?>)?:[A-Fa-f0-9]{4}\.[^\.\:]*'),1) 
                            %N followed by 1 or 2 digits followed by : followed by 4 hex deigts followed by . without any further . or :
                            operand = []; 
                            %type, scope, and typemod refer to how subindex will be reported 
                            %(scope always 0, type mod always 0x40, and iDefinedVar always empty)
                            %typeEl, scopeEl, and typemodEl, and iDefinedVarEl refer to the variable subindex
                            %if the subIndex is literal AND there are not multiple subindices,
                            %typeEl, scopeEl will be empty and typemodEl = 0;
                            scope = 0; 
                            typemod = 64; %0x40
                            type = 0;
                            subIndex = []; 
                            nSubIndices = 0;
                            odIndex = [];

                            %Get NODE
                            nodeStr = regexp(operandStr, 'N\d{1,2}', 'match'); 
                            if ~isempty(nodeStr)
                                nodeStr = nodeStr{1}(2:end); %convert to string  and scrap leading N 
                                node = str2double(nodeStr); 
                                if isnan(node) || node>15
                                    warnStr = addText(warnStr, 'node should be 15 or lower'); 
                                end
                            else
                                error('should not get here, because expression already matched')
                            end

                            %Get OD INDEX  - literal (hex) only - required
                            indexStr = regexp(operandStr, '\:[A-Fa-f0-9]{4}\.', 'match');  
                            if ~isempty(indexStr)
                                indexStr = indexStr{1}(2:end-1); %convert to string  and scrap leading : and trailing .
                                odIndex = hex2dec(indexStr); 
                            else
                                error('should not get here, because expression already matched')
                            end

                            %Get OD SUBINDEX  - literal (decimal) or variable -required
                            subIndexStr = regexp(operandStr, '\.\w+', 'match'); %find . followed by digits

                            if ~isempty(subIndexStr)
                                subIndexStr = subIndexStr{1}(2:end); %convert to string and scrap '.'
                                subIndex = str2double(subIndexStr);

                                %literal subIndex
                                if ~isnan(subIndex)
                                    if subIndex > 255
                                        warnStr = addText(warnStr, 'invalid subindex (must be <=255)'); %TODO: change to errStr
                                    end

                                %non literal subIndex    
                                else
                                    subIndex = [];
                                    [isDefinedVarEl, iDefinedVarEl] = ismember(subIndexStr, varnames);
                                    if isDefinedVarEl
                                        if isNumericType(var(iDefinedVarEl).type) && var(iDefinedVarEl).array == 0
                                            scopeEl = scopeStr2Code(var(iDefinedVarEl).scope);
                                            typeEl = typeStr2Code(var(iDefinedVarEl).type);
                                            typemodEl = 192; %0xC0
                                        else
                                            warnStr = addText(warnStr, 'variable subindex must be a numeric scalar type'); %TODO: change to errStr
                                        end
                                    else
                                        warnStr = addText(warnStr, 'variable subindex undefined'); %TODO: change to errStr
                                    end
                                end
                            else
                               warnStr = addText(warnStr, 'no subindex found'); %TODO: change to errStr
                            end

                            %Get NUMBER OF SUBINDICES - optional, default 1
                            nSubIndicesStr = regexp(operandStr, '\^\w+', 'match'); %find ^ followed by word
                            if ~isempty(nSubIndicesStr)
                                nSubIndicesStr = nSubIndicesStr{1}(2:end); %convert to string and scrap '^'
                                nSubIndices = str2double(nSubIndicesStr); 
                                if isnan(nSubIndices) || nSubIndices > 50 && nSubIndices > 0
                                     warnStr = addText(warnStr,['invalid number of subindices ^' nSubIndicesStr] ); %TODO: change to errStr
                                elseif nSubIndices > 1
                                    typemodEl = 192; %0xC0
                                    typeEl = 5;
                                    scopeEl = 0; %literal
                                end
                            end
                            
                            %Get TYPE OF SUBINDEX - optional, default uint8
                            typeStr = regexp(operandStr, '\|\w+', 'match'); %find | followed by word (type)
                            if isempty(typeStr)
                                type = typeStr2Code('uint8');  
                                warnStr = addText(warnStr, 'assuming uint8 type for network operand');
                            else
                                typeStr = typeStr{1}(2:end); %convert to string and scrap '|'
                                type = typeStr2Code(typeStr); 
                                if isempty(type)
                                    warnStr = addText(warnStr, 'invalid type for network operand'); %TODO change to errStr
                                    type = typeStr2Code('uint8');
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
                                   warnStr = addText(warnStr, 'invalid port/netID specifier, ignoring'); 
                                end
                            else
                                disp('using default port/netID')
                            end
                            fprintf('\nfound Network, node %2.0f, port %2.0f, netID %2.0f, odIndex %4X.%2.0f (%2.0f)', node, port, netID, odIndex, subIndex, nSubIndices);
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
                                type = typeStr2Code(var(iDefinedVar).type);
                                scope = scopeStr2Code(var(iDefinedVar).scope);
                                maxEl = var(iDefinedVar).array;

                                if maxEl > 0 %array
                                    typemod = 0; 
                                    typemodEl = 128; % 0x80
                                    scopeEl = 0;
                                    typeEl = 6;
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
                                    if var(iDefinedVar).array == 0 
                                        warnStr=addText(warnStr, 'attempting to index non-array variable');  %TODO: change to errStr
                                    else
                                        el = str2double(elStr);
                                        if ~isnan(el)
                                            if el > maxEl-1
                                                warnStr=addText(warnStr, 'exceeds array bounds');  %TODO: cha %TODO: change to errStr
                                            else
                                                 %scalar literal array element
                                                typeEl = 6;
                                                scopeEl = 0;

                                            end
                                        else
                                            elStr = strtrim(elStr);
                                            if isempty(elStr)
                                                el = 65534; %0xFFFE: code for entire array
                                            else
                                                el = [];
                                                [isDefinedVarEl, iDefinedVarEl] = ismember(elStr, varnames);
                                                if isDefinedVarEl
                                                    if var(iDefinedVarEl).array >0
                                                        warnStr=addText(warnStr, 'array variable used as array index');  %TODO: cha %TODO: change to errStr
                                                    else
                                                        %verify that variable is valid as an index (scalar
                                                        %numeric)
                                                        typeElStr = var(iDefinedVarEl).type;
                                                        if isNumericType(typeElStr)
                                                            typeEl = typeStr2Code(typeElStr);
                                                            scopeEl = scopeStr2Code(var(iDefinedVarEl).scope);
                                                            disp(['found usage of:' varnames(iDefinedVarEl) ' as array element']);
                                                        else
                                                            warnStr=addText(warnStr, 'non-numeric variable used as array index');  %TODO: cha %TODO: change to errStr
                                                        end
                                                    end

                                                else
                                                     warnStr=addText(warnStr, 'undefined variable used as array index');  %TODO: cha %TODO: change to errStr
                                                end
                                            end
                                        end
                                    end

                                end
                                disp(['found usage of:' varnames{iDefinedVar}]);
                                el = typecast(uint16(el), 'uint8');
                            %undefined variable
                            else
                                if j<=nOperands
                                    warnStr=addText(warnStr, ['undefined variable in operand' num2str(j)]);  %TODO: cha %TODO: change to errStr
                                else
                                    warnStr=addText(warnStr, 'undefined variable in result');  %TODO: cha %TODO: change to errStr
                                end
                            end
                            
                            
                        end %end non-literals (else case)
                    end 
                end %end while
                

                if j<=nOperands
                    operation(i_op).operand(j).typeScope = typemod+scope+type;
                    operation(i_op).operand(j).typeScopePair = typemodEl+scopeEl+typeEl;
                    operation(i_op).operand(j).iVar = iDefinedVar;
                    operation(i_op).operand(j).literal = operand;
                    operation(i_op).operand(j).literalPair = el;
                    operation(i_op).operand(j).iVarPair = iDefinedVarEl;
                    operation(i_op).operand(j).network = network;
                else
                    operation(i_op).result.typeScope = typemod+scope+type;
                    operation(i_op).result.typeScopePair = typemodEl+scopeEl+typeEl;
                    operation(i_op).result.iVar = iDefinedVar;
                    if ~isempty(operand)
                        disp('no literal allowed for result unless jump label')
                    end
                    operation(i_op).result.literalPair = el;
                    operation(i_op).result.iVarPair = iDefinedVarEl;
                    operation(i_op).result.network = network;
                end
            end %end for operands
            % -------------- end check if operands are valid  --------------------%
            
        end  %end ~isempty(ei_op)
        
        % ------------  start generate variable tables  -------------%
        stacktable = [];
        consttable = [];
        globaltable = [];

        for k = 1:length(var)
            if isNumericType(var(k).type)
                
                %array
                if var(k).array > 0 
                    var(k).init = zeros(1,var(k).array);
                    if ~isempty(var(k).initStr)
                        if length(var(k).initStr)<=2
                            warnStr=addText(warnStr, 'invalid array initializer, setting to zero'); 
                        else
                            init = str2double(regexp(var(k).initStr(2:end-1), '\d+','match'));
                            if length(init)>var(k).array
                                var(k).init = init(1:var(k).array);
                                warnStr=addText(warnStr, 'ignoring extra array initializer elements'); 
                            else
                                var(k).init(1:length(init)) = init;
                                if length(init)<var(k).array
                                    warnStr=addText(warnStr, 'setting some uninitialized elemnts to zero'); 
                                end
                            end
                        end  
                    end
                    
                %non-array (uninitialized)   
                elseif isempty(var(k).initStr)
                   var(k).init = 0;
                   
                %non-array (initialized)     
                else
                    var(k).init = str2double(var(k).initStr);
                    if isnan(var(k).init)
                        warnStr=addText(warnStr, 'invalid variable initializer, initializing to zero'); 
                        var(k).init = 0;
                    end
                end
                varBytes = typecast(cast(var(k).init, var(k).type), 'uint8');
                
            elseif isequal(var(k).type, 'string')
                if var(k).initStr(1)=='#'
                    strLen = str2double(var(k).initStr(2:end));
                    if isnan(strLen) || strLen < 1 || strLen > 50
                        warnStr=addText(warnStr, 'string length initializer should be 1-50'); 
                        var(k).init = [];
                    else
                        var(k).init = zeros(1, strLen); %all null
                    end
                else
                    if length(var(k).initStr)<=2
                        warnStr=addText(warnStr, 'zero length string'); 
                        var(k).init = [];
                    else
                        var(k).init = var(k).initStr(2:end-1);
                    end
                end
                varBytes = [uint8(var(k).init), uint8(0)]; %null terminate string
                
                
           elseif isequal(var(k).type, 'bytearray')
                if length(var(k).initStr)<=2
                    warnStr=addText(warnStr, 'zero length bytearray'); 
                    var(k).init = [];
                else
                    var(k).init = hex2dec(regexp(var(k).initStr(2:end-1), '[A-Fa-f0-9]{2}','match'));
                end
                varBytes = uint8(var(k).init);
            end
            
            switch var(k).scope 
                case 'stack'
                    var(k).pointer = length(stacktable);
                    stacktable = [stacktable varBytes]; 
                case 'const'
                    var(k).pointer = length(consttable);
                    consttable = [consttable varBytes];
                case 'global'
                    var(k).pointer = length(globaltable);
                    globaltable = [globaltable varBytes];                    
            end
            
            
        end
        % ------------  end generate variable tables  -------------%
        
        
        
        % ------------- end generate download bytes ------------%
        
        
        if ~isempty(ei_label)
            formattedtext=[formattedtext '<FONT COLOR="800040"><i>' A{i}(si_label:ei_label) '</i>'];
        end
        
        
        if ~isempty(ei_vartypescope)
            formattedtext=[formattedtext '<FONT COLOR=#48D1CC><b>' A{i}(si_vartypescope:ei_vartypescope) '</b>'];
        end
        
        if ~isempty(ei_var)
            formattedtext=[formattedtext '<FONT COLOR=#FF00FF><b>' A{i}(si_var:ei_var) '</b>'];
        end
        
        if ~isempty(ei_opcode)
            formattedtext=[formattedtext '<FONT COLOR="blue"><b>' A{i}(si_opcode:ei_opcode) '</b>'];
        end
        
        if ~isempty(ei_unknown)
            formattedtext=[formattedtext '<FONT COLOR="red"><i><u>' A{i}(si_unknown:ei_unknown) '</i></u>'];
        end

        if ~isempty(ei_operand)
            str = formatHTML(A{i}(si_operand:ei_operand));
            formattedtext=[formattedtext '<FONT COLOR="black">'  str];
        end
        
        if ~isempty(ei_unused)
            formattedtext=[formattedtext '<FONT COLOR="red"><i><u>' A{i}(si_unused:ei_unused) '</i></u>'];
        end
        
        if ~isempty(ei_varinit)
            str = formatHTML(A{i}(si_varinit:ei_varinit));
            formattedtext=[formattedtext '<FONT COLOR=#FF8000><b>' str '</b>'];
        end
        
        if ~isempty(ei_resultsymbol)
            formattedtext=[formattedtext '<FONT COLOR="blue"><b>' A{i}(si_resultsymbol:ei_resultsymbol) '</b>'];
        end
        
        if ~isempty(ei_result)
            formattedtext=[formattedtext '<FONT COLOR="black">' A{i}(si_result:ei_result) ];
        end
        
        if ~isempty(ei_comment)
            formattedtext=[formattedtext '<FONT COLOR="green"><i>' A{i}(si_comment:ei_comment) '</i>'];
        end
        
        if ~isempty(warnStr)
            formattedtext=[formattedtext '<FONT COLOR="red"><small><i><u>' warnStr '</i></u></small>'];
        end
        formattedtext=[formattedtext '</pre></HTML>'];
    end
    B{i} = formattedtext;

    
end %end looping through all lines
    
%
%text(0,0.5,B)
%axis off

%%

%hnd = uitable('Position', [10 10 900 780],'Data',B, 'FontName', 'monospaced', 'FontSize', 12, 'ColumnWidth', {900}, 'ColumnEditable', true)
hnd = uicontrol('Position', [10 10 900 780],'Style','listbox','String',B, 'FontName', 'monospaced', 'FontSize', 12)
%%

%%
%
nOps = i_op;
% tbldata = cell(nOps,7);
% for i=1:nOps
%     tbldata{i,1} = sprintf(' %02X (%s)', operation(i).opCodeByte, operation(i).opCodeName);
% end
% 
% uitable('Position', [910 10 580 780],'Data', tbldata,'ColumnName',{'OpCode','Op1','Op1','Op3', 'Op4','Op5','Result'})

%if start and end lines were not included, add them
nLabels = size(label,2);
if ~isempty(operation)
    if isempty(label) || ~ismember('start', label(:,1)) 
        label = [{'start', operation(1).line};label];
    end
    if isempty(label) || ~ismember('end', label(:,1)) 
        label = [label;{'end', operation(end).line}];
    end
end
        
    % ------------ start generate download bytes ----------- %
i_jump = 0;
jump = zeros(nOps,1);
opBytes = cell(nOps,1);
for k=1:nOps
    fprintf('\nOperation %2.0f:', k)
    copyResult = opcodelist{operation(k).index, 8};
    [opBytes{k}, jump(k)] = assembleOperation(operation(k), var, label, copyResult);
end

opBytes{nOps+1} = [2 255];  %add EXIT as last operation

    
if sum(jump>0) < nLabels
    warning('label unused')
end

% count bytes from jumps to labels

for k=1:length(jump)
    if jump(k)>0
        %find first operation following label (may be on a following line)
        jumpOp = 0;
        for j = length(operation):-1:1
            if operation(j).line >= jump(k)
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


for k = 1: length(opBytes)
    fprintf('\n');
    fprintf('%02X ', opBytes{k});
end



function str = addText(str, newStr)
    if isempty(str)
        str = [' ~' newStr];
    else
        str = [str, ' | ' newStr];
    end
end

function result = isNumericType(type)
    result = ismember(type, {'uint8', 'int8', 'uint16', 'int16', 'uint32','int32'});
end

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
function code = typeStr2Code(str)
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
        case 'bytearray'
            code = 10;
        case 'fixp'
            code = 11;
        otherwise 
            code = [];
    end
end

function code = scopeStr2Code(str)
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
end

function [opBytes, jumpLine] = assembleOperation(op, var, label, copyResult)
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
                pointer = var(operand.iVarPair).pointer;
                pointer = typecast(uint16(pointer), 'uint8');
                operand.bytes = [4, operand.typeScopePair, pointer, 8 ,operand.typeScope,port,netId,node,odIndexBytes,nSubIndices]; 
              
            else
                %literal but multiple subindices  
                if nSubIndices > 1 
                    operand.bytes = [4, operand.typeScopePair, subIndex,0, 8 ,operand.typeScope,port,netId,node,odIndexBytes,nSubIndices]; 
                
                %literal and single subindex 
                else 
                    operand.bytes = [8, operand.typeScope, port,netId,node,odIndexBytes,subIndex]; % TODO: correct
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
                    [isLabel, iLabel] = ismember(operand.literal, label(:,1));
                    if ~isLabel
                        error(['label at line#' num2str(op.line) ' "' operand.literal '" not start, end, or defined label'])
                    end
                    jumpLine = label{iLabel,2};
                    operand.bytes = [6, operand.typeScope, 0,0,0,0]; %need to replace final 4 zeros with correct values
                end

            %variable (if paired, may include a literal)   
            else
                if isempty(operand.iVar)
                    error('variable not defined')
                elseif length(operand.iVar)~=1 || operand.iVar<1 || operand.iVar>length(var)
                    operand.iVar
                    error('variable invalid')
                    
                else
                    pointer = var(operand.iVar).pointer;
                    pointer = typecast(uint16(pointer), 'uint8');

                    nEl = var(operand.iVar).array;

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
                                    pointerPair = var(operand.iVarPair).pointer;
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
            opBytes = [opBytes operand.bytes operand.bytes];
        else
            opBytes = [opBytes operand.bytes];
        end
    end %for operand
    if copyResult
        opBytes = [length(opBytes)+3, op.opCodeByte, nResult*16+nOperands+1, opBytes]; %add length, opcode, and nResult:nOperand+1
    else
        opBytes = [length(opBytes)+3, op.opCodeByte, nResult*16+nOperands, opBytes]; %add length, opcode, and nResult:nOperand
    end
end

function htmlStr = formatHTML(str, varargin)
    
    htmlStr = strrep(str, '<', '&#60');
    htmlStr = strrep(htmlStr, '>', '&#62');
    
end
