function StrA = XMLMarkerSetFcn(Ain)
%Convert XML code from nnps file to Text and numbers
%Ain is string, character array or cell array with groupMarketSet XML data copied from nnps file
%if input is a cellarray of char,then need to convert to char
if iscellstr(Ain)
    a=char(Ain);
else
    a=Ain;
end
StrA=strings;%str = strings returns a string with no characters.
% add date and time 
dstr=datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss');
StrA=sprintf('%s\n',dstr);
pairtext='groupSet_ID';
psize=size(pairtext,2)+2;
pair1=['<',pairtext,'>'];
pair2=['</',pairtext,'>'];
b=regexpi(a,pair1);
c=regexpi(a,pair2);
TotalMarkers=size(b,2);
%T = table('Size',sz,'VariableTypes',varTypes,'VariableNames',varNames)
Vtype={'double','cell'};
Vname={'groupSet_Id','groupPatternMarkerSet'};
Tsize=[TotalMarkers,2];
grpMarkerSet=table('Size',Tsize,'VariableTypes',Vtype,'VariableNames',Vname);
%
FGID=zeros(TotalMarkers,1);
for i=1:TotalMarkers
FGid=str2double((extractBetween(a,b(i)+psize,c(i)-1)));
grpMarkerSet.groupSet_Id(i)=FGid;
end
% I could make this into a function with ID and type but will just do both
% sets for now.
pairtext='groupPatternMarkerSet';
psize=size(pairtext,2)+2;
pair1=['<',pairtext,'>'];
pair2=['</',pairtext,'>'];
b=regexpi(a,pair1);
c=regexpi(a,pair2);
TotalMarkers=size(b,2);
for i=1:TotalMarkers
d64=extractBetween(a,b(i)+psize,c(i)-1);
grpMarkerSet.groupPatternMarkerSet(i)=d64;
end

for i=1:TotalMarkers
   glength(i)=length(char(grpMarkerSet{i,2})); 
end
maxlength=max(glength)+1; 

for i=1:TotalMarkers
    base64str=char(grpMarkerSet{i,2});
    FG=grpMarkerSet{i,1};
    b64length=length(base64str);
    newspaces=blanks(maxlength-b64length);
    commandrow=base64decodeX(base64str);
    commandrowsize=size(commandrow,2);
    maxcommand=commandrow(1,commandrowsize);
    StrA=[StrA sprintf('FG %2d, Max:%d  %s %s',FG,maxcommand,base64str,newspaces)];
    StrA=[StrA sprintf('%d ',commandrow)];   
    StrA=[StrA sprintf('\n')];
end


