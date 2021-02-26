scantypelist = {'BL';'App';'StimMin';'StimMax'};

newfig = false; %new figure for each iteration of same scan type
colsubplot = true;
lw = [2 1 2 1 1 1 1 1 1 1 1 1];
for j=1:length(scantypelist)

    if ~newfig && ~colsubplot
        fig = figure;
        fig.Position = [0 50 650 900];
    end
    
    files = dir(['Scan' scantypelist{j} '*.mat']);
    f = cell(length(files), 1);
    for i=[1 6]
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
        compliance = sum(comp, 2)/size(comp,2);

        if colsubplot
            n=3;
            c=4;
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

        
        
        subplot(n,c,k)
            yyaxis left
                plot(vnet, errRate, '-', 'LineWidth', lw(i));
                    ylabel('Scan Error Rate'); hold on;
                plot(vnet, brownOut+errRate, ':', 'LineWidth', lw(i));
                    axis([4.7 9.6 -0.1 1.1]);
            yyaxis right
                plot(vnet, pmcanerrtot,'-', 'LineWidth', lw(i)); hold on;
                    ylabel('PM CAN Errors')
                    axis([4.7 9.6 .1 maxcanerr]);
                    ax = gca;
                    ax.YScale = 'log';

            title([datestr(f{i}.T, 'yyyy mmm dd   HH:MM')   '  '  name]);

        subplot(n,c,k+c)
            yyaxis left
                plot(vnet, -power,'-', 'LineWidth', lw(i)); hold on;
                %plot(vnet, adpower,':', 'LineWidth', lw(i));
                    ylabel('Power (mW)')
                    axis([4.7 9.6 50 850]);
                
            yyaxis right
                plot(vnet, pmbat,'-', 'LineWidth', lw(i)); hold on;
                    ylabel('Battery (mV)')
                    axis([4.7 9.6 2400 4200]);

        subplot(n,c,k+2*c)
            yyaxis left
                plot(vnet, vin,'-', 'LineWidth', lw(i)); hold on;

                plot(vnet, advnet,':', 'LineWidth', lw(i)); hold on;
                    ylabel('VIN (V)')
                    ylabel('VIN (V)')
                    axis([4.7 9.6 3.3 9.7]);

            yyaxis right
                plot(vnet, compliance,'-', 'LineWidth', lw(i)); hold on;
                    ylabel('Compliance Rate')
                    axis([4.7 9.6 -0.1 1.1]);
                    xlabel('VNET (V)')
    end
end
%%
appfiles = dir('ScanApp*.mat');
app = cell(length(appfiles), 1);
for i=1:length(appfiles)
    app{i} = load(appfiles(i).name);
    app{i}.T = datetime(appfiles(i).datenum,'ConvertFrom', 'datenum');
end

