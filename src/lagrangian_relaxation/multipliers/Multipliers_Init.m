function multipliers = Multipliers_Init(data)
% MULTIPLIERS_INIT Initialize (flat start) multipliers for Lagrangian relaxation
% (c) Copyright 2025 Runfeng Yu

% row number for multipliers is equal to store number
multipliers.gamma = zeros(data.num_store, data.num_cus);
multipliers.kappa = zeros(data.num_store, data.num_cus);
end
