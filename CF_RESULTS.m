% RESULTS
%% Counterfactual demand density plots
load('FRANCE_DEMAND.mat','YY','Y_hat','Y_time','RTE','idxTest','idxTest0')
b = find(Y_time>=datetime(2020,1,2) & Y_time<datetime(2020,6,1));
Y = YY;

Y_time(idxTest0)

Demand_c = Y_hat(b);

N = 6;
C = linspecer(N);

figure(1)
%histogram(Y(setdiff(idxTest,idxTest0))/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Y(setdiff(idxTest,idxTest0))/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Y_hat(setdiff(idxTest,idxTest0))/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Y_hat(setdiff(idxTest,idxTest0))/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual demand','Counterfactual demand')
set(legend,'Location','NorthEast')
xlabel('Demand (GW)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_demand_histogram.eps'],'epsc')
idxTest0 = intersect(idxTest0,b);

figure(1)
%histogram(Y(idxTest0(1:end-24))/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Y(idxTest0(1:end))/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Y_hat(idxTest0(1:end-24))/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Y_hat(idxTest0(1:end))/1000)
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual demand','Counterfactual demand')
set(legend,'Location','NorthEast')
xlabel('Demand (GW)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_demand_histogram_crisis.eps'],'epsc')


%% Counterfactual prices
load('FRANCE_REGRESSIONS.mat')

b = find(DATA.Time>=datetime(2020,1,2) & DATA.Time<datetime(2020,6,1));
b0 = find(RESULTS.DAM.TIME>=datetime(2020,1,2) & RESULTS.DAM.TIME<datetime(2020,6,1));
b1 = find(RESULTS.IMPORT(6).TIME>=datetime(2020,1,2) & RESULTS.IMPORT(6).TIME<datetime(2020,6,1));

Qc = Demand_c/1000; %counterfactual demand
Q = DATA.Consommation(b)/1000; %actual demand
Pc = RESULTS.IMPORT(6).price_range; %price range for import function
Ic = RESULTS.IMPORT(6).nI; %import function
I = (DATA.Echphysiques(b0))/1000; %actual net imports
N = DATA.Nucleaire(b0)/1000; %actual nuclear prod
R = (DATA.Eolien(b0) + DATA.Solaire(b0))/1000; %actual renewable prod
Rc = R; %cf renewable

% Counterfactual NG price
NGPc = DATA.naturalgas_price(b);
idx = find(DATA.Time(b)>=datetime(2020,3,15));
mean(DATA.naturalgas_price(find(DATA.Time>=datetime(2020,3,15) & DATA.Time<datetime(2020,5,31))))
NGPc(idx) = mean(DATA.naturalgas_price(find(DATA.Time>=datetime(2020,1,2) & DATA.Time<datetime(2020,3,1))));
NGP = DATA.naturalgas_price(b);

idx = find(DATA.Time(b0)<datetime(2020,3,1));
Qc(idx) = Q(idx); %demand before march 1, 2020 must be the same
P = DATA.Price_FR(b0); %observed price

load('PROD_C.mat','PROD_C'); %load counterfactual production

%Counterfactual nuke
[~,b] = setdiff(PROD_C.Time_c,DATA.Time(b0));
PROD_C.Time_c(b) = [];
PROD_C.Nuke_c(b) = [];
Nc = N;
idx = find(DATA.Time(b0)>=datetime(2020,3,15));
Nc(idx) = PROD_C.Nuke_c(idx)/1000;

%https://ec.europa.eu/energy/sites/ener/files/documents/fr_swd_en.pdf
%France is aiming at 40% RES in electricity generation. We assume that all
%the increase comes from Wind+Solar. Alpha is used to multiply the observed
% RES production in order to achieve 40% in the (domestic production) electricity mix.

GEN_REN = (DATA.Eolien+DATA.Solaire+DATA.Hydraulique+DATA.Pompage+DATA.Bionergies);
GEN_TOTAL = (DATA.Consommation-DATA.Echphysiques);
sum(GEN_REN(idx))./sum(GEN_TOTAL(idx));
sum(DATA.Hydraulique(idx)/1000+DATA.Pompage(idx)/1000+DATA.Bionergies(idx)/1000)./sum(GEN_TOTAL(idx)/1000);
sum((DATA.Eolien(idx) + DATA.Solaire(idx))/1000)./sum(GEN_TOTAL(idx)/1000)
idx = find(DATA.Time>=datetime(2020,1,2) & DATA.Time<=datetime(2020,6,1));
alpha = (0.4-sum(DATA.Hydraulique(idx)/1000+DATA.Pompage(idx)/1000+DATA.Bionergies(idx)/1000)./sum(GEN_TOTAL(idx)/1000))/(sum(DATA.Eolien(idx)+DATA.Solaire(idx))./sum(GEN_TOTAL(idx)));
Rc3 = alpha*(DATA.Eolien(b0) + DATA.Solaire(b0))/1000;

%Check!
sum(DATA.Hydraulique(idx)/1000+DATA.Pompage(idx)/1000+DATA.Bionergies(idx)/1000+DATA.Eolien(idx)/1000+DATA.Solaire(idx)/1000)./sum(GEN_TOTAL(idx)/1000)
sum(DATA.Hydraulique(idx)/1000+DATA.Pompage(idx)/1000+DATA.Bionergies(idx)/1000+alpha*DATA.Eolien(idx)/1000+alpha*DATA.Solaire(idx)/1000)./sum(GEN_TOTAL(idx)/1000)

%Factor for nuclear
alpha_n = 0.5/(sum(DATA.Nucleaire(idx)/1000)./sum(GEN_TOTAL(idx)/1000));

plot(DATA.Time(b0),N)
hold on
plot(DATA.Time(b0),Nc)
hold off

CF.NUKE = N;
CF.NUKE2 = Nc;
CF.TIME = DATA.Time;

% Counterfactual 1: No-Lockdown
objf1 = (Pc - P) - ( B_GMM2(1) * ((Qc-Ic-Rc-Nc) - (Q-I-R-N))) - ( B_GMM2(2) * (Nc - N)); % 
% Counterfactual 2: No-fuel price drop
objf2 = (Pc - P) - (B_GMM2(3) * (NGPc - NGP)) - ( B_GMM2(1) * ((Q-Ic-Rc-N) - (Q-I-R-N))) ; % 
% Counterfactual 3: 1+2
objf3 = (Pc - P) - (B_GMM2(3) * (NGPc - NGP)) - ( B_GMM2(1) * ((Qc-Ic-Rc-Nc) - (Q-I-R-N))) - ( B_GMM2(2) * (Nc - N)) ; 
% Counterfactual 4: Lockdown + 40% penetration RES and 50% nuke
objf4 = (Pc - P) - ( B_GMM2(1) * ((Q-I-Rc3-N*alpha_n) - (Q-I-R-N))) - ( B_GMM2(2) * (N*alpha_n - N)) ; 

Y_prices = P;
Y_cprices1 = P;
Y_cprices2 = P;
Y_cprices3 = P;
Y_cprices4 = P;

idx = find(DATA.Time(b0)<datetime(2020,3,1));

for ii=idx(end):length(P) %find roots = find cf prices
    [~,b] = min((objf1(ii,:)).^2);
    Y_cprices1(ii) = Pc(b);
    [~,b] = min((objf2(ii,:)).^2);
    Y_cprices2(ii) = Pc(b);
    [~,b] = min((objf3(ii,:)).^2);
    Y_cprices3(ii) = Pc(b);
    [~,b] = min((objf4(ii,:)).^2);
    Y_cprices4(ii) = Pc(b);

end

Y_time = RESULTS.DAM.TIME(b0);

figure(5)
plot(Y_time,smooth(Y_prices,48),'LineWidth',2)
hold on
plot(Y_time,smooth(Y_cprices1,48))
plot(Y_time,smooth(Y_cprices2,48))
plot(Y_time,smooth(Y_cprices3,48),'LineWidth',2)
plot(Y_time,smooth(Y_cprices4,48),'--')
%plot(Y_time,smooth(Y_cprices5,72))
hold off

mean(Y_prices(Y_time>datetime(2020,3,15))) %15.3
mean(Y_cprices3(Y_time>datetime(2020,3,15))) %27.9
mean(Y_cprices4(Y_time>datetime(2020,3,15))) %8.5

% 50% attributed to gas price drop
(mean(Y_prices(Y_time>datetime(2020,3,15)))-mean(Y_cprices2(Y_time>datetime(2020,3,15))))/(mean(Y_prices(Y_time>datetime(2020,3,15)))-mean(Y_cprices2(Y_time>datetime(2020,3,15)))+mean(Y_prices(Y_time>datetime(2020,3,15)))-mean(Y_cprices1(Y_time>datetime(2020,3,15))))


%% Counterfactual net imports

obj0 = repmat(RESULTS.IMPORT(6).price_range,length(Y_prices),1)-Y_prices;
obj1 = repmat(RESULTS.IMPORT(6).price_range,length(Y_prices),1)-Y_cprices1;
obj2 = repmat(RESULTS.IMPORT(6).price_range,length(Y_prices),1)-Y_cprices2;
obj3 = repmat(RESULTS.IMPORT(6).price_range,length(Y_prices),1)-Y_cprices3;
obj4 = repmat(RESULTS.IMPORT(6).price_range,length(Y_prices),1)-Y_cprices4;

