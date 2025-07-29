function l_bound = Lb_Get_Value(data, multipliers)
% LB_GET_VALUE Get a lower bound with current multipliers and super-customers
% (c) Copyright 2025 Runfeng Yu

% initialize a lower bound
l_bound = Lb_Init(data, multipliers);

% solve four subproblems
[l_bound.binary_location, cost_fix] = Loc_Subproblem(data, multipliers);
[l_bound.bops_attempt, cost_bops] = Bops_Subproblem(data, multipliers);

% update value
l_bound.value = cost_fix + cost_bops;

% update direction
l_bound.upd_dir.beta = ...
    Get_Dir_Beta(l_bound.bops_attempt, l_bound.binary_location, ...
    size(multipliers.beta));
l_bound.upd_dir.mu = ...
    Get_Dir_Mu(l_bound.bops_attempt, l_bound.binary_location, ...
    size(multipliers.mu), data);
end

function dir_beta = Get_Dir_Beta(bops_attempt, binary_location, beta_sz)
% get update directions of multipliers-beta
% Dir_{im} = \sum_{r=1}^{R} y_{imr} - v_i
dir_beta = zeros(beta_sz); % \sum_{r=1}^{R} y_{imr}: times of customer m use i
for m = 1:beta_sz(2)
    attempt = bops_attempt(m, :);
    attempt(attempt == 0 | attempt == -1) = [];
    for i = 1:length(attempt)
        store_ind = attempt(i);
        dir_beta(store_ind, m) = dir_beta(store_ind, m) + 1;
    end
end
dir_beta = bsxfun(@minus, dir_beta, binary_location); % subtract v_i
end

function dir_mu = Get_Dir_Mu(bops_attempt, binary_location, mu_sz, data)
% get update directions of multipliers-mu
% \sum_{j:d_{mj}>d_{mi}}y_{j1}^m (customer n use j) + v_i - 1
dir_mu = zeros(mu_sz);
for m = 1:mu_sz(2)
    temp_dist = data.dist_snd_layer(m, data.ind_store);
    for i = 1:mu_sz(1)
        temp_length = data.dist_snd_layer(m, i);
        j_set_ind = temp_dist > temp_length;
        if ~isempty(j_set_ind)
            if bops_attempt(m, 1) ~= 0 && j_set_ind(bops_attempt(m, 1))
                dir_mu(i, m) = 1;
            end
        end
    end
end
dir_mu = bsxfun(@minus, dir_mu, binary_location) - 1;
end

function [binary_location, cost_fix] = Loc_Subproblem(data, multipliers)
% open store with coefficient less than 0
coder.noImplicitExpansionInFunction();
coefficient = data.fixed_store - ...
    sum(multipliers.beta, 2) + sum(multipliers.mu, 2);
binary_location = coefficient <= 0; % open stores with coefficient <= 0
cost_fix = sum(binary_location.*coefficient) - sum(multipliers.mu, "all");
end

function [bops_attempt, cost_bops] = Bops_Subproblem(data, multipliers)
% find the optimal BOPS customers' attempt
cus_value = zeros(data.num_cus, 1);
bops_attempt = -1 * ones(data.num_cus, data.max_try);
prob = data.srv_lv * (1 - data.srv_lv).^(0:data.max_try - 1);

parfor counter = 1:data.num_cus
    demand = data.dmd_bops(counter);

    single_cus_cost = inf * ones(data.max_try, 1);
    attempt = -1 * ones(data.max_try);

    dist_to_store = ...
        data.dist_snd_layer(counter+data.num_store, 1:data.num_store);
    ind_i_set = dist_to_store > dist_to_store';
    potential_store = find(dist_to_store <= data.farthest);
    dist_to_potential_store = dist_to_store(potential_store);
    multiplier = multipliers.beta(potential_store, counter);

    for r = 1:data.max_try
        if r == 1
            penalty = data.coef_penalty * demand;
            single_cus_cost(r) = penalty;
            attempt(r, 1) = 0;
            continue
        end

        cost_mat = zeros(length(potential_store), r-1);
        for s = 1:r - 1
            temp = data.coef_bops * demand * dist_to_potential_store' * prob(s);
            cost_mat(:, s) = cost_mat(:, s) + temp;
        end
        penalty = data.coef_penalty * demand * (1 - data.srv_lv)^(r - 1);
        cost_mat = bsxfun(@plus, cost_mat, multiplier);

        fix_cost = zeros(length(potential_store), 1);
        for i_ind = 1:length(potential_store)
            mu_ind = ind_i_set(:, potential_store(i_ind));
            fix_cost(i_ind) = sum(multipliers.mu(mu_ind, counter));
        end
        cost_mat(:, 1) = cost_mat(:, 1) + fix_cost;

        [min_cost, min_ind] = min(cost_mat, [], 1);
        single_cus_cost(r) = sum(min_cost) + penalty;
        attempt(r, 1:length([potential_store(min_ind), 0])) = ...
            [potential_store(min_ind), 0];
    end

    [min_val, min_ind] = min(single_cus_cost, [], 1);
    cus_value(counter) = min_val;
    bops_attempt(counter, :) = attempt(min_ind, :);
end
cost_bops = sum(cus_value);
end
