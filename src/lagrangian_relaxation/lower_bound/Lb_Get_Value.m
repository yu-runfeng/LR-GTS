function l_bound = Lb_Get_Value(data, super_cus, multipliers)
% LB_GET_VALUE Get a lower bound with current multipliers and super-customers
% (c) Copyright 2025 Runfeng Yu

% initialize a lower bound
l_bound = Lb_Init(data, multipliers);

% solve four subproblems
[l_bound.binary_location, cost_fix] = Loc_Subproblem(data, multipliers);
[l_bound.sfs_assign, cost_sfs] = Sfs_Subproblem(data, super_cus, multipliers);

% update value
l_bound.value = cost_fix + cost_sfs;

% update direction
l_bound.upd_dir.alpha = Get_Dir_Alpha(l_bound.sfs_assign, ...
    l_bound.binary_location, size(multipliers.alpha));
end

function dir_alpha = Get_Dir_Alpha(sfs_assign, binary_location, alpha_sz)
% get update directions of multipliers-alpha
% Dir_{ip} = X_{ip} - v_i
dir_alpha = zeros(alpha_sz); % build X_{ip}
for p = 1:alpha_sz(2)
    dir_alpha(sfs_assign(p), p) = 1;
end
dir_alpha = bsxfun(@minus, dir_alpha, binary_location); % subtract v_i
end

function [binary_location, cost_fix] = Loc_Subproblem(data, multipliers)
% open store with coefficient less than 0
coefficient = data.fixed_store - sum(multipliers.alpha, 2);
binary_location = coefficient <= 0; % open stores with coefficient <= 0
cost_fix = sum(binary_location.*coefficient);
end

function [sfs_assign, cost_sfs] = Sfs_Subproblem(data, super_cus, multipliers)
% assign super customers to stores
assign_cost = multipliers.alpha + data.coef_sfs * super_cus.dist_mat;
[cost_super_cus, sfs_assign] = min(assign_cost, [], 1);
cost_sfs = sum(cost_super_cus) + data.fixed_vhc * super_cus.num;
end
