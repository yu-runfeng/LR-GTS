% Generate LR_GTS mex file
% (c) Copyright 2025 Runfeng Yu

clc;
clear all;

file_path = '../../data/tuzun/coordP111112.dat';
data = Read_Tuzun(file_path);

[param_lr, param_ts, param_lr_gts] = Param_Setting(data);

param_lr.ITER_MAX = 20; % maximum LR iteration

param_ts.ITER_MAX = 10;
param_ts.DIV_ITER_UNIMP = 3;

param_lr_gts.ITER_UNIMP = 10; % uninproved interation
param_lr_gts.TIME_LIMIT = 120; % time limit

solution = Lr_Gts(data, param_lr_gts, param_lr, param_ts);