[a,b0] = min(obj0'.^2);
[a,b1] = min(obj1'.^2);
[a,b2] = min(obj2'.^2);
[a,b3] = min(obj3'.^2);
[a,b4] = min(obj4'.^2);

Ic0 = nan(length(Y_prices),1); %given observed price and estimated net import function, predict net imports
Ic1 = nan(length(Y_prices),1);
Ic2 = nan(length(Y_prices),1);
Ic3 = nan(length(Y_prices),1);
Ic4 = nan(length(Y_prices),1);
%obj0(b0(1))

for ii=1:length(Y_prices) %take counterfctual price and recover counterfactual net import from function
    Ic0(ii,1) =  RESULTS.IMPORT(ir).nI(ii,b0(ii));
    Ic1(ii,1) =  RESULTS.IMPORT(ir).nI(ii,b1(ii));
    Ic2(ii,1) =  RESULTS.IMPORT(ir).nI(ii,b2(ii));
    Ic3(ii,1) =  RESULTS.IMPORT(ir).nI(ii,b3(ii));
    Ic4(ii,1) =  RESULTS.IMPORT(ir).nI(ii,b4(ii));
end

Ic4 = I;

b0 = find(RESULTS.DAM.TIME>=datetime(2020,1,2) & RESULTS.DAM.TIME<datetime(2020,6,1));

figure(6)
plot(DATA.Time,smooth(DATA.Echphysiques,72),'LineWidth',1.5)
hold on
plot(DATA.Time(b0),smooth(1000*Ic0,72))
plot(DATA.Time(b0),smooth(1000*Ic1,72))
plot(DATA.Time(b0),smooth(1000*Ic2,72))
plot(DATA.Time(b0),smooth(1000*Ic3,72),'LineWidth',1.5)
plot(DATA.Time(b0),smooth(1000*Ic4,72))
xlim([datetime(2020,1,1) datetime(2020,5,30)])
hold off

idx = find(DATA.Time(b0)>=datetime(2020,3,15) & DATA.Time(b0)<datetime(2020,6,1));
sum(DATA.Echphysiques(b0(idx)) - 1000*Ic1(idx))/1000
sum(DATA.Echphysiques(b0(idx)) - 1000*Ic2(idx))/1000
sum(DATA.Echphysiques(b0(idx)) - 1000*Ic3(idx))/1000
sum(DATA.Echphysiques(b0(idx)) - 1000*Ic4(idx))/1000

%% Regression results IMPORTS
DATA_temp = table(Y_time, Y_prices, Y_cprices1,  Y_cprices2, Y_cprices3, Y_cprices4, Ic0, Ic1, Ic2, Ic3, Ic4);


clear TABLEVALS TABLEVALS1 TABLEVALS2 TABLEVALS3 TABLEVALS4 TABLEVALS5 TABLEVALS6

IMPORTS_VARS{:};

ROWNAMES = {'$Price \text{ } (Endog.)$', ' ' ,...
    '$Wind.FR \text{ } (IV)$', ' ' ,...
    '$Temp.FR$', ' ' ,...
    '$Temp.IT$', ' ' ,...
    '$Temp.DE$', ' ' ,...
    '$Temp.ES$', ' ' ,...
    '$Temp.CH$', ' ' ,...
    '$Temp.UK$', ' ' ,...
    '$Temp.BE$', ' ' ,...
    '$Solar.BE$', ' ' ,...
    '$WindOff.BE$', ' ' ,...
    '$WindOns.BE$', ' ' ,...
    '$Solar.CH$', ' ' ,...
    '$WindOns.CH$', ' ' ,...
    '$Solar.DE$', ' ' ,...
    '$WindOff.DE$', ' ' ,...
    '$WindOns.DE$', ' ' ,...
    '$Solar.ES$', ' ' ,...
    '$WindOns.ES$', ' ' ,...
    '$Solar.FR$', ' ' ,...
    '$Solar.UK$', ' ' ,...
    '$WindOff.UK$', ' ' ,...
    '$WindOns.UK$', ' ' ,...
    '$TC.CH.FR$', ' ' ,...
    '$TC.FR.CH$', ' ' ,...
    '$TC.ES.FR$', ' ' ,...
    '$TC.FR.ES$', ' ' ,...
    '$TC.IT.FR$', ' ' ,...
    '$TC.FR.IT$', ' ' ,...
    '$TC.UK.FR$', ' ' ,...
    '$TC.FR.UK$', ' ' ,...
    };
%'$TC\_FR-UK$', ' ' ,...
%'$TC\_UK-FR$', ' ' ,...



IMPORTS_VARS;


TARGET = [[RESULTS.IMPORT(6).B_LS(1);nan;RESULTS.IMPORT(6).B_LS(2:30)],...
    [nan;RESULTS.IMPORT(6).B_FS(1);RESULTS.IMPORT(6).B_FS(2:30)],...
    [RESULTS.IMPORT(6).B_GMM(1);nan;RESULTS.IMPORT(6).B_GMM(2:30)],...    
    ];
TARGET2 = [[RESULTS.IMPORT(6).SE_LS(1);nan;RESULTS.IMPORT(6).SE_LS(2:30)],...
    [nan;RESULTS.IMPORT(6).SE_FS(1);RESULTS.IMPORT(6).SE_FS(2:30)],...
    [RESULTS.IMPORT(6).SE_GMM(1);nan;RESULTS.IMPORT(6).SE_GMM(2:30)],...
    ];


TSTAT = TARGET./TARGET2;

[a,b] = sort(abs(TSTAT(3:end,3)),'descend');
TSTAT([b+2],:);
TARGET(b+2,:);
ROWN = ROWNAMES(5:2:end);
ROWN2 = ROWNAMES(6:2:end);
ROWN = [ROWN(b);ROWN2(b)];
ROWNAMES = [ROWNAMES(1:4),ROWN(:)'];

TARGET = TARGET([1;2;b+2],:);
TARGET2 = TARGET2([1;2;b+2],:);

l = 1;
for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        if isnan(TARGET(i,j))
            TABLEVALS{l,j} = ['$ $'];
            TABLEVALS{l+1,j} = ['$ $'];
        else
            TABLEVALS{l,j} = ['',num2str(TARGET(i,j),'%0.2f'),''];
            TABLEVALS{l+1,j} = ['(',num2str(TARGET2(i,j),'%0.2f'),')'];
        end
        
    end
    l=l+2;
end
TABLEVALS;


TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{3}{D{.}{.}{-1}}} \toprule',...
    '& \multicolumn{1}{c}{(LS)} & \multicolumn{1}{c}{(FS)} & \multicolumn{1}{c}{(IV)} \\',...
    '  & \multicolumn{1}{c}{Net Imports}  & \multicolumn{1}{c}{Price} & \multicolumn{1}{c}{Net Imports}  \\',...
    ' \cline{2-2} \cline{3-3} \cline{4-4} ',...
    ];
for j=1:26 %size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{j},' & ',TABLEVALS{j,1},' & ',TABLEVALS{j,2},' & ',TABLEVALS{j,3},' \\ '];
    table(ROWNAMES(j),TABLEVALS(j,1),TABLEVALS(j,2),TABLEVALS(j,3));
end

TABLE = [TABLE,...
    ' \hline ',...
    ' Dummies &  \multicolumn{3}{c}{Hours/Weekdays/Months/Years/Holidays} \\ ',...
    ' \# Covariates & ',' ',num2str(length(RESULTS.IMPORT(6).B_LS),'%0.0f'),' ',' & ',' ',num2str(length(RESULTS.IMPORT(6).B_LS),'%0.0f'),' ' ,' & ',' ',num2str(length(RESULTS.IMPORT(6).B_LS),'%0.0f'),' ' ,' \\ ',...
    ' Obs & ',' ',num2str(RESULTS.IMPORT(6).OBS,'%0.0f'),' ',' & ',' ',num2str(RESULTS.IMPORT(6).OBS,'%0.0f'),' ' ,' & ',' ',num2str(RESULTS.IMPORT(6).OBS,'%0.0f'),' ' ,' \\ ',...
    ' RMSE & ',' ',num2str(RESULTS.IMPORT(6).RMSE(2),'%0.1f'),' ',' & ',' ',num2str(RESULTS.IMPORT(6).RMSE(1),'%0.1f'),' ' ,' & ',' ',num2str(RESULTS.IMPORT(6).RMSE(3),'%0.1f'),' ' ,' \\ ',...
    ];

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_REGIMP.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);


%% Regression results DAY-AHEAD PRICES
%size([X_dummies,X_holidays],2)
clear TABLEVALS TABLEVALS1 TABLEVALS2 TABLEVALS3 TABLEVALS4 TABLEVALS5 TABLEVALS6

DA_VARS{:}

ROWNAMES = {'$Q_t \text{ } (End.)$', ' ' ,...
    '$N_t \text{ } (End.)$', ' ' ,...
    '$Wind.FR \text{ } (IV)$', ' ' ,...
    '$Outages \text{ } (IV)$', ' ' ,...
    '$Nat. \text{ } Gas \text{ } Price$', ' ' ,...
    '$Solar.BE$', ' ' ,...
    '$WindOff.BE$', ' ' ,...
    '$WindOns.BE$', ' ' ,...
    '$Solar.CH$', ' ' ,...
    '$WindOns.CH$', ' ' ,...
    '$Solar.DE$', ' ' ,...
    '$WindOff.DE$', ' ' ,...
    '$WindOns.DE$', ' ' ,...
    '$Solar.ES$', ' ' ,...
    '$WindOns.ES$', ' ' ,...
    '$Solar.FR$', ' ' ,...
    '$Solar.UK$', ' ' ,...
    '$WindOff.UK$', ' ' ,...
    '$WindOns.UK$', ' ' ,...
    '$TC.CH.FR$', ' ' ,...
    '$TC.FR.CH$', ' ' ,...
    '$TC.ES.FR$', ' ' ,...
    '$TC.FR.ES$', ' ' ,...
    '$TC.IT.FR$', ' ' ,...
    '$TC.FR.IT$', ' ' ,...
    '$TC.UK.FR$', ' ' ,...
    '$TC.FR.UK$', ' ' ,...
    };


TARGET = [[RESULTS.DAM.B_LS(1:2);nan;nan;RESULTS.DAM.B_LS(3:25)],...
    [nan;nan;RESULTS.DAM.B_FS(1:25,1)],...
    [nan;nan;RESULTS.DAM.B_FS(1:25,2)],...
    [RESULTS.DAM.B_GMM0(1:2);nan;nan;RESULTS.DAM.B_GMM0(3:25)],...
    [RESULTS.DAM.B_GMM(1:2);nan;nan;RESULTS.DAM.B_GMM(3:25)],...
    ];
TARGET2 = [[RESULTS.DAM.SE_LS(1:2);nan;nan;RESULTS.DAM.SE_LS(3:25)],...
    [nan;nan;RESULTS.DAM.SE_FS(1:25,1)],...
    [nan;nan;RESULTS.DAM.SE_FS(1:25,2)],...
    [RESULTS.DAM.SE_GMM0(1:2);nan;nan;RESULTS.DAM.SE_GMM0(3:25)],...
    [RESULTS.DAM.SE_GMM(1:2);nan;nan;RESULTS.DAM.SE_GMM(3:25)],...
    ];


TSTAT = TARGET./TARGET2;

[a,b] = sort(abs(TSTAT(5:end,5)),'descend');
TSTAT([b+4],:);
TARGET(b+4,:);
ROWN = ROWNAMES(9:2:end);
ROWN2 = ROWNAMES(10:2:end);
ROWN = [ROWN(b);ROWN2(b)];
ROWNAMES = [ROWNAMES(1:8),ROWN(:)'];

TARGET = TARGET([(1:4)';b+4],:);
TARGET2 = TARGET2([(1:4)';b+4],:);


l = 1;
for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        if isnan(TARGET(i,j))
            TABLEVALS{l,j} = ['$ $'];
            TABLEVALS{l+1,j} = ['$ $'];
        else
            TABLEVALS{l,j} = ['',num2str(TARGET(i,j),'%0.2f'),''];
            TABLEVALS{l+1,j} = ['(',num2str(TARGET2(i,j),'%0.2f'),')'];
        end
        
    end
    l=l+2;
end
TABLEVALS;


TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{5}{D{.}{.}{-1}}} \toprule',...
    '  ',...
    '& \multicolumn{1}{c}{(LS)} & \multicolumn{1}{c}{(FS1)} & \multicolumn{1}{c}{(FS2)} & \multicolumn{1}{c}{(IV1)} & \multicolumn{1}{c}{(IV2)} \\',...
    '  & \multicolumn{1}{c}{Price} & \multicolumn{1}{c}{Q} & \multicolumn{1}{c}{N} & \multicolumn{1}{c}{Price} & \multicolumn{1}{c}{Price}  \\',...
    ' \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5} \cline{6-6} ',...
    ];
for j=1:26 %size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{j},' & ',TABLEVALS{j,1},' & ',TABLEVALS{j,2},' & ',TABLEVALS{j,3},' & ',TABLEVALS{j,4},' & ',TABLEVALS{j,5},' \\ '];
end

TABLE = [TABLE,...
    ' \hline ',...
    ' Dummies &  \multicolumn{5}{c}{Hours/Weekdays/Months/Years/Holidays} \\ ',...
    ' \# Covariates & ',' ',num2str(length(RESULTS.DAM.B_LS),'%0.0f'),' ',' & ',' ',num2str(length(RESULTS.DAM.B_LS),'%0.0f'),' ' ,' & ',' ',num2str(length(RESULTS.DAM.B_LS),'%0.0f'),' ' ,' & ',' ',num2str(length(RESULTS.DAM.B_LS),'%0.0f'),' ',' & ',' ',num2str(length(RESULTS.DAM.B_LS),'%0.0f'),' ' ,' \\ ',...
    ' Obs & ',' ',num2str(RESULTS.DAM.OBS,'%0.0f'),' ',' & ',' ',num2str(RESULTS.DAM.OBS,'%0.0f'),' ' ,' & ',' ',num2str(RESULTS.DAM.OBS,'%0.0f'),' ' ,' & ',' ',num2str(RESULTS.DAM.OBS,'%0.0f'),' ' ,' & ',' ',num2str(RESULTS.DAM.OBS,'%0.0f'),' ' ,' \\ ',...
    ' RMSE & ',' ',num2str(RESULTS.DAM.RMSE(2,1),'%0.1f'),' ',' & ',' ',num2str(RESULTS.DAM.RMSE(1,1),'%0.1f'),' ' ,' & ',' ',num2str(RESULTS.DAM.RMSE(1,2),'%0.1f'),' ' ,' & ',' ',num2str(RESULTS.DAM.RMSE(3,1),'%0.1f'),' ' ,' & ',' ',num2str(RESULTS.DAM.RMSE(4,1),'%0.1f'),' ' ,' \\ ',...
    ];

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_REGDAM.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%% DA price impacts plot

N = 6;
C = linspecer(N);

b00 = find(Y_time>=datetime(2020,3,15));
Y_cprices3s = smooth(Y_cprices3,24);
Y_cprices1s = smooth(Y_cprices1,24);
figure(1)
%plot(Y_time(b00),Y_cprices1s(b00),'color',C(3,:),'linewidth',1.8)
%plot(Y_time,smooth(Y_cprices4,24),'color',C(6,:),'linewidth',1.8)
plot(Y_time,smooth(Y_prices,24),'color',C(2,:),'linewidth',1.8)
hold on
plot(Y_time(b00),Y_cprices3s(b00),'-.','color',C(1,:),'linewidth',1.8)
    plot([datetime(2020,3,15) datetime(2020,3,15)],[-50 100],':k','color',C(5,:),'linewidth',2)
    plot([datetime(2020,5,11) datetime(2020,5,11)],[-50 100],':k','color',C(5,:),'linewidth',2) 

hold off
ylim([-15 45])
xlim([datetime(2020,2,18) datetime(2020,5,28,10,00,00)])
legend('Actual','No Demand/Gas price Reductions (CF3)','Lockdown start/end')
set(gca,'FontSize',15)
set(legend,'Location','SouthWest')
ylabel('Day-ahead price (€/MWh)')
saveas(1,['RESULTS/FIGURES/plot_DAMPRICES.eps'],'epsc')

%    '&  \multicolumn{1}{c}{No Dem. Red.} & \multicolumn{1}{c}{No Gas. Red.} & \multicolumn{1}{c}{No D/G Red.} & \multicolumn{1}{c}{More Renew.}   \\ \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5}  ',...


bb = find(Y_time>=datetime(2020,3,16) & Y_time<datetime(2020,6,1));
mean(Y_prices(bb))./mean(Y_cprices3(bb))

figure(1)
histogram(Y_prices(bb),50,'FaceColor',C(2,:),'Orientation', 'horizontal')
hold on
histogram(Y_cprices3(bb),50,'FaceColor',C(1,:),'Orientation', 'horizontal')
plot([0 1000],[0.86*36.61 0.86*36.61],'--k','color',C(4,:),'LineWidth',1.8)
plot([0 1000],[0.86*68.71 0.86*68.71],':k','LineWidth',1.8)
plot([0 1000],[mean(Y_prices(bb)) mean(Y_prices(bb))],'-','color',C(2,:),'LineWidth',1.8)
plot([0 1000],[mean(Y_cprices3(bb)) mean(Y_cprices3(bb))],'-.','color',C(1,:),'LineWidth',1.8)
xlim([0 350])
%histogram(Y_cprices4(bb),50)
hold off
set(gca,'FontSize',15)
legend('Actual prices during the crisis','Counterfactual No D/G Red. (CF3)','LCOE CCGT','LCOE Combustion Turbine','Average price during the crisis','Average counterfactual price')
set(legend,'Location','SouthEast')
xlabel('Frequency')
ylabel('Day-ahead price (€/MWh)')
saveas(1,['RESULTS/FIGURES/plot_DAMPRICES_histogram.eps'],'epsc')


%% Imports

b00 = find(DATA.Time(b0)<datetime(2020,3,1));

Ic0 =  DATA.Echphysiques(b0)/1000; %set value to observed physical exchanges
Ic1(b00) = DATA.Echphysiques(b0(b00))/1000;
Ic3(b00) = DATA.Echphysiques(b0(b00))/1000;

N = 6;
C = linspecer(N);

b00 = find(Y_time>=datetime(2020,3,15));
Ic3s = smooth(Ic3,72);
Ic1s = smooth(Ic1,72);
figure(1)
%plot(Y_time(b00),Ic1s(b00),'color',C(3,:),'linewidth',1.8)
%plot(Y_time,smooth(Y_cprices4,24),'color',C(6,:),'linewidth',1.8)
plot(Y_time,smooth(Ic0,72),'color',C(2,:),'linewidth',1.8)
hold on
plot(Y_time(b00),Ic3s(b00),'-.','color',C(1,:),'linewidth',1.8)
    plot([datetime(2020,3,15) datetime(2020,3,15)],[-20 10],':k','color',C(5,:),'linewidth',2)
    plot([datetime(2020,5,11) datetime(2020,5,11)],[-20 10],':k','color',C(5,:),'linewidth',2) %plot([datetime(2020,3,22) datetime(2020,3,22)],[-50 100],'--k','color',C(5,:),'linewidth',1.8)
% bb0 = find(Y_time>datetime(2018,03,16) & Y_time<datetime(2018,6,1));
% plot(Y_time(bb0)+365*2,smooth(Y_prices(bb0),48),'--')
% bb0 = find(Y_time>datetime(2019,03,16) & Y_time<datetime(2019,6,1));
% plot(Y_time(bb0)+365,smooth(Y_prices(bb0),48),'--')
hold off
ylim([-15 1])
xlim([datetime(2020,2,18) datetime(2020,5,28,10,00,00)])
legend('Actual','No D/G Red. (CF3)','Lockdown start/end')
set(gca,'FontSize',15)
set(legend,'Location','best')
ylabel('Net Imports (GW)')
saveas(1,['RESULTS/FIGURES/plot_IMPORTS.eps'],'epsc')

% figure(1)
% plot(Y_time,cumsum(1000*Ic3),'color',C(1,:),'linewidth',1.8)
% hold on
% plot(Y_time,cumsum(1000*Ic1),'color',C(3,:),'linewidth',1.8)
% %plot(Y_time,smooth(Y_cprices4,24),'color',C(6,:),'linewidth',1.8)
% plot(Y_time,cumsum(1000*Ic0),'color',C(2,:),'linewidth',1.8)
% plot([datetime(2020,3,15) datetime(2020,3,15)],[-20000 10000],'--k','color',C(4,:),'linewidth',1.8)
% %plot([datetime(2020,3,22) datetime(2020,3,22)],[-50 100],'--k','color',C(5,:),'linewidth',1.8)
% % bb0 = find(Y_time>datetime(2018,03,16) & Y_time<datetime(2018,6,1));
% % plot(Y_time(bb0)+365*2,smooth(Y_prices(bb0),48),'--')
% % bb0 = find(Y_time>datetime(2019,03,16) & Y_time<datetime(2019,6,1));
% % plot(Y_time(bb0)+365,smooth(Y_prices(bb0),48),'--')
% hold off
% %ylim([-15000 2000])
% xlim([datetime(2020,2,18) datetime(2020,5,28,10,00,00)])
% legend('Lockd./Gas','Lockdown','Actual','Lockdown')
% set(gca,'FontSize',15)
% set(legend,'Location','SouthWest')
% ylabel('Net Imports (GWh)')
% saveas(1,['RESULTS/FIGURES/plot_IMPORTS.eps'],'epsc')

%% DA Average price impacts by week
idx = find(Y_time==datetime(2020,3,15,23,30,00));

DAMEFFECT = nan(11,5);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    DAMEFFECT(i,1) = mean(Y_prices(b0)-Y_cprices1(b0));
    DAMEFFECT(i,2) = mean(Y_prices(b0)-Y_cprices2(b0));
    DAMEFFECT(i,3) = mean(Y_prices(b0)-Y_cprices3(b0));
    DAMEFFECT(i,4) = mean(Y_cprices4(b0)-Y_cprices3(b0));
end
DAMEFFECT = [DAMEFFECT;mean(DAMEFFECT)];


IMPEFFECT = nan(11,4);
[~,b] = setdiff(DATA.Time,Y_time);
b
Y_imp = DATA.Echphysiques;
Y_imp(b) = [];

for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    IMPEFFECT(i,1) = sum(Y_imp(b0)/1000-Ic1(b0));
    IMPEFFECT(i,2) = sum(Y_imp(b0)/1000-Ic2(b0));
    IMPEFFECT(i,3) = sum(Y_imp(b0)/1000-Ic3(b0));
    IMPEFFECT(i,4) = sum(Y_imp(b0)/1000-Ic4(b0));
end
IMPEFFECT = [IMPEFFECT;sum(IMPEFFECT)];

DAMEFFECT

IMPEFFECT

%% Table: Weekly price reductions -- all seven weeks -- drop week before.

clear TABLEVALS TABLEVALS2
TARGET= DAMEFFECT;

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.2f'),' $'];
    end
end


ROWNAMES = {...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31','Average'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{4}{D{.}{.}{0}}} \toprule',...
    '  ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '& \multicolumn{1}{c}{(CF1)} & \multicolumn{1}{c}{(CF2)} & \multicolumn{1}{c}{(CF3)} & \multicolumn{1}{c}{(CF4)} \\',...
    '&    \multicolumn{1}{c}{No Dem. Red.} & \multicolumn{1}{c}{No Gas. Red.} & \multicolumn{1}{c}{No D/G Red.} & \multicolumn{1}{c}{More Renew.}   \\ \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5}  ',...
    ...
    ];
for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_DAMP.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);


clear TABLEVALS TABLEVALS2
TARGET= IMPEFFECT;

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.0f'),' $'];
    end
end


ROWNAMES = {...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31','Total'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{4}{D{.}{.}{0}}} \toprule',...
    '  ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '& \multicolumn{1}{c}{(CF1)} & \multicolumn{1}{c}{(CF2)} & \multicolumn{1}{c}{(CF3)} & \multicolumn{1}{c}{(CF4)} \\',...
    '&  \multicolumn{1}{c}{No Dem. Red.} & \multicolumn{1}{c}{No Gas. Red.} & \multicolumn{1}{c}{No D/G Red.} & \multicolumn{1}{c}{More Renew.}   \\ \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5}  ',...
    ...
    ];
for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_IMP.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%% Revenues impacts by week TOTAL and by sector
idx = find(Y_time==datetime(2020,3,15,23,30,00));

REVEFFECT = nan(11,6);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    REVEFFECT(i,1) = sum( (Q(b0)-Ic0(b0))*1000  .* Y_prices(b0))/1e6;
    REVEFFECT(i,2) = sum( (Qc(b0)-Ic1(b0))*1000  .* Y_cprices1(b0))/1e6;
    REVEFFECT(i,3) = sum( (Q(b0)-Ic2(b0))*1000  .* Y_cprices2(b0))/1e6;
    REVEFFECT(i,4) = sum( (Qc(b0)-Ic3(b0))*1000  .* Y_cprices3(b0))/1e6;
    REVEFFECT(i,5) = sum( (Qc(b0)-Ic4(b0))*1000  .* Y_cprices4(b0))/1e6;
end
REVEFFECT = [REVEFFECT;sum(REVEFFECT)];
REVEFFECT(end,1) - REVEFFECT(end,4)

b0 = find(Y_time>=datetime(2020,3,15,23,30,00));

sum( (Qc(b0)-Ic3(b0))*1000  .* Y_cprices3(b0))/1e6 - sum((Q(b0)-Ic0(b0))*1000  .* Y_prices(b0))/1e6 %+1390 millions

sum(Ic0(b0)*1000.*Y_prices(b0))/1e6-sum(Ic3(b0)*1000.*Y_cprices3(b0))/1e6 %+58 millions

sum(Q(b0)*1000.*Y_prices(b0))/1e6 - sum(Qc(b0)*1000.*Y_cprices3(b0))/1e6 %-1330 million

%% Get a consistent counterfactual hydro generation

load('PROD_C.mat','PROD_C')
idx_PROD = find(PROD_C.Time_c>=datetime(2020,1,2) & PROD_C.Time_c<datetime(2020,6,1));
%Impose equilibrium
PROD_C.Hydro_c(idx_PROD) =1000*( Qc - Ic3 - PROD_C.Thermal_c(idx_PROD)/1000 - PROD_C.Nuke_c(idx_PROD)/1000 - R);

alpha1 = (1000*(Qc-R-Ic1)./(PROD_C.Thermal_c(idx_PROD)+PROD_C.Nuke_c(idx_PROD)+PROD_C.Hydro_c(idx_PROD)));
alpha3 = (1000*(Qc-R-Ic3)./(PROD_C.Thermal_c(idx_PROD)+PROD_C.Nuke_c(idx_PROD)+PROD_C.Hydro_c(idx_PROD)));

% %%Store vars
% load('FRANCE_DEMAND.mat','YY','Y_hat','Y_time','RTE','idxTest','idxTest0')
% DATA_CF = table2timetable(table(YY/1000,Y_hat/1000,Y_time,'VariableNames',{'Consommation','Consommation_CF','Time'}),'RowTimes','Time');
% 
% load('PROD_C.mat','PROD_C');
% DATA_CF2 = table2timetable(table(PROD_C.Nuke/1000,PROD_C.Nuke_c/1000,PROD_C.Import/1000,PROD_C.Time_c,'VariableNames',...
%     {'Nucleaire','Nucleaire_CF','Netimports','Time'}),'RowTimes','Time');
% 
% load('RENEWABLE.mat')
% DATA_CF3 = table2timetable(table(RENEWABLE.WindOnshore_FR/1000+RENEWABLE.Solar_FR/1000,RENEWABLE.Time,'VariableNames',...
%     {'Renouv','Time'}),'RowTimes','Time');
% 
% load('NATGAS.mat')
% NATGAS.naturalgas_price_CF = NATGAS.naturalgas_price*0 + mean(DATA.naturalgas_price(find(DATA.Time>=datetime(2020,1,2) & DATA.Time<datetime(2020,3,1))));
% 
% DATA_CF = outerjoin(DATA_CF,DATA_CF2,'Key','Time');
% DATA_CF = outerjoin(DATA_CF,DATA_CF3,'Key','Time');
% DATA_CF = outerjoin(DATA_CF,table2timetable(NATGAS,'RowTimes','Time'),'Key','Time');
% 
% DATA_CF2 = table2timetable(table(ULIM/1000,LLIM/1000,DATA.Time,'VariableNames',...
%     {'ULIM','LLIM','Time'}),'RowTimes','Time');
% DATA_CF = outerjoin(DATA_CF,DATA_CF2,'Key','Time');
% 
% idx1 = find(DATA_CF.Time<datetime(2020,1,1) | DATA_CF.Time>=datetime(2020,7,1));
% DATA_CF(idx1,:) = [];
% 
% writetable(timetable2table(DATA_CF),'DATA_CF.txt');

Y_time = PROD_C.Time_c(idx_PROD);

plot(Y_time, smooth(Qc - Ic3 - PROD_C.Thermal_c(idx_PROD)/1000 - PROD_C.Nuke_c(idx_PROD)/1000 - R,72))
hold on
plot(Y_time,smooth(PROD_C.Hydro_c(idx_PROD)/1000,72),'--')
plot(Y_time, smooth(Q - Ic0 - PROD_C.Thermal(idx_PROD)/1000 - PROD_C.Nuke(idx_PROD)/1000 - R,72),'--')
plot(Y_time,smooth(PROD_C.Hydro(idx_PROD)/1000,72))

hold off

%Installed Capacity in France 2020
%https://www.irena.org/-/media/Files/IRENA/Agency/Publication/2020/Jul/IRENA_Renewable_Energy_Statistics_2020.pdf
%Total thermal is 20364 MW

idx0 = find(PROD_C.Time_c>=datetime(2020,3,16) & PROD_C.Time_c<datetime(2020,6,1));
idx1 = find(PROD_C.Time_c(idx_PROD)>=datetime(2020,3,16) & PROD_C.Time_c(idx_PROD)<datetime(2020,6,1));
idx2 = find(DATA.Time>=datetime(2020,3,16) & (DATA.Time<datetime(2020,6,1)));

%% Thermal production histogram

figure(1)
histogram(DATA.Gaz(idx2)+DATA.Fioul(idx2)+DATA.Charbon(idx2)+DATA.Bionergies(idx2),50,'FaceColor',C(2,:),'Orientation', 'horizontal')
hold on
histogram(alpha3(idx1).*PROD_C.Thermal_c(idx0),50,'FaceColor',C(1,:),'Orientation', 'horizontal')
plot([0 500],[ 20364*0.33 20364*0.33],'--k','color',C(4,:),'LineWidth',1.1)
plot([0 500],[ 20364*0.5 20364*0.5],':k','color',C(4,:),'LineWidth',1.1)
plot([0 500],[mean(DATA.Gaz(idx2)+DATA.Fioul(idx2)+DATA.Charbon(idx2)+DATA.Bionergies(idx2)) mean(DATA.Gaz(idx2)+DATA.Fioul(idx2)+DATA.Charbon(idx2)+DATA.Bionergies(idx2))],'-','color',C(2,:),'LineWidth',1.1)
plot([0 500],[mean(alpha3(idx1).*PROD_C.Thermal_c(idx0)) mean(alpha3(idx1).*PROD_C.Thermal_c(idx0))],'-.','color',C(1,:),'LineWidth',1.1)
xlim([0 500])
hold off
set(gca,'FontSize',15)
legend('Actual generation during the crisis','Counterfactual No D/G Red.','Implied average w/ 33% capacity factor','Implied average w/ 50% capacity factor','Average generation during the crisis','Average counterfactual generation')
set(legend,'Location','NorthEast')
xlabel('Frequency')
ylabel('Thermal generation (MW)')
saveas(1,['RESULTS/FIGURES/plot_THERMAL_histogram.eps'],'epsc')


%% Revenue impacts by sector

Carbon = 20; %data
K = (1/0.52*NGP + 0.43*Carbon); %marginal cost of thermal plants 
K_c = (1/0.52*NGPc + 0.43*Carbon); %counterfactual marginal cost of thermal plants
REVEFFECT_THERMAL = nan(11,3);

for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    REVEFFECT_THERMAL(i,1) = sum(PROD_C.Thermal(idx_PROD(b0)).*(Y_prices(b0)-K(b0)))/1e6;
    REVEFFECT_THERMAL(i,2) = sum(alpha1(b0).*PROD_C.Thermal_c(idx_PROD(b0)).*(Y_cprices1(b0)-K(b0)))/1e6;
    REVEFFECT_THERMAL(i,3) = sum(alpha3(b0).*PROD_C.Thermal_c(idx_PROD(b0)).*(Y_cprices3(b0)-K_c(b0)))/1e6;
end
REVEFFECT_THERMAL = [REVEFFECT_THERMAL;sum(REVEFFECT_THERMAL)];
REVEFFECT_THERMAL

V_ARENH = 100*1e6/8760; %volume ARENH by hour
P_ARENH = 12
REVEFFECT_NUKE = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    REVEFFECT_NUKE(i,1) = sum((PROD_C.Nuke(idx_PROD(b0))-V_ARENH).*(Y_prices(b0)-P_ARENH))/1e6;
    REVEFFECT_NUKE(i,2) = sum((alpha1(b0).*PROD_C.Nuke_c(idx_PROD(b0))-V_ARENH) .*(Y_cprices1(b0)-P_ARENH))/1e6;
    REVEFFECT_NUKE(i,3) = sum((alpha3(b0).*PROD_C.Nuke_c(idx_PROD(b0))-V_ARENH).*(Y_cprices3(b0)-P_ARENH))/1e6;
    
    %
    % plot(PROD_C.Nuke(idx_PROD(b0))-V_ARENH)
    % hold on
    % plot((alpha1(b0).*PROD_C.Nuke_c(idx_PROD(b0))-V_ARENH))
    % plot((alpha3(b0).*PROD_C.Nuke_c(idx_PROD(b0))-V_ARENH))
    % hold off
    % pause
    
end

REVEFFECT_NUKE = [REVEFFECT_NUKE;sum(REVEFFECT_NUKE)];

REVEFFECT_HYDRO = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    REVEFFECT_HYDRO(i,1) = sum(PROD_C.Hydro(idx_PROD(b0)).*Y_prices(b0))/1e6;
    REVEFFECT_HYDRO(i,2) = sum(alpha1(b0).*PROD_C.Hydro_c(idx_PROD(b0)).*Y_cprices1(b0))/1e6;
    REVEFFECT_HYDRO(i,3) = sum(alpha3(b0).*PROD_C.Hydro_c(idx_PROD(b0)).*Y_cprices3(b0))/1e6;
end
REVEFFECT_HYDRO = [REVEFFECT_HYDRO;sum(REVEFFECT_HYDRO)];

REVEFFECT_REN = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    REVEFFECT_REN(i,1) = sum(1000*R(b0).*Y_prices(b0))/1e6;
    REVEFFECT_REN(i,2) = sum(1000*R(b0).*Y_cprices1(b0))/1e6;
    REVEFFECT_REN(i,3) = sum(1000*R(b0).*Y_cprices3(b0))/1e6;
end
REVEFFECT_REN = [REVEFFECT_REN;sum(REVEFFECT_REN)];

REVEFFECT_THERMAL+REVEFFECT_NUKE+REVEFFECT_HYDRO+REVEFFECT_REN

REVEFFECT(:,[1 2 4])

sum(PROD_C.Hydro_c(idx_PROD(b0))-PROD_C.Hydro(idx_PROD(b0)))/1000

%% Table

A1 = [REVEFFECT_THERMAL(:,1)-REVEFFECT_THERMAL(:,2),REVEFFECT_THERMAL(:,1)-REVEFFECT_THERMAL(:,3)];
A2 = [REVEFFECT_NUKE(:,1)-REVEFFECT_NUKE(:,2),REVEFFECT_NUKE(:,1)-REVEFFECT_NUKE(:,3)];
A3 = [REVEFFECT_HYDRO(:,1)-REVEFFECT_HYDRO(:,2),REVEFFECT_HYDRO(:,1)-REVEFFECT_HYDRO(:,3)];
A4 = [REVEFFECT_REN(:,1)-REVEFFECT_REN(:,2),REVEFFECT_REN(:,1)-REVEFFECT_REN(:,3)];

TARGET = [[A1(:,1),A2(:,1),A3(:,1),A4(:,1)],[A1(:,2),A2(:,2),A3(:,2),A4(:,2)]];

clear TABLEVALS TABLEVALS2

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.1f'),' $'];
    end
end


ROWNAMES = {...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31','Total'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{8}{D{.}{.}{0}}} \toprule',...
    '  ',... 
    '& \multicolumn{4}{c}{(CF1)} & \multicolumn{4}{c}{(CF3)} \\',...
    '&  \multicolumn{4}{c}{No Demand Red.} &  \multicolumn{4}{c}{No Dem/Gas Red.}  \\ \cline{2-5} \cline{6-9} ',...
    '&  \multicolumn{1}{c}{The.} & \multicolumn{1}{c}{Nuc.} & \multicolumn{1}{c}{Hyd.} & \multicolumn{1}{c}{Ren.} &  \multicolumn{1}{c}{The.} & \multicolumn{1}{c}{Nuc.} & \multicolumn{1}{c}{Hyd.} & \multicolumn{1}{c}{Ren.} \\  ',...
    ...
    ];
for i=1:size(TABLEVALS,1)-1
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},' & ',TABLEVALS{i,6},' & ',TABLEVALS{i,7},' & ',TABLEVALS{i,8},...
        ' \\ '];
end
i = i+1;
TABLE = [TABLE, '  ',...
    ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},' & ',TABLEVALS{i,6},' & ',TABLEVALS{i,7},' & ',TABLEVALS{i,8},...
    ' \\ '];

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_REVSECTOR.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

