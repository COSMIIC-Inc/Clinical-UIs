% scantypelist = {'App'};
%scantypelist = {'StimMax'};
scantypelist = {'App';'StimMin';'StimMax'};
%scantypelist = {'BL';'App';'StimMin';'StimMax'};

newfig =false; %new figure for each iteration of same scan type
colsubplot = true;
lw = [ 2 1 1 1 1 2 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1 1];% [2 1 2 1 1 1 1 1 1 1 1 1];
clf
for j=1:length(scantypelist)

    if ~newfig && ~colsubplot
        fig = figure;
        fig.Position = [0 50 650 900];
    end
    
%     files = [dir('ScanStimMax_20210826135706.mat')
%         dir('ScanStimMax_20210826125458.mat')
%         dir('ScanApp_20210826132304.mat')
%         dir('ScanStimMin_20210824160352.mat')
%         dir('ScanStimMax_20210824172617.mat')
%         dir('ScanStimMax_20210824162225.mat')
 %             ]; 

    
       files = dir(['Scan' scantypelist{j} '*.mat']);
       files = files([end-1, end ]);  
    f = cell(length(files), 1);
    vdrop = {};
    for i=[1:length(files)]
        f{i} = load(files(i).name);
        f{i}.T = datetime(files(i).datenum,'ConvertFrom', 'datenum');
        str = regexp(files(i).name, 'Scan[a-zA-Z]+', 'match');
        f{i}.NAME = str{1}(5:end);

        othererr = f{i}.OTHERERR;
        neterr = f{i}.NETERR;
        snerr = f{i}.SNERR;
        blerr = f{i}.BLERR;
        exterr = f{i}.EXTERR;
        cnt = f{i}.CNT;
        vnet = f{i}.VNET;
        pmcanerr = f{i}.PMCANERR;
        pmbat = f{i}.PMBAT;
        pmtemp = f{i}.PMTEMP;
        vin = f{i}.VIN;
        power = f{i}.POWER;
        comp = f{i}.COMP;
        name = f{i}.NAME;
        advrec = f{i}.ADVREC;
        advsys = f{i}.ADVSYS;
        adpower = f{i}.ADPOWER;
        advnet = f{i}.ADVNET;
        
        scancount = 10;

        pmcanerrtot = pmcanerr(:, 1);
        pmcanerrtot(pmcanerrtot==0)=0.1;
