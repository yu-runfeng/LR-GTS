function l_bound = Lb_Init(data, multipliers)
% LB_INIT Initialize a lower bound struct
% (c) Copyright 2025 Runfeng Yu

% multipliers update directions
update_direction = struct();
update_direction.beta = zeros(size(multipliers.beta));
update_direction.mu = zeros(size(multipliers.mu));

% lower bound struct
l_bound = struct();
l_bound.upd_dir = update_direction;
l_bound.binary_location = false(data.num_store, 1);
l_bound.bops_attempt = -1 * ones(data.num_cus, data.max_try);
l_bound.value = 0;
end