TARGET = REVEFFECT;

clear TABLEVALS TABLEVALS2

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.0f'),' $'];
    end
end


ROWNAMES = {...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31','Total'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{5}{D{.}{.}{0}}} \toprule',...
    ' & & \multicolumn{1}{c}{(CF1)} & \multicolumn{1}{c}{(CF2)} & \multicolumn{1}{c}{(CF3)} & \multicolumn{1}{c}{(CF4)} \\ & \multicolumn{1}{c}{Actual} &  \multicolumn{1}{c}{No D. Red.} & \multicolumn{1}{c}{No G. Red.} & \multicolumn{1}{c}{No D/G Red.} & \multicolumn{1}{c}{More R.}   \\ \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5} \cline{6-6}',...
    ];
for i=1:size(TABLEVALS,1)-1
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},...
        ' \\ '];
end
i = i+1;
TABLE = [TABLE, '  ',...
    ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},...
    ' \\ '];

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_REV.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%% Including Hedging
load('PROD_C.mat','PROD_C')

idx_PROD = find(PROD_C.Time_c>=datetime(2020,1,2) & PROD_C.Time_c<datetime(2020,6,1));
idx_PROD2 = find(PROD_C.Time_c(idx_PROD)>=datetime(2020,3,1));

R = Rc; %(DATA.Eolien+DATA.Solaire)./1000;

