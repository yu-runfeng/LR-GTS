function [neighbor, break_arcs, best_general_cost] = Route_Intro_Exchange( ...
    route, data, tabu_list, frequency, frequency_sum, param_ts, is_random)
% ROUTE_INTRO_EXCHANGE Exchange two customers within a route
% (C) Copyright 2025 Runfeng Yu

% initialization
route_num = length(route.length);
employ_num = sum(cellfun(@(x) length(x) > 2, route.waypoints));

% random move mode
if is_random
    neighbor = route;
    break_arcs = zeros(4, 2);
    best_general_cost = inf;

    % route must have at least five nodes (three customers and two stores)
    node_num = cellfun(@(x) length(x), route.waypoints, UniformOutput = true);
    enough_len_ind = find(node_num >= 5);
    if isempty(enough_len_ind)
        return
    end

    % randomly select a route
    route_ind = enough_len_ind(randi(length(enough_len_ind)));
    route_len = route.length(route_ind);

    % randomly select two customers
    fst = Get_Exchange_Info();
    snd = Get_Exchange_Info();
    while 1
        fst_temp = randi([2, length(route.waypoints{route_ind}) - 1]);
        snd_temp = randi([2, length(route.waypoints{route_ind}) - 1]);
        if abs(fst_temp-snd_temp) >= 2
            fst.ind = min([fst_temp, snd_temp]);
            snd.ind = max([fst_temp, snd_temp]);
            break
        end
    end

    fst.cus = route.waypoints{route_ind}(fst.ind);
    fst.before = route.waypoints{route_ind}(fst.ind - 1);
    fst.after = route.waypoints{route_ind}(fst.ind + 1);

    snd.cus = route.waypoints{route_ind}(snd.ind);
    snd.before = route.waypoints{route_ind}(snd.ind - 1);
    snd.after = route.waypoints{route_ind}(snd.ind + 1);

    % update the best known neighbor
    [neighbor, break_arcs, best_general_cost] = Update_Neighbor(data, route, ...
        route_len, route_ind, tabu_list, fst, snd, employ_num, frequency, ...
        frequency_sum, param_ts, is_random, neighbor, break_arcs, ...
        best_general_cost);
    return
end

% general search mode
nhbr_par = repmat({route}, route_num, 1);
arcs_par = repmat({zeros(4, 2)}, route_num, 1);
cost_par = inf(route_num, 1);

parfor route_ind = 1:route_num
    [route_neighbor, route_arcs, route_general_cost] = Exchange_Cus( ...
        route, data, tabu_list, frequency, frequency_sum, param_ts, ...
        employ_num, route_ind, false);
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

function [neighbor, break_arcs, best_general_cost] = Exchange_Cus(route, ...
    data, tabu_list, frequency, frequency_sum, param_ts, employ_num, ...
    route_ind, is_random)
% Exchange two customers within a route

coder.inline("always");

% initialization
neighbor = route;
break_arcs = zeros(4, 2);
best_general_cost = inf;

% update the best neighbor for each customer in the route{route_ind}
route_len = route.length(route_ind);
fst = Get_Exchange_Info();
for fst_ind = 2:length(route.waypoints{route_ind}) - 1
    fst.ind = fst_ind;
    fst.cus = route.waypoints{route_ind}(fst_ind);
    fst.before = route.waypoints{route_ind}(fst_ind - 1);
    fst.after = route.waypoints{route_ind}(fst_ind + 1);

    % second customer
    snd = Get_Exchange_Info();
    for snd_ind = fst_ind + 2:length(route.waypoints{route_ind}) - 1
        % exchanging two consecutive nodes equals relocate operation, thus
        % start with first_ind + 2, and causes a fatal error in calculating
        % route length
        snd.ind = snd_ind;
        snd.cus = route.waypoints{route_ind}(snd_ind);
        snd.before = route.waypoints{route_ind}(snd_ind - 1);
        snd.after = route.waypoints{route_ind}(snd_ind + 1);

        [neighbor, break_arcs, best_general_cost] = Update_Neighbor(data, ...
            route, route_len, route_ind, tabu_list, fst, snd, employ_num, ...
            frequency, frequency_sum, param_ts, is_random, neighbor, ...
            break_arcs, best_general_cost);
    end
end
end

function info = Get_Exchange_Info()
% Get exchange information

coder.inline("always");
info = struct();
info.ind = 0;
info.cus = 0;
info.before = 0;
info.after = 0;
end

function [neighbor, arcs, general_cost] = Update_Neighbor(data, route, ...
    route_len, route_ind, tabu_list, fst, snd, employ_num, frequency, ...
    frequency_sum, param_ts, is_random, neighbor, arcs, general_cost)
% Update the neighbor route and cost

coder.inline("always");

% newly connected arcs and tabu condition
new_arc = [fst.before, snd.cus; snd.cus, fst.after; ...
    snd.before, fst.cus; fst.cus, snd.after];
if ~is_random && any(Tabu_List_Is_Member(tabu_list, new_arc))
    return
end

% increased length and granularity condition
increase_len = [data.dist_snd_layer(fst.before, snd.cus); ...
    data.dist_snd_layer(snd.cus, fst.after); ...
    data.dist_snd_layer(snd.before, fst.cus); ...
    data.dist_snd_layer(fst.cus, snd.after)];
if ~is_random && any(increase_len > param_ts.GRN)
    return
end

% decreased length
decrease_len = [data.dist_snd_layer(fst.before, fst.cus); ...
    data.dist_snd_layer(fst.cus, fst.after); ...
    data.dist_snd_layer(snd.before, snd.cus); ...
    data.dist_snd_layer(snd.cus, snd.after)];

% new route
new_route = route.waypoints{route_ind};
new_route([fst.ind, snd.ind]) = new_route([snd.ind, fst.ind]);
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

arcs = [fst.before, fst.cus; fst.cus, fst.after; ...
    snd.before, snd.cus; snd.cus, snd.after];
general_cost = new_cost.generalized;

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end
