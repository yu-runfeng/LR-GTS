function u_bnd = Ub_Get_Value(data, binary_location)
% UB_GET_VALUE Get an upper bound with super customers and store locations
% (c) Copyright 2025 Runfeng Yu

coder.noImplicitExpansionInFunction();
u_bnd = Ub_Init(data);
% if no store opened, open the cheapest
if sum(binary_location) == 0
    binary_location = Force_Open_Store(data);
    u_bnd.binary_location = binary_location;
end

% BOPS channel
[u_bnd.bops_attempt, u_bnd.cost.bops] = Get_Bops_Attempt(data, binary_location);

% warehouse to store
u_bnd.cost.fix = sum(data.fixed_store.*binary_location);
u_bnd.binary_location = binary_location;
u_bnd.value = u_bnd.cost.fix + u_bnd.cost.bops;
end

function binary_location = Force_Open_Store(data)
% open multiple facilities
binary_location = false(size(data.fixed_store));
% binary_location(data.fixed_store == min(data.fixed_store)) = true;
binary_location(randi(length(binary_location))) = true;
end


function [bops_attempt, channel_cost] = Get_Bops_Attempt(data, binary_location)
% Calculate Bops customers' optimal attempt with given stores
coder.noImplicitExpansionInFunction();
prob_y = data.srv_lv * (1 - data.srv_lv).^(0:data.max_try - 1);
bops_attempt = -1 * ones(data.num_cus, data.max_try);
opened_store = find(binary_location == 1);
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
        bops_attempt(counter, :) = [cus_path', 0]; % suffix with dummy store
        len_path = data.max_try - 1;
    else
        len = data.max_try - length(cus_path) - 1;
        temp = [cus_path', 0, -1 * ones(1, len)];
        bops_attempt(counter, :) = temp; % suffix with 0
    end

    % cost calculation
    prob = [prob_y(1:len_path), (1 - data.srv_lv)^len_path];
    price = [sort_price(1:len_path), data.coef_penalty];
    channel_cost = channel_cost + sum(price.*prob) * data.dmd_bops(counter);
end
end
