function l_bound = Lb_Get_Value(data, super_cus, multipliers)
% LB_GET_VALUE Get a lower bound with current multipliers and super-customers
% (c) Copyright 2025 Runfeng Yu

% initialize a lower bound
l_bound = Lb_Init(data, multipliers);

% solve four subproblems
[l_bound.binary_location, cost_fix] = Loc_Subproblem(data, multipliers);
[l_bound.sfs_assign, cost_sfs] = Sfs_Subproblem(data, super_cus, multipliers);
[l_bound.bops_attempt, cost_bops] = Bops_Subproblem(data, multipliers);
[l_bound.os_attempt, cost_os] = Os_Subproblem(data, multipliers);

% update value
l_bound.value = cost_fix + cost_sfs + cost_bops + cost_os;
end

function [binary_location, cost_fix] = Loc_Subproblem(data, multipliers)
% open store with coefficient less than 0
coder.noImplicitExpansionInFunction();
coefficient = data.fixed_store - sum(multipliers.alpha, 2) - ...
    sum(multipliers.beta, 2) + sum(multipliers.mu, 2) - ...
    sum(multipliers.gamma, 2) + sum(multipliers.kappa, 2);
binary_location = coefficient <= 0; % open stores with coefficient <= 0
cost_fix = sum(binary_location.*coefficient) - sum(multipliers.mu, "all") - ...
    sum(multipliers.kappa, "all");
end

function [sfs_assign, cost_sfs] = Sfs_Subproblem(data, super_cus, multipliers)
% assign super customers to stores
coder.noImplicitExpansionInFunction();
[a, b] = meshgrid(super_cus.demand, data.dist_fst_layer);
assign_cost = multipliers.alpha + data.coef_sfs * super_cus.dist_mat + ...
    data.coef_trans * a .* b;
[cost_super_cus, sfs_assign] = min(assign_cost, [], 1);
cost_sfs = sum(cost_super_cus) + data.fixed_vhc * super_cus.num;
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
        cost_mat(:, 1) = data.dist_fst_layer(potential_store)' * ...
            data.coef_trans * demand;
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

function [os_attempt, cost_os] = Os_Subproblem(data, multipliers)
% find the optimal OS customers' attempt
os_attempt = -1 * ones(data.num_cus, data.max_try+1);
cost_os = zeros(data.num_cus, 1);
srv_lv = data.srv_lv;
dist_fst_layer = data.dist_fst_layer;
dist_snd_layer = data.dist_snd_layer;
dmd_os = data.dmd_os;
farthest = data.farthest;
ind_cus = data.ind_cus;
ind_store = data.ind_store;
max_try = data.max_try;
num_store = data.num_store;
pnt_price = data.coef_penalty;
coef_os = data.coef_os;
coef_trans = data.coef_trans;
dist_for_cus = dist_snd_layer(ind_cus, ind_store);
kappa = multipliers.kappa;
gamma = multipliers.gamma;

parfor ind = 1:data.num_cus
    cus = ind_cus(ind);
    cus_dmd = dmd_os(ind);
    pen_cost = zeros(num_store+1, 1);
    dist_for_cus_ind = dist_for_cus(ind, :);

    ind_i_set = dist_for_cus_ind > dist_for_cus_ind';
    for i_ind = 1:num_store
        kappa_ind = false(num_store, 1);
        for j = 1:num_store
            temp_flag = ind_i_set(j, :);
            if temp_flag(i_ind)
                kappa_ind(j) = true;
            end
        end
        temp = kappa(:, ind);
        pen_cost(i_ind+1) = sum(temp(kappa_ind, 1));
    end

    cur_path = cus;
    cur_val = 0;
    cur_len = 0;
    cur_prob = 1;
    best_path = [];
    best_val = inf;
    extend_store = [0, ind_store];

    % Coder settings
    MAX_TRY = coder.ignoreConst(max_try);
    coder.varsize('cur_path', [1, 100]);

    [best_path, best_val] = Os_Dfs(cur_path, cur_len, cur_val, cur_prob, ...
        best_path, best_val, extend_store, cus_dmd, dist_snd_layer, ...
        dist_fst_layer, farthest, MAX_TRY, pnt_price, 1-srv_lv, ...
        coef_os, coef_trans, gamma, pen_cost);

    if length(best_path) < max_try + 1
        best_path = [best_path, zeros(1, max_try+1-length(best_path))];
    end

    os_attempt(ind, :) = best_path;
    cost_os(ind) = best_val;
end
cost_os = sum(cost_os);
os_attempt = os_attempt(:, 2:end);
end

function [best_path, best_val] = Os_Dfs(cur_path, cur_len, cur_val, ...
    cur_prob, best_path, best_val, extend_store, cus_dmd, dist_snd_layer, ...
    dist_fst_layer, farthest, max_try, pnt_price, prob_fail, coef_os, ...
    coef_trans, gamma, fix_cost)
% deep first search in OS subproblem
if ~any(extend_store == 0)
    error('no dummy store in extend_store');
end

if length(cur_path) == max_try
    cur_path = [cur_path, 0]; % suffix with dummy store
    cur_val = cur_val + cus_dmd * pnt_price * cur_prob;
    if cur_val < best_val
        best_path = cur_path;
        best_val = cur_val;
    end
    return
end

for ind = 1:length(extend_store)
    store = extend_store(ind);
    stack_path = cur_path;
    stack_cost = cur_val;
    stack_prob = cur_prob;
    stack_len = cur_len;

    cur_path = [cur_path, store];

    if store == 0
        cur_val = cur_val + cus_dmd * pnt_price * cur_prob;
        if cur_val < best_val
            best_path = cur_path;
            best_val = cur_val;
        end

        cur_path = stack_path;
        cur_prob = stack_prob;
        cur_val = stack_cost;
        cur_len = stack_len;
        continue
    else
        temp_len = cur_len + dist_snd_layer(cur_path(end-1), cur_path(end));

        temp_val = cur_val + ...
            gamma(store, cur_path(1)-size(gamma, 1)) + ...
            cus_dmd * coef_os * cur_prob * ...
            dist_snd_layer(cur_path(end-1), cur_path(end));

        if length(cur_path) == 2
            temp_val = temp_val + fix_cost(cur_path(2)+1) + ...
                cus_dmd * dist_fst_layer(cur_path(2)) * coef_trans;
        end

        if temp_val > best_val || all(temp_len(:) > farthest)
            % prune
            cur_path = stack_path;
            cur_prob = stack_prob;
            cur_val = stack_cost;
            cur_len = stack_len;
        else
            % branch
            temp_extend_store = extend_store;
            temp_extend_store(ind) = [];
            temp_prob = cur_prob * prob_fail;

            [best_path, best_val] = Os_Dfs(cur_path, temp_len, temp_val, ...
                temp_prob, best_path, best_val, temp_extend_store, cus_dmd, ...
                dist_snd_layer, dist_fst_layer, farthest, max_try, ...
                pnt_price, prob_fail, coef_os, coef_trans, gamma, fix_cost);
            cur_path = stack_path;
            cur_prob = stack_prob;
            cur_val = stack_cost;
            cur_len = stack_len;
        end
    end
end
end