%Impose equilibrium
PROD_C.Hydro_c(idx_PROD) =1000*( Qc - Ic3 - PROD_C.Thermal_c(idx_PROD)/1000 - PROD_C.Nuke_c(idx_PROD)/1000 - R);

alpha1 = (1000*(Qc-R-Ic1)./(PROD_C.Thermal_c(idx_PROD)+PROD_C.Nuke_c(idx_PROD)+PROD_C.Hydro_c(idx_PROD)));
alpha3 = (1000*(Qc-R-Ic3)./(PROD_C.Thermal_c(idx_PROD)+PROD_C.Nuke_c(idx_PROD)+PROD_C.Hydro_c(idx_PROD)));

% % Hedging? Average by week? Month? !!entire period 
% CONTRACTS = mean(alpha3(idx_PROD2).*PROD_C.Thermal_c(idx_PROD(idx_PROD2)));
% CONTRACTS = mean((alpha3(idx_PROD2).*PROD_C.Nuke_c(idx_PROD(idx_PROD2))-V_ARENH)); %net of ARENH?
% CONTRACTS = mean(alpha3(idx_PROD2).*PROD_C.Hydro_c(idx_PROD(idx_PROD2)));
% CONTRACTS = mean(1000*R(idx_PROD2));


Carbon = 20; %rapport Clemence
K = (1/0.52*NGP + 0.43*Carbon); %marginal cost of thermal plants %RTE 0.65*
K_c = (1/0.52*NGPc + 0.43*Carbon); %counterfactual marginal cost of thermal plants

