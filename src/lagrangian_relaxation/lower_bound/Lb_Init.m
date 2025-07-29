function l_bound = Lb_Init(data, multipliers)
% LB_INIT Initialize a lower bound struct
% (c) Copyright 2025 Runfeng Yu

% multipliers update directions
update_direction = struct();
update_direction.gamma = zeros(size(multipliers.gamma));
update_direction.kappa = zeros(size(multipliers.kappa));

% lower bound struct
l_bound = struct();
l_bound.upd_dir = update_direction;
l_bound.binary_location = false(data.num_store, 1);
l_bound.os_attempt = -1 * ones(data.num_cus, data.max_try);
l_bound.value = 0;
end
