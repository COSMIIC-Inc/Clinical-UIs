%formatRPDOpm.m
RPDOpm=reshape(cellstr(dec2hex(PDOmap1600x8,8)),8,8)';
pdostr='CApdopm={';
for i=1:7
    for j=1:7
        pdostr=[pdostr,sprintf('''%s'',',RPDOpm{i,j})];
    end
        pdostr=[pdostr,sprintf('''%s'';...\n',RPDOpm{i,8})];
end
    for j=1:7
        pdostr=[pdostr,sprintf('''%s'',',RPDOpm{8,j})];
    end
        pdostr=[pdostr,sprintf('''%s''};\n',RPDOpm{8,8})];
clipboard('copy',pdostr);
%% create cell array of hex with PDOs arranged by Col
% Easier to display this way
% PDO1    PDO2      PDO3    etc...
CApdopm=...
{'1F53A208','1F53D408','1F53A808','1F53AC08','1F53B008','1F53B408','1F53B808','1F53BC08';...
'1F532E08','1F53D208','1F53A908','1F53AD08','1F53B108','1F53B508','1F53B908','1F53BD08';...
'1F53A408','1F53C008','1F53AA08','1F53AE08','1F53B208','1F53B608','1F53BA08','1F53BE08';...
'1F53A508','1F53C108','1F53AB08','1F53AF08','1F53B308','1F53B708','1F53BB08','1F53BF08';...
'1F53A308','1F53D508','1F53D608','1F53D808','1F53DA08','1F53DC08','1F53DE08','1F53E008';...
'1F532F08','1F53D308','1F53D708','1F53D908','1F53DB08','1F53DD08','1F53DF08','1F53E108';...
'1F53A608','1F53C208','1F53C408','1F53C508','1F53C608','1F53C708','1F53C808','1F53C908';...
'1F53A708','1F53C308','1F53CA08','1F53CB08','1F53CC08','1F53CD08','1F53CE08','1F53CF08'};

%% convert cell array of hex back to uint32 array, with PDOs arranged by row
% Need to be arranged in rows
% PDO1...
% PDO2... etc
pdodec=reshape(uint32(hex2dec(CApdopm)),8,8)';  %back to original array

%% could also just do this
       RPDO.mapping = cell(8,1);
            for i=1:8
                RPDO.mapping{i}=uint32(hex2dec(CApdopm(:,i)))'; %Convert one column at a time
            end
            
%% TPDO
            TPDO.mapping = cell(8,1);
            TPDO.mapping{1} = uint32(hex2dec({'30210108','30210208','30210308','30210408','30210508','30210608','30210708','30210808'})');
            TPDO.mapping{2} = uint32(hex2dec({'30210908','30210a08','30210b08','30210c08','30210d08','30210e08','30210f08','30211008'})');
            TPDO.mapping{3} = uint32(hex2dec({'30211108','30211208','30211308','30211408','30211508','30211608','30211708','30211808'})');
            TPDO.mapping{4} = uint32(hex2dec({'30211908','30211a08','30211b08','30211c08','30211d08','30211e08','30211f08','30212008'})');
            TPDO.mapping{5} = uint32(hex2dec({'30212108','30212208','30212308','30212408','30212508','30212608','30212708','30212808'})');
            TPDO.mapping{6} = uint32(hex2dec({'30212908','30212a08','30212b08','30212c08','30212d08','30212e08','30212f08','30213008'})');
            TPDO.mapping{7} = uint32(hex2dec({'00000000','00000000','00000000','00000000','00000000','00000000','00000000','00000000'})');
            TPDO.mapping{8} = uint32(hex2dec({'00000000','00000000','00000000','00000000','00000000','00000000','00000000','00000000'})');
%% convert to decimal
tpdodec=TPDO.mapping{1}; %first row
for i=2:8
   tpdodec=[tpdodec;TPDO.mapping{i}]; %add rows
end
%tpdodec=tpdodec';
%% start with row vectors then I don't need to transpose I think
TPDOpm=reshape(cellstr(dec2hex(tpdodec,8)),8,8)';
pdostr='tpdopm=...\n{';
for i=1:7
    for j=1:7
        pdostr=[pdostr,sprintf('''%s'',',TPDOpm{i,j})];
    end
        pdostr=[pdostr,sprintf('''%s'';...\n',TPDOpm{i,8})];
end
    for j=1:7
        pdostr=[pdostr,sprintf('''%s'',',TPDOpm{8,j})];
    end
        pdostr=[pdostr,sprintf('''%s''};\n',TPDOpm{8,8})];
clipboard('copy',pdostr);
%%
tpdopm=...
{'30210108','30210908','30211108','30211908','30212108','30212908','00000000','00000000';...
'30210208','30210A08','30211208','30211A08','30212208','30212A08','00000000','00000000';...
'30210308','30210B08','30211308','30211B08','30212308','30212B08','00000000','00000000';...
'30210408','30210C08','30211408','30211C08','30212408','30212C08','00000000','00000000';...
'30210508','30210D08','30211508','30211D08','30212508','30212D08','00000000','00000000';...
'30210608','30210E08','30211608','30211E08','30212608','30212E08','00000000','00000000';...
'30210708','30210F08','30211708','30211F08','30212708','30212F08','00000000','00000000';...
'30210808','30211008','30211808','30212008','30212808','30213008','00000000','00000000'};

