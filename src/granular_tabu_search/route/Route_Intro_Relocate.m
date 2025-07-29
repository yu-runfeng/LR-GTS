function [neighbor, break_arcs, best_general_cost] = Route_Intro_Relocate( ...
    route, data, tabu_list, frequency, frequency_sum, param_ts, is_random)
% ROUTE_INTRO_RELOCATE Relocate a customer within a route
% (c) Copyright 2025 Runfeng Yu

% initialization
route_num = length(route.length);
employ_num = sum(cellfun(@(x) length(x) > 2, route.waypoints));

% random move mode
if is_random
    neighbor = route;
    break_arcs = zeros(3, 2);
    best_general_cost = inf;

    % route must have at least four nodes (two customers and two stores)
    node_num = cellfun(@(x) length(x), route.waypoints, UniformOutput = true);
    enough_len_ind = find(node_num >= 4);
    if isempty(enough_len_ind)
        return
    end

    % randomly select a route
    route_ind = enough_len_ind(randi(length(enough_len_ind)));
    route_len = route.length(route_ind);
    cus_ind = randi([2, length(route.waypoints{route_ind}) - 1]);

    % update relocate information
    info = Get_Relocate_Info();
    info.cus = route.waypoints{route_ind}(cus_ind);
    info.old_before = route.waypoints{route_ind}(cus_ind - 1);
    info.old_after = route.waypoints{route_ind}(cus_ind + 1);

    % randomly select a position in the route (copied)
    route_copy = route.waypoints{route_ind};
    route_copy(cus_ind) = [];
    info.pos_ind = randi([1, length(route_copy) - 1]);
    while cus_ind == info.pos_ind + 1
        info.pos_ind = randi([1, length(route_copy) - 1]);
    end

    % update the best known neighbor
    [neighbor, break_arcs, best_general_cost] = Update_Neighbor(data, route, ...
        route_len, route_ind, tabu_list, info, route_copy, ...
        employ_num, frequency, frequency_sum, param_ts, is_random, ...
        neighbor, break_arcs, best_general_cost);
    return
end

% general search mode
nhbr_par = repmat({route}, route_num, 1);
arcs_par = repmat({zeros(3, 2)}, route_num, 1);
cost_par = inf(route_num, 1);

parfor route_ind = 1:route_num
    [route_neighbor, route_arcs, route_general_cost] = Relocate_Cus( ...
        route, data, tabu_list, frequency, frequency_sum, param_ts, ...
        employ_num, route_ind, is_random);
    nhbr_par{route_ind} = route_neighbor;
    arcs_par{route_ind} = route_arcs;
    cost_par(route_ind) = route_general_cost;
end

% find the best neighbor
[~, best_ind] = min(cost_par);
neighbor = nhbr_par{best_ind};
break_arcs = arcs_par{best_ind};
best_general_cost = cost_par(best_ind);

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end

function [neighbor, break_arcs, best_general_cost] = Relocate_Cus( ...
    route, data, tabu_list, frequency, frequency_sum, param_ts, employ_num, ...
    route_ind, is_random)
% Relocate a customer within a route

% initialization
neighbor = route;
break_arcs = zeros(3, 2);
best_general_cost = inf;

% update the best neighbor for each customer in the route{route_ind}
route_len = route.length(route_ind);
info = Get_Relocate_Info();
for cus_ind = 2:length(route.waypoints{route_ind}) - 1
    info.cus = route.waypoints{route_ind}(cus_ind);
    info.old_before = route.waypoints{route_ind}(cus_ind - 1);
    info.old_after = route.waypoints{route_ind}(cus_ind + 1);

    route_copy = route.waypoints{route_ind};
    route_copy(cus_ind) = [];

    % for each position in the route (copied)
    for pos_ind = 1:length(route_copy) - 1
        if cus_ind == pos_ind + 1
            continue % deleting and inserting at same position
        end

        info.pos_ind = pos_ind;
        [neighbor, break_arcs, best_general_cost] = Update_Neighbor(data, ...
            route, route_len, route_ind, tabu_list, info, route_copy, ...
            employ_num, frequency, frequency_sum, param_ts, is_random, ...
            neighbor, break_arcs, best_general_cost);
    end
end
end

function info = Get_Relocate_Info()
% Get relocate information

info = struct();
info.cus = 0;
info.old_before = 0;
info.old_after = 0;
info.pos_ind = 0;
end

function [neighbor, arcs, general_cost] = Update_Neighbor(data, route, ...
    route_len, route_ind, tabu_list, route_info, route_copy, employ_num, ...
    frequency, frequency_sum, param_ts, is_random, neighbor, arcs, general_cost)
% Update the neighbor route and cost

% before node and after node of the position
new_before = route_copy(route_info.pos_ind);
new_after = route_copy(route_info.pos_ind+1);

% newly connected arcs and tabu condition
new_arc = [new_before, route_info.cus; route_info.cus, new_after; ...
    route_info.old_before, route_info.old_after];
if ~is_random && any(Tabu_List_Is_Member(tabu_list, new_arc))
    return
end

% increased length and granularity condition
increase_len = [data.dist_snd_layer(new_before, route_info.cus); ...
    data.dist_snd_layer(route_info.cus, new_after); ...
    data.dist_snd_layer(route_info.old_before, route_info.old_after)];
if ~is_random && any(increase_len > param_ts.GRN)
    return
end

% decreased length
decrease_len = [data.dist_snd_layer(route_info.old_before, route_info.cus); ...
    data.dist_snd_layer(route_info.cus, route_info.old_after); ...
    data.dist_snd_layer(new_before, new_after)];

% new route
new_route = [route_copy(1:route_info.pos_ind), route_info.cus, ...
    route_copy(route_info.pos_ind+1:end)];
new_route_len = route_len + sum(increase_len-decrease_len);

% [DEBUG] new route must be different from the old one
% assert(any(new_route ~= route.waypoints{route_ind}));

% update cost for the new route structure
new_cost = Update_Intro_Cost(route.cost, data, route, route_ind, ...
    new_route_len, employ_num, frequency_sum, param_ts);

% if a more better neighbor is found, substitute the neighbor
if new_cost.generalized >= general_cost
    return
end
neighbor = route;
neighbor.waypoints{route_ind} = new_route;
neighbor.length(route_ind) = new_route_len;
neighbor.cost = new_cost;

arcs = [route_info.old_before, route_info.cus; ...
    route_info.cus, route_info.old_after; ...
    new_before, new_after];
general_cost = new_cost.generalized;

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end
