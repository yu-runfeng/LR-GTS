% Generate LR_GTS mex file
% (c) Copyright 2025 Runfeng Yu

clc;
clear all;

data = Read_Snyder('../../data/snyder/15nodes/');

param_lr = Param_Setting();
param_lr.ITER_MAX = 5; % maximum LR iteration

best_sol = Lagrangian_Relaxation(data, param_lr);
