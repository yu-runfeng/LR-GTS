function u_bound = Ub_Init(data, super_cus)
% UB_INIT Initialize an upper bound struct
% (c) Copyright 2025 Runfeng Yu

% cost struct
cost = struct();
cost.fix = 0;
cost.sfs = 0;

% upper bound struct
u_bound.binary_location = false(data.num_store, 1);
u_bound.super_cus = super_cus;
u_bound.super_cus_assign = zeros(super_cus.num, 1);
u_bound.cost = cost;
u_bound.value = 0;
end