REVEFFECT_THERMAL = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    CONTRACTS = mean(alpha3(idx_PROD2).*PROD_C.Thermal_c(idx_PROD(idx_PROD2)));
    REVEFFECT_THERMAL(i,1) = sum((PROD_C.Thermal(idx_PROD(b0))-CONTRACTS).*(Y_prices(b0)-K(b0)))/1e6;
    REVEFFECT_THERMAL(i,2) = sum((alpha1(b0).*PROD_C.Thermal_c(idx_PROD(b0))-CONTRACTS).*(Y_cprices1(b0)-K(b0)))/1e6;
    REVEFFECT_THERMAL(i,3) = sum((alpha3(b0).*PROD_C.Thermal_c(idx_PROD(b0))-CONTRACTS).*(Y_cprices3(b0)-K_c(b0)))/1e6;
end
REVEFFECT_THERMAL = [REVEFFECT_THERMAL;sum(REVEFFECT_THERMAL)];
REVEFFECT_THERMAL

K = 12; %marginal cost of nuke plants %RTE 0.65*
K_c = 12; %counterfactual marginal cost of nuke plants

V_ARENH = 100*1e6/8760; %volume ARENH by hour
REVEFFECT_NUKE = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    CONTRACTS = mean((alpha3(idx_PROD2).*PROD_C.Nuke_c(idx_PROD(idx_PROD2))-V_ARENH));
    REVEFFECT_NUKE(i,1) = sum((PROD_C.Nuke(idx_PROD(b0))-V_ARENH - CONTRACTS).*(Y_prices(b0)-12))/1e6;
    REVEFFECT_NUKE(i,2) = sum((alpha1(b0).*PROD_C.Nuke_c(idx_PROD(b0))-V_ARENH - CONTRACTS) .*(Y_cprices1(b0)-12))/1e6;
    REVEFFECT_NUKE(i,3) = sum((alpha3(b0).*PROD_C.Nuke_c(idx_PROD(b0))-V_ARENH - CONTRACTS).*(Y_cprices3(b0)-12))/1e6;
end
REVEFFECT_NUKE = [REVEFFECT_NUKE;sum(REVEFFECT_NUKE)];

REVEFFECT_HYDRO = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    CONTRACTS = mean(alpha3(idx_PROD2).*PROD_C.Hydro_c(idx_PROD(idx_PROD2)));
    REVEFFECT_HYDRO(i,1) = sum((PROD_C.Hydro(idx_PROD(b0))-CONTRACTS) .*Y_prices(b0))/1e6;
    REVEFFECT_HYDRO(i,2) = sum((alpha1(b0).*PROD_C.Hydro_c(idx_PROD(b0))-CONTRACTS).*Y_cprices1(b0))/1e6;
    REVEFFECT_HYDRO(i,3) = sum((alpha3(b0).*PROD_C.Hydro_c(idx_PROD(b0))-CONTRACTS).*Y_cprices3(b0))/1e6;
end
REVEFFECT_HYDRO = [REVEFFECT_HYDRO;sum(REVEFFECT_HYDRO)];

REVEFFECT_REN = nan(11,3);
for i = 1:11
    b0 = (idx+(i-1)*24*7+1:idx+i*24*7);
    max(Y_time(b0));
    CONTRACTS = mean(1000*R(idx_PROD2));
    REVEFFECT_REN(i,1) = sum((1000*R(b0)-CONTRACTS).*Y_prices(b0))/1e6;
    REVEFFECT_REN(i,2) = sum((1000*R(b0)-CONTRACTS).*Y_cprices1(b0))/1e6;
    REVEFFECT_REN(i,3) = sum((1000*R(b0)-CONTRACTS).*Y_cprices3(b0))/1e6;
end
REVEFFECT_REN = [REVEFFECT_REN;sum(REVEFFECT_REN)];

REVEFFECT(:,[1 2 4])


%% Table

A1 = [REVEFFECT_THERMAL(:,1)-REVEFFECT_THERMAL(:,2),REVEFFECT_THERMAL(:,1)-REVEFFECT_THERMAL(:,3)];
A2 = [REVEFFECT_NUKE(:,1)-REVEFFECT_NUKE(:,2),REVEFFECT_NUKE(:,1)-REVEFFECT_NUKE(:,3)];
A3 = [REVEFFECT_HYDRO(:,1)-REVEFFECT_HYDRO(:,2),REVEFFECT_HYDRO(:,1)-REVEFFECT_HYDRO(:,3)];
A4 = [REVEFFECT_REN(:,1)-REVEFFECT_REN(:,2),REVEFFECT_REN(:,1)-REVEFFECT_REN(:,3)];

TARGET = [[A1(:,1),A2(:,1),A3(:,1),A4(:,1)],[A1(:,2),A2(:,2),A3(:,2),A4(:,2)]];

clear TABLEVALS TABLEVALS2

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.1f'),' $'];
    end
end


ROWNAMES = {...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31','Total'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{8}{D{.}{.}{0}}} \toprule',...
    '  ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '& \multicolumn{4}{c}{(CF1)} & \multicolumn{4}{c}{(CF3)} \\',...
    '&  \multicolumn{4}{c}{No Demand Red.} &  \multicolumn{4}{c}{No Dem/Gas Red.}  \\ \cline{2-5} \cline{6-9} ',...
    '&  \multicolumn{1}{c}{The.} & \multicolumn{1}{c}{Nuc.} & \multicolumn{1}{c}{Hyd.} & \multicolumn{1}{c}{Ren.} &  \multicolumn{1}{c}{The.} & \multicolumn{1}{c}{Nuc.} & \multicolumn{1}{c}{Hyd.} & \multicolumn{1}{c}{Ren.} \\  ',...
    ...
    ];
for i=1:size(TABLEVALS,1)-1
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},' & ',TABLEVALS{i,6},' & ',TABLEVALS{i,7},' & ',TABLEVALS{i,8},...
        ' \\ '];
end
i = i+1;
TABLE = [TABLE, '  ',...
    ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},' & ',TABLEVALS{i,6},' & ',TABLEVALS{i,7},' & ',TABLEVALS{i,8},...
    ' \\ '];

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_REV_hedging.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);


%% Retailers?

% Qp is counterfactual (say lockdown+gas)
% Qr is realized
%No contract
c = 115.71;
F = 50.8;

b0 = find(Y_time>datetime(2020,3,15));

Q1 = Q(b0)*1000; %realized
Q0 = Qc(b0)*1000; %domestic consumption (counterfactual)
P1 = Y_prices(b0);
P0 = Y_cprices3(b0);

sum(Q1.*(c-P1) - Q0.*(c-P0))/1000000 %no contracts
sum((Q0-Q1).*(P1-P0) + (Q1-Q0).*(c-P0))/1000000 %no contracts

%% Natural gas price
figure(1)
plot(Y_time,NGP,'color',C(2,:),'linewidth',1.8)
hold on
plot(DATA.Time+days(365),DATA.naturalgas_price,'--','color',C(6,:),'linewidth',1.1)
plot(DATA.Time+2*days(365),DATA.naturalgas_price,':','color',C(6,:),'linewidth',1.1)
plot([datetime(2020,3,15) datetime(2020,5,31)],[NGPc(find(Y_time==datetime(2020,4,1,00,30,00))) NGPc(find(Y_time==datetime(2020,4,1,00,30,00))) ],'-.','color',C(1,:),'linewidth',1.8)
plot([datetime(2020,3,15) datetime(2020,3,15)],[0 40],'--k','color',C(4,:),'linewidth',1.1)
hold off
xlim([datetime(2020,1,1) datetime(2020,5,31)])
ylim([0 20])
legend('2020 prices','2019 prices','2018 prices','Counterfactual prices','Lockdown')
set(gca,'FontSize',15)
set(legend,'Location','best')
ylabel('PEG Natural gas price (EUR/MWh)')
saveas(1,['RESULTS/FIGURES/plot_NG.eps'],'epsc')

%% Summary stats
clear TABLEVALS

TARGET = [mean(SUMMARYSTATS);std(SUMMARYSTATS);quantile(SUMMARYSTATS,0.01);quantile(SUMMARYSTATS,0.99)];
for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.2f'),' $'];
    end
end
TABLEVALS


ROWNAMES = {...
    'Mean',...
    'Std',...
    '1st percentile',...
    '99th percentile',...
    'Obs',...
    };

%SUMMARYSTATS = [DATA.Price_FR,DATA.Echphysiques/1000,DATA.naturalgas_price,DATA.Q/1000,DATA.Nucleaire/1000,DATA.WindOnshore_FR/1000,DATA.NUKE_UCAP_F/1000];

TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{7}{D{.}{.}{0}}} \toprule',...
    '  ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '&  \multicolumn{1}{c}{Price} &  \multicolumn{1}{c}{NetImp} & \multicolumn{1}{c}{NatGas} & \multicolumn{1}{c}{Q} & \multicolumn{1}{c}{N} & \multicolumn{1}{c}{Wind} & \multicolumn{1}{c}{Out.}  \\ \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5} \cline{6-6} \cline{7-7} \cline{8-8}  ',...    ...
    ];
for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},' & ',TABLEVALS{i,6},' & ',TABLEVALS{i,7},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_DESCRREG.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%%
temp = timetable(Q-Qc,'RowTimes',Y_time);
sum(temp.Var1)

sum(temp.Var1(find(temp.Time>=datetime(2020,3,16) & temp.Time<datetime(2020,6,1) )))

%% RESULTS PRODUCTION
load('PROD_C.mat')

idx_PROD = find(PROD_C.Time_c>=datetime(2020,1,2) & PROD_C.Time_c<datetime(2020,6,1));
PROD_C.Conso_c(idx_PROD,1) = 1000*Qc;
PROD_C.Hydro_c(idx_PROD) =1000*( Qc - Ic3 - PROD_C.Thermal_c(idx_PROD)/1000 - PROD_C.Nuke_c(idx_PROD)/1000 - R);PROD_C.Import_c(idx_PROD,1) = 1000*Ic3;
YYY = [PROD_C.Conso,PROD_C.Thermal,PROD_C.Nuke,PROD_C.Hydro,PROD_C.Import];
YY_hat= [PROD_C.Conso_c,PROD_C.Thermal_c,PROD_C.Nuke_c,PROD_C.Hydro_c,PROD_C.Import_c];

idxTest1 = setdiff(idxTest,idxTest0);
idxTestb = idxTest1; %all observations);

%CHECKS
% idx = find(PROD_C.Time_c>=datetime(2020,3,16) & PROD_C.Time_c<datetime(2020,6,1));
% temp = sum(YYY(idx,:) - YY_hat(idx,:))
% sum(temp(2:end))
% plot(YYY(idx_PROD,1) - sum(YYY(idx_PROD,2:end),2))
% hold on
% plot(YY_hat(idx_PROD,1) - sum(YY_hat(idx_PROD,2:end),2))
% plot(R*1000)
% hold off


