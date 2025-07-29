function [neighbor, break_arcs, best_general_cost] = Route_Inter_Exchange( ...
    route, data, tabu_list, frequency, frequency_sum, param_ts, is_random)
% ROUTE_INTER_EXCHANGE Exchange two customers between two routes (parallel)
% (c) Copyright 2025 Runfeng Yu

% initialization
route_num = length(route.length);
employ_num = sum(cellfun(@(x) length(x) > 2, route.waypoints));

% random move mode
if is_random
    neighbor = route;
    break_arcs = zeros(4, 2);
    best_general_cost = inf;

    % routes must have at least one customer
    node_num = cellfun(@(x) length(x), route.waypoints, UniformOutput = true);
    enough_len_ind = find(node_num >= 3);
    if length(enough_len_ind) < 2
        return
    end

    % first route
    fst_ind = enough_len_ind(randi(length(enough_len_ind)));
    pos_ind = randi([2, length(route.waypoints{fst_ind}) - 1]);

    fst_info = Get_Exchange_Info();
    fst_info.route_ind = fst_ind;
    fst_info.cus = route.waypoints{fst_info.route_ind}(pos_ind);
    fst_info.before = route.waypoints{fst_info.route_ind}(pos_ind - 1);
    fst_info.after = route.waypoints{fst_info.route_ind}(pos_ind + 1);
    fst_info.dmd = data.dmd_sfs(fst_info.cus-data.num_store);
    fst_info.position = pos_ind;

    % second route not same as first route
    snd_ind = enough_len_ind(randi(length(enough_len_ind)));
    while fst_ind == snd_ind
        snd_ind = enough_len_ind(randi(length(enough_len_ind)));
    end
    pos_ind = randi([2, length(route.waypoints{snd_ind}) - 1]);

    snd_info = Get_Exchange_Info();
    snd_info.route_ind = snd_ind;
    snd_info.cus = route.waypoints{snd_info.route_ind}(pos_ind);
    snd_info.before = route.waypoints{snd_info.route_ind}(pos_ind - 1);
    snd_info.after = route.waypoints{snd_info.route_ind}(pos_ind + 1);
    snd_info.dmd = data.dmd_sfs(snd_info.cus-data.num_store);
    snd_info.position = pos_ind;

    % update the best known neighbor
    [neighbor, break_arcs, best_general_cost] = Exchange_Cus(route, ...
        data, fst_info, snd_info, tabu_list, frequency, frequency_sum, ...
        param_ts, employ_num, neighbor, break_arcs, best_general_cost, true);
    return
end

% general search mode
nhbr_par = repmat({route}, route_num, 1);
arcs_par = repmat({zeros(4, 2)}, route_num, 1);
cost_par = inf(route_num, 1);

% first route
parfor fst_ind = 1:route_num
    route_neighbor = route;
    route_arcs = zeros(4, 2);
    route_general_cost = inf;

    fst_count = length(route.waypoints{fst_ind});
    fst_store = route.waypoints{fst_ind}(1);

    fst_info = Get_Exchange_Info();
    fst_info.route_ind = fst_ind;

    % first customer
    for m = 2:length(route.waypoints{fst_info.route_ind}) - 1
        fst_info.cus = route.waypoints{fst_info.route_ind}(m);
        fst_info.before = route.waypoints{fst_info.route_ind}(m - 1);
        fst_info.after = route.waypoints{fst_info.route_ind}(m + 1);
        fst_info.dmd = data.dmd_sfs(fst_info.cus-data.num_store);
        fst_info.position = m;

        % second route
        for snd_ind = fst_info.route_ind + 1:route_num
            snd_count = length(route.waypoints{snd_ind});
            snd_store = route.waypoints{snd_ind}(1);

            if fst_count == 3 && snd_count == 3 && fst_store == snd_store
                continue
            end

            % second customer
            snd_info = Get_Exchange_Info();
            snd_info.route_ind = snd_ind;
            for n = 2:length(route.waypoints{snd_info.route_ind}) - 1
                snd_info.cus = route.waypoints{snd_info.route_ind}(n);
                snd_info.before = route.waypoints{snd_info.route_ind}(n - 1);
                snd_info.after = route.waypoints{snd_info.route_ind}(n + 1);
                snd_info.dmd = data.dmd_sfs(snd_info.cus-data.num_store);
                snd_info.position = n;

                % exchange customers
                [route_neighbor, route_arcs, route_general_cost] = ...
                    Exchange_Cus(route, data, fst_info, snd_info, tabu_list, ...
                    frequency, frequency_sum, param_ts, employ_num, ...
                    route_neighbor, route_arcs, route_general_cost, false);
            end
        end
    end
    nhbr_par{fst_ind} = route_neighbor;
    arcs_par{fst_ind} = route_arcs;
    cost_par(fst_ind) = route_general_cost;
end

% find the best neighbor
[~, best_ind] = min(cost_par);
neighbor = nhbr_par{best_ind};
break_arcs = arcs_par{best_ind};
best_general_cost = cost_par(best_ind);

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end

function info = Get_Exchange_Info()
% Get exchange information

info = struct();
info.cus = -1;
info.before = -1;
info.after = -1;
info.dmd = -1;
info.route_ind = -1;
info.position = -1;
end

