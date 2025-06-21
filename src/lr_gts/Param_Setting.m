function [param_lr, param_ts, param_lr_gts] = Param_Setting(data)
% PARAM_SETTING Set parameters for LR, GTS, and LR-GTS
% (c) Copyright 2025 Runfeng Yu

% LR parameters for benchmark instances
param_lr.STEP_SCALAR = 2; % step scalar
param_lr.STEP_DEC = 1.05; % step scalar decrease scaling
param_lr.STEP_MIN = 0.002; % minimal step scalar
param_lr.ITER_MAX = 10000; % maximum LR iteration
param_lr.ITER_SEARCH = 40; % local search iteration
param_lr.ITER_UNIMP = 500; % unimproved iteration
param_lr.LR_GAP = 0.03; % acceptable gap
param_lr.TIME_LIMIT = 100; % time limit
param_lr.PRINT_FLAG = false; % print log

% LR parameters for case study
% param_lr.STEP_SCALAR = 20; % step scalar
% param_lr.STEP_DEC = 1.1; % step scalar decrease scaling
% param_lr.STEP_MIN = 0.002; % minimal step scalar
% param_lr.ITER_MAX = 10000; % maximum LR iteration
% param_lr.ITER_SEARCH = 10; % local search iteration
% param_lr.ITER_UNIMP = 500; % unimproved iteration
% param_lr.LR_GAP = 0.03; % acceptable gap
% param_lr.TIME_LIMIT = 1000; % time limit
% param_lr.PRINT_FLAG = false; % print log

% GTS parameters
param_ts.TABU_MAX = ceil(data.num_cus*0.20); % maximum length of tabu list
param_ts.TABU_MIN = ceil(data.num_cus*0.10); % manimum length of tabu list
param_ts.GRN = mean(data.dist_snd_layer, "all"); % granularity
param_ts.GRN_INC = 1.8; % granulaity increase scaling
param_ts.GRN_ITER_UNIMP = ceil(data.num_cus*0.03); % uninproved interation
param_ts.PEN = 2 * data.coef_sfs * param_ts.GRN / mean(data.dmd_sfs); % penalty
param_ts.PEN_MAX = 100 * max(data.dist_snd_layer, [], "all"); % maximum penalty
param_ts.PEN_MIN = 0.1; % minimum penalty
param_ts.PEN_INC = 1.2; % penalty increase scaling
param_ts.PEN_DEC = 0.8; % penalty decrease scaling
param_ts.INTER_FEAS = 8; % continuous feasible iteration
param_ts.INTER_INFS = ceil(0.06*data.num_cus); % continuous infeasible iteration
param_ts.DIV = 2; % diversity parameter
param_ts.DIV_ITER_RAND = ceil(0.08*data.num_cus); % random move iteration
param_ts.DIV_ITER_UNIMP = ceil(data.num_cus*0.4); % uninproved interation
param_ts.ITER_UNIMP = ceil(data.num_cus*2); % uninproved interation
param_ts.ITER_MAX = ceil(data.num_cus*4); % maximum iteration
param_ts.PRINT_FLAG = false;

% parameters in LR-GTS
param_lr_gts.ITER_UNIMP = ceil(max(50, data.num_cus/2)); % unimproved iteration
param_lr_gts.TIME_LIMIT = 1200; % time limit

% sort fields
param_lr = orderfields(param_lr);
param_ts = orderfields(param_ts);
param_lr_gts = orderfields(param_lr_gts);
end
