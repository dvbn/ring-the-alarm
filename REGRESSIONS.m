% Import and supply estimation
% Tables + Figures

clear
close all
clc
load('RTE.mat')
load('WEATHER_FR.mat')
load('WEATHER_EUR.mat')
load('RENEWABLE.mat')
load('TRANSFERCAP.mat')
load('NATGAS.mat')
load('SPOTPRICE.mat')
load('OUTAGES.mat')


%% Explanatory variables
DATA = innerjoin(RTE,WEATHER_FR(:,[1 50])); %For regressions
idx_Temp = find(contains(WEATHER_FR.Properties.VariableNames,'Temp')==1);

DATA = innerjoin(RTE,WEATHER_FR(:,[1 50])); %For ATE production% [1 idx_Temp]
DATA = innerjoin(DATA,WEATHER_EUR(:,[1 6 46 86 106 114 133]));

%DATA = removevars(DATA, {'FioulTAC','FioulCogn','FioulAutres','GazTAC','GazCogn','GazCCG','GazAutres','HydrauliqueFil','HydrauliqueLacs','HydrauliqueSTEP','BionergiesDechets','BionergiesBiomass','BionergiesBiogaz'});
DATA(:,{'FioulTAC','FioulCogn','FioulAutres','GazTAC','GazCogn','GazCCG','GazAutres','HydrauliqueFil','HydrauliqueLacs','HydrauliqueSTEP','BionergiesDechets','BionergiesBiomass','BionergiesBiogaz'}) = [];
DATA = innerjoin(DATA,RENEWABLE);
DATA = innerjoin(DATA,TRANSFERCAP);
DATA = innerjoin(DATA,SPOTPRICE);
DATA = innerjoin(DATA,OUTAGES);

DATA = innerjoin(DATA,NATGAS);
%DATA = outerjoin(DATA,NATGAS,'Key','Time');
%DATA(:,'Time_NATGAS') = [];
%DATA.Properties.VariableNames{1} = 'Time';

%DATA = removevars(DATA, {'HYDRO_TCAP','THERM_TCAP','NUKE_TCAP'});
DATA(:,{'HYDRO_TCAP','THERM_TCAP','NUKE_TCAP'}) = [];

RTE = innerjoin(RTE,DATA);

DATA.Q = sum(RTE{:,[5 6 7 11 12 13]},2); %Thermal + Hydro production
DATA.Properties.VariableNames{21} = 'Temp_FR_paris';
DATA.HCDD = abs(DATA.Temp_FR_paris-15.5).^2;

clear WEATHER_FR WEATHER_EUR RENEWABLE TRANSFERCAP NATGAS SPOTPRICE RTE;