for jj=1:5
    
    YY = YYY(:,jj)/1000;
    Y_hat = YY_hat(:,jj)/1000;
    
    zone = 1;
    sqrt(mean((YY(idxTestb)-Y_hat(idxTestb)).^2))
    
    TABLE1 = zeros(1,26);
    TABLE2_EST = zeros(1,14);
    TABLE2_PER = zeros(1,14);
    TABLE2_STD = zeros(1,14);
    
    RMSPE = zeros(12,2);
    OBS = zeros(12,4);
    
    idxTestb = idxTest1; %all observations);
    %%%%Prediction performance
    histogram(YY(idxTestb)-Y_hat(idxTestb),100)
    hold on
    histogram(YY(idxTest0)-Y_hat(idxTest0),100)
    hold off
    
    jj
  
    BIAS(zone,1) = nanmean(YY(idxTestb)-Y_hat(idxTestb));
    ABSBIAS(zone,1) = nanmean(abs(YY(idxTestb)-Y_hat(idxTestb))./YY(idxTestb))
    STD(zone,1) = nanstd(YY(idxTestb)-Y_hat(idxTestb));

%pause


    RMSPE(zone,1) = sqrt(mean((YY(idxTestb)-Y_hat(idxTestb)).^2));
    OBS(zone,1) = length(idxTrain);
    OBS(zone,2) = length(idxValid);
    OBS(zone,3) = length(idxTestb);
    OBS(zone,4) = length(find(Y_time>=datetime(2020,3,1)));
    
    %%%%Prediction errors covariance
    listdays = unique(datetime(datestr(Y_time(idxTest),'dd-mm-yyyy'),'InputFormat','dd-MM-yyyy'));
    Yd = nan(24,length(listdays));
    Yd_hat = nan(24,length(listdays));
    Yd_f = nan(24,length(listdays));
    
    YY_time = Y_time;
    j=1;
    for i=1:length(listdays)
        bd = find(day(listdays(i))==day(YY_time) & month(listdays(i))==month(YY_time)  & year(listdays(i))==year(YY_time));
        if sum(isnan(YY(bd)))==0 && length(bd)==24
            Yd(:,j) = YY(bd);
            Yd_hat(:,j) = Y_hat(bd);
            j=j+1;
        end
        
    end
    
    %b0 = find(listdays<datetime('1-Mar-2020')); %old version
    b0 = find(listdays<datetime('15-Mar-2020')); %new version
    b1 = find(listdays>=datetime('1-Mar-2020'));
    b2 = find(listdays>=datetime('15-Mar-2020'));
    
    COV_U = nancov(Yd(:,b0)'-Yd_hat(:,b0)');
    %COV_U0 = nancov(Yd(:,b00)'-Yd_hat(:,b00)');
    COV_Uf = nancov(Yd(:,b0)'-Yd_f(:,b0)');
    
    hour_std = diag(sqrt(COV_U));
    %hour_std0 = diag(sqrt(COV_U0));
    
    %table(hour_std,hour_std0)
    %pause
    
    hourf_std = diag(sqrt(COV_Uf));
    %table(hour_std,hourf_std)
    
    %%%%How has demand changed?
    listdays = unique(datetime(datestr(YY_time,'dd-mm-yyyy'),'InputFormat','dd-MM-yyyy'));
    
    b1 = find(listdays>=datetime('1-Mar-2020') & listdays<datetime('31-Dec-2020'));
    Yd = nan(24,length(b1));
    Yd_hat = nan(24,length(b1));
    Yd_f = nan(24,length(b1));
    meanhour = nan(24,length(b1));
    meanhour_f = nan(24,length(b1));
    WALD_t  = nan(1,length(b1));
    WALDf_t  = nan(1,length(b1));
    WALD_df  = nan(1,length(b1));
    meanYhat  = nan(1,length(b1));
    meandiff  = nan(1,length(b1));
    std_diff  = nan(1,length(b1));
    meandiff_f  = nan(1,length(b1));
    std_diff_f  = nan(1,length(b1));
    weekid  = nan(1,length(b1));
    
    Date = listdays(b1);
    for i=1:length(b1)
        bd = find(day(listdays(b1(i)))==day(YY_time) & month(listdays(b1(i)))==month(YY_time)  & year(listdays(b1(i)))==year(YY_time));
        Yd(hour(YY_time(bd))+1,i) = YY(bd);
        Yd_hat(hour(YY_time(bd))+1,i) = Y_hat(bd);
        %Yd_f(hour(YY_time(bd))+1,i) = YY_fload(bd);
        Date(i) = listdays(b1(i));
        
        hourly_idx = hour(YY_time(bd))+1;
        WALD_t(i) = (Yd(hourly_idx,i)-Yd_hat(hourly_idx,i))'*inv(COV_U(hourly_idx,hourly_idx)+0*eye(length(hourly_idx)))*(Yd(hourly_idx,i)-Yd_hat(hourly_idx,i));
        %WALDf_t(i) = (Yd(hourly_idx,i)-Yd_f(hourly_idx,i))'*inv(COV_Uf(hourly_idx,hourly_idx)+0*eye(length(hourly_idx)))*(Yd(hourly_idx,i)-Yd_f(hourly_idx,i));
        WALD_df(i) = length(hourly_idx);
        
        meanYhat(i) = sum((Yd_hat(hourly_idx,i)));
        
        meandiff(i) = sum((Yd(hourly_idx,i)-Yd_hat(hourly_idx,i)));
        std_diff(i) = sqrt(sum(sum(COV_U(hourly_idx,hourly_idx))));
        %meandiff_f(i) = sum((Yd(hourly_idx,i)-Yd_f(hourly_idx,i)));
        std_diff_f(i) = sqrt(sum(sum(COV_Uf(hourly_idx,hourly_idx))));
        
        meanhour(hourly_idx,i) = (Yd(hourly_idx,i)-Yd_hat(hourly_idx,i));
        %meanhour_f(hourly_idx,i) = (Yd(hourly_idx,i)-Yd_f(hourly_idx,i));
        weekid(i) = week(listdays(b1(i)));
    end
    
    weekid = [9;weekid(1:end-1)'];
    
    meanh = nan(24,14); %mean errors (mine)
    meanhf = nan(24,14); %mean errors (forecast)
    meanhat = nan(24,14); %mean predicted demand over weekdays
    meany = nan(24,14); %mean demand over weekdays
    sumh = nan(14,1); %mean errors (mine)
    sumhat = nan(14,1); %mean errors (mine)
    sumhf = nan(14,1); %mean errors (forecast)
    sumh_std = nan(14,1); %mean errors (mine)
    sumhf_std = nan(14,1); %mean errors (forecast)
    
    for i=1:14
        b = find(weekid==i+9);
        meanh(:,i) = nanmean(meanhour(:,b),2);
        meanhf(:,i) = nanmean(meanhour_f(:,b),2);
        meanhat(:,i) = nanmean(Yd_hat(:,b),2);
        meany(:,i) = nanmean(Yd(:,b),2);
        
        sumhat(i) = nansum(nansum(Yd_hat(:,b),2));
        sumh(i,1) = nansum(nansum(meanhour(:,b),2));
        sumhf(i,1) = nansum(nansum(meanhour_f(:,b),2));
        sumh_std(i,1) = sqrt(nansum(std_diff(b).^2));
        sumhf_std(i,1) = sqrt(nansum(std_diff_f(b).^2));
        
        x = meanhour(:,b);
        y = Yd(:,b);
        BIAS_WEEK(i,1) = nanmean(x(:));
        ABSBIAS_WEEK(i,1) = nanmean(abs(x(:))./y(:));
        STD_WEEK(i,1) = nanstd(x(:));
        RMSPE_WEEK(i,1) = sqrt(nanmean(x(:).^2));
        x = meanhour_f(:,b);
        BIAS_WEEK(i,2) = nanmean(x(:));
        ABSBIAS_WEEK(i,2) = nanmean(abs(x(:))./y(:));
        STD_WEEK(i,2) = nanstd(x(:));
        RMSPE_WEEK(i,2) = sqrt(nanmean(x(:).^2));
    end
    %pause
    
    %%%%Table1: Prediction performance: RMSPE and load forecast improvements
    TABLE1_RMSPE = [RMSPE(zone,:),reshape(RMSPE_WEEK(1:14,:)',[1 28])];
    TABLE1_ABSBIAS = [ABSBIAS(zone,:),reshape(ABSBIAS_WEEK(1:14,:)',[1 28])];
    
    
    %%%%Table2: ATE by week
    TABLE2_EST = [sumh(1:14)'];
    TABLE2_STD = [sumh_std(1:14)'];
    TABLE2_PER = sumh(1:14)./sumhat(1:14);
    
    RESULTS(jj).TABLE1 = TABLE1;
    RESULTS(jj).TABLE1_ABSBIAS = TABLE1_ABSBIAS;
    RESULTS(jj).TABLE1_RMSPE = TABLE1_RMSPE;
    RESULTS(jj).TABLE2_EST = TABLE2_EST;
    RESULTS(jj).TABLE2_PER = TABLE2_PER;
    RESULTS(jj).TABLE2_STD = TABLE2_STD;
    
end


%% Table: Prediction performance 
clear TABLEVALS TABLEVALS2
TARGET= [...%RESULTS(1).TABLE1_RMSPE(1,[1 (3:2:30)])',...    
    RESULTS(2).TABLE1_ABSBIAS(1,[1 (2:2:29)])',...
    RESULTS(2).TABLE1_RMSPE(1,[1 (3:2:30)])',...    
    RESULTS(3).TABLE1_ABSBIAS(1,[1 (2:2:29)])',...
    RESULTS(3).TABLE1_RMSPE(1,[1 (3:2:30)])',...
   ];

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        if j==1 || j==3
            TABLEVALS{i,j} = ['$',num2str(100*TARGET(i,j),'%0.1f'),'\% $'];
        else
            TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.2f'),' $'];
        end
    end
end

TABLEVALS


ROWNAMES = {'Test set',...
    '03/02-03/08',...
    '03/09-03/15',...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{4}{D{.}{.}{0}}} \toprule',...
    '  ',...
    '& \multicolumn{2}{c}{Thermal} & \multicolumn{2}{c}{Nuclear}   \\ '...
    '& \multicolumn{1}{c}{MAPE} & \multicolumn{1}{c}{RMSE} & \multicolumn{1}{c}{MAPE} & \multicolumn{1}{c}{RMSE}   \\ '...    
    ' \cline{2-3} \cline{4-5} ',...
    ...
    ];
for i=1:14
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4} , ...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_PERF_PROD.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);


%% Table: Weekly demand reductions -- all seven weeks -- drop week before.
%TABLE2_EST/1000
%TABLE2_PER
%TABLE2_STD/1000

clear TABLEVALS TABLEVALS2
TARGET= [RESULTS(1).TABLE2_EST(1,:)',...
    RESULTS(2).TABLE2_EST(1,:)',...
    RESULTS(3).TABLE2_EST(1,:)',...
    RESULTS(4).TABLE2_EST(1,:)',...
    RESULTS(5).TABLE2_EST(1,:)'];
TARGET = [TARGET,sum(TARGET,2)];
TARGET = [TARGET(3:end-1,1),TARGET(3:end-1,5),TARGET(3:end-1,2),TARGET(3:end-1,3),TARGET(3:end-1,4)];
TARGET = [TARGET;sum(TARGET)]/1000

%percent change of each fuel from March 16 to May 31?
idx_PROD = find(PROD_C.Time_c>=datetime(2020,3,16) & PROD_C.Time_c<datetime(2020,6,1));

% Part thermique a baissé
sum(PROD_C.Thermal_c(idx_PROD)) / sum(PROD_C.Conso_c(idx_PROD)-PROD_C.Import_c(idx_PROD)) %  0.0780
sum(PROD_C.Thermal(idx_PROD)) / sum(PROD_C.Conso(idx_PROD)-PROD_C.Import(idx_PROD)) % 0.0557
(sum(PROD_C.Thermal(idx_PROD))-sum(PROD_C.Thermal_c(idx_PROD))) /sum(PROD_C.Thermal_c(idx_PROD))  % -51%

% Part nucleaire a baissé
sum(PROD_C.Nuke_c(idx_PROD)) / sum(PROD_C.Conso_c(idx_PROD)-PROD_C.Import_c(idx_PROD)) % 0.7447
sum(PROD_C.Nuke(idx_PROD)) / sum(PROD_C.Conso(idx_PROD)-PROD_C.Import(idx_PROD)) %  0.6936
sum(PROD_C.Nuke(idx_PROD)) / sum(PROD_C.Nuke_c(idx_PROD)) % -15%

% Part hydro a augmenté
sum(PROD_C.Hydro_c(idx_PROD)) / sum(PROD_C.Conso_c(idx_PROD)-PROD_C.Import_c(idx_PROD)) % 0.0764
sum(PROD_C.Hydro(idx_PROD)) / sum(PROD_C.Conso(idx_PROD)-PROD_C.Import(idx_PROD)) % 0.1417
sum(PROD_C.Hydro(idx_PROD))/sum(PROD_C.Hydro_c(idx_PROD)) % +72%

1- sum(PROD_C.Thermal_c(idx_PROD) + PROD_C.Nuke_c(idx_PROD) + PROD_C.Hydro_c(idx_PROD)) / sum(PROD_C.Conso_c(idx_PROD)-PROD_C.Import_c(idx_PROD))  %0.1010
1- sum(PROD_C.Thermal(idx_PROD) + PROD_C.Nuke(idx_PROD) + PROD_C.Hydro(idx_PROD)) / sum(PROD_C.Conso(idx_PROD)-PROD_C.Import(idx_PROD)) %0.1090

%production domestique a baissé de 7.5%
sum(PROD_C.Conso(idx_PROD)-PROD_C.Import(idx_PROD))/sum(PROD_C.Conso_c(idx_PROD)-PROD_C.Import_c(idx_PROD))
%conso a baissé de 12%
1- sum(PROD_C.Conso(idx_PROD))/sum(PROD_C.Conso_c(idx_PROD)) 
%netimport a baissé de 24.5% (+ d'exportations)
(sum(PROD_C.Import_c(idx_PROD))-sum(PROD_C.Import(idx_PROD)))/abs(sum(PROD_C.Import_c(idx_PROD)))

sum(PROD_C.Import_c(idx_PROD))
abs(sum(PROD_C.Import_c(idx_PROD)))

%HERE! 16 septembre 2021
% Improve last table with reductions by fuel / demand / imports

for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['$',num2str(TARGET(i,j),'%0.2f'),' $'];
    end
end
TABLEVALS

TARGET  = [RESULTS(2).TABLE2_STD(1,1),RESULTS(3).TABLE2_STD(1,1),RESULTS(4).TABLE2_STD(1,1),RESULTS(5).TABLE2_STD(1,1)];
%RESULTS(1).TABLE2_STD(1,1),
for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS2{i,j} = ['$(',num2str(TARGET(i,j),'%0.1f'),') $'];
    end
end


ROWNAMES = {...
    '03/16-03/22',...
    '03/23-03/29',...
    '03/30-04/05',...
    '04/06-04/12',...
    '04/13-04/19',...
    '04/20-04/26',...
    '04/27-05/04',...
    '05/05-05/10',...
    '05/11-05/18',...
    '05/19-05/24',...
    '05/25-05/31','Total'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{6}{D{.}{.}{0}}} \toprule',...
    ' ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '&  \multicolumn{1}{c}{Demand} & \multicolumn{1}{c}{Net Imp.} &\multicolumn{1}{c}{Therm.} & \multicolumn{1}{c}{Nuclear} & \multicolumn{1}{c}{Hydro}   \\ \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5} \cline{6-6}  ',...
    ...
    ];
for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_PRODRED.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);


%% Figure
close all
b0 = find(Y_time>datetime(2020,1,20) & Y_time<=datetime(2020,5,31));
b00 = find(Y_time>datetime(2020,1,20) & Y_time<=datetime(2021,5,31));

for i = 1:5
    Y_LOAD = YYY(:,i);
    Y_CLOAD = YY_hat(:,i);
    
    
    N = 6;
    C = linspecer(N);
    
    b2 = find(Y_time(b0)>=datetime(2020,3,1));
    Y_CLOAD2 = Y_CLOAD;
    Y_CLOAD(b2,:) = Y_LOAD(b2,:);
    
    if i~=4
    figure(i)
    plot(Y_time(b0),smooth(Y_LOAD(b0,1),24*2)/1000,'color',C(2,:),'linewidth',1.8)
    hold on
    y = smooth(Y_CLOAD(b0,1),24*2)/1000;
    y2 = smooth(Y_CLOAD2(b0,1),24*2)/1000;
    plot(Y_time(b0),y2,'-.','color',C(1,:),'linewidth',1.8)    
    plot(Y_time+days(365),smooth(Y_LOAD(:,1),24*2)/1000,':k','linewidth',1.1)
    plot([datetime(2020,3,15) datetime(2020,3,15)],[0 100],':k','color',C(5,:),'linewidth',2)
    plot([datetime(2020,5,11) datetime(2020,5,11)],[0 100],':k','color',C(5,:),'linewidth',2) 
    %plot(Y_time+days(2*365),smooth(Y_LOAD(:,1),48)/1000,':k','linewidth',1.1)
    hold off
    xlim([datetime(2020,2,18) datetime(2020,5,30,10,00,00)])
    else
       figure(i)
    plot(Y_time(b0),smooth(Y_LOAD(b0,1),24*2)/1000,'color',C(2,:),'linewidth',1.8)
    hold on
    y = smooth(Y_CLOAD(b0,1),24*2)/1000;
    y2 = smooth(Y_CLOAD2(b0,1),24*2)/1000;
    plot(Y_time(b0),y2,'-.','color',C(1,:),'linewidth',1.8)    
    plot(Y_time+days(365),smooth(Y_LOAD(:,1),24*2)/1000,':k','linewidth',1)
    plot([datetime(2020,3,15) datetime(2020,3,15)],[0 100],':k','color',C(5,:),'linewidth',2)
    plot([datetime(2020,5,11) datetime(2020,5,11)],[0 100],':k','color',C(5,:),'linewidth',2)
    %plot(Y_time+days(2*365),smooth(Y_LOAD(:,1),48)/1000,':k','linewidth',1.1)
    hold off
    xlim([datetime(2020,2,18) datetime(2020,5,30,10,00,00)])
    end
        
%     figure(i+10)
%     plot(Y_time(b00),smooth(Y_LOAD(b00,1),24*15)/1000,'color',C(2,:),'linewidth',1.1)
%     hold on
%     y = smooth(Y_CLOAD(b00,1),24*15)/1000;
%     y2 = smooth(Y_CLOAD2(b00,1),24*15)/1000;
%     plot(Y_time(b00),y2,'-','color',C(1,:),'linewidth',1.1)    
%     plot(Y_time+days(365),smooth(Y_LOAD(:,1),24*15)/1000,':k','linewidth',1.1)
%     plot([datetime(2020,3,15) datetime(2020,3,15)],[-100 100],'--k','color',C(5,:),'linewidth',1.1)    
%     %plot(Y_time+days(2*365),smooth(Y_LOAD(:,1),48)/1000,':k','linewidth',1.1)
%     hold off
%     xlim([datetime(2020,2,18) datetime(2021,5,30,10,00,00)])
    
    if i==1
        ylim([30 70])
    elseif i==2
        ylim([0 10])
    elseif i==3
        ylim([25 55])
    elseif i==4
        ylim([0 13])
    elseif i==5
        ylim([-15 2])
    end
    
    legend('Actual production','Counterfactual production','Actual production (2019)','Lockdown start/end')
    set(gca,'FontSize',13)
    set(legend,'Location','best')
    ylabel('Generation (GW)')
    %pause
    saveas(i,['RESULTS/FIGURES/plot_prod',num2str(i),'.eps'],'epsc')
end

%%
%%%Histograms
load('PROD_C.mat')
b = find(Y_time>=datetime(2020,1,2) & Y_time<datetime(2020,6,1));
Y = YY;

N = 6;
C = linspecer(N);

Y = YY(:,2);
Yhat = Y_hat(:,2);
figure(1)
%histogram(Y(idxTest1)/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Y(idxTest1)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Yhat(idxTest1)/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Yhat(idxTest1)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual generation','Counterfactual generation')
set(legend,'Location','best')
xlabel('Thermal generation (GW)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_therm_histogram.eps'],'epsc')
idxTest0 = intersect(idxTest0,b);

figure(1)
%histogram(Y(idxTest0(1:end-24))/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Y(idxTest0)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Yhat(idxTest0(1:end-24))/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Yhat(idxTest0)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual generation','Counterfactual generation')
set(legend,'Location','best')
xlabel('Thermal generation (GW)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_therm_histogram_crisis.eps'],'epsc')

Y = YY(:,3);
Yhat = Y_hat(:,3);

figure(1)
%histogram(Y(idxTest1)/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Y(idxTest1)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Yhat(idxTest1)/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Yhat(idxTest1)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual generation','Counterfactual generation')
set(legend,'Location','best')
xlabel('Nuclear generation (GW)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_nuclear_histogram.eps'],'epsc')
idxTest0 = intersect(idxTest0,b);


figure(1)
%histogram(Y(idxTest0)/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Y(idxTest0)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Yhat(idxTest0)/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Yhat(idxTest0)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual generation','Counterfactual generation')
set(legend,'Location','best')
xlabel('Nuclear generation (GW)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_nuclear_histogram_crisis.eps'],'epsc')

load('FRANCE_CO2.mat')
b = find(Emissions_time>=datetime(2020,1,2) & Emissions_time<datetime(2020,6,1));

figure(1)
%histogram(Emissions(idxTest1)/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Emissions(idxTest1)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Emissions_hat(idxTest1)/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Emissions_hat(idxTest1)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual emissions','Counterfactual emissions')
set(legend,'Location','best')
xlabel('Emissions (Kt)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_emissions_histogram.eps'],'epsc')
idxTest0 = intersect(idxTest0,b);

figure(1)
%histogram(Emissions(idxTest0(1:end-24))/1000,100,'FaceColor',C(2,:))
[f,xi] = ksdensity(Emissions(idxTest0)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
%histogram(Emissions_hat(idxTest0(1:end-24))/1000,100,'FaceColor',C(1,:))
[f,xi] = ksdensity(Emissions_hat(idxTest0)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual emissions','Counterfactual emissions')
set(legend,'Location','best')
xlabel('Emissions (Kt)')
ylabel('Density')
saveas(1,['RESULTS/FIGURES/plot_emissions_histogram_crisis.eps'],'epsc')

sum(Emissions(find(Emissions_time>=datetime(2020,3,15) & Emissions_time<datetime(2020,6,1))))/sum(Emissions_hat(find(Emissions_time>=datetime(2020,3,15) & Emissions_time<datetime(2020,6,1))))
sum(Emissions(find(Emissions_time>=datetime(2020,3,15) & Emissions_time<datetime(2020,6,1))))/sum(Emissions(find(Emissions_time>=datetime(2018,3,15) & Emissions_time<datetime(2018,6,1))))
sum(Emissions(find(Emissions_time>=datetime(2020,3,15) & Emissions_time<datetime(2020,6,1))))/sum(Emissions(find(Emissions_time>=datetime(2019,3,15) & Emissions_time<datetime(2019,6,1))))

%% WEATHER VARS SUMMARY

clear
close all
clc

load('WEATHER_FR.mat')

DATA = WEATHER_FR;
clear WEATHER_FR;
DATA(DATA.Time>=datetime(2021,6,1),:) = [];

clear cityname
idx_Dewp = find(contains(DATA.Properties.VariableNames,'Dewpoint')==1);
idx_Temp = find(contains(DATA.Properties.VariableNames,'Temp')==1);
idx_Humi = find(contains(DATA.Properties.VariableNames,'Humi')==1);
idx_Prec = find(contains(DATA.Properties.VariableNames,'Precip')==1);
idx_Pres = find(contains(DATA.Properties.VariableNames,'Pressure')==1);
idx_Visi = find(contains(DATA.Properties.VariableNames,'Visib')==1);
idx_Windg = find(contains(DATA.Properties.VariableNames,'Windgust')==1);
idx_Winds = find(contains(DATA.Properties.VariableNames,'Windspeed')==1);
idx_maxt = find(contains(DATA.Properties.VariableNames,'maxt')==1);
idx_maxd = find(contains(DATA.Properties.VariableNames,'maxd')==1);
idx_mint = find(contains(DATA.Properties.VariableNames,'mint')==1);
idx_mind = find(contains(DATA.Properties.VariableNames,'mind')==1);

CODE = [7015,7110,7130,7149,7157,7222,7480,7481,7510,7630,7643,7650,7747];

for ii=1:length(CODE)
targ = strfind(DATA.Properties.VariableNames{idx_Temp(ii)},num2str(CODE(ii)));
cityname{ii} = DATA.Properties.VariableNames{idx_Temp(ii)}(6+5:end);
end

[~,B] = sort(cityname);
cityname = cityname(B);
CODE = CODE(B);

for ii=1:length(CODE)
b = find(contains(DATA.Properties.VariableNames(idx_Temp),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Temp(b)});
    TARGET2 = std(DATA{:,idx_Temp(b)});
    TABLEVALS1{ii,1} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,1} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,1} = [' . '];
    TABLEVALS2{ii,1} = [' . '];          
end

b = find(contains(DATA.Properties.VariableNames(idx_Dewp),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Dewp(b)});
    TARGET2 = std(DATA{:,idx_Dewp(b)});
    TABLEVALS1{ii,2} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,2} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,2} = [' . '];
    TABLEVALS2{ii,2} = [' . '];          
end

b = find(contains(DATA.Properties.VariableNames(idx_Humi),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Humi(b)});
    TARGET2 = std(DATA{:,idx_Humi(b)});
    TABLEVALS1{ii,3} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,3} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,3} = [' . '];
    TABLEVALS2{ii,3} = [' . '];          
