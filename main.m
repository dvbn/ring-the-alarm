%% Benatia, 2021
% Ring the Alarm! Electricity markets, renewables and the pandemic
% Updated V2. October 2021

% Required:
% Statistics and Machine Learning Toolbox
% Parallel Computing Toolbox
% Deep Learning Toolbox
% Econometrics Toolbox
% Optimization Toolbox

clear
clc
cd(fileparts(mfilename('fullpath')))

mkdir('RESULTS/TABLES')
mkdir('RESULTS/FIGURES')

%% Estimate counterfactual demand and co2 emissions using neural net
run('DEMAND_AND_CO2.m')

%% Estimate counterfactual generation by technology using neural net 
run('PRODUCTION.m')

%% Estimate import function and domestic supply function using IV regression
run('REGRESSIONS.m')

%% Results
run('CF_RESULTS.m')

%% Delete temporary files
delete('FRANCE_CO2.mat')
delete('FRANCE_DEMAND.mat')
delete('PROD_C.mat')