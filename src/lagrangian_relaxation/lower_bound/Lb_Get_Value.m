function l_bound = Lb_Get_Value(data, multipliers)
% LB_GET_VALUE Get a lower bound with current multipliers
% (c) Copyright 2025 Runfeng Yu

% initialize a lower bound
l_bound = Lb_Init(data, multipliers);

% solve four subproblems
[l_bound.binary_location, cost_fix] = Loc_Subproblem(data, multipliers);
[l_bound.os_attempt, cost_os] = Os_Subproblem(data, multipliers);

% update value
l_bound.value = cost_fix + cost_os;

% update direction
l_bound.upd_dir.gamma = ...
    Get_Dir_Gamma(l_bound.os_attempt, l_bound.binary_location, ...
    size(multipliers.gamma));
l_bound.upd_dir.kappa = ...
    Get_Dir_Kappa(l_bound.os_attempt, l_bound.binary_location, ...
    size(multipliers.kappa), data);
end

function dir_gamma = Get_Dir_Gamma(os_attempt, binary_location, gamma_sz)
% get update directions of multipliers-gamma
% \sum_{k\in I_{ni}^+}z_{ki}^{n} (times of customer n use i) - v_i
dir_gamma = zeros(gamma_sz);
for n = 1:gamma_sz(2)
    attempt = os_attempt(n, :);
    attempt(attempt == 0 | attempt == -1) = [];
    for i = 1:length(attempt)
        store_ind = attempt(i);
        dir_gamma(store_ind, n) = dir_gamma(store_ind, n) + 1;
    end
end
dir_gamma = bsxfun(@minus, dir_gamma, binary_location); % subtract v_i
end

function dir_kappa = Get_Dir_Kappa(os_attempt, binary_location, kappa_sz, data)
% get update directions of multipliers-kappa
% \sum_{j: d_{n j}>d_{n i}} z_{n j}^{n}+v_{i} - 1
dir_kappa = zeros(kappa_sz);
for m = 1:kappa_sz(2)
    for i = 1:kappa_sz(1)
        j_set = find(data.dist_snd_layer(m, data.ind_store) > ...
            data.dist_snd_layer(m, i));
        if any(j_set == os_attempt(m, 1))
            dir_kappa(i, m) = 1;
        end
    end
end
dir_kappa = bsxfun(@minus, dir_kappa, binary_location) - 1;
end

function [binary_location, cost_fix] = Loc_Subproblem(data, multipliers)
% open store with coefficient less than 0
coder.noImplicitExpansionInFunction();
coefficient = data.fixed_store - sum(multipliers.gamma, 2) + ...
    sum(multipliers.kappa, 2);
binary_location = coefficient <= 0; % open stores with coefficient <= 0
cost_fix = sum(binary_location.*coefficient) - sum(multipliers.kappa, "all");
end

function [os_attempt, cost_os] = Os_Subproblem(data, multipliers)
% find the optimal OS customers' attempt
os_attempt = -1 * ones(data.num_cus, data.max_try+1);
cost_os = zeros(data.num_cus, 1);
srv_lv = data.srv_lv;
dist_snd_layer = data.dist_snd_layer;
dmd_os = data.dmd_os;
farthest = data.farthest;
ind_cus = data.ind_cus;
ind_store = data.ind_store;
max_try = data.max_try;
num_store = data.num_store;
pnt_price = data.coef_penalty;
coef_os = data.coef_os;
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
        farthest, MAX_TRY, pnt_price, 1-srv_lv, ...
        coef_os, gamma, pen_cost);

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
    farthest, max_try, pnt_price, prob_fail, coef_os, gamma, fix_cost)
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
            temp_val = temp_val + fix_cost(cur_path(2)+1);
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
                dist_snd_layer, farthest, max_try, pnt_price, prob_fail, ...
                coef_os, gamma, fix_cost);
            cur_path = stack_path;
            cur_prob = stack_prob;
            cur_val = stack_cost;
            cur_len = stack_len;
        end
    end
end
end
