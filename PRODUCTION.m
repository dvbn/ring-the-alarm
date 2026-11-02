% Generation by sector prediction
% Build figures and tables

clear
close all
clc
load('RTE.mat')
load('WEATHER_FR.mat')
load('WEATHER_EUR.mat')
load('RENEWABLE.mat') 
load('TRANSFERCAP.mat')
load('OUTAGES.mat')

%Some interesting stats about generation by fuel/tech
RTE.DomProd = RTE.Fioul+RTE.Charbon+RTE.Gaz+RTE.Bionergies + RTE.Nucleaire + RTE.Hydraulique  + RTE.Solaire + RTE.Eolien;
RTE.Echphysiques_I = RTE.Echphysiques.*(RTE.Echphysiques>0);
RTE.Echphysiques_X = -RTE.Echphysiques.*(RTE.Echphysiques<0);
RTEy = table2timetable(RTE,'RowTimes',RTE.Time);
RTEy(:,[1 15:33]) = [];
RTEy = retime(RTEy,'yearly','sum');
RTEy = timetable2table(RTEy);
RTEy{:,2:end} = RTEy{:,2:end}/1e6;
% RTEy.RENEW = (RTEy.Hydraulique+RTEy.Eolien+RTEy.Solaire+RTEy.Bionergies)./RTEy.DomProd;
% RTEy.Consommation = RTEy.Consommation./RTEy.DomProd;
% RTEy.Fioul = RTEy.Fioul./RTEy.DomProd;
% RTEy.Charbon = RTEy.Charbon./RTEy.DomProd;
% RTEy.Gaz = RTEy.Gaz./RTEy.DomProd;
% RTEy.Bionergies = RTEy.Bionergies./RTEy.DomProd;
% RTEy.Nucleaire = RTEy.Nucleaire./RTEy.DomProd;
% RTEy.Eolien = RTEy.Eolien./RTEy.DomProd;
% RTEy.Solaire = RTEy.Solaire./RTEy.DomProd;
% RTEy.Hydraulique = RTEy.Hydraulique./RTEy.DomProd;
% RTEy.Pompage = RTEy.Pompage./RTEy.DomProd;
% RTEy.Echphysiques = -RTEy.Echphysiques./RTEy.DomProd;
% RTEy = removevars(RTEy, {'PrevisionJ1','PrevisionJ'});
% RTEy = movevars(RTEy, 'Bionergies', 'Before', 'Nucleaire');
% RTEy = movevars(RTEy, 'Hydraulique', 'Before', 'Eolien');
% RTEy = movevars(RTEy, 'Pompage', 'Before', 'Eolien');
% RTEy = removevars(RTEy, {'Echphysiques','DomProd'});
RTEy

load('RTE.mat')

%% Organize variables

idx_Dewp = find(contains(WEATHER_FR.Properties.VariableNames,'Dewpoint')==1);
idx_Temp = find(contains(WEATHER_FR.Properties.VariableNames,'Temp')==1);
idx_Humi = find(contains(WEATHER_FR.Properties.VariableNames,'Humi')==1);
idx_Prec = find(contains(WEATHER_FR.Properties.VariableNames,'Precip')==1);
idx_Pres = find(contains(WEATHER_FR.Properties.VariableNames,'Pressure')==1);
idx_Visi = find(contains(WEATHER_FR.Properties.VariableNames,'Visib')==1);
idx_Windg = find(contains(WEATHER_FR.Properties.VariableNames,'Windgust')==1);
idx_Winds = find(contains(WEATHER_FR.Properties.VariableNames,'Windspeed')==1);

DATA = innerjoin(RTE,WEATHER_FR(:,[1 idx_Dewp, idx_Humi, idx_Prec, idx_Pres, idx_Temp, idx_Visi, idx_Windg, idx_Winds]));
idx_Temp = find(contains(WEATHER_EUR.Properties.VariableNames,'Temp')==1);
DATA = innerjoin(DATA,WEATHER_EUR(:,[1 idx_Temp]));

clear WEATHER_FR WEATHER_EUR;
DATA = removevars(DATA, {'Consommation','PrevisionJ1','PrevisionJ','Fioul','Charbon','Gaz','Nucleaire','Eolien','Solaire','Hydraulique','Pompage','Bionergies','Echphysiques','TauxdeCo2','Ech_UK','Ech_ES','Ech_IT','Ech_CH','Ech_DEBE','FioulTAC','FioulCogn','FioulAutres','GazTAC','GazCogn','GazCCG','GazAutres','HydrauliqueFil','HydrauliqueLacs','HydrauliqueSTEP','BionergiesDechets','BionergiesBiomass','BionergiesBiogaz'});
DATA = innerjoin(DATA,RENEWABLE);
DATA = innerjoin(DATA,TRANSFERCAP);
DATA = innerjoin(DATA,OUTAGES);
DATA = removevars(DATA, {'HYDRO_TCAP','THERM_TCAP','NUKE_TCAP'});
[b,~] = find(DATA.Time<=datetime(2018,1,1,0,0,0));
DATA(b,:) = [];
RTE = innerjoin(RTE,DATA);
RTE(:,34:end) = [];

DATA(:,1+find(sum(isnan(DATA{:,2:end}),1)>0)) = []; %one var has many missing, drop it!

% Set time and dependent variable
Y = [RTE.Consommation,RTE.Fioul+RTE.Charbon+RTE.Gaz+RTE.Bionergies,RTE.Nucleaire,RTE.Hydraulique+RTE.Pompage,RTE.Echphysiques];
Y_time = DATA.Time; % Time variable


% Time dummies + linear trend
X_hour = dummyvar(hour(Y_time)+1);
X_wday = dummyvar(weekday(Y_time));
X_month = dummyvar(month(Y_time));
X_year = dummyvar(year(Y_time)-2013);
X_time = (1:length(Y_time))';
X_dummies = [X_hour(:,2:end),X_wday(:,2:end),X_month(:,2:end),X_time/(365*24)]; %

% Define holidays
%... to be dropped from sample
holidays_drop = [2020,1,1;2019,1,1;2018,1,1;2017,1,1;2016,1,1;2015,1,1;2014,1,1; ...  %New Year's Day
    2020,12,25;2019,12,25;2018,12,25;2017,12,25;2016,12,25;2015,12,25;2014,12,25; ...  %Xmas
    2020,12,26;2019,12,26;2018,12,26;2017,12,26;2016,12,26;2015,12,26;2014,12,26; ...  %Boxing day
    2020,12,24;2019,12,24;2018,12,24;2017,12,24;2016,12,24;2015,12,24;2014,12,24; ... %Xmas eve
    2020,12,31;2019,12,31;2018,12,31;2017,12,31;2016,12,31;2015,12,31;2014,12,31; ... %New Year's eve
    2020,11,11;2019,11,11;2018,11,11;2017,11,11;2016,11,11;2015,11,11;2014,11,11; ... %Veteran's Day
    2020,07,14; 2019,07,14; 2018,07,14; 2017,07,14; 2016,07,14; 2015,07,14; 2014,07,14; ... %Bastille
    2020,08,15; 2019,08,15; 2018,08,15; 2017,08,15; 2016,08,15; 2015,08,15; 2014,08,15; ... %Marie
    2020,11,01; 2019,11,01; 2018,11,01; 2017,11,01; 2016,11,01; 2015,11,01; 2014,11,01; ... %Toussaint
    ];

xx = repmat((1:size(holidays_drop,1)/7),7,1);
holidays_drop = [holidays_drop,xx(:)];

%... to be kept in sample
holidays_keep = [2020,04,13; 2019,04,22; 2018,04,2; 2017,04,17; 2016,04,28; 2015,04,5; 2014,04,21; ... %Ascension
    2020,05,01; 2019,05,01; 2018,05,01; 2017,05,01; 2016,05,01; 2015,05,01; 2014,05,01; ... %Labor
    2020,05,21; 2019,05,30; 2018,05,10; 2017,05,25; 2016,05,05; 2015,05,14; 2014,05,29; ... %Paques
    2020,06,01; 2019,06,09; 2018,05,20; 2017,06,04; 2016,05,16; 2015,05,25; 2014,06,09; ... %Pentecote
    2020,06,21; 2019,06,21; 2018,06,21; 2017,06,21; 2016,06,21; 2015,06,21; 2014,06,21; ... %Music
    2020,05,08; 2019,05,08; 2018,05,08; 2017,05,08; 2016,05,08; 2015,05,08; 2014,05,08]; %Armistice

xx = repmat((1:size(holidays_keep,1)/7),7,1);
holidays_keep = [holidays_keep,xx(:)];

% Dummies for holidays to be kept
X_holidays = zeros(length(Y_time),1);

for i=1:length(holidays_keep)
    b_i = find(year(Y_time)==holidays_keep(i,1) & month(Y_time)==holidays_keep(i,2) & day(Y_time)==holidays_keep(i,3));
    X_holidays(b_i,1) = holidays_keep(i,4);
end
X_holidays = dummyvar(X_holidays+1);
X_holidays(:,1) = [];

% we will predict all the following, but only keep Thermal + Nuclear (2nd and
% 3rd columns)
Y = [RTE.Consommation,RTE.Fioul+RTE.Charbon+RTE.Gaz+RTE.Bionergies,RTE.Nucleaire,RTE.Hydraulique+RTE.Pompage,RTE.Echphysiques];

% Feature matrix
XX = [table2array(DATA(:,2:end)),RTE.Solaire,RTE.Eolien,X_dummies,X_holidays]; %Features

YY = Y;

% Discard days with holidays outside the period of interest (March-May)
% This is used to prevent bias predictions caused by holidays
for i=1:length(holidays_drop)
    b = find(year(Y_time)==holidays_drop(i,1) & month(Y_time)==holidays_drop(i,2) & day(Y_time)==holidays_drop(i,3));
    YY(b,:) = [];
    Y_time(b) = [];
    XX(b,:) = [];
    RTE(b,:) = [];
end

size(X_dummies)
size(X_holidays)
size(XX)

clear Y b b_i i xx X_dummies X_holidays X_hour X_month X_time X_wday holidays_drop holidays_keep idx*




%% Sample-splitting

rng(1)
b0 = find(Y_time>=min(Y_time) & Y_time<datetime(2020,3,1)); %all observations

LISTS0 = [num2str(year(Y_time(b0))),num2str(month(Y_time(b0))),num2str(day(Y_time(b0)))];

[LISTS1,IC,IA] = unique(cellstr(LISTS0));
perm1 = randperm(length(LISTS1))';
idxtrain = perm1(1:round(length(LISTS1)*0.7));
idxvalid = perm1(round(length(LISTS1)*0.7)+1:round(length(LISTS1)*0.9));
idxtest = perm1(round(length(LISTS1)*0.9)+1:end);
% perm1 = (1:length(LISTS1))';
% idxtrain = perm1(1:round(length(LISTS1)*0.7));
% idxvalid = perm1(round(length(LISTS1)*0.7)+1:round(length(LISTS1)*0.9));
% idxtest = perm1(round(length(LISTS1)*0.9)+1:end);
% LISTS1(idxtest)


traintestvalid_id = zeros(length(LISTS1),3);
traintestvalid_id(idxtrain,1) = 1;
traintestvalid_id(idxtest,2) = 1;
traintestvalid_id(idxvalid,3) = 1;

idxTrain = find(traintestvalid_id(IA,1)==1);
idxTest = find(traintestvalid_id(IA,2)==1);
idxValid = find(traintestvalid_id(IA,3)==1);

idxTrain = sort(idxTrain);
idxValid = sort(idxValid);
idxTest = sort([idxTest;find(Y_time>=datetime(2020,3,1))]);
idxTest0 = find(Y_time>=datetime(2020,3,1));
%
length(idxTrain);
length(idxValid);
length(find(Y_time>datetime(2020,3,1)));
length(idxTest);

% Set Train-Validation set (cross-fitting) 
nCrossFit = 10;
ndays = length(idxtrain)+length(idxvalid)+length(idxtest);
C_holdout = cvpartition(ndays, 'HoldOut', length(idxtest)/ndays); % ~22%
C_crossval = cvpartition(C_holdout.TrainSize, 'KFold', nCrossFit);

% Set Testing set
testDay = find(C_holdout.test);

% Initialize cellArray for Cross-Fitting split
trainInd = cell(nCrossFit,1);
valInd = cell(nCrossFit,1);

idxdays = sort([idxtrain;idxvalid]);

% Set Train-Validation sets

for k=1:nCrossFit
    idxtrain = idxdays(C_crossval.training(k));
    idxvalid = idxdays(C_crossval.test(k));
    
    traintestvalid_id = zeros(length(LISTS1),3);
    traintestvalid_id(idxtrain,1) = 1;
    traintestvalid_id(idxtest,2) = 1;
    traintestvalid_id(idxvalid,3) = 1;
    
    idxTrain = find(traintestvalid_id(IA,1)==1);
    idxValid = find(traintestvalid_id(IA,3)==1);
    
    trainInd{k} = sort(idxTrain);
    valInd{k} = sort(idxValid);
