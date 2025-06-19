function l_bound = Lb_Init(data, multipliers)
% LB_INIT Initialize a lower bound struct
% (c) Copyright 2025 Runfeng Yu

% lower bound struct
l_bound = struct();
l_bound.binary_location = false(data.num_store, 1);
l_bound.sfs_assign = zeros(1, size(multipliers.alpha, 2));
l_bound.bops_attempt = -1 * ones(data.num_cus, data.max_try);
l_bound.os_attempt = -1 * ones(data.num_cus, data.max_try);
l_bound.value = 0;
end
