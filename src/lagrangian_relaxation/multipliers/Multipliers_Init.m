function multipliers = Multipliers_Init(data, super_customer_num)
% MULTIPLIERS_INIT Initialize (flat start) multipliers for Lagrangian relaxation
% (c) Copyright 2025 Runfeng Yu

% row number for multipliers is equal to store number
multipliers.alpha = zeros(data.num_store, super_customer_num);
end
