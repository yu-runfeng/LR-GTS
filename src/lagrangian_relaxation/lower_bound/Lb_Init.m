function l_bound = Lb_Init(data, multipliers)
% LB_INIT Initialize a lower bound struct
% (c) Copyright 2025 Runfeng Yu

% multipliers update directions
update_direction = struct();
update_direction.alpha = zeros(size(multipliers.alpha));

% lower bound struct
l_bound = struct();
l_bound.upd_dir = update_direction;
l_bound.binary_location = false(data.num_store, 1);
l_bound.sfs_assign = zeros(1, size(multipliers.alpha, 2));
l_bound.value = 0;
end
