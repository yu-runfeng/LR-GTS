function route = Route_Init_From_Sol(data, sol, capacity_penalty)
% ROUTE_INIT_FROM_SOL Get route from current solution
% (c) Copyright 2025 Runfeng Yu

cycle = sol.super_cus.cycle;
vehicle_num = length(cycle);
route_len = zeros(vehicle_num, 1);

% split and join the route
for v_ind = 1:length(sol.super_cus.cycle)
    temp_cycle = cycle{v_ind};
    assert(~isempty(temp_cycle));

    store = sol.super_cus_assign(v_ind);
    insert_position = sol.super_cus.insert_position(store, v_ind);

    cycle{v_ind, 1} = [store, temp_cycle(insert_position+1:end), ...
        temp_cycle(1:insert_position), store];

    route_len(v_ind) = sol.super_cus.dist_mat(store, v_ind);

    % [DEBUG]
    arc_from = cycle{v_ind, 1}(1:end - 1);
    arc_to = cycle{v_ind, 1}(2:end);
    ind = sub2ind(size(data.dist_snd_layer), arc_from, arc_to);
    test_len = sum(data.dist_snd_layer(ind));
    assert(Is_Close(route_len(v_ind), test_len, 1e-4));
end
exceeded_capacity = sol.super_cus.demand - data.cap_vhc;
exceeded_capacity(exceeded_capacity < 0) = 0;

% generate cost
trans_cost = zeros(vehicle_num, 1);
for v_ind = 1:vehicle_num
    store = sol.super_cus_assign(v_ind);
    trans_cost(v_ind) = data.coef_trans * data.dist_fst_layer(store) * ...
        sol.super_cus.demand(v_ind);
end

penalty_cap = sol.super_cus.demand - data.cap_vhc;
penalty_cap(penalty_cap < 0) = 0;
penalty_cap = penalty_cap * capacity_penalty;

cost = Cost_Init_From_Value(data, trans_cost, route_len, penalty_cap);

% generate route
route = struct();
route.waypoints = cycle;
route.length = route_len;
route.occupied_capacity = sol.super_cus.demand;
route.exceeded_capacity = exceeded_capacity;
route.cost = cost;

assert(Is_Close(sum(route.cost.fixed+route.cost.route), sol.cost.sfs, 1e-4))

% append empty routes
route = Route_Append_Empty(route, find(sol.binary_location == 1));
end
