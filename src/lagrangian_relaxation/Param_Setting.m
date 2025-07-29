function param_lr = Param_Setting()
% PARAM_SETTING Set parameters for LR, GTS, and LR-GTS
% (c) Copyright 2025 Runfeng Yu

% LR parameters for benchmark instances
param_lr.STEP_SCALAR = 2; % step scalar
param_lr.STEP_DEC = 1.05; % step scalar decrease scaling
param_lr.STEP_MIN = 0.0001; % minimal step scalar
param_lr.ITER_MAX = 10000; % maximum LR iteration
param_lr.ITER_SEARCH = 30; % local search iteration
param_lr.ITER_UNIMP = 700; % unimproved iteration
param_lr.LR_GAP = 0.01; % acceptable gap
param_lr.TIME_LIMIT = 1200; % time limit
param_lr.PRINT_FLAG = false; % print log

% sort fields
param_lr = orderfields(param_lr);
end