Y_time = DATA.Time;
X_hour = dummyvar(hour(Y_time)+1);
X_wday = dummyvar(weekday(Y_time));
X_month = dummyvar(month(Y_time));
X_year = dummyvar(year(Y_time)-min(year(Y_time))+1);
X_time = (1:length(Y_time))';
X_dummies = [ones(length(Y_time),1),X_wday(:,2:end),X_hour(:,2:end),X_month(:,2:end),X_year(:,2:end),X_time/(365*24)]; %keep one 'extra' dummy to act as an intercept
names = {'Constant' 'Mon' 'Tue' 'Wed' 'Thu' 'Fri' 'Sat'  'Hour1' 'Hour2' 'Hour3' 'Hour4' 'Hour5' 'Hour6' 'Hour7' 'Hour8' 'Hour9' 'Hour10' 'Hour11' 'Hour12' 'Hour13' 'Hour14' 'Hour15' 'Hour16' 'Hour17' 'Hour18' 'Hour19' 'Hour20' 'Hour21' 'Hour22'  'Hour23' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec' 'Y2019' 'Y2020' 'Timetrend'};
%names = {'Constant' 'Mon' 'Tue' 'Wed' 'Thu' 'Fri' 'Sat'  'Hour1' 'Hour2' 'Hour3' 'Hour4' 'Hour5' 'Hour6' 'Hour7' 'Hour8' 'Hour9' 'Hour10' 'Hour11' 'Hour12' 'Hour13' 'Hour14' 'Hour15' 'Hour16' 'Hour17' 'Hour18' 'Hour19' 'Hour20' 'Hour21' 'Hour22'  'Hour23' 'Feb' 'Mar' 'Apr' 'May' 'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec' 'Y2019' 'Y2020' 'Y2021' 'Timetrend'};
DUMS = array2table(X_dummies);
DUMS.Properties.VariableNames = names;  
DUMS.Time = DATA.Time;

%Here we keep all holiday dummies and observations
holidays_drop = [2020,1,1;2019,1,1;2018,1,1;2017,1,1;2016,1,1;2015,1,1;2014,1,1; ...
    2020,12,25;2019,12,25;2018,12,25;2017,12,25;2016,12,25;2015,12,25;2014,12,25; ...
    2020,12,24;2019,12,24;2018,12,24;2017,12,24;2016,12,24;2015,12,24;2014,12,24; ...
    2020,12,31;2019,12,31;2018,12,31;2017,12,31;2016,12,31;2015,12,31;2014,12,31; ...
    2020,11,11;2019,11,11;2018,11,11;2017,11,11;2016,11,11;2015,11,11;2014,11,11; ...
    2020,07,14; 2019,07,14; 2018,07,14; 2017,07,14; 2016,07,14; 2015,07,14; 2014,07,14; ...
    2020,08,15; 2019,08,15; 2018,08,15; 2017,08,15; 2016,08,15; 2015,08,15; 2014,08,15; ...
    2020,11,01; 2019,11,01; 2018,11,01; 2017,11,01; 2016,11,01; 2015,11,01; 2014,11,01; ...
    ];

xx = repmat((1:size(holidays_drop,1)/7),7,1);
holidays_drop = [holidays_drop,xx(:)];

holidays_keep = [2020,04,13; 2019,04,22; 2018,04,2; 2017,04,17; 2016,04,28; 2015,04,5; 2014,04,21; ...
    2020,05,01; 2019,05,01; 2018,05,01; 2017,05,01; 2016,05,01; 2015,05,01; 2014,05,01; ...
    2020,05,21; 2019,05,30; 2018,05,10; 2017,05,25; 2016,05,05; 2015,05,14; 2014,05,29; ...
    2020,06,01; 2019,06,09; 2018,05,20; 2017,06,04; 2016,05,16; 2015,05,25; 2014,06,09; ...
    2020,06,21; 2019,06,21; 2018,06,21; 2017,06,21; 2016,06,21; 2015,06,21; 2014,06,21; ...
    2020,05,08; 2019,05,08; 2018,05,08; 2017,05,08; 2016,05,08; 2015,05,08; 2014,05,08];

xx = repmat(8+(1:size(holidays_keep,1)/7),7,1);
holidays_keep = [holidays_drop;holidays_keep,xx(:)];

X_holidays = zeros(length(Y_time),1);

for i=1:length(holidays_keep)
    b_i = find(year(Y_time)==holidays_keep(i,1) & month(Y_time)==holidays_keep(i,2) & day(Y_time)==holidays_keep(i,3));
    X_holidays(b_i,1) = holidays_keep(i,4);
end

X_holidays = dummyvar(X_holidays+1);
X_holidays = X_holidays(:,2:end);

HOLIDAYS = array2table(X_holidays);
HOLIDAYS.Properties.VariableNames = {'Newyear' 'Xmas' 'XmasEve' 'NewyearEve' 'Armistice' 'Bastille' 'Marie' 'Toussaint' 'Paques' 'Travail' 'Ascension' 'Pentecote' 'Musique' 'Victoire'};  
DUMS = [DUMS,HOLIDAYS];
%DUMS = movevars(DUMS, 'Time', 'Before', 'Constant');
DUMS = DUMS(:,[45 1:44 46:end]);
DATA = innerjoin(DATA,DUMS);

clear DUMS b_i holidays_drop HOLIDAYS holidays_drop holidays_keep X_dummies X_holidays X_hour X_month X_time X_wday X_year xx i 

%writetable(DATA,'DATA.txt')


%
idx = find(DATA.Time>=datetime(2019,1,1) & DATA.Time<datetime(2020,1,1) );
645/(sum(DATA.Nucleaire(idx).*DATA.Price_FR(idx))/1e6)
87/(sum(DATA.Hydraulique(idx).*DATA.Price_FR(idx))/1e6)
34/(sum(PET(idx).*DATA.Price_FR(idx))/1e6)
136/(sum(REN(idx).*DATA.Price_FR(idx))/1e6)

PET = DATA.Fioul + DATA.Gaz + DATA.Charbon + DATA.Bionergies;
REN = DATA.Eolien + DATA.Solaire;
%% Regressions

%%%%Clean&prep
TIME = DATA.Time;
ir = 6;
clear B_GMM SE_GMM
b0 = find(TIME<datetime(2020,3,1) & TIME>=datetime(2018,1,1));

Y = DATA.Echphysiques; %Dep var
W = [DATA.WindOnshore_FR./1000]; %IV
Z = DATA.Price_FR; %Endog indep var

%Controls
X = [DATA{:,(21:27)},DATA{:,[(28:38)]},DATA{:,[(40:42)]},DATA{:,[(43:50)]}]; %21:27 = Temps, 28:38 + 40:42 = Renews except Windonshore FR, 43:50 = Transfercaps
X = X./repmat(nanstd(X),size(X,1),1); %standardized
X = [X,DATA{:,[(59:116)]}]; %dummies/constant w/ year dummies

IMPORTS_VARS = {DATA.Properties.VariableNames([(21:38) (40:50)])};

b1 = find(TIME>=datetime(2020,3,1));

SUMMARYSTATS = [Z,Y,DATA.WindOnshore_FR];

%Keep a txt file of used data for estimation
DATA2 = DATA;
DATA2.Echphysiques = DATA.Echphysiques/1000;
DATA2.WindOnshore_FR = DATA.WindOnshore_FR./nanstd(DATA.WindOnshore_FR);
DATA2.Eolien = DATA.Eolien./nanstd(DATA.Eolien);
DATA_REG = DATA2(b0,[1 8,9,14,57,(21:53),(60:116)]);
writetable(DATA_REG,'DATA_REG.txt')
clear DATA2 DATA_REG



%Final data for estimation
XX = [Z(b0,:),X(b0,:)]; %explanatory
ZZ = [W(b0,:),X(b0,:)]; %iv
YY = Y(b0,:)/1000; %dep var
T = length(YY); %sample size
dof = size(W,2)-size(Z,2); %degrees of freedom
xk = size(XX,2); %number of predictors
size(XX) 
NETIMPORT = YY;

%%%%Estimation
RMSE = nan(3,1);

%First-stage
[~,~,~,~,B_FS,COV_FS,~,~,S,nblags] = HAC_GMM(Z(b0,:),ZZ,ZZ,dof);
RMSE(1) = sqrt(mean((ZZ*B_FS-Z(b0,:)).^2));
table(B_FS,sqrt(diag(COV_FS)))

%Least-squares w/o IV estimates
[~,~,~,~,B_LS,COV_LS,~,~,S,nblags] = HAC_GMM(YY,XX,XX,dof);
RMSE(2) = sqrt(mean((XX*B_LS-YY).^2));
table(B_LS,sqrt(diag(COV_LS)))

%Least-squares w/ IV estimates
[B_GMM0,COVB0,B_GMM1,COVB1,B_GMM2,COVB2,Jtest,Jpval,S,nblags] = HAC_GMM(YY,XX,ZZ,dof);

RMSE(3) = sqrt(mean((XX*B_GMM2-YY).^2));
table(B_LS,sqrt(diag(COV_LS)),B_GMM0,B_GMM2,sqrt(diag(COVB2)),sqrt(diag(COVB1)))

%Test of overidentifying restrictions.
table(Jtest,Jpval)

%%%%Predictions & save
XX = [Z,X]; %full sample (including March 2020 to 2021)
Yhat = XX*B_GMM2*1000;
[~,idx0] = setdiff(Y_time,TIME);

%Enforce transfer capacity limits ex-post
LLIM = -(-quantile(DATA.Ech_DEBE,0.01)+DATA.FR_UK+DATA.FR_CH+DATA.FR_ES+DATA.FR_IT);
ULIM = quantile(DATA.Ech_DEBE,0.99)+(DATA.UK_FR+DATA.CH_FR+DATA.ES_FR+DATA.IT_FR);
LLIM(idx0) = [];
ULIM(idx0) = [];

%Store
RESULTS.IMPORT(ir).Y = Y; %actual
RESULTS.IMPORT(ir).Yhat = XX*B_GMM2*1000; %min(max(XX*B_GMM2*1000,LLIM),ULIM); %prediction w/ bounds
RESULTS.IMPORT(ir).Yhat2 = min(max(XX*B_GMM2*1000 + B_GMM2(1)*10*1000,LLIM),ULIM); %prediction if there was a price change +10$

idxb = find(TIME>=datetime(2020,4,1) & TIME<=datetime(2020,5,1));
sum(RESULTS.IMPORT(ir).Yhat(idxb)-RESULTS.IMPORT(ir).Y(idxb))/1000

RESULTS.IMPORT(ir).B_LS = B_LS(1:xk);
RESULTS.IMPORT(ir).SE_LS = sqrt(diag(COV_LS((1:xk),(1:xk))));
RESULTS.IMPORT(ir).B_FS = B_FS(1:xk);
RESULTS.IMPORT(ir).SE_FS = sqrt(diag(COV_FS((1:xk),(1:xk))));
RESULTS.IMPORT(ir).B_GMM = B_GMM2(1:xk);
RESULTS.IMPORT(ir).SE_GMM = sqrt(diag(COVB2((1:xk),(1:xk))));
RESULTS.IMPORT(ir).COV_GMM = COVB2((1:xk),(1:xk));
RESULTS.IMPORT(ir).OBS = T;
RESULTS.IMPORT(ir).RMSE = RMSE;
RESULTS.IMPORT(ir).stdY = std(YY);
RESULTS.IMPORT(ir).Jtest = Jtest;
RESULTS.IMPORT(ir).Jpval = Jpval;

XX = [Z,X];
b = find(TIME>=datetime(2020,1,2) & TIME<datetime(2020,6,1));
price_range = linspace(-50,100,10000);
nI = repmat(X*B_GMM2(2:end),1,10000) + (repmat(price_range,size(X,1),1))*B_GMM2(1);
nI0 = XX*B_GMM2(1:end)*1000;

nI = nI(b,:);
nI0 = nI0(b,:);
plot(nI(1,:),price_range)

% Bounds based on transfer limits
nI = min(max(nI,LLIM(b)/1000),ULIM(b)/1000);
RESULTS.IMPORT(ir).price_range = price_range; %price range for net import function
RESULTS.IMPORT(ir).nI = nI; %net import function accounting for u and l bounds
RESULTS.IMPORT(ir).TIME = TIME(b);
RESULTS.IMPORT(ir).nI0 = nI0;

N = 6;
C = linspecer(N);

figure(1)
[f,xi] = ksdensity(Y(b0)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
[f,xi] = ksdensity(Yhat(b0)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual prices','Predicted netimports')
set(legend,'Location','NorthEast')
xlabel('Price')
ylabel('Density')
set(gca,'FontSize',15)
saveas(1,['RESULTS/FIGURES/plot_importPRED_histogram.eps'],'epsc')

figure(2)
[f,xi] = ksdensity(Y(b1)/1000);
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
[f,xi] = ksdensity(Yhat(b1)/1000);
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual prices','Predicted netimports')
set(legend,'Location','NorthEast')
xlabel('Price')
ylabel('Density')
set(gca,'FontSize',15)
saveas(2,['RESULTS/FIGURES/plot_importPRED_crisis_histogram.eps'],'epsc')


%% Estimate DA function

Y = DATA.Price_FR;
W0 = [DATA.WindOnshore_FR./nanstd(DATA.WindOnshore_FR),DATA.Nucleaire./1000];
W = [DATA.WindOnshore_FR./1000,DATA.NUKE_UCAP_F./1000];

Z = DATA.Q/1000;
Z = [DATA.Q/1000,DATA.Nucleaire/1000];
X = [DATA{:,[(21:27)]},DATA{:,[(28:38)]},DATA{:,[(40:42)]},DATA{:,[(43:50)]}]; %21:27 = Temps, 28:38 + 40:42 = Renews except Windonshore FR, 43:50 = Transfercaps
X = X./repmat(nanstd(X),size(X,1),1); %standardized
X = [DATA.naturalgas_price,X,DATA{:,[(59:116)]}];

DA_VARS = {DATA.Properties.VariableNames([(28:38) (40:50)])};

TIME = DATA.Time;

b0 = find(TIME<=datetime(2020,3,1) & TIME>=datetime(2018,1,1));
SUMMARYSTATS = [DATA.Price_FR,DATA.Echphysiques/1000,DATA.naturalgas_price,DATA.Q/1000,DATA.Nucleaire/1000,DATA.WindOnshore_FR/1000,DATA.NUKE_UCAP_F/1000];
SUMMARYSTATS = SUMMARYSTATS(b0,:);

b1 = find(TIME>=datetime(2020,3,16) & TIME<datetime(2020,6,1));

%Drop vars with too many missings or zero variations
X(:,find(sum(X(b0,:))==0 | sum(X(b0,:))==size(X,1))) = [];
X(:,find(sum(abs(X(b0,:)))==0)) = [];

%Estimation sample
XX = [Z(b0,:),X(b0,:)];
ZZ = [W(b0,:),X(b0,:)];
ZZ0 = [W0(b0,:),X(b0,:)];
YY = Y(b0,:);
T = length(YY);
xk = size(XX,2);
dof = size(W,2)-size(Z,2);

%%%%Estimation
RMSE = nan(3,size(Z,2));

[B_GMM0,COVB0,B_GMM1,COVB1,B_GMM20,COVB20,Jtest,Jpval,S,nblags] = HAC_GMM(YY,XX,ZZ0,dof);
[B_GMM0,COVB0,B_GMM1,COVB1,B_GMM2,COVB2,Jtest,Jpval,S,nblags] = HAC_GMM(YY,XX,ZZ,dof);

B_FS = zeros(size(ZZ,2),size(Z,2));
SE_FS = zeros(size(ZZ,2),size(Z,2));
for ii=1:size(Z,2)
    [~,~,~,~,B0_FS,COV0_FS,~,~,S,nblags] = HAC_GMM(Z(b0,ii),ZZ,ZZ,dof);
    B_FS(:,ii) = B0_FS;
    SE_FS(:,ii) = sqrt(diag(COV0_FS));
    
end


RMSE(1,:) = sqrt(mean((ZZ*B_FS-Z(b0,:)).^2));
RMSE(3,:) = sqrt(mean((XX*B_GMM2-YY).^2));
RMSE(4,:) = sqrt(mean((XX*B_GMM20-YY).^2));

[~,~,~,~,B_LS,COV_LS,~,~,S,nblags] = HAC_GMM(YY,XX,XX,dof);

RMSE(2,:) = sqrt(mean((XX*B_LS-YY).^2));


%First-stage
table(B_FS(1:10,:),SE_FS(1:10,:))

%Least-squares and IV estimates
table(B_LS,sqrt(diag(COV_LS)),B_GMM2,sqrt(diag(COVB2)),B_GMM20,sqrt(diag(COVB20)))

%Test of overidentifying restrictions.
table(Jtest,Jpval)


%Storage
RESULTS.DAM.B_LS = B_LS;
RESULTS.DAM.SE_LS = sqrt(diag(COV_LS)); 
RESULTS.DAM.B_FS = B_FS;
RESULTS.DAM.SE_FS = SE_FS;
RESULTS.DAM.B_GMM = B_GMM2;
RESULTS.DAM.SE_GMM = sqrt(diag(COVB2)) ; 
RESULTS.DAM.B_GMM0 = B_GMM20;
RESULTS.DAM.SE_GMM0 = sqrt(diag(COVB20)) ; 
RESULTS.DAM.COV_GMM = COVB2;
RESULTS.DAM.COV_GMM0 = COVB20; 
RESULTS.DAM.OBS = T;


RESULTS.DAM.RMSE = RMSE;
RESULTS.DAM.stdY = std(YY);
RESULTS.DAM.Jtest = Jtest;
RESULTS.DAM.Jpval = Jpval;

Prod = DATA.Q;
prod_range = linspace(min(Prod),max(Prod),10000);
RESULTS.DAM.prod_range = prod_range;
RESULTS.DAM.TIME = TIME;

table(RESULTS.DAM.B_LS(1:10),...
    RESULTS.DAM.SE_LS(1:10),B_GMM2(1:10),RESULTS.DAM.SE_GMM(1:10))


XX = [Z,X];
Yhat = XX*B_GMM2;


N = 6;
C = linspecer(N);

figure(1)
[f,xi] = ksdensity(Y(b0));
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
[f,xi] = ksdensity(Yhat(b0));
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual prices','Predicted prices')
set(legend,'Location','NorthEast')
xlabel('Price')
ylabel('Density')
set(gca,'FontSize',15)
saveas(1,['RESULTS/FIGURES/plot_pricePRED_histogram.eps'],'epsc')

figure(2)
[f,xi] = ksdensity(Y(b1));
plot(xi,f,'color',C(2,:),'LineWidth',1.1)
hold on
[f,xi] = ksdensity(Yhat(b1));
plot(xi,f,'-.','color',C(1,:),'LineWidth',1.1)
hold off
set(gca,'FontSize',15)
legend('Actual prices','Predicted prices')
set(legend,'Location','NorthEast')
xlabel('Price')
ylabel('Density')
set(gca,'FontSize',15)
saveas(2,['RESULTS/FIGURES/plot_pricePRED_crisis_histogram.eps'],'epsc')


save('FRANCE_REGRESSIONS.mat')