end


b = find(contains(DATA.Properties.VariableNames(idx_Pres),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Pres(b)});
    TARGET2 = std(DATA{:,idx_Pres(b)});
    TABLEVALS1{ii,4} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,4} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,4} = [' . '];
    TABLEVALS2{ii,4} = [' . '];          
end

b = find(contains(DATA.Properties.VariableNames(idx_Prec),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Prec(b)});
    TARGET2 = std(DATA{:,idx_Prec(b)});
    TABLEVALS1{ii,5} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,5} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,5} = [' . '];
    TABLEVALS2{ii,5} = [' . '];          
end


b = find(contains(DATA.Properties.VariableNames(idx_Visi),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Visi(b)});
    TARGET2 = std(DATA{:,idx_Visi(b)});
    TABLEVALS1{ii,6} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,6} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,6} = [' . '];
    TABLEVALS2{ii,6} = [' . '];          
end


b = find(contains(DATA.Properties.VariableNames(idx_Windg),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Windg(b)});
    TARGET2 = std(DATA{:,idx_Windg(b)});
    TABLEVALS1{ii,7} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,7} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,7} = [' . '];
    TABLEVALS2{ii,7} = [' . '];          
end


b = find(contains(DATA.Properties.VariableNames(idx_Winds),num2str(CODE(ii))));
if ~isempty(b)
    cityname
    %var exists for this city
    TARGET1 = mean(DATA{:,idx_Winds(b)});
    TARGET2 = std(DATA{:,idx_Winds(b)});
    TABLEVALS1{ii,8} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii,8} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii,8} = [' . '];
    TABLEVALS2{ii,8} = [' . '];          
