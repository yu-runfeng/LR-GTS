function u_bnd = Ub_Get_Value(data, super_cus, binary_location)
% UB_GET_VALUE Get an upper bound with super customers and store locations
% (c) Copyright 2025 Runfeng Yu

u_bnd = Ub_Init(data, super_cus);
% if no store opened, open the cheapest
if sum(binary_location) == 0
    binary_location = Force_Open_Store(data);
    u_bnd.binary_location = binary_location;
end

% SFS channel
[u_bnd.super_cus_assign, u_bnd.cost.sfs, ~] = ...
    Assign_Super_Cus(data, super_cus, binary_location);
u_bnd.cost.sfs = u_bnd.cost.sfs + super_cus.num * data.fixed_vhc;

% warehouse to store
u_bnd.cost.fix = sum(data.fixed_store.*binary_location);
u_bnd.binary_location = binary_location;
u_bnd.value = u_bnd.cost.fix + u_bnd.cost.sfs;
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
opened_store = find(binary_location == 1);
cost = data.coef_sfs * super_cus.dist_mat(binary_location, :); % channel cost
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
end

% assert(Is_Close(sum(total_cost), channel_cost+trans_cost, 10e-4));
end
