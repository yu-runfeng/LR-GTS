function u_bnd = Ub_Get_Value(data, super_cus, binary_location)
% UB_GET_VALUE Get an upper bound with super customers and store locations
% (c) Copyright 2025 Runfeng Yu

coder.noImplicitExpansionInFunction();
u_bnd = Ub_Init(data, super_cus);
% if no store opened, open the cheapest
if sum(binary_location) == 0
    binary_location = Force_Open_Store(data);
    u_bnd.binary_location = binary_location;
end

% SFS channel
[u_bnd.super_cus_assign, u_bnd.cost.sfs, cost_sfs_trans] = ...
    Assign_Super_Cus(data, super_cus, binary_location);
u_bnd.cost.sfs = u_bnd.cost.sfs + super_cus.num * data.fixed_vhc;

% BOPS channel
[u_bnd.bops_attempt, u_bnd.cost.bops, cost_bops_trans] = ...
    Get_Bops_Attempt(data, binary_location);

% OS channel
[u_bnd.os_attempt, u_bnd.cost.os, cost_os_trans] = ...
    Get_Os_Attempt(data, binary_location);

% warehouse to store
u_bnd.cost.fix = sum(data.fixed_store.*binary_location);
u_bnd.cost.trans = cost_sfs_trans + cost_bops_trans + cost_os_trans;
u_bnd.binary_location = binary_location;
u_bnd.value = u_bnd.cost.fix + u_bnd.cost.trans + u_bnd.cost.sfs + ...
    u_bnd.cost.bops + u_bnd.cost.os;
end

function binary_location = Force_Open_Store(data)
% open multiple facilities
binary_location = false(size(data.fixed_store));
% binary_location(data.fixed_store == min(data.fixed_store)) = true;
binary_location(randi(length(binary_location))) = true;
end

function [assignment, channel_cost, trans_cost] = ...
    Assign_Super_Cus(data, super_cus, binary_location)
% assign each super-customer to the store with the minimal cost
coder.noImplicitExpansionInFunction();
opened_store = find(binary_location == 1);
cost = data.coef_sfs * super_cus.dist_mat(binary_location, :); % channel cost
[a, b] = meshgrid(super_cus.demand, data.dist_fst_layer(binary_location, :));
cost = cost + data.coef_trans * a .* b; % transportation cost
[total_cost, opened_store_ind] = min(cost, [], 1);

% assignment
assignment = zeros(super_cus.num, 1);
channel_cost = 0;
trans_cost = 0;

for i = 1:super_cus.num
    store_ind = opened_store(opened_store_ind(i));
    assignment(i) = store_ind;
    channel_cost = ...
        channel_cost + data.coef_sfs * super_cus.dist_mat(store_ind, i);
    trans_cost = trans_cost + ...
        data.coef_trans * super_cus.demand(i) * data.dist_fst_layer(store_ind);
end

assert(Is_Close(sum(total_cost), channel_cost+trans_cost, 10e-4));
end

function [bops_attempt, channel_cost, trans_cost] = ...
    Get_Bops_Attempt(data, binary_location)
% Calculate Bops customers' optimal attempt with given stores
coder.noImplicitExpansionInFunction();
prob_y = data.srv_lv * (1 - data.srv_lv).^(0:data.max_try - 1);
bops_attempt = -1 * ones(data.num_cus, data.max_try);
opened_store = find(binary_location == 1);
trans_cost = 0;
channel_cost = 0;

% assign for each customer
parfor counter = 1:data.num_cus
    cus_ind = data.ind_cus(counter);
    cus_dist = data.dist_snd_layer(cus_ind, opened_store);
    [sort_dist, sort_ind] = sort(cus_dist);
    sort_price = sort_dist * data.coef_bops;
    cus_path = opened_store(sort_ind);
    cus_path(sort_price > data.coef_penalty | sort_dist > data.farthest) = [];

    % fill in the path
    len_path = length(cus_path);
    if len_path > data.max_try - 1
        cus_path = cus_path(1:data.max_try-1);
        len_path = data.max_try - 1;
    end
    temp = [cus_path', 0, -1 * ones(1, data.max_try - len_path - 1)];
    bops_attempt(counter, :) = temp;

    % cost calculation
    prob = [prob_y(1:len_path), (1 - data.srv_lv)^len_path];
    price = [sort_price(1:len_path), data.coef_penalty];
    channel_cost = channel_cost + sum(price.*prob) * data.dmd_bops(counter);

    if cus_path(1) ~= 0
        trans_cost = trans_cost + data.dmd_bops(counter) * data.coef_trans * ...
            data.dist_fst_layer(cus_path(1));
    end
end
end

function [os_attempt, channel_cost, trans_cost] = ...
    Get_Os_Attempt(data, binary_location)
% Calculate OS customers' optimal attempt with given stores
os_attempt = zeros(data.num_cus, data.max_try+1);
channel_cost = 0;
opened_store = find(binary_location == 1)';

% assign for each customer
parfor counter = 1:data.num_cus
    cus = data.ind_cus(counter);
    cus_dmd = data.dmd_os(counter);
    cus_dist = data.dist_snd_layer(cus, opened_store);
    [min_dist, min_ind] = min(cus_dist);
    first_store = opened_store(min_ind); % frequent store

    if min_dist > data.farthest
        best_val = cus_dmd * data.coef_penalty;
        best_path = [];
    else
        cur_path = [cus, first_store];
        cur_val = cus_dmd * min_dist * data.coef_os;
        cur_len = min_dist;
        cur_prob = 1 - data.srv_lv;
        extend_store = [0, opened_store];
        extend_store(extend_store == first_store) = [];

        % Coder settings
        MAX_TRY = coder.ignoreConst(data.max_try);
        coder.varsize('cur_path', [1, 100]);

        % dfs
        [best_path, best_val] = Os_Dfs(cur_path, cur_len, cur_val, cur_prob, ...
            [], inf, extend_store, cus_dmd, data.dist_snd_layer, ...
            data.dist_fst_layer, data.farthest, MAX_TRY, data.coef_penalty, ...
            1-data.srv_lv, data.coef_os, data.coef_trans);
    end

    % cost and path assignment
    os_attempt(counter, :) = ...
        [best_path, zeros(1, data.max_try+1-length(best_path))];

    channel_cost = channel_cost + best_val;
end

trans_cost = 0;
for counter = 1:data.num_cus
    % if successfully assigned -> calculate transportation cost
    if os_attempt(counter, 2) ~= 0 && os_attempt(counter, 2) ~= -1
        trans_cost = trans_cost + data.dmd_os(counter) * ...
            data.dist_fst_layer(os_attempt(counter, 2)) * data.coef_trans;
    end
end

os_attempt = os_attempt(:, 2:end);
end

function [best_path, best_val] = Os_Dfs(cur_path, cur_len, cur_val, ...
    cur_prob, best_path, best_val, extend_store, cus_dmd, dist_snd_layer, ...
    dist_fst_layer, farthest, max_try, pnt_price, prob_fail, coef_os, ...
    coef_trans)

% deep first search in OS channel
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
        temp_val = cur_val + cus_dmd * coef_os * cur_prob * ...
            dist_snd_layer(cur_path(end-1), cur_path(end));

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
                pnt_price, prob_fail, coef_os, coef_trans);

            cur_path = stack_path;
            cur_prob = stack_prob;
            cur_val = stack_cost;
            cur_len = stack_len;
        end
    end
end
end