end

end

TABLEVALS1;
TABLEVALS2;
cityname(5) = {'Lyon/Satol'};
cityname(9) = {'Paris/CDG'};

%%
load('WEATHER_EUR.mat')
DATA = WEATHER_EUR;
DATA(DATA.Time>=datetime(2021,6,1) | DATA.Time<datetime(2014,1,1),:) = [];
idx_Temp = find(contains(DATA.Properties.VariableNames,'Temp')==1);
DATA = DATA(:,[1 idx_Temp]);
DATA(:,1+find(sum(isnan(DATA{:,2:end}),1)>0)) = [];
DATA.Properties.VariableNames{10} = 'Temp_CH_zurich';

cityname2(1) = {'Turin (IT)'};
cityname2(2) = {'Bologna (IT)'};
cityname2(3) = {'Florence (IT)'};
cityname2(4) = {'Frankfurt (DE)'};
cityname2(5) = {'Berlin (DE)'};
cityname2(6) = {'Alcantaril (ES)'};
cityname2(7) = {'Madrid (ES)'};
cityname2(8) = {'Barcelona (ES)'};
cityname2(9) = {'Zurich (CH)'};
cityname2(10) = {'Geneva (CH)'};
cityname2(11) = {'London (UK)'};
cityname2(12) = {'Shoreham (UK)'};
cityname2(13) = {'Brussels (BE)'};

[~,B] = sort(cityname2);
cityname2 = cityname2(B);
DATA = DATA(:,B+1);


for ii=1:length(cityname2)
b = find(contains(DATA.Properties.VariableNames,lower(cityname2{ii}(1:4))));
b
if ~isempty(b)
    cityname2(ii)
    %var exists for this city
    TARGET1 = mean(DATA{:,b});
    TARGET2 = std(DATA{:,b});
    TABLEVALS1{ii+13,1} = [' ',num2str(TARGET1,'%0.1f'),' '];
    TABLEVALS2{ii+13,1} = [' (',num2str(TARGET2,'%0.1f'),') '];        
else
    %var does not exist for this city
    TABLEVALS1{ii+13,1} = [' . '];
    TABLEVALS2{ii+13,1} = [' . '];          
end
for jj=2:8
   %var does not exist for this city
    TABLEVALS1{ii+13,jj} = [' . '];
    TABLEVALS2{ii+13,jj} = [' . '];  
    
end

end

TABLEVALS1

%%
ROWNAMES = [cityname';cityname2'];
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{16}{D{.}{.}{0}}} \toprule',...
    '  ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '& \multicolumn{2}{c}{Temp.} & \multicolumn{2}{c}{DewP.} & \multicolumn{2}{c}{Humi.} & \multicolumn{2}{c}{Pres.}' ,...
    '& \multicolumn{2}{c}{Prec.} & \multicolumn{2}{c}{Visi.} & \multicolumn{2}{c}{WindG.} & \multicolumn{2}{c}{WindS.} \\ ',...
    ' \cline{2-17} ',...
    ];

for i=1:13
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS1{i,1},' & ',TABLEVALS2{i,1},...
        ' & ',TABLEVALS1{i,2},' & ',TABLEVALS2{i,2},...
        ' & ',TABLEVALS1{i,3},' & ',TABLEVALS2{i,3},...
        ' & ',TABLEVALS1{i,4},' & ',TABLEVALS2{i,4},...
        ' & ',TABLEVALS1{i,5},' & ',TABLEVALS2{i,5},...
        ' & ',TABLEVALS1{i,6},' & ',TABLEVALS2{i,6},...
        ' & ',TABLEVALS1{i,7},' & ',TABLEVALS2{i,7},...
        ' & ',TABLEVALS1{i,8},' & ',TABLEVALS2{i,8},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \midrule '];

for i=14:size(TABLEVALS1,1)
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS1{i,1},' & ',TABLEVALS2{i,1},...
        ' & ',TABLEVALS1{i,2},' & ',TABLEVALS2{i,2},...
        ' & ',TABLEVALS1{i,3},' & ',TABLEVALS2{i,3},...
        ' & ',TABLEVALS1{i,4},' & ',TABLEVALS2{i,4},...
        ' & ',TABLEVALS1{i,5},' & ',TABLEVALS2{i,5},...
        ' & ',TABLEVALS1{i,6},' & ',TABLEVALS2{i,6},...
        ' & ',TABLEVALS1{i,7},' & ',TABLEVALS2{i,7},...
        ' & ',TABLEVALS1{i,8},' & ',TABLEVALS2{i,8},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_WEATHERFR.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%%
load('FRANCE_REGRESSIONS.mat')
DATA = removevars(DATA, {'HCDD','Constant','Mon','Tue','Wed','Thu','Fri','Sat','Hour1','Hour2','Hour3','Hour4','Hour5','Hour6','Hour7','Hour8','Hour9','Hour10','Hour11','Hour12','Hour13','Hour14','Hour15','Hour16','Hour17','Hour18','Hour19','Hour20','Hour21','Hour22','Hour23','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec','Y2019','Y2020','Timetrend','Newyear','Xmas','XmasEve','NewyearEve','Armistice','Bastille','Marie','Toussaint','Paques','Travail','Ascension','Pentecote','Musique','Victoire'});
DATA = removevars(DATA, {'Temp_FR_paris','Temp_IT_turin','Temp_DE_frankfurt','Temp_ES_barcelona','Temp_CH_geneva','Temp_UK_london','Temp_BE_brussels'});
DATA = removevars(DATA, {'Ech_UK','Ech_ES','Ech_IT','Ech_CH','Ech_DEBE'});
DATA(find(DATA.Time>=datetime(2020,3,1)),:) = [];
DATA.Hydraulique = DATA.Hydraulique + DATA.Pompage;
DATA.Pompage = [];
DATA = removevars(DATA, 'Price_FR');
DATA = removevars(DATA, {'naturalgas_price','Q'});
DATA = removevars(DATA, 'PrevisionJ');
DATA = removevars(DATA, 'Echphysiques');
DATA = removevars(DATA, 'Consommation');
DATA = removevars(DATA, 'Nucleaire');
DATA = movevars(DATA, 'Bionergies', 'Before', 'Eolien');
DATA = removevars(DATA, 'NUKE_UCAP_F');

DATA{:,2:end} = DATA{:,2:end}/1000;
DATA.TauxdeCo2 = DATA.TauxdeCo2*1000;

TARGET = [mean(DATA{:,2:end},1)',...
std(DATA{:,2:end},1)',...
quantile(DATA{:,2:end},0.01)',...
quantile(DATA{:,2:end},0.99)'];
clear TABLEVALS
for i=1:size(TARGET,1)
    for j=1:size(TARGET,2)
TABLEVALS{i,j} = [' ',num2str(TARGET(i,j),'%0.2f'),' '];
    end
end
TABLEVALS
ROWNAMES = [...
    {'Demand (F)'    },...
    {'Oil.FR (A)'          },...
    {'Coal.FR (A)'        },...
    {'Nat.Gas.FR (A)'            },...
    {'Biomass.FR (A)'     },...
    {'Wind.FR (A)'         },...
    {'Solar.FR (A)'        },...
    {'Hydro.FR (A)'    },...
    {'Co2rate.FR (A)'      },...
    {'Solar.BE (F)'       },...
    {'WindOff.BE (F)'},...
    {'WindOns.BE (F)' },...
    {'Solar.CH (F)'       },...
    {'WindOns.CH (F)' },...
    {'Solar.DE (F)'       },...
    {'WindOff.DE (F)'},...
    {'WindOn.DE (F)' },...
    {'Solar.ES (F)'       },...
    {'WindOns.ES (F)' },...
    {'Solar.FR (F)'       },...
    {'WindOns.FR (F)' },...
    {'Solar.UK (F)'       },...
    {'WindOff.UK (F)'},...
    {'WindOns.UK (F)' },...
    {'TC.CH.FR'          },...
    {'TC.FR.CH'          },...
    {'TC.ES.FR'          },...
    {'TC.FR.ES'          },...
    {'TC.IT.FR'          },...
    {'TC.FR.IT'          },...
    {'TC.UK.FR'          },...
    {'TC.FR.UK'          },...
    {'Out.Nuclear (Planned)'    },...
    {'Out.Thermal (All)'     },...
    {'Out.Hydro (All)'     }]';

TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{4}{D{.}{.}{0}}} \toprule',...
    '  ',...  %'& \multicolumn{4}{c}{Actual} & \multicolumn{4}{c}{Counterfactual} \\ \hline  ',...
    '& \multicolumn{1}{c}{Mean} & \multicolumn{1}{c}{St. Dev.} & \multicolumn{1}{c}{1st p.} & \multicolumn{1}{c}{99th p.} \\' ,...    
    ' \cline{2-5} ',...
    ];

for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_OTHERVARS.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);