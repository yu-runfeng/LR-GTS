function data = Read_Snyder(file_path)
% READ_SNYDER Read from Snyder's dataset
% (c) Copyright 2025 Runfeng Yu

cost = load([file_path, 'cost.csv']);
demand = load([file_path, 'dmd.csv']);
fixed_cost = load([file_path, 'fc.csv']);

coef_penalty = cost(1, 2);

fixed_cost = fixed_cost(2:end);
cost = cost(2:end, 2:end);
cost = cost(1:size(cost, 1)/2, :);
num_cus = size(cost, 1);
num_store = size(cost, 2);

assert(length(demand) == length(fixed_cost));
assert(size(cost, 1) == length(demand));
assert(size(cost, 1) == size(cost, 2));

data = struct();
data.coef_penalty = coef_penalty;
data.coef_os = 1;
data.dist_snd_layer = repmat(cost, 2, 1);
data.dmd_os = demand;
data.farthest = 1e7;
data.fixed_store = fixed_cost;
data.ind_store = 1:num_store;
data.ind_cus = num_store + 1:2 * num_store;
data.num_cus = num_cus;
data.num_store = num_store;
data.max_try = 4;
data.srv_lv = 0.95;

data = orderfields(data);
end