end

%%

close all
clear net
net = feedforwardnet(5);
idxTest1 = setdiff(idxTest,idxTest0);
YYY = YY;
rng(1)
Y_hat = YYY*nan;
Y_hat2 = YYY*nan;
for i=1:5
    XXX = XX;
    i
    
    YY_hat = nan(size(YY,1),nCrossFit);
    for k=1:nCrossFit
    net = configure(net,XXX(:,:)',YYY(:,i)');
    net.trainFcn = 'trainlm';
    net.performFcn = 'mse';
    net.performParam.normalization = 'standard';
    net.trainParam.max_fail = 10;
    net.divideFcn = 'divideind';
    net.divideParam.trainInd = trainInd{k}; %idxTrain;
    net.divideParam.valInd = valInd{k}; %idxTrain;
    net.divideParam.testInd = idxTest;
    [net,TR] = train(net,XXX(:,:)',YYY(:,i)');
    Y_hat2(:,i) = net(XXX(:,:)')';
    YY_hat(:,k) = Y_hat2(:,i);    
    
    end
    Y_hat(:,i) = median(YY_hat,2);
    
     std((Y_hat(idxTest1,i)/1000-YYY(idxTest1,i)/1000))
     %std((Y_hat(idxTest1,i)-YYY(idxTest1,i)))
%     median(abs(Y_hat(idxTest1,i)-YYY(idxTest1,i)))
     sqrt(mean((Y_hat(idxTest1,i)/1000-YYY(idxTest1,i)/1000).^2))
%     mean(abs(Y_hat(idxTest1,i)-YYY(idxTest1,i))./Y_hat(idxTest1,i))
    
% figure(i)
%     plot(Y_time,smooth(YYY(:,i),24),'LineWidth',2)
%     hold on
%     plot(Y_time,smooth(Y_hat(:,i),24),'LineWidth',2)
%     for k=1:nCrossFit
%       plot(Y_time,smooth(YY_hat(:,k),24),'--k')  
%     end
%     hold off
%     xlim([datetime(2020,3,1) datetime(2020,6,1)])
%     
%     
%     figure(i+10)
%     plot(Y_time,smooth(YYY(:,i)-Y_hat(:,i),24*5)/1000,'LineWidth',1.1)
%     hold on
%     xlim([datetime(2020,1,1) datetime(2020,6,1)])
%     load('FRANCE_DEMAND.mat','Y')
%     plot(Y.Time,smooth(Y.Var3,24*5)/1000,'LineWidth',1.1)
%     hold off
%     xlim([datetime(2020,1,1) datetime(2020,6,1)])

    %pause
 
end


%%

close all

PROD_C = struct;
PROD_C.Time_c = RTE.Time;
PROD_C.Conso = YY(:,1);
PROD_C.Conso_c = Y_hat(:,1);
PROD_C.Thermal = YY(:,2);
PROD_C.Thermal_c = Y_hat(:,2);
PROD_C.Nuke = YY(:,3);
PROD_C.Nuke_c = Y_hat(:,3);
PROD_C.Hydro = YY(:,4);
PROD_C.Hydro_c = Y_hat(:,4);
PROD_C.Renew = (RTE.Solaire+RTE.Eolien)/1000;
PROD_C.Import = YY(:,5);
PROD_C.Import_c = Y_hat(:,5);
PROD_C.idxTrain = idxTrain;
PROD_C.idxValid = idxValid;
PROD_C.idxTest = idxTest;

%As a share of total domestic production
PROD_C.Thermal_perc = (YY(:,2))./(sum(YY(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Nuke_perc = (YY(:,3))./(sum(YY(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Hydro_perc = (YY(:,4))./(sum(YY(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Ren_perc = (RTE.Solaire+RTE.Eolien)./(sum(YY(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Thermal_perc_c = (Y_hat(:,2))./(sum(Y_hat(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Nuke_perc_c = (Y_hat(:,2))./(sum(Y_hat(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Hydro_perc_c = (Y_hat(:,2))./(sum(Y_hat(:,2:4),2)+RTE.Solaire+RTE.Eolien);
PROD_C.Ren_perc_c = (RTE.Solaire+RTE.Eolien)./(sum(Y_hat(:,2:4),2)+RTE.Solaire+RTE.Eolien);

save('PROD_C.mat');


