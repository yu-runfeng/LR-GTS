function u_bound = Ub_Init(data)
% UB_INIT Initialize an upper bound struct
% (c) Copyright 2025 Runfeng Yu

% cost struct
cost = struct();
cost.fix = 0;
cost.os = 0;

% upper bound struct
u_bound.binary_location = false(data.num_store, 1);
u_bound.os_attempt = zeros(data.num_cus, data.max_try);
u_bound.cost = cost;
u_bound.value = 0;
end