function [neighbor, arcs, general_cost] = Exchange_Cus(route, data, ...
    fst_info, snd_info, tabu_list, frequency, frequency_sum, param_ts, ...
    employ_num, neighbor, arcs, general_cost, is_random)
% Exchange two customers between two routes

% newly connected arcs and tabu condition
new_arc = [fst_info.before, snd_info.cus; snd_info.cus, fst_info.after; ...
    snd_info.before, fst_info.cus; fst_info.cus, snd_info.after];
if ~is_random && any(Tabu_List_Is_Member(tabu_list, new_arc))
    return
end

% increased length and granularity condition
increase_len = [data.dist_snd_layer(fst_info.before, snd_info.cus); ...
    data.dist_snd_layer(snd_info.cus, fst_info.after); ...
    data.dist_snd_layer(snd_info.before, fst_info.cus); ...
    data.dist_snd_layer(fst_info.cus, snd_info.after)];
if ~is_random && any(increase_len > param_ts.GRN)
    return
end

% new routes
fst_route = route.waypoints{fst_info.route_ind};
fst_route(fst_info.position) = snd_info.cus;
fst_len = route.length(fst_info.route_ind) - ...
    data.dist_snd_layer(fst_info.before, fst_info.cus) - ...
    data.dist_snd_layer(fst_info.cus, fst_info.after) + ...
    data.dist_snd_layer(fst_info.before, snd_info.cus) + ...
    data.dist_snd_layer(snd_info.cus, fst_info.after);
fst_cap = route.occupied_capacity(fst_info.route_ind) + ...
    (snd_info.dmd - fst_info.dmd);
fst_cus = fst_route(2:end-1) - data.num_store;
fst_exceed = max([fst_cap - data.cap_vhc, 0]);

snd_route = route.waypoints{snd_info.route_ind};
snd_route(snd_info.position) = fst_info.cus;
snd_len = route.length(snd_info.route_ind) - ...
    data.dist_snd_layer(snd_info.before, snd_info.cus) - ...
    data.dist_snd_layer(snd_info.cus, snd_info.after) + ...
    data.dist_snd_layer(snd_info.before, fst_info.cus) + ...
    data.dist_snd_layer(fst_info.cus, snd_info.after);
snd_cap = route.occupied_capacity(snd_info.route_ind) + ...
    (fst_info.dmd - snd_info.dmd);
snd_cus = snd_route(2:end-1) - data.num_store;
snd_exceed = max([snd_cap - data.cap_vhc, 0]);

% [DEBUG] check if the new route is same as the old route
% if ~is_random
%     if length(fst_route) == length(route.waypoints{snd_info.route_ind}) && ...
%             all(fst_route == route.waypoints{snd_info.route_ind})
%         error("same route");
%     end
%     if length(snd_route) == length(route.waypoints{fst_info.route_ind}) && ...
%             all(snd_route == route.waypoints{fst_info.route_ind})
%         error("same route");
%     end
% end

% update the new cost, fixed costs are not needed to be updated
cost = route.cost;

% update routing cost
cost.route(fst_info.route_ind) = fst_len * data.coef_sfs;
cost.route(snd_info.route_ind) = snd_len * data.coef_sfs;

% update total cost
cost.total = sum(cost.fixed+cost.route);

% update capacity penalty cost because param_ts.PEN is mutable
cost.penalty_capacity(fst_info.route_ind) = param_ts.PEN * fst_exceed;
cost.penalty_capacity(snd_info.route_ind) = param_ts.PEN * snd_exceed;

% update diversity cost
is_inferior = cost.total + sum(cost.penalty_capacity) > ...
    route.cost.total + sum(route.cost.penalty_capacity);
if is_inferior
    f = param_ts.DIV * cost.total * sqrt(data.num_cus*employ_num);
    cost.diversity = f * frequency_sum;
    cost.diversity(fst_info.route_ind) = ...
        f * sum(frequency(fst_info.route_ind, fst_cus));
    cost.diversity(snd_info.route_ind) = ...
        f * sum(frequency(snd_info.route_ind, snd_cus));
else
    cost.diversity(:) = 0;
end

% update generalized cost
cost.generalized = cost.total + sum(cost.penalty_capacity+cost.diversity);

if cost.generalized >= general_cost
    return
end

neighbor = route;
neighbor.cost = cost;
neighbor.waypoints{fst_info.route_ind} = fst_route;
neighbor.length(fst_info.route_ind) = fst_len;
neighbor.occupied_capacity(fst_info.route_ind) = fst_cap;
neighbor.exceeded_capacity(fst_info.route_ind) = fst_exceed;

neighbor.waypoints{snd_info.route_ind} = snd_route;
neighbor.length(snd_info.route_ind) = snd_len;
neighbor.occupied_capacity(snd_info.route_ind) = snd_cap;
neighbor.exceeded_capacity(snd_info.route_ind) = snd_exceed;

arcs = [fst_info.before, fst_info.cus; fst_info.cus, fst_info.after; ...
    snd_info.before, snd_info.cus; snd_info.cus, snd_info.after];
general_cost = cost.generalized;

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end
