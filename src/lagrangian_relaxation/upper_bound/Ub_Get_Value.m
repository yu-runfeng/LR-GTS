function u_bnd = Ub_Get_Value(data, binary_location)
% UB_GET_VALUE Get an upper bound with store locations
% (c) Copyright 2025 Runfeng Yu

coder.noImplicitExpansionInFunction();
u_bnd = Ub_Init(data);
% if no store opened, open the cheapest
if sum(binary_location) == 0
    binary_location = Force_Open_Store(data);
    u_bnd.binary_location = binary_location;
end

% OS channel
[u_bnd.os_attempt, u_bnd.cost.os] = Get_Os_Attempt(data, binary_location);

% warehouse to store
u_bnd.cost.fix = sum(data.fixed_store.*binary_location);
u_bnd.binary_location = binary_location;
u_bnd.value = u_bnd.cost.fix + u_bnd.cost.os;
end

function binary_location = Force_Open_Store(data)
% open multiple facilities
binary_location = false(size(data.fixed_store));
% binary_location(data.fixed_store == min(data.fixed_store)) = true;
binary_location(randi(length(binary_location))) = true;
end

function [os_attempt, channel_cost] = Get_Os_Attempt(data, binary_location)
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
            data.farthest, MAX_TRY, data.coef_penalty, 1-data.srv_lv, ...
            data.coef_os);
    end

    % cost and path assignment
    os_attempt(counter, :) = ...
        [best_path, zeros(1, data.max_try+1-length(best_path))];

    channel_cost = channel_cost + best_val;
end

os_attempt = os_attempt(:, 2:end);
end

function [best_path, best_val] = Os_Dfs(cur_path, cur_len, cur_val, ...
    cur_prob, best_path, best_val, extend_store, cus_dmd, dist_snd_layer, ...
    farthest, max_try, pnt_price, prob_fail, coef_os)

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
                dist_snd_layer, farthest, max_try, pnt_price, prob_fail, ...
                coef_os);

            cur_path = stack_path;
            cur_prob = stack_prob;
            cur_val = stack_cost;
            cur_len = stack_len;
        end
    end
end
end
