% Generate LR_GTS mex file
% (c) Copyright 2025 Runfeng Yu

clc;
clear all;

data = Read_Nguyen('./data/nguyen/25-5MNb.txt');

[param_lr, param_ts, param_lr_gts] = Param_Setting(data);

param_lr.ITER_MAX = 5; % maximum LR iteration
param_ts.ITER_MAX = 10;
param_ts.DIV_ITER_UNIMP = 3;
param_lr_gts.ITER_UNIMP = 3; % uninproved interation
param_lr_gts.TIME_LIMIT = 10; % time limit

solution = Lr_Gts(data, param_lr_gts, param_lr, param_ts);