%         sum(othererr, 2);
%         sum(neterr, 2);
%         sum(snerr, 2);
%         sum(exterr, 2);
%         sum(blerr, 2);
        errRate = sum(neterr, 2)./(sum(cnt, 2)+sum(neterr, 2)+sum(blerr, 2));
        brownOut = sum(blerr/scancount, 2)/size(blerr,2);
        comp = comp(:, 1:3);  %IGNORE comp(4,:) because it is for BP
        compliance = sum(comp, 2)/size(comp,2);

        if colsubplot
            n=3;
            c=length(scantypelist);
            k=j;
        else
            if newfig
                fig = figure;
                fig.Position = [0 50 650 900];
            end
            n=3;
            c=1;
            k=1;
        end
        maxcanerr = 65535;

                vnetWindow = vnet(brownOut+errRate==0 & pmcanerrtot<100); 
                vnetMin = min(vnetWindow);
                vnetMax = max(vnetWindow);
                big = 99999;
        subplot(n,c,k)
            yyaxis left

                patch([vnetMin vnetMin vnetMax vnetMax], [-big big big -big], [1 1 .6], 'EdgeColor', 'none', 'FaceAlpha', .5); hold on;
                    
                h = plot(vnet, errRate, '-', 'LineWidth', lw(i));
                    ylabel('Scan Error Rate'); hold on;
                    darkenLines(h, i);
                        
                h = plot(vnet, brownOut+errRate, ':', 'LineWidth', lw(i));
                    axis([4.7 9.6 -0.1 1.1]);
                    darkenLines(h, i);
                    
            yyaxis right
         
                h = plot(vnet, pmcanerrtot,'-', 'LineWidth', lw(i)); hold on;
                    ylabel('PM CAN Errors')
                    axis([4.7 9.6 .1 maxcanerr]);
                    ax = gca;
                    ax.YScale = 'log';
                    darkenLines(h, i);

            ax = gca;
            existingTitle = ax.Title.String;
            if isempty(existingTitle)
                title([datestr(f{i}.T, 'yyyy mmm dd   HH:MM')   '  '  name]);
            else
                title({existingTitle; [datestr(f{i}.T, 'yyyy mmm dd   HH:MM')   '  '  name]});
            end
            

        subplot(n,c,k+c)
            yyaxis left
                patch([vnetMin vnetMin vnetMax vnetMax], [-big big big -big], [1 1 .6], 'EdgeColor', 'none', 'FaceAlpha', .5); hold on;
                h = plot(vnet, -power,'-', 'LineWidth', lw(i)); hold on;
                %plot(vnet, adpower,':', 'LineWidth', lw(i));
                    ylabel('Power (mW)')
                    axis([4.7 9.6 50 850]);
                    darkenLines(h, i);
                
            yyaxis right
                h = plot(vnet, pmbat,'-', 'LineWidth', lw(i)); hold on;
                    ylabel('Battery (mV)')
                    axis([4.7 9.6 2400 4200]);
                    darkenLines(h, i);

        subplot(n,c,k+2*c)
            yyaxis left
                patch([vnetMin vnetMin vnetMax vnetMax], [-big big big -big], [1 1 .6], 'EdgeColor', 'none', 'FaceAlpha', .5); hold on;
                h = plot(vnet, vin,'-', 'LineWidth', lw(i)); hold on;
                    darkenLines(h, i);

                h = plot(vnet, advnet,':', 'LineWidth', lw(i)); hold on;
                    ylabel('VIN (V)')
                    ylabel('VIN (V)')
                    axis([4.7 9.6 3.3 9.7]);
                    darkenLines(h, i);

            yyaxis right
                h = plot(vnet, compliance,'-', 'LineWidth', lw(i)); hold on;
                    ylabel('Compliance Rate')
                    axis([4.7 9.6 -0.1 1.1]);
                    xlabel('VNET (V)')
                    darkenLines(h, i);
        vdrop{i} = repmat(vnet', 1, size(vin,2))-vin;
                %    vdrop = [vdrop; vnet-vin];
    end
end
%%
appfiles = dir('ScanApp*.mat');
app = cell(length(appfiles), 1);
for i=1:length(appfiles)
    app{i} = load(appfiles(i).name);
    app{i}.T = datetime(appfiles(i).datenum,'ConvertFrom', 'datenum');
end
%%
figure
C = [1 .5 0
     0 .5 0
     0 0 1
     1 0 0 ];
colororder(C)

plot(vnet, vdrop{1}, 'LineWidth', 2); hold on;
plot(vnet, vdrop{2}, ':', 'LineWidth', 2);  hold on;
%plot(vnet, vdrop{3}, 'LineWidth', 1) ;  hold on;
%plot(vnet, vdrop{4}, '--', 'LineWidth', 1); 
hold off;
%legend('node1EMC', 'node2EMC', 'node3EMC', 'node4EMC (BP)', 'node1EMC_dist', 'node2EMC_dist', 'node3EMC_dist', 'node4EMC_dist (BP)')
%legend('node1EMC', 'node2EMC', 'node3EMC', 'node4EMC (BP)', 'node1NES', 'node2NES', 'node3NES', 'node4NES (BP)')
%legend('node1NES', 'node2NES', 'node3NES', 'node4NES (BP)', 'node1NESnonet', 'node2NESnonet', 'node3NESnonet', 'node4NESnonet (BP)')
%legend('node1EMC', 'node2EMC', 'node3EMC', 'node4EMC (BP)', 'node1EMC-NESPM', 'node2EMC-NESPM', 'node3EMC-NESPM', 'node4EMC-NESPM (BP)')
%legend('node1 1batR', 'node2 1batR', 'node3 1batR', 'node4 1batR(BP)', 'node1 1bat', 'node2 1bat', 'node3 1bat', 'node4 1bat (BP)','node1 3bat', 'node2 3bat', 'node3 3bat', 'node4 3bat(BP)')

ylabel('Vdrop VNET-VIN (V)')
xlabel ('VNET (V)')
axis([4.7 9.6 0.4 1.8])

%%
function darkenLines(h, n)
    for i=1:n-1
        for ih=1:length(h)
            h(ih).Color = h(ih).Color*.5;
        end
    end
end