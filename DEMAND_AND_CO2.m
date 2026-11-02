% Demand and CO2 emissions prediction
% Build figures and tables




clear
close all
clc
load('RTE.mat')
load('WEATHER_FR.mat')

%% Organize variables
DATA = innerjoin(RTE,WEATHER_FR);
clear RTE WEATHER_FR;

% Set time and dependent variable
Y = DATA.Consommation; % Realized Demand
Y_time = DATA.Time; % Time variable

% Time dummies + linear trend
X_hour = dummyvar(hour(Y_time)+1);
X_wday = dummyvar(weekday(Y_time));
X_month = dummyvar(month(Y_time));
X_time = (1:length(Y_time))';
X_dummies = [X_hour(:,2:end),X_wday(:,2:end),X_month(:,2:end),X_time/(365*24)]; %keep one 'extra' dummy to act as an intercept

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


% Feature matrix
XX = [table2array(DATA(:,[idx_Dewp, idx_Humi, idx_maxd, idx_maxt, idx_mind, idx_mint, idx_Prec, idx_Pres, idx_Temp, idx_Visi, idx_Windg, idx_Winds])),X_dummies,X_holidays]; %Features

YY = log(DATA.Consommation); %Dependent var (log demand)
YY_fload = log(DATA.PrevisionJ1); %Forecast (log forecast demand Day-1)

% Discard days with holidays outside the period of interest (March-May)
% This is used to prevent bias predictions caused by holidays
for i=1:length(holidays_drop)
    b = find(year(Y_time)==holidays_drop(i,1) & month(Y_time)==holidays_drop(i,2) & day(Y_time)==holidays_drop(i,3));
    YY(b) = [];
    YY_fload(b) = [];
    Y_time(b) = [];
    XX(b,:) = [];
end

size(X_dummies)
size(X_holidays)
size(XX) 
size(idx_Dewp)
size(idx_Temp)
size([idx_maxd, idx_maxt, idx_mind, idx_mint]) %43

clear Y b b_i i xx X_dummies X_holidays X_hour X_month X_time X_wday holidays_drop holidays_keep idx*

%% Sample-splitting
% Split observations by days, then allocate randomly each day to train/test/valid
% samples

rng(1)
b0 = find(Y_time>=min(Y_time) & Y_time<datetime(2020,3,1)); %all observations

LISTS0 = [num2str(year(Y_time(b0))),num2str(month(Y_time(b0))),num2str(day(Y_time(b0)))];
[LISTS1,IC,IA] = unique(cellstr(LISTS0));
perm1 = randperm(length(LISTS1))';
idxtrain = perm1(1:round(length(LISTS1)*0.7));
idxvalid = perm1(round(length(LISTS1)*0.7)+1:round(length(LISTS1)*0.9));
idxtest = perm1(round(length(LISTS1)*0.9)+1:end);

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

%# of observations for training/validation
length(idxTrain) + length(idxValid)

%rest of sample (test + post march 2020 period)
length(find(Y_time>datetime(2020,3,1)))
length(idxTest)

% Set Train-Validation set (cross-fitting) 
nCrossFit = 10;
ndays = length(idxtrain)+length(idxvalid)+length(idxtest);
C_holdout = cvpartition(ndays, 'HoldOut', length(idxtest)/ndays); % ~10%
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

%% Neural network

YY_hat = nan(size(YY,1),nCrossFit);
% Configure the neural net
for k=1:nCrossFit
net = feedforwardnet(5);
net = configure(net,XX',YY');
net.trainFcn = 'trainlm';
net.performFcn = 'mse';
net.divideFcn = 'divideind';
net.divideParam.trainInd = trainInd{k}; %idxTrain;
net.divideParam.valInd = valInd{k}; %idxValid;
net.divideParam.testInd = idxTest;
net.trainParam.max_fail = 10;
[net,TR] = train(net,XX',YY');

