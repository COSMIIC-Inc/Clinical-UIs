function [success, channels, nodes, groups] = readnnpsCNG()
% read the channels, nodes and groups from the nnps file
% and arrange them in the manner that patternedit app wants
% success=1 if read correctly.  0 if not
% 	channels	6x4 cell   indexed by node,chan 
%   first remove MES channels 
% 		{'name' } char  muscle name, 
%  		{'min'  } double set to 0
%  		{'max'  } double set to 255
%  		{'notes'} char set to ''
% This means I need to create a structure with rows=stim nodes, x 4 channels
% min and max may need to be set manually to 0,255
% 	groups	18x1 cell index by FG number, empty structure with empty fields if no FG
%    	{'name'    } char  
% 		{'cmdID'   } double 
% 		{'download'} logic 
% 		{'notes'   } char  
% 	nodes	9x1 cell - listed by node number.  
% 		{'name' } char 
% 		{'type' } char PG, BP, PM or CT   - 
% 		{'notes'} char set to ''
success=0;
% % read GroupSets
[fn, pn]=uigetfile('*.nnps','Get NNPS configuration File');
xmlfile=fullfile(pn,fn);
xDoc=xmlread(xmlfile);
gTags={'groupSet_Id','groupSetName','groupSetNotes',...
    'groupOutputCommandID','InputSource_Id','groupPatternMarkerSet',...
    'isDownloaded'};
ngTags=size(gTags,2);
%
allGroupSet=xDoc.getElementsByTagName('GroupSet');
numGS=allGroupSet.getLength;
gsCell=cell(numGS,ngTags); % create cell array to enter data
 % % get the data
for k=0:allGroupSet.getLength-1  % for each groupset - zero based for DOM
    thisListitem = allGroupSet.item(k); %for each groupset, need to parse items
    for j=1:7 % 1 based indexing for matlab array
        thisList = thisListitem.getElementsByTagName(gTags(j));
        thisElement = thisList.item(0);
        if ~isempty(thisElement.getFirstChild)
            gsCell(k+1,j) = thisElement.getFirstChild.getData;
        end
    end
end
% % translate moduleRecordID to node
myTagsMod={'moduleType','moduleName','nodeNumber','moduleRecordID'};
nmodTags=size(myTagsMod,2);
allMod=xDoc.getElementsByTagName('eachModule');
numMod=allMod.getLength;
modCell=cell(numMod,nmodTags); % create cell array to enter data
for k=0:allMod.getLength-1  % for each chan - zero based for DOM
    thisListitem = allMod.item(k); %for each groupset, need to parse items
    for j=1:nmodTags % 1 based indexing for matlab array
        thisList = thisListitem.getElementsByTagName(myTagsMod(j));
        thisElement = thisList.item(0);
        if ~isempty(thisElement.getFirstChild)
            modCell(k+1,j) = thisElement.getFirstChild.getData;
        end
    end
end
% % read Channels
% need to combine this with readGroupSets
myTagsCh={'channelName','channelType','muscle','moduleRecordID','eachChannel_Id'};
nTags=size(myTagsCh,2);
% note there are six tags I have chosen
% [fn, pn]=uigetfile('*.nnps','Get NNPS configuration File');
% xmlfile=fullfile(pn,fn);
% xDoc=xmlread(xmlfile);
allChan=xDoc.getElementsByTagName('eachChannel');
numCH=allChan.getLength;
chCell=cell(numCH,nTags); % create cell array to enter data
% % get the data
for k=0:allChan.getLength-1  % for each chan - zero based for DOM
    thisListitem = allChan.item(k); %for each groupset, need to parse items
    for j=1:nTags % 1 based indexing for matlab array
        thisList = thisListitem.getElementsByTagName(myTagsCh(j));
        thisElement = thisList.item(0);
        if ~isempty(thisElement.getFirstChild)
            chCell(k+1,j) = thisElement.getFirstChild.getData;
        end
    end
end

% % Add column for node number based on modID
for i=1:numCH
    modID=str2num(chCell{i,4});
    for j=1:numMod
        if modID==str2num(modCell{j,4})
            chCell{i,6}=modCell{j,3};
            break;
        end
    end
end

% % Convert to correct format

% % put these in a structure form that patternedit needs
% Note that each variable is a cell array of structures with the following fields
% Note that there may not be notes for the nodes or channels
% All the cell arrays are character which need to be converted for numbers
% 	channels	6x4 cell   indexed by node,chan  node=chCell{n,4},chan=chCell{n,1}
%   first remove MES channels based on chCell{n,2}
% 		{'name' } char  muscle name, chCell{n,3}
%  		{'min'  } double set to 0
%  		{'max'  } double set to 255
%  		{'notes'} char set to ''
% This means I need to create a structure with rows=stim nodes, x 4 channels
% min and max may need to be set manually to 0,255
% 	groups	18x1 cell index by FG number, empty structure with empty fields if no FG
%    	{'name'    } char  - gsCell{n,2}
% 		{'cmdID'   } double - gsCell{n,4}
% 		{'download'} logic - gsCell{n,7}
% 		{'notes'   } char  - gsCell{n,3}
% 	nodes	9x1 cell - listed by node number.  index=node number  modCell{n,3}
% 		{'name' } char modCell{n,2}
% 		{'type' } char PG, BP, PM or CT   - modCell{n,1} shorten Type
% 		{'notes'} char set to ''
% type make PG or BP  to be consistent with patternedit
% Create a structure
nnps=struct;  %structure with no fields yet

%Nodes - need to assume there are nine, then fill in the blanks
nnps.nodes=cell(9,1);
% initialize the structure with blanks in fields
for i=1:9
    nnps.nodes{i}.name='';
    nnps.nodes{i}.type='';
    nnps.nodes{i}.notes='';
end
% fill nodes with data from modCell, since not in same order
numPG=0; %number of PG4 channels
for i=1:numMod
    nn=str2num(modCell{i,3});
    nnps.nodes{nn}.name=modCell{i,2};
    long=modCell{i,1};
    % tried to make this a function but did not work for some reason
    if contains(long,'PG')
        st='PG';
        numPG=numPG+1;
    elseif contains(long,'BP')
        st='BP';
    elseif contains(long,'Power')
        st='PM';
    elseif contains(long,'Tower')
        st='CT';
    else
        st='';
    end
    nnps.nodes{nn}.type=st;

    % notes leave blank for now
end
% step though modCell and put them into the correct locations
% Channels
nnps.channels=cell(numPG,4); % cell array equal to number of stim nodes
% Initialize the fields to '' and 0
for i=1:numPG
    for j=1:4
        nnps.channels{i,j}.name=' ';
        nnps.channels{i,j}.min=0;
        nnps.channels{i,j}.max=255;
        nnps.channels{i,j}.notes='';
    end
end
% what if there are 4 nodes, but they are 1 3 4 6?
% For now need to assume that first 1-6 are stim, or will need to change pattern edit
for i=1:numCH
    % first remove MES channels based on chCell{n,2}
    %node=chCell{n,4},chan=chCell{n,1}
    if contains(chCell{i,2},'Pulse') %stim channel
        nn=str2num(chCell{i,6});
        ch=str2num(chCell{i,1});
        nnps.channels{nn,ch}.name=chCell{i,3}; % name of channel
    end
end

% groups
nnps.groups=cell(numGS,1);
%fill in cell structures
for i=1:numGS
    nnps.groups{i}.name=gsCell{i,2};
    nnps.groups{i}.cmdID=str2num(gsCell{i,4});
    nnps.groups{i}.download=str2num(gsCell{i,7});
    nnps.groups{i}.notes=gsCell{i,3};
end

% % export 

channels = nnps.channels;
nodes = nnps.nodes;
groups = nnps.groups;
success=1;
