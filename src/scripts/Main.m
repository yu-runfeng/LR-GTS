% Main function for LRGTS heuristic for a store location problem
% (c) Copyright 2025 Runfeng Yu

clc;
clear;

file_path = './data/nguyen/100-10MNb.txt';
data = Read_Nguyen(file_path);

[param_lr, param_ts, param_lr_gts] = Param_Setting(data);

param_ts.ITER_MAX = 100;
param_ts.DIV_ITER_UNIMP = 15;

rng(1);
solution = Lr_Gts(data, param_lr_gts, param_lr, param_ts);