% Predict
Y_hat = net(XX')';
YY_hat(:,k) = exp(Y_hat);
mean(Y_hat);
end

YY = exp(YY);
YY_fload = exp(YY_fload);


Y_hat = median(YY_hat,2);

%% Some stats and save results

idxTest1 = setdiff(idxTest,idxTest0); %test set w/o post-lockdown period


mean(abs(Y_hat(idxTest1)-YY(idxTest1))./YY(idxTest1)) %MAPE FNET
mean(abs(DATA.PrevisionJ1-DATA.Consommation)./DATA.Consommation) %MAPE RTE

sqrt(mean((Y_hat(idxTest1)/1000-YY(idxTest1)/1000).^2)) %RMSE FNET
sqrt(mean((DATA.PrevisionJ1(idxTest1)/1000-DATA.Consommation(idxTest1)/1000).^2)) %RMSE RTE


plot(Y_time,smooth(YY,24*7),'LineWidth',2)
hold on
plot(Y_time+days(365),smooth(YY,24*7),'--')
plot(Y_time+days(2*365),smooth(YY,24*7),':')
for k=1:nCrossFit
plot(Y_time,smooth(YY_hat(:,k),24*7))
end
plot(Y_time,smooth(median(YY_hat,2),24*7),'LineWidth',2)
hold off
xlim([datetime(2020,2,1) datetime(2021,7,1)])

Y = timetable(YY,median(YY_hat,2),YY-median(YY_hat,2),'RowTimes',Y_time);
Ym = retime(Y,'monthly','mean');

plot(Ym.Time,Ym.Var3)


save('FRANCE_DEMAND.mat')



%% CO2 emissions
clear
close all
clc
load('RTE.mat')
load('WEATHER_FR.mat')
load('WEATHER_EUR.mat')
load('RENEWABLE.mat') 
load('TRANSFERCAP.mat')
load('OUTAGES.mat')



%% Organize variables
idx_Dewp = find(contains(WEATHER_FR.Properties.VariableNames,'Dewpoint')==1);
idx_Temp = find(contains(WEATHER_FR.Properties.VariableNames,'Temp')==1);
idx_Humi = find(contains(WEATHER_FR.Properties.VariableNames,'Humi')==1);
idx_Prec = find(contains(WEATHER_FR.Properties.VariableNames,'Precip')==1);
idx_Pres = find(contains(WEATHER_FR.Properties.VariableNames,'Pressure')==1);
idx_Visi = find(contains(WEATHER_FR.Properties.VariableNames,'Visib')==1);
idx_Windg = find(contains(WEATHER_FR.Properties.VariableNames,'Windgust')==1);
idx_Winds = find(contains(WEATHER_FR.Properties.VariableNames,'Windspeed')==1);

DATA = innerjoin(RTE,WEATHER_FR(:,[1, idx_Dewp, idx_Humi, idx_Prec, idx_Pres, idx_Temp, idx_Visi, idx_Windg, idx_Winds]));

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

DATA(:,1+find(sum(isnan(DATA{:,2:end}),1)>0)) = [];

% Set time and dependent variable
Y = RTE.TauxdeCo2.*RTE.Consommation/1000; % CO2 emissions
Y_time = DATA.Time; % Time variable

% Time dummies + linear trend
X_hour = dummyvar(hour(Y_time)+1);
X_wday = dummyvar(weekday(Y_time));
X_month = dummyvar(month(Y_time));
X_time = (1:length(Y_time))';
X_dummies = [X_hour(:,2:end),X_wday(:,2:end),X_month(:,2:end),X_time/(365*24)]; %keep one 'extra' dummy to act as an intercept

% Define holidays
% ... to be dropped from sample
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

% ... to be kept in sample
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


% Feature matrix
XX = [table2array(DATA(:,2:end)),RTE.Solaire,RTE.Eolien,X_dummies,X_holidays]; %Features

YY = log(Y);

% Discard days with holidays outside the period of interest (March-May)
% This is used to prevent bias predictions caused by holidays
for i=1:length(holidays_drop)
    b = find(year(Y_time)==holidays_drop(i,1) & month(Y_time)==holidays_drop(i,2) & day(Y_time)==holidays_drop(i,3));
    YY(b) = [];
    Y_time(b) = [];
    XX(b,:) = [];
    RTE(b,:) = [];
end

size(X_dummies)
size(X_holidays)
size(XX)


clear Y b b_i i xx X_dummies X_holidays X_hour X_month X_time X_wday holidays_drop holidays_keep idx*


%% Sample-splitting
% Same as for demand

rng(1)
b0 = find(Y_time>=min(Y_time) & Y_time<datetime(2020,3,1)); %all observations

LISTS0 = [num2str(year(Y_time(b0))),num2str(month(Y_time(b0))),num2str(day(Y_time(b0)))];
[LISTS1,IC,IA] = unique(cellstr(LISTS0));
perm1 = randperm(length(LISTS1))';
idxtrain = perm1(1:round(length(LISTS1)*0.7));
idxvalid = perm1(round(length(LISTS1)*0.7)+1:round(length(LISTS1)*0.9));
idxtest = perm1(round(length(LISTS1)*0.9)+1:end);

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

%# of observations for training/validation
length(idxTrain) + length(idxValid)

%rest of sample (test + post march 2020 period)
length(find(Y_time>datetime(2020,3,1)))
length(idxTest)

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
day_train_index = find(C_holdout.training);
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

    
%% Neural network CO2

% Same as for demand
Emissions_hat = nan(size(YY,1),nCrossFit);
YY_hat = nan(size(YY,1),nCrossFit);
for k=1:nCrossFit
net = feedforwardnet(5);
net = configure(net,XX',YY');
net.trainFcn = 'trainlm';
net.performFcn = 'mse';
net.divideFcn = 'divideind';
net.divideParam.trainInd = trainInd{k}; %idxTrain;
net.divideParam.valInd = valInd{k}; %idxValid;
net.divideParam.testInd = idxTest;
net.trainParam.max_fail = 10;
[net,TR] = train(net,XX',YY');
Y_hat = net(XX')';

Emissions = exp(YY);
Emissions_hat(:,k) = exp(Y_hat);
YY_hat(:,k) = Y_hat;
Emissions_time = Y_time;
end

Y_hat = median(YY_hat,2);

% Quick check at the results
idxTest1 = setdiff(idxTest,idxTest0);
histogram( Emissions(idxTest1))
hold on
histogram(Emissions_hat(idxTest1) )
hold off
%close all

plot(Emissions_time,smooth(Emissions,72),'LineWidth',2)
hold on
plot(Emissions_time+days(365),smooth(Emissions,72),'--')
plot(Emissions_time+days(2*365),smooth(Emissions,72),':')
for k=1:nCrossFit
plot(Emissions_time,smooth(Emissions_hat(:,k),72))
end
plot(Emissions_time,smooth(median(Emissions_hat,2),72),'LineWidth',2)
hold off
xlim([datetime(2020,1,1) datetime(2021,7,1)])

Emissions_hat = median(Emissions_hat,2);
% Pred performance
mean(abs(Emissions_hat(idxTest1)-Emissions(idxTest1))./Emissions(idxTest1)) %MAPE FNET
std(Emissions_hat(idxTest1)-Emissions(idxTest1)) %STD FNET
sqrt(mean((Emissions_hat(idxTest1)/1000-Emissions(idxTest1)/1000).^2)) %RMSE FNET

save('FRANCE_CO2.mat')

idx = find(Emissions_time>=datetime(2020,3,16) & Emissions_time<=datetime(2020,6,1));
(sum(Emissions_hat(idx)) - sum(Emissions(idx)))./...
sum(Emissions_hat(idx))
%  28.5 reduction w/ respect to predicted counterfactual emissions
sum(RTE.Consommation(idx))

idx2 = find(Emissions_time>=datetime(2019,3,16) & Emissions_time<=datetime(2019,6,1));
(sum(Emissions(idx2)) - sum(Emissions(idx)))./...
sum(Emissions(idx2))
% 42% reduction w/ respect to 2019 observed emissions
sum(RTE.Consommation(idx2))

idx2 = find(Emissions_time>=datetime(2018,3,16) & Emissions_time<=datetime(2018,6,1));
(sum(Emissions(idx2)) - sum(Emissions(idx)))./...
sum(Emissions(idx2))
% 43% reduction w/ respect to 2018 observed emissions
sum(RTE.Consommation(idx2))

%% RESULTS for CO2 emissions
clear
clc
load('FRANCE_CO2.mat')
YY =exp(YY);
Y_hat =exp(Y_hat);

YY = YY/1000;
Y_hat = Y_hat/1000;

zone = 1;
sqrt(mean((YY(idxValid)-Y_hat(idxValid)).^2))

TABLE1 = zeros(1,26);
TABLE2_EST = zeros(1,14);
TABLE2_PER = zeros(1,14);
TABLE3_EST = zeros(1,8);
TABLE4_EST = zeros(1,8);
TABLE2_STD = zeros(1,14);
TABLE3_STD = zeros(1,8);
TABLE4_STD = zeros(1,8);

RMSPE = zeros(12,2);
OBS = zeros(12,4);

idxTestb = idxTest1; %all observations);

%%%%Prediction performance
histogram(YY(idxTestb)-Y_hat(idxTestb),100)
hold on
histogram(YY(idxTest0)-Y_hat(idxTest0),100)
hold off

BIAS(zone,1) = nanmean(YY(idxTestb)-Y_hat(idxTestb));
ABSBIAS(zone,1) = nanmean(abs(YY(idxTestb)-Y_hat(idxTestb))./YY(idxTestb));
STD(zone,1) = nanstd(YY(idxTestb)-Y_hat(idxTestb));
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

b0 = find(listdays<datetime('1-Mar-2020'));
b1 = find(listdays>=datetime('1-Mar-2020'));
b2 = find(listdays>=datetime('15-Mar-2020'));

% Covariances and hourly std
COV_U = nancov(Yd(:,b0)'-Yd_hat(:,b0)');
COV_Uf = nancov(Yd(:,b0)'-Yd_f(:,b0)');

hour_std = diag(sqrt(COV_U));
hourf_std = diag(sqrt(COV_Uf));

%How has demand changed?
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
    WALD_df(i) = length(hourly_idx);
    
    meanYhat(i) = sum((Yd_hat(hourly_idx,i)));
    
    meandiff(i) = sum((Yd(hourly_idx,i)-Yd_hat(hourly_idx,i)));
    std_diff(i) = sqrt(sum(sum(COV_U(hourly_idx,hourly_idx))));
    std_diff_f(i) = sqrt(sum(sum(COV_Uf(hourly_idx,hourly_idx))));
    
    meanhour(hourly_idx,i) = (Yd(hourly_idx,i)-Yd_hat(hourly_idx,i));
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
TABLE2_EST(zone,:) = [sumh(1:14)'];
TABLE2_STD(zone,:) = [sumh_std(1:14)'];
TABLE2_PER(zone,:) = sumh(1:14)./sumhat(1:14);

for i=1:14
    b = find(weekid==i+9 & weekday(Date)~=7 & weekday(Date)~=1 );
    meanh(:,i) = nanmean(meanhour(:,b),2);
    meanhf(:,i) = nanmean(meanhour_f(:,b),2);
    meanhat(:,i) = nanmean(Yd_hat(:,b),2);
    meany(:,i) = nanmean(Yd(:,b),2);
    
    sumh(i,1) = nansum(nansum(meanhour(:,b),2));
    sumhf(i,1) = nansum(nansum(meanhour_f(:,b),2));
    sumh_std(i,1) = sqrt(nansum(std_diff(b).^2));
    sumhf_std(i,1) = sqrt(nansum(std_diff_f(b).^2));
end

%%%%Table3: Daily patterns change
TABLE3_EST(zone,:) = [nansum(meanh([1:6,23:24],3),1)./nansum(meanhat([1:6,23:24],3),1),...
    nansum(meanh([7:12],3),1)./nansum(meanhat([7:12],3),1),...
    nansum(meanh([13:18],3),1)./nansum(meanhat([13:18],3),1),...
    nansum(meanh([19:22],3),1)./nansum(meanhat([19:22],3),1),...
    mean(nansum(meanh([1:6,23:24],4:9),1))./mean(nansum(meanhat([1:6,23:24],4:9),1)),...
    mean(nansum(meanh([7:12],4:9),1))./mean(nansum(meanhat([7:12],4:9),1)),...
    mean(nansum(meanh([13:18],4:9),1))./mean(nansum(meanhat([13:18],4:9),1)),...
    mean(nansum(meanh([19:22],4:9),1))./mean(nansum(meanhat([19:22],4:9),1)),...
    ];
derivvec1 = repmat((-nansum(meanhat([1:6,23:24],3),1)-nansum(meanh([1:6,23:24],3),1))./nansum(meanhat([1:6,23:24],3),1).^2,length([1:6,23:24]),1);
derivvec2 = repmat((-nansum(meanhat([7:12],3),1)-nansum(meanh([7:12],3),1))./nansum(meanhat([7:12],3),1).^2,length(7:12),1);
derivvec3 = repmat((-nansum(meanhat([13:18],3),1)-nansum(meanh([13:18],3),1))./nansum(meanhat([13:18],3),1).^2,length([13:18]),1);
derivvec4 = repmat((-nansum(meanhat([19:22],3),1)-nansum(meanh([19:22],3),1))./nansum(meanhat([19:22],3),1).^2,length([19:22]),1);

derivvec5 = repmat((-mean(nansum(meanhat([1:6,23:24],4:9),1))-mean(nansum(meanh([1:6,23:24],4:9),1)))./mean(nansum(meanhat([1:6,23:24],4:9),1)).^2,length([1:6,23:24]),1);
derivvec6 = repmat((-mean(nansum(meanhat([7:12],4:9),1))-mean(nansum(meanh([7:12],4:9),1)))./mean(nansum(meanhat([7:12],4:9),1)).^2,length([7:12]),1);
derivvec7 = repmat((-mean(nansum(meanhat([13:18],4:9),1))-mean(nansum(meanh([13:18],4:9),1)))./mean(nansum(meanhat([13:18],4:9),1)).^2,length([13:18]),1);
derivvec8 = repmat((-mean(nansum(meanhat([19:22],4:9),1))-mean(nansum(meanh([19:22],4:9),1)))./mean(nansum(meanhat([19:22],4:9),1)).^2,length([19:22]),1);


TABLE3_STD(zone,:) = [sqrt(1/6*derivvec1'*COV_U([1:6,23:24],[1:6,23:24])*derivvec1),...
    sqrt(1/6*derivvec2'*COV_U([7:12],[7:12])*derivvec2),...
    sqrt(1/6*derivvec3'*COV_U([13:18],[13:18])*derivvec3),...
    sqrt(1/6*derivvec4'*COV_U([19:22],[19:22])*derivvec4),...
    sqrt(1/6*derivvec5'*COV_U([1:6,23:24],[1:6,23:24])*derivvec5),...
    sqrt(1/6*derivvec6'*COV_U([7:12],[7:12])*derivvec6),...
    sqrt(1/6*derivvec7'*COV_U([13:18],[13:18])*derivvec7),...
    sqrt(1/6*derivvec8'*COV_U([19:22],[19:22])*derivvec8),...
    ];

%%%%Table4: Same but for weekends
for i=1:14
    b = find(weekid==i+9);
    bb = find(weekday(Date)==1 | weekday(Date)==7);
    b = intersect(b,bb);
    meanh(:,i) = nanmean(meanhour(:,b),2);
    meanhf(:,i) = nanmean(meanhour_f(:,b),2);
    meanhat(:,i) = nanmean(Yd_hat(:,b),2);
    meany(:,i) = nanmean(Yd(:,b),2);
end

TABLE4_EST(zone,:) = [nansum(meanh([1:6,23:24],3),1)./nansum(meanhat([1:6,23:24],3),1),...
    nansum(meanh([7:12],3),1)./nansum(meanhat([7:12],3),1),...
    nansum(meanh([13:18],3),1)./nansum(meanhat([13:18],3),1),...
    nansum(meanh([19:22],3),1)./nansum(meanhat([19:22],3),1),...
    mean(nansum(meanh([1:6,23:24],4:9),1))./mean(nansum(meanhat([1:6,23:24],4:9),1)),...
    mean(nansum(meanh([7:12],4:9),1))./mean(nansum(meanhat([7:12],4:9),1)),...
    mean(nansum(meanh([13:18],4:9),1))./mean(nansum(meanhat([13:18],4:9),1)),...
    mean(nansum(meanh([19:22],4:9),1))./mean(nansum(meanhat([19:22],4:9),1)),...
    ];
derivvec1 = repmat((-nansum(meanhat([1:6,23:24],3),1)-nansum(meanh([1:6,23:24],3),1))./nansum(meanhat([1:6,23:24],3),1).^2,length([1:6,23:24]),1);
derivvec2 = repmat((-nansum(meanhat([7:12],3),1)-nansum(meanh([7:12],3),1))./nansum(meanhat([7:12],3),1).^2,length(7:12),1);
derivvec3 = repmat((-nansum(meanhat([13:18],3),1)-nansum(meanh([13:18],3),1))./nansum(meanhat([13:18],3),1).^2,length([13:18]),1);
derivvec4 = repmat((-nansum(meanhat([19:22],3),1)-nansum(meanh([19:22],3),1))./nansum(meanhat([19:22],3),1).^2,length([19:22]),1);

derivvec5 = repmat((-mean(nansum(meanhat([1:6,23:24],4:9),1))-mean(nansum(meanh([1:6,23:24],4:9),1)))./mean(nansum(meanhat([1:6,23:24],4:9),1)).^2,length([1:6,23:24]),1);
derivvec6 = repmat((-mean(nansum(meanhat([7:12],4:9),1))-mean(nansum(meanh([7:12],4:9),1)))./mean(nansum(meanhat([7:12],4:9),1)).^2,length([7:12]),1);
derivvec7 = repmat((-mean(nansum(meanhat([13:18],4:9),1))-mean(nansum(meanh([13:18],4:9),1)))./mean(nansum(meanhat([13:18],4:9),1)).^2,length([13:18]),1);
derivvec8 = repmat((-mean(nansum(meanhat([19:22],4:9),1))-mean(nansum(meanh([19:22],4:9),1)))./mean(nansum(meanhat([19:22],4:9),1)).^2,length([19:22]),1);


TABLE4_STD(zone,:) = [sqrt(1/8*derivvec1'*COV_U([1:6,23:24],[1:6,23:24])*derivvec1),...
    sqrt(1/6*derivvec2'*COV_U([7:12],[7:12])*derivvec2),...
    sqrt(1/6*derivvec3'*COV_U([13:18],[13:18])*derivvec3),...
    sqrt(1/6*derivvec4'*COV_U([19:22],[19:22])*derivvec4),...
    sqrt(1/6*derivvec5'*COV_U([1:6,23:24],[1:6,23:24])*derivvec5),...
    sqrt(1/6*derivvec6'*COV_U([7:12],[7:12])*derivvec6),...
    sqrt(1/6*derivvec7'*COV_U([13:18],[13:18])*derivvec7),...
    sqrt(1/6*derivvec8'*COV_U([19:22],[19:22])*derivvec8),...
    ];


RTE2 = RTE;

TABLE1_CO2 = TABLE1;
TABLE1_ABSBIAS_CO2 = TABLE1_ABSBIAS;
TABLE1_RMSPE_CO2 = TABLE1_RMSPE;
TABLE2_EST_CO2 = TABLE2_EST;
TABLE2_PER_CO2 = TABLE2_PER;
TABLE2_STD_CO2 = TABLE2_STD;

YY_CO2 = YY;
Y_hat_CO2 = Y_hat;
Y_time_CO2 = Y_time;

%% RESULTS LOAD
load('FRANCE_DEMAND.mat')

% idx = find(Y_time>=datetime(2020,3,16) & Y_time<=datetime(2020,6,1));
% (sum(Y_hat(idx)) - sum(YY(idx)))./...
% sum(Y_hat(idx))
% % 12% reduction w/ respect to predicted counterfactual emissions
% 
% idx2 = find(Y_time>=datetime(2019,3,16) & Y_time<=datetime(2019,6,1));
% (sum(YY(idx2)) - sum(YY(idx)))./...
% sum(YY(idx2))
% % 15% reduction w/ respect to 2019 observed emissions
% 
% 
% idx2 = find(Y_time>=datetime(2018,3,16) & Y_time<=datetime(2018,6,1));
% (sum(YY(idx2)) - sum(YY(idx)))./...
% sum(YY(idx2))
% % 15% reduction w/ respect to 2018 observed emissions

zone = 1;
sqrt(mean((YY(idxValid)-YY_fload(idxValid)).^2))
sqrt(mean((YY(idxValid)-Y_hat(idxValid)).^2))

TABLE1 = zeros(1,26);
TABLE2_EST = zeros(1,14);
TABLE2_PER = zeros(1,14);
TABLE3_EST = zeros(1,8);
TABLE4_EST = zeros(1,8);
TABLE2_STD = zeros(1,14);
TABLE3_STD = zeros(1,8);
TABLE4_STD = zeros(1,8);

RMSPE = zeros(12,2);
OBS = zeros(12,4);

%%%%Prediction performance
histogram(YY(idxValid)-Y_hat(idxValid),100)
hold on
histogram(YY(idxValid)-YY_fload(idxValid),100)
hold off

idxTestb = idxTest1; %all observations);
%%%%Prediction performance
histogram(YY(idxTestb)-Y_hat(idxTestb),100)
hold on
histogram(YY(idxTestb)-YY_fload(idxTestb),100)
histogram(YY(idxTest0)-Y_hat(idxTest0),100)
hold off

% uhat = abs(YY-Y_hat);
% [uhat,b] = sort(uhat(idxTestb));
% table(YY(idxTestb(b)),uhat,YY_time(idxTestb(b)))

BIAS(zone,1) = nanmean(YY(idxTestb)-Y_hat(idxTestb));
BIAS(zone,2) = nanmean(YY(idxTestb)-YY_fload(idxTestb));
ABSBIAS(zone,1) = nanmean(abs(YY(idxTestb)-Y_hat(idxTestb))./YY(idxTestb));
ABSBIAS(zone,2) = nanmean(abs(YY(idxTestb)-YY_fload(idxTestb))./YY(idxTestb));
STD(zone,1) = nanstd(YY(idxTestb)-Y_hat(idxTestb));
STD(zone,2) = nanstd(YY(idxTestb)-YY_fload(idxTestb));
RMSPE(zone,1) = sqrt(mean((YY(idxTestb)-Y_hat(idxTestb)).^2));
RMSPE(zone,2) = sqrt(mean((YY(idxTestb)-YY_fload(idxTestb)).^2));
OBS(zone,1) = length(idxTrain);
OBS(zone,2) = length(idxValid);
OBS(zone,3) = length(idxTestb);
OBS(zone,4) = length(find(Y_time>=datetime(2020,3,15)));

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
        Yd_f(:,j) = YY_fload(bd);
        j=j+1;
    end
    
end

b0 = find(listdays<datetime('1-Mar-2020'));
b1 = find(listdays>=datetime('1-Mar-2020'));
b2 = find(listdays>=datetime('15-Mar-2020'));

COV_U = nancov(Yd(:,b0)'-Yd_hat(:,b0)');
COV_Uf = nancov(Yd(:,b0)'-Yd_f(:,b0)');

hour_std = diag(sqrt(COV_U));
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
    Yd_f(hour(YY_time(bd))+1,i) = YY_fload(bd);
    Date(i) = listdays(b1(i));
    
    hourly_idx = hour(YY_time(bd))+1;
    WALD_t(i) = (Yd(hourly_idx,i)-Yd_hat(hourly_idx,i))'*inv(COV_U(hourly_idx,hourly_idx)+0*eye(length(hourly_idx)))*(Yd(hourly_idx,i)-Yd_hat(hourly_idx,i));
    WALDf_t(i) = (Yd(hourly_idx,i)-Yd_f(hourly_idx,i))'*inv(COV_Uf(hourly_idx,hourly_idx)+0*eye(length(hourly_idx)))*(Yd(hourly_idx,i)-Yd_f(hourly_idx,i));
    WALD_df(i) = length(hourly_idx);
    
    meanYhat(i) = sum((Yd_hat(hourly_idx,i)));
    
    meandiff(i) = sum((Yd(hourly_idx,i)-Yd_hat(hourly_idx,i)));
    std_diff(i) = sqrt(sum(sum(COV_U(hourly_idx,hourly_idx))));
    meandiff_f(i) = sum((Yd(hourly_idx,i)-Yd_f(hourly_idx,i)));
    std_diff_f(i) = sqrt(sum(sum(COV_Uf(hourly_idx,hourly_idx))));
    
    meanhour(hourly_idx,i) = (Yd(hourly_idx,i)-Yd_hat(hourly_idx,i));
    meanhour_f(hourly_idx,i) = (Yd(hourly_idx,i)-Yd_f(hourly_idx,i));
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

%%%%Table1: Prediction performance: RMSPE and load forecast improvements
TABLE1_RMSPE = [RMSPE(zone,:),reshape(RMSPE_WEEK(1:14,:)',[1 28])];
TABLE1_ABSBIAS = [ABSBIAS(zone,:),reshape(ABSBIAS_WEEK(1:14,:)',[1 28])];


%%%%Table2: ATE by week
TABLE2_EST(zone,:) = [sumh(1:14)'];
TABLE2_STD(zone,:) = [sumh_std(1:14)'];
TABLE2_PER(zone,:) = sumh(1:14)./sumhat(1:14);

zone
nansum(meanhf(:,1:14))./nansum(meany(:,1:14))
nansum(meanh(:,1:14))./nansum(meanhat(:,1:14))

%%%%Table3: Daily patterns change for weekdays
for i=1:14
    b = find(weekid==i+9 & weekday(Date)~=7 & weekday(Date)~=1 );
    meanh(:,i) = nanmean(meanhour(:,b),2);
    meanhf(:,i) = nanmean(meanhour_f(:,b),2);
    meanhat(:,i) = nanmean(Yd_hat(:,b),2);
    meany(:,i) = nanmean(Yd(:,b),2);
    
    sumh(i,1) = nansum(nansum(meanhour(:,b),2));
    sumhf(i,1) = nansum(nansum(meanhour_f(:,b),2));
    sumh_std(i,1) = sqrt(nansum(std_diff(b).^2));
    sumhf_std(i,1) = sqrt(nansum(std_diff_f(b).^2));
end



TABLE3_EST(zone,:) = [nansum(meanh([1:6,23:24],3),1)./nansum(meanhat([1:6,23:24],3),1),...
    nansum(meanh([7:12],3),1)./nansum(meanhat([7:12],3),1),...
    nansum(meanh([13:18],3),1)./nansum(meanhat([13:18],3),1),...
    nansum(meanh([19:22],3),1)./nansum(meanhat([19:22],3),1),...
    mean(nansum(meanh([1:6,23:24],4:9),1))./mean(nansum(meanhat([1:6,23:24],4:9),1)),...
    mean(nansum(meanh([7:12],4:9),1))./mean(nansum(meanhat([7:12],4:9),1)),...
    mean(nansum(meanh([13:18],4:9),1))./mean(nansum(meanhat([13:18],4:9),1)),...
    mean(nansum(meanh([19:22],4:9),1))./mean(nansum(meanhat([19:22],4:9),1)),...
    ];
derivvec1 = repmat((-nansum(meanhat([1:6,23:24],3),1)-nansum(meanh([1:6,23:24],3),1))./nansum(meanhat([1:6,23:24],3),1).^2,length([1:6,23:24]),1);
derivvec2 = repmat((-nansum(meanhat([7:12],3),1)-nansum(meanh([7:12],3),1))./nansum(meanhat([7:12],3),1).^2,length(7:12),1);
derivvec3 = repmat((-nansum(meanhat([13:18],3),1)-nansum(meanh([13:18],3),1))./nansum(meanhat([13:18],3),1).^2,length([13:18]),1);
derivvec4 = repmat((-nansum(meanhat([19:22],3),1)-nansum(meanh([19:22],3),1))./nansum(meanhat([19:22],3),1).^2,length([19:22]),1);

derivvec5 = repmat((-mean(nansum(meanhat([1:6,23:24],4:9),1))-mean(nansum(meanh([1:6,23:24],4:9),1)))./mean(nansum(meanhat([1:6,23:24],4:9),1)).^2,length([1:6,23:24]),1);
derivvec6 = repmat((-mean(nansum(meanhat([7:12],4:9),1))-mean(nansum(meanh([7:12],4:9),1)))./mean(nansum(meanhat([7:12],4:9),1)).^2,length([7:12]),1);
derivvec7 = repmat((-mean(nansum(meanhat([13:18],4:9),1))-mean(nansum(meanh([13:18],4:9),1)))./mean(nansum(meanhat([13:18],4:9),1)).^2,length([13:18]),1);
derivvec8 = repmat((-mean(nansum(meanhat([19:22],4:9),1))-mean(nansum(meanh([19:22],4:9),1)))./mean(nansum(meanhat([19:22],4:9),1)).^2,length([19:22]),1);


TABLE3_STD(zone,:) = [sqrt(1/6*derivvec1'*COV_U([1:6,23:24],[1:6,23:24])*derivvec1),...
    sqrt(1/6*derivvec2'*COV_U([7:12],[7:12])*derivvec2),...
    sqrt(1/6*derivvec3'*COV_U([13:18],[13:18])*derivvec3),...
    sqrt(1/6*derivvec4'*COV_U([19:22],[19:22])*derivvec4),...
    sqrt(1/6*derivvec5'*COV_U([1:6,23:24],[1:6,23:24])*derivvec5),...
    sqrt(1/6*derivvec6'*COV_U([7:12],[7:12])*derivvec6),...
    sqrt(1/6*derivvec7'*COV_U([13:18],[13:18])*derivvec7),...
    sqrt(1/6*derivvec8'*COV_U([19:22],[19:22])*derivvec8),...
    ];

%%%%Table4: Same but for weekends
for i=1:14
    b = find(weekid==i+9);
    bb = find(weekday(Date)==1 | weekday(Date)==7);
    b = intersect(b,bb);
    meanh(:,i) = nanmean(meanhour(:,b),2);
    meanhf(:,i) = nanmean(meanhour_f(:,b),2);
    meanhat(:,i) = nanmean(Yd_hat(:,b),2);
    meany(:,i) = nanmean(Yd(:,b),2);
end

TABLE4_EST(zone,:) = [nansum(meanh([1:6,23:24],3),1)./nansum(meanhat([1:6,23:24],3),1),...
    nansum(meanh([7:12],3),1)./nansum(meanhat([7:12],3),1),...
    nansum(meanh([13:18],3),1)./nansum(meanhat([13:18],3),1),...
    nansum(meanh([19:22],3),1)./nansum(meanhat([19:22],3),1),...
    mean(nansum(meanh([1:6,23:24],4:9),1))./mean(nansum(meanhat([1:6,23:24],4:9),1)),...
    mean(nansum(meanh([7:12],4:9),1))./mean(nansum(meanhat([7:12],4:9),1)),...
    mean(nansum(meanh([13:18],4:9),1))./mean(nansum(meanhat([13:18],4:9),1)),...
    mean(nansum(meanh([19:22],4:9),1))./mean(nansum(meanhat([19:22],4:9),1)),...
    ];
derivvec1 = repmat((-nansum(meanhat([1:6,23:24],3),1)-nansum(meanh([1:6,23:24],3),1))./nansum(meanhat([1:6,23:24],3),1).^2,length([1:6,23:24]),1);
derivvec2 = repmat((-nansum(meanhat([7:12],3),1)-nansum(meanh([7:12],3),1))./nansum(meanhat([7:12],3),1).^2,length(7:12),1);
derivvec3 = repmat((-nansum(meanhat([13:18],3),1)-nansum(meanh([13:18],3),1))./nansum(meanhat([13:18],3),1).^2,length([13:18]),1);
derivvec4 = repmat((-nansum(meanhat([19:22],3),1)-nansum(meanh([19:22],3),1))./nansum(meanhat([19:22],3),1).^2,length([19:22]),1);

derivvec5 = repmat((-mean(nansum(meanhat([1:6,23:24],4:9),1))-mean(nansum(meanh([1:6,23:24],4:9),1)))./mean(nansum(meanhat([1:6,23:24],4:9),1)).^2,length([1:6,23:24]),1);
derivvec6 = repmat((-mean(nansum(meanhat([7:12],4:9),1))-mean(nansum(meanh([7:12],4:9),1)))./mean(nansum(meanhat([7:12],4:9),1)).^2,length([7:12]),1);
derivvec7 = repmat((-mean(nansum(meanhat([13:18],4:9),1))-mean(nansum(meanh([13:18],4:9),1)))./mean(nansum(meanhat([13:18],4:9),1)).^2,length([13:18]),1);
derivvec8 = repmat((-mean(nansum(meanhat([19:22],4:9),1))-mean(nansum(meanh([19:22],4:9),1)))./mean(nansum(meanhat([19:22],4:9),1)).^2,length([19:22]),1);


TABLE4_STD(zone,:) = [sqrt(1/8*derivvec1'*COV_U([1:6,23:24],[1:6,23:24])*derivvec1),...
    sqrt(1/6*derivvec2'*COV_U([7:12],[7:12])*derivvec2),...
    sqrt(1/6*derivvec3'*COV_U([13:18],[13:18])*derivvec3),...
    sqrt(1/6*derivvec4'*COV_U([19:22],[19:22])*derivvec4),...
    sqrt(1/6*derivvec5'*COV_U([1:6,23:24],[1:6,23:24])*derivvec5),...
    sqrt(1/6*derivvec6'*COV_U([7:12],[7:12])*derivvec6),...
    sqrt(1/6*derivvec7'*COV_U([13:18],[13:18])*derivvec7),...
    sqrt(1/6*derivvec8'*COV_U([19:22],[19:22])*derivvec8),...
    ];



%% Table: Summary stats
load('SPOTPRICE.mat')
load('RTE.mat')
RTE = innerjoin(RTE,SPOTPRICE);
clear SPOTPRICE;

%RTE.Time = datetime([year(RTE.date),month(RTE.date),day(RTE.date),hour(RTE.Heures),minute(RTE.Heures),zeros(length(RTE.Heures),1)]);
Emissions_ = RTE.Consommation.*RTE.TauxdeCo2;
%sum(Emissions_(find(RTE.Time>=datetime(2019,1,1) & RTE.Time<datetime(2020,1,1)))/1000)
Renshare = (RTE.Eolien+RTE.Bionergies+RTE.Solaire)./(RTE.Consommation-RTE.Echphysiques);

idx = unique([idxTest; idxTrain; idxValid]);
dates = RTE.Time(idx);
Y_prices = RTE.Price_FR;
Y_load = RTE.Consommation;
Y_fload = RTE.PrevisionJ1;

TABLEDES = nan(7,5);
TABLEDES2 = nan(7,5);

for yy=2014:2020
    idx = find(year(RTE.Time)==yy);
    
    TABLEDES(yy-2013,1) = nanmean(Y_load(idx))/1000';
    TABLEDES(yy-2013,2) = nanmean(abs(Y_fload(idx)-Y_load(idx)))';
    TABLEDES(yy-2013,3) = nanmean(Y_prices(idx))';
    TABLEDES(yy-2013,4) = nanmean(Emissions_(idx))/1e6';
    TABLEDES(yy-2013,5) = nanmean(Renshare(idx));
    
    TABLEDES2(yy-2013,1) = nanstd(Y_load(idx))/1000';
    TABLEDES2(yy-2013,2) = nanstd(abs(Y_fload(idx)-Y_load(idx)))';
    TABLEDES2(yy-2013,3) = nanstd(Y_prices(idx))';
    TABLEDES2(yy-2013,4) = nanstd(Emissions_(idx))/1e6';
    TABLEDES2(yy-2013,5) = nanstd(Renshare(idx));
end

TABLEDES

clear TABLEVALS
TARGET= TABLEDES;
TARGET2 = TABLEDES2;
for i = 1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{i,j} = ['',num2str(TARGET(i,j),'%0.2f'),''];
        TABLEVALS2{i,j} = ['(',num2str(TARGET2(i,j),'%0.2f'),')'];
        if j==2
            TABLEVALS{i,j} = ['',num2str(TARGET(i,j),'%0.1f'),''];
            TABLEVALS2{i,j} = ['(',num2str(TARGET2(i,j),'%0.1f'),')'];
        elseif j==5
            TABLEVALS{i,j} = ['',num2str(TARGET(i,j)*100,'%0.1f'),'\% '];
            TABLEVALS2{i,j} = ['(',num2str(TARGET2(i,j),'%0.2f'),')  '];
        end
    end
end

ROWNAMES = {'2014','2015','2016','2017','2018','2019','2020'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{4}{D{.}{.}{-1}}} \toprule',...
    '  ',...
    ' Year & \multicolumn{1}{c}{Actual load} & \multicolumn{1}{c}{Abs. F. error} & \multicolumn{1}{c}{DA price} & \multicolumn{1}{c}{Emissions}   \\',...
    ' \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5}  ',...
    ];
for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i}, ' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4}, ' \\ '...
        ' & ',TABLEVALS2{i,1},' & ',TABLEVALS2{i,2},' & ',TABLEVALS2{i,3},' & ',TABLEVALS2{i,4},...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_DESCR.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);


%% Table: Forecasting performance MAP
%TABLE1_ABSBIAS
clear TABLEVALS TABLEVALS2
TARGET= [TABLE1_ABSBIAS(1,[1 (3:2:30)])*100;TABLE1_ABSBIAS(1,[2 (4:2:30)])*100;...
    TABLE1_RMSPE(1,[1 (3:2:30)])/1000;TABLE1_RMSPE(1,[2 (4:2:30)])/1000;...
    TABLE1_ABSBIAS_CO2([1 (2:2:29)])*100;TABLE1_RMSPE_CO2([1 (3:2:30)])]';

for j=1:size(TARGET,1)
    TABLEVALS{j,1} = ['',num2str(TARGET(j,1),'%0.1f'),' '];
    TABLEVALS{j,2} = ['',num2str(TARGET(j,2),'%0.1f'),' '];
    TABLEVALS{j,3} = ['',num2str(TARGET(j,3),'%0.2f'),' '];
    TABLEVALS{j,4} = ['',num2str(TARGET(j,4),'%0.2f'),' '];
    TABLEVALS{j,5} = ['',num2str(TARGET(j,5),'%0.1f'),' '];
    TABLEVALS{j,6} = ['',num2str(TARGET(j,6),'%0.2f'),' '];
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
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{6}{D{.}{.}{-1}}} \toprule',...
    '  ',...
    '& \multicolumn{4}{c}{Demand} & \multicolumn{2}{c}{Emissions} \\ '...
    '& \multicolumn{2}{c}{MAPE (\%)} & \multicolumn{2}{c}{RMSE} & \multicolumn{1}{c}{MAPE (\%)} & \multicolumn{1}{c}{RMSE}    \\',...
    ' \cline{2-3} \cline{4-5} \cline{6-7} ',...
    '&  \multicolumn{1}{c}{FNet} & \multicolumn{1}{c}{RTE} &  \multicolumn{1}{c}{FNet} & \multicolumn{1}{c}{RTE} &  \multicolumn{1}{c}{FNet} & \multicolumn{1}{c}{FNet}   \\',...
    ...
    ];
for i=1:14
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4},' & ',TABLEVALS{i,5},' & ',TABLEVALS{i,6} , ...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_PERF.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%We may not want to include all weeks, instead keep the first 4 weeks,
%and then plot forecast errors over the period.

%% Table: Weekly demand reductions -- all seven weeks -- drop week before.
%TABLE2_EST/1000
%TABLE2_PER
%TABLE2_STD/1000

b0 = find(Y_time>=datetime(2020,3,16) & Y_time<datetime(2020,6,1));
b1 = find(Y_time_CO2>=datetime(2020,3,16) & Y_time_CO2<datetime(2020,6,1));

for i=1:2
    sum(YY(b0(1+(i-1)*24*7:i*24*7))-Y_hat(b0(1+(i-1)*24*7:i*24*7)))./sum(Y_hat(b0(1+(i-1)*24*7:i*24*7)))
    sum(YY_CO2(b1(1+(i-1)*24*7:i*24*7))-Y_hat_CO2(b1(1+(i-1)*24*7:i*24*7)))./sum(Y_hat_CO2(b1(1+(i-1)*24*7:i*24*7)))
    
end


clear TARGET TABLEVALS
TARGET= [TABLE2_EST(:,3:end-1)/1000;TABLE2_PER(:,3:end-1)*100;TABLE2_EST_CO2(:,3:end-1);TABLE2_PER_CO2(:,3:end-1)*100]';
TARGET = [TARGET;sum(TARGET)];
TARGET(end,2) = sum(YY(b0)-Y_hat(b0))./sum(Y_hat(b0))*100;
TARGET(end,4) =sum(YY_CO2(b1)-Y_hat_CO2(b1))./sum(Y_hat_CO2(b1))*100;
for i=1:size(TARGET,1)
    TABLEVALS{i,1} = ['',num2str(TARGET(i,1),'%0.0f'),''];
    TABLEVALS{i,2} =['',num2str(TARGET(i,2),'%0.1f'),' '];
    TABLEVALS{i,3} =['',num2str(TARGET(i,3),'%0.0f'),' '];
    TABLEVALS{i,4} =['',num2str(TARGET(i,4),'%0.1f'),' '];
end
%TABLEVALS{i+1,1} = ['$(',num2str(TABLE2_STD(1,7)/1000,'%0.1f'),')$'];
%TABLEVALS{i+1,2} = '';

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
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{6}{D{.}{.}{-0}}} \toprule',...
    '    ',...
    '& \multicolumn{3}{c}{Demand} & \multicolumn{3}{c}{Emissions} \\   ',...
    '& \multicolumn{1}{c}{GWh}  & \multicolumn{1}{c}{SE} & \multicolumn{1}{c}{\%} & \multicolumn{1}{c}{Kt}  & \multicolumn{1}{c}{SE} & \multicolumn{1}{c}{\%} \\ \cline{2-4} \cline{5-7}  ',...
    ...
    ];
for i=1:size(TABLEVALS,1)-1
    TABLE = [TABLE,...
        ROWNAMES{i},' & ',TABLEVALS{i,1},' & ',['$(',num2str(TABLE2_STD(1,7)/1000,'%0.0f'),')$'],' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',['$(',num2str(TABLE2_STD_CO2(1,7),'%0.0f'),')$'],' & ',TABLEVALS{i,4}...
        ' \\ '];
end
TABLE = [TABLE,...
    '  ', ROWNAMES{i+1},' & ',TABLEVALS{i+1,1},' & & ',TABLEVALS{i+1,2},'  & ',TABLEVALS{i+1,3},' & & ',TABLEVALS{i+1,4},' '...
    ' \\ '];

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_WEEKRED.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

%% Table: Daily change -- night/morning/afternoon/evening (weekdays)
%TABLE3_EST/1000
%TABLE3_STD/1000
%drop schools closure

clear TARGET TARGET2 TABLEVALS TABLEVALS2
TARGET= [TABLE3_EST(:,5:end);TABLE4_EST(:,5:end)];
TARGET2= [TABLE3_STD(:,5:end);TABLE4_STD(:,5:end)];
for i = 1:size(TARGET,1)
    for j=1:size(TARGET,2)
        TABLEVALS{1,j} = ['',num2str(100*TARGET(1,j),'%0.1f'),''];
        TABLEVALS{2,j} = ['',num2str(100*TARGET(2,j),'%0.1f'),''];
        TABLEVALS2{1,j} = ['(',num2str(100*TARGET2(1,j),'%0.1f'),')'];
        TABLEVALS2{2,j} = ['(',num2str(100*TARGET2(2,j),'%0.1f'),')'];
    end
end

% 10PM-6AM
% 6AM-12PM
% 12PM-6PM
% 6PM-10PM

ROWNAMES = {'Weekdays (\%)','Week-ends (\%)'};
COLNAMES = {' ',' ',' '};
TABLE = ['\begin{tabular*}{\columnwidth}{@{\hspace{\tabcolsep}\extracolsep{\fill}}l*{4}{D{.}{.}{-1}}} \toprule',...
    '  ',...
    '& \multicolumn{1}{c}{Night}  & \multicolumn{1}{c}{Morning}  &  \multicolumn{1}{c}{Afternoon} & \multicolumn{1}{c}{Evening}    \\',...
    '& \multicolumn{1}{c}{10PM-6AM}  & \multicolumn{1}{c}{6AM-12PM}  &  \multicolumn{1}{c}{12PM-6PM} & \multicolumn{1}{c}{6PM-10PM}    \\',...
    ' \cline{2-2} \cline{3-3} \cline{4-4} \cline{5-5} ',...
    ...
    ];
for i=1:size(TABLEVALS,1)
    TABLE = [TABLE,...
        ROWNAMES{i}, ' & ',TABLEVALS{i,1},' & ',TABLEVALS{i,2},' & ',TABLEVALS{i,3},' & ',TABLEVALS{i,4}, ' \\ ',...
        ' & ',TABLEVALS2{i,1},' & ',TABLEVALS2{i,2},' & ',TABLEVALS2{i,3},' & ',TABLEVALS2{i,4}, ...
        ' \\ '];
end

TABLE = [TABLE,...
    ' \bottomrule \end{tabular*}'];

fileID = fopen(['RESULTS/TABLES/table_DAILYWDAY.tex'],'w');
fprintf(fileID,'%s',TABLE);
fclose(fileID);

TABLEVALS
%% Figure Load vs load forecast

b0 = find(Y_time>datetime(2020,1,20) & Y_time<=datetime(2020,5,31));
b00 = find(Y_time>datetime(2019,1,20) & Y_time<=datetime(2019,5,31));

[~,b] = setdiff(RTE.Time,Y_time);
Y_load(b) = [];

Y_LOAD = Y_load;
Y_FLOAD = YY_fload;
Y_CLOAD = Y_hat;

close all

N = 6;
C = linspecer(N);

b2 = find(Y_time(b0)>datetime(2020,3,15));
Y_CLOAD2 = Y_CLOAD;
Y_CLOAD(b2,:) = Y_fload(b2,:);

figure(1)
plot(Y_time(b0),smooth(Y_LOAD(b0,1),48)/1000,'color',C(2,:),'linewidth',1.8)
hold on
plot(Y_time(b0),smooth(Y_FLOAD(b0,1),48)/1000,'--','color',C(2,:),'linewidth',1.8)
y = smooth(Y_CLOAD(b0,1),48)/1000;
y2 = smooth(Y_CLOAD2(b0,1),48)/1000;
plot(Y_time(b0),y2,'-.','color',C(1,:),'linewidth',1.8)
plot(Y_time(b00)+days(365),smooth(Y_LOAD(b00,1),48)/1000,':k','linewidth',0.5)
plot([datetime(2020,3,15) datetime(2020,3,15)],[30 100],':k','color',C(5,:),'linewidth',2)
plot([datetime(2020,5,11) datetime(2020,5,11)],[30 100],':k','color',C(5,:),'linewidth',2)
hold off
xlim([datetime(2020,2,18) datetime(2020,5,30,10,00,00)])
ylim([35 73])
legend('Actual load','Load Forecast (RTE)','Counterfactual load (FNet)','Actual load (2019)','Lockdown start/end')
set(gca,'FontSize',15)
set(legend,'Location','NorthEast')
ylabel('Load (GW)')
saveas(1,['RESULTS/FIGURES/plot_LOAD1.eps'],'epsc')


figure(2)
b2 = find(Y_time>=datetime(2020,3,23) & Y_time<datetime(2020,3,30));
Xinterp = (duration(0,30,0):hours(1):duration(23,30,0)+days(6));
Xout = (duration(0,40,0):minutes(1):duration(23,20,0)+days(6));

target = Y_LOAD(b2,1);
F = griddedInterpolant(datenum(Xinterp)',target,'spline','spline');
ytemp = F(datenum(Xout))';
%Xout.Format = 'hh:mm';
plot(min(Y_time(b2))+Xout,ytemp/1000,'-','color',C(2,:),'linewidth',1.8)
hold on
target = Y_FLOAD(b2,1);
F = griddedInterpolant(datenum(Xinterp)',target,'spline','spline');
ytemp = F(datenum(Xout))';
plot(min(Y_time(b2))+Xout,ytemp/1000,'--','color',C(2,:),'linewidth',1.8)
target = Y_CLOAD(b2,1);
F = griddedInterpolant(datenum(Xinterp)',target,'spline','spline');
ytemp = F(datenum(Xout))';
%Xout.Format = 'hh:mm';
plot(min(Y_time(b2))+Xout,ytemp/1000,'-.','color',C(1,:),'linewidth',1.8)
hold off
set(gca,'FontSize',15)
ylabel('Load (GW)')
legend('Actual load','Load Forecast (RTE)','Counterfactual load (FNet)','Location','best')
%xtickangle(-30)
ylim([35 73])
saveas(2,['RESULTS/FIGURES/plot_LOAD2.eps'],'epsc')

b0 = find(Y_time>datetime(2019,7,15) & Y_time<=datetime(2021,7,15));
b00 = find(Y_time>datetime(2018,12,15) & Y_time<=datetime(2020,7,15));

YL = timetable(Y_LOAD,Y_CLOAD,'RowTimes',Y_time);
YW = retime(YL,'weekly','sum');

figure(3)
plot(Y_time(b0),smooth(Y_LOAD(b0,1),24*7)/1000,'color',C(2,:),'linewidth',1.8)
hold on
y = smooth(Y_CLOAD(b0,1),24*7)/1000;
y2 = smooth(Y_CLOAD2(b0,1),24*7)/1000;
plot(Y_time(b0),y2,'-.','color',C(1,:),'linewidth',1.8)
plot(Y_time(b00)+days(365),smooth(Y_LOAD(b00,1),24*7)/1000,':k','linewidth',0.5)
patch([datetime(2020,3,15) datetime(2020,5,11) datetime(2020,5,11) datetime(2020,3,15)],[0 0 100 100],C(5,:),'FaceAlpha',0.15,'EdgeColor',C(5,:),'LineWidth',1.8)
patch([datetime(2020,10,30) datetime(2020,12,15) datetime(2020,12,15) datetime(2020,10,30)],[0 0 100 100],C(5,:),'FaceAlpha',0.15,'EdgeColor',C(5,:),'LineWidth',1.8)
patch([datetime(2021,4,3) datetime(2021,5,13) datetime(2021,5,3) datetime(2021,4,3)],[0 0 100 100],C(5,:),'FaceAlpha',0.15,'EdgeColor',C(5,:),'LineWidth',1.8)
hold off
xlim([datetime(2020,1,1) datetime(2021,5,15,0,00,00)])
ylim([37 82])
legend('Actual load','Counterfactual load (FNet)','Actual load (2019-2020)','Lockdown periods')
set(gca,'FontSize',15)
set(legend,'Location','NorthWest')
ylabel('Load (GW)')
saveas(3,['RESULTS/FIGURES/plot_LOAD3.eps'],'epsc')

b2 = find(Y_time(b0)>datetime(2020,3,15));
Y_CLOAD2 = Y_CLOAD;
Y_CLOAD(b2,:) = Y_fload(b2,:);

%% Forecast errors

C = linspecer(6);
idx = unique([idxTest; idxTrain; idxValid]);
bb0 = find(YY_time(idx)>datetime(2020,1,15));
bb1 = find(RTE.Time>datetime(2020,1,15));
Y_errors = abs(Y_FLOAD(bb0) - Y_LOAD(bb0))./Y_LOAD(bb0);
Y_errors2 = abs(Y_hat(bb0) - Y_LOAD(bb0))./Y_LOAD(bb0);
figure(1)
plot(YY_time(idx(bb0)),smooth(Y_errors,48),'color',C(2,:),'linewidth',1.8)
hold on
plot(YY_time(idx(bb0)),smooth(Y_errors2,48),'-.','color',C(1,:),'linewidth',1.8)
plot([datetime(2020,1,16) datetime(2020,5,31)],[TABLE1_ABSBIAS(1,2) TABLE1_ABSBIAS(1,2)],'--k','linewidth',1.1)
plot([datetime(2020,3,15) datetime(2020,3,15)],[0 100],':k','color',C(5,:),'linewidth',2)
plot([datetime(2020,5,11) datetime(2020,5,11)],[0 100],':k','color',C(5,:),'linewidth',2)
%plot([datetime(2020,3,23) datetime(2020,3,23)],[0 0.1],'--k','color',C(5,:),'linewidth',1.1)
hold off
xlim([datetime(2020,2,18) datetime(2020,5,31)])
yticks((0:0.03:0.3))
ylim([0 0.095])
yticklabels({'0%','3%','6%','9%','12%','15%','18%','21%','24%','27%','30%'})
ylim([0 0.3])
yticklabels({'0%','3%','6%','9%','12%','15%','18%','21%','24%','27%','30%'})
set(gca,'FontSize',15)
legend('Forecast errors (RTE)','Prediction errors (FNet)','Average forecast errors (RTE)','Lockdown start/end')
set(legend,'Location','best')
ylabel('Mean Absolute Prediction Errors (MAPE)')
saveas(1,['RESULTS/FIGURES/plot_EERRORS.eps'],'epsc')


%% Emissions

b0 = find(Y_time_CO2>datetime(2020,1,20) & Y_time_CO2<datetime(2020,6,1));
b00 = find(Y_time_CO2>datetime(2018,12,15) & Y_time_CO2<=datetime(2020,7,15));

close all
figure(1)
plot(Y_time_CO2(b0),smooth(YY_CO2(b0,1),48),'color',C(2,:),'linewidth',1.8)
hold on
%plot(Y_time(b0(b2)),y(b2),'color',C(1,:),'linewidth',1.1)
plot(Y_time_CO2(b0),smooth(Y_hat_CO2(b0,1),48),'-.','color',C(1,:),'linewidth',1.8)
plot(Y_time_CO2(b00)+days(365),smooth(YY_CO2(b00,1),48),':k','linewidth',0.5)
plot([datetime(2020,3,15) datetime(2020,3,15)],[0 100],':k','color',C(5,:),'linewidth',2)
plot([datetime(2020,5,11) datetime(2020,5,11)],[0 100],':k','color',C(5,:),'linewidth',2)
hold off
xlim([datetime(2020,2,18) datetime(2020,5,30,10,00,00)])
ylim([0 3.5])
legend('Actual emissions','Counterfactual emissions','Actual emissions (2019)','Lockdown start/end')
set(gca,'FontSize',15)
set(legend,'Location','NorthEast')
ylabel('CO2 emissions (kt/h)')
saveas(1,['RESULTS/FIGURES/plot_EMISSIONS.eps'],'epsc')

b0 = find(Y_time_CO2>datetime(2018,1,1) & Y_time_CO2<datetime(2021,6,1));
figure(2)
plot(Y_time_CO2(b0),smooth(YY_CO2(b0,1),24*31),'color',C(2,:),'linewidth',1.1)
hold on
%plot(Y_time(b0(b2)),y(b2),'color',C(1,:),'linewidth',1.1)
plot(Y_time_CO2(b0),smooth(Y_hat_CO2(b0,1),24*31),'-','color',C(1,:),'linewidth',1.1)
%plot([datetime(2020,3,13) datetime(2020,3,13)],[30 100],'--k','color',C(4,:),'linewidth',1.1)
plot([datetime(2020,3,15) datetime(2020,3,15)],[0 5],'--k','color',C(5,:),'linewidth',1.1)
hold off
xlim([datetime(2019,1,1) datetime(2021,5,15,10,00,00)])
ylim([0 5])
legend('Actual emissions','Counterfactual emissions','Lockdown')
set(gca,'FontSize',15)
set(legend,'Location','best')
ylabel('CO2 emissions (kt/h)')
saveas(2,['RESULTS/FIGURES/plot_EMISSIONS2.eps'],'epsc')


%% Daily load patterns
%%%%Figure 2: New York State - standardized load - weekdays!
b2 = find(Y_time>datetime(2020,3,16));
idx_week2to4 = [b2(1:24*5);b2(1+24*7:24*5+24*7);b2(1+2*24*7:24*5+2*24*7)];
idx_week5to7 = [b2(1+3*24*7:24*5+3*24*7);b2(1+4*24*7:24*5+4*24*7);b2(1+5*24*7:24*5+5*24*7)];
close all
figure(1)
Xinterp = (duration(0,30,0):hours(1):duration(23,30,0));
Xout = (duration(0,40,0):minutes(1):duration(23,20,0));
Xout.Format = 'hh:mm';
target = mean(reshape(Y_LOAD(idx_week2to4,1),[24 15]),2);
F = griddedInterpolant(datenum(Xinterp)',target,'spline','spline');
F = griddedInterpolant(datenum(Xinterp)',target,'nearest');
ytemp = F(datenum(Xout))';
%plot(Xout,ytemp/1000,'-','color',C(2,:),'linewidth',1.1)
[peak11,b11] = max(ytemp(find(Xout<duration(13,0,0))));
[peak12,b12] = max(ytemp(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
hold on
target = mean(reshape(Y_CLOAD(idx_week2to4,1),[24 15]),2);
F = griddedInterpolant(datenum(Xinterp)',target,'nearest');
ytempC1 = F(datenum(Xout))';
[peak21,b21] = max(ytempC1(find(Xout<duration(13,0,0))));
[peak22,b22] = max(ytempC1(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
set(gca,'FontSize',15)
ylabel('NYISO Load (GW)')
xtickangle(-30)
%ylim([12.5 19])

figure(1)
Xinterp = (duration(0,30,0):hours(1):duration(23,30,0));
Xout = (duration(0,40,0):minutes(1):duration(23,20,0));
Xout.Format = 'hh:mm';
target2 = mean(reshape(Y_LOAD(idx_week5to7,1),[24 15]),2);
F = griddedInterpolant(datenum(Xinterp)',target2,'nearest');
ytemp = F(datenum(Xout))';
%plot(Xout,ytemp/1000,'--','color',C(2,:),'linewidth',1.1)
[peak112,b112] = max(ytemp(find(Xout<duration(13,0,0))));
[peak122,b122] = max(ytemp(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
hold on
target2 = mean(reshape(Y_CLOAD(idx_week5to7,1),[24 15]),2);
F = griddedInterpolant(datenum(Xinterp)',target2,'nearest');
ytemp = F(datenum(Xout))';
plot(Xout,ytemp/1000,'-','color',C(2,:),'linewidth',1.1)
plot(Xout,ytempC1/1000,'-.','color',C(1,:),'linewidth',1.1)
[peak212,b212] = max(ytemp(find(Xout<duration(13,0,0))));
[peak222,b222] = max(ytemp(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
text(duration(8,0,0),target(9)/1000,{datestr(duration(8,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(1,:))
text(duration(19,0,0),target(20)/1000,{datestr(duration(19,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(1,:))
text(duration(9,0,0),target2(10)/1000,{datestr(duration(9,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(2,:))
text(duration(19,0,0),target2(20)/1000,{datestr(duration(19,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(2,:))
hold off
ylim([36 70])
set(gca,'FontSize',15)
ylabel('Load (GW)')
legend('Average daily load','Counterfactual av. daily load','Location','best')
set(legend','location','best')
xtickangle(-30)
%ylim([12.5 18.5])
xlim([duration(0,40,0) duration(23,20,0)])
box on
saveas(1,['RESULTS/FIGURES/plot_LOAD_weekdays.eps'],'epsc')

%% Daily load patterns
%%%%Figure 2: New York State - standardized load - weekends!
b2 = find(Y_time>datetime(2020,3,21));
idx_week2to4 = [b2(1:24*2);b2(1+24*7:24*2+24*7);b2(1+2*24*7:24*2+2*24*7)];
idx_week5to7 = [b2(1+3*24*7:24*2+3*24*7);b2(1+4*24*7:24*2+4*24*7);b2(1+5*24*7:24*2+5*24*7)];

figure(2)
Xinterp = (duration(0,30,0):hours(1):duration(23,30,0));
Xout = (duration(0,40,0):minutes(1):duration(23,20,0));
Xout.Format = 'hh:mm';
target = mean(reshape(Y_LOAD(idx_week2to4,1),[24 6]),2);
F = griddedInterpolant(datenum(Xinterp)',target,'spline','spline');
F = griddedInterpolant(datenum(Xinterp)',target,'nearest');
ytemp = F(datenum(Xout))';
%plot(Xout,ytemp/1000,'-','color',C(2,:),'linewidth',1.1)
[peak11,b11] = max(ytemp(find(Xout<duration(13,0,0))));
[peak12,b12] = max(ytemp(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
hold on
target = mean(reshape(Y_CLOAD(idx_week2to4,1),[24 6]),2);
F = griddedInterpolant(datenum(Xinterp)',target,'nearest');
ytempC1 = F(datenum(Xout))';
[peak21,b21] = max(ytempC1(find(Xout<duration(13,0,0))));
[peak22,b22] = max(ytempC1(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
set(gca,'FontSize',15)
ylabel('NYISO Load (GW)')
xtickangle(-30)
%ylim([12.5 19])

figure(2)
Xinterp = (duration(0,30,0):hours(1):duration(23,30,0));
Xout = (duration(0,40,0):minutes(1):duration(23,20,0));
Xout.Format = 'hh:mm';
target2 = mean(reshape(Y_LOAD(idx_week5to7,1),[24 6]),2);
F = griddedInterpolant(datenum(Xinterp)',target2,'nearest');
ytemp = F(datenum(Xout))';
%plot(Xout,ytemp/1000,'--','color',C(2,:),'linewidth',1.1)
[peak112,b112] = max(ytemp(find(Xout<duration(13,0,0))));
[peak122,b122] = max(ytemp(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
hold on
target2 = mean(reshape(Y_CLOAD(idx_week5to7,1),[24 6]),2);
F = griddedInterpolant(datenum(Xinterp)',target2,'nearest');
ytemp = F(datenum(Xout))';
plot(Xout,ytemp/1000,'-','color',C(2,:),'linewidth',1.1)
plot(Xout,ytempC1/1000,'-.','color',C(1,:),'linewidth',1.1)
[peak212,b212] = max(ytemp(find(Xout<duration(13,0,0))));
[peak222,b222] = max(ytemp(find(Xout>=duration(16,0,0) & Xout<duration(22,0,0))));
text(duration(12,0,0),target(13)/1000,{datestr(duration(12,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(1,:))
text(duration(19,0,0),target(20)/1000,{datestr(duration(19,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(1,:))

text(duration(12,0,0),target2(13)/1000,{datestr(duration(12,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(2,:))
text(duration(19,0,0),target2(20)/1000,{datestr(duration(19,0,0))},'VerticalAlignment','bottom','HorizontalAlignment','center','FontSize',11,'color',C(2,:))
hold off
ylim([36 70])
set(gca,'FontSize',15)
ylabel('Load (GW)')
legend('Average daily load','Counterfactual av. daily load')
set(legend','location','best')
xtickangle(-30)
%ylim([12.5 18.5])
xlim([duration(0,40,0) duration(23,20,0)])
box on
saveas(2,['RESULTS/FIGURES/plot_LOAD_weekends.eps'],'epsc')