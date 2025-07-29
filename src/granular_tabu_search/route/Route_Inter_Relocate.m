function [neighbor, break_arcs, best_general_cost] = Route_Inter_Relocate( ...
    route, data, tabu_list, frequency, frequency_sum, param_ts, is_random)
% ROUTE_INTER_RELOCATE Relocate a customer between two routes
% (c) Copyright 2025 Runfeng Yu

% initialization
route_num = length(route.length);
employ_num = sum(cellfun(@(x) length(x) > 2, route.waypoints));

% random move mode
if is_random
    neighbor = route;
    break_arcs = zeros(3, 2);
    best_general_cost = inf;

    if route_num < 2
        return
    end

    % the first route must have at least 1 customer
    node_num = cellfun(@(x) length(x), route.waypoints, UniformOutput = true);
    if all(node_num < 3)
        return
    end
    enough_len_ind = find(node_num >= 3);

    fst = Get_Route_Info();
    fst.ind = enough_len_ind(randi(length(enough_len_ind)));
    select_ind = randi([2, length(route.waypoints{fst.ind}) - 1]);

    % update cus
    cus = Get_Cus_Info();
    cus.ind = route.waypoints{fst.ind}(select_ind);
    cus.old_before = route.waypoints{fst.ind}(select_ind - 1);
    cus.old_after = route.waypoints{fst.ind}(select_ind + 1);
    cus.dmd = data.dmd_sfs(cus.ind-data.num_store);

    % update first route
    fst.route = route.waypoints{fst.ind};
    fst.route(select_ind) = [];
    fst.route_len = route.length(fst.ind) + ...
        data.dist_snd_layer(cus.old_before, cus.old_after) - ...
        data.dist_snd_layer(cus.old_before, cus.ind) - ...
        data.dist_snd_layer(cus.ind, cus.old_after);
    fst.route_cap = route.occupied_capacity(fst.ind) - cus.dmd;
    fst.route_cus = fst.route(2:end-1) - data.num_store;
    fst.fixed_cost = ~isempty(fst.route_cus) * data.fixed_vhc;

    % second route
    snd_ind = randi(length(route.waypoints));
    while fst.ind == snd_ind
        snd_ind = randi(length(route.waypoints));
    end

    cus.pos_ind = randi([1, length(route.waypoints{snd_ind}) - 1]);
    cus.new_before = route.waypoints{snd_ind}(cus.pos_ind);
    cus.new_after = route.waypoints{snd_ind}(cus.pos_ind + 1);

    if route.waypoints{fst.ind}(1) == route.waypoints{snd_ind}(1) && ...
            length(route.waypoints{fst.ind}) == 3
        return
    end

    % relocate and update neighbor
    [neighbor, break_arcs, best_general_cost] = ...
        Relocate_Cus(fst, cus, snd_ind, 0, employ_num, ...
        route, data, tabu_list, frequency, frequency_sum, param_ts, ...
        neighbor, break_arcs, best_general_cost, true);
    return
end

% general search mode
nhbr_par = repmat({route}, route_num, 1);
arcs_par = repmat({zeros(3, 2)}, route_num, 1);
cost_par = inf(route_num, 1);

% first route provides a customer
parfor fst_ind = 1:route_num
    route_neighbor = route;
    route_arcs = zeros(3, 2);
    route_general_cost = inf;

    fst = Get_Route_Info();
    fst.ind = fst_ind;

    for select_ind = 2:length(route.waypoints{fst.ind}) - 1
        cus = Get_Cus_Info();
        cus.ind = route.waypoints{fst.ind}(select_ind);
        cus.old_before = route.waypoints{fst.ind}(select_ind - 1);
        cus.old_after = route.waypoints{fst.ind}(select_ind + 1);
        cus.dmd = data.dmd_sfs(cus.ind-data.num_store);

        % new first route
        fst.route = route.waypoints{fst.ind};
        fst.route(select_ind) = [];
        fst.route_cap = route.occupied_capacity(fst.ind) - cus.dmd;
        fst.route_cus = fst.route(2:end-1) - data.num_store;
        fst.fixed_cost = ~isempty(fst.route_cus) * data.fixed_vhc;
        fst.route_len = route.length(fst.ind) + ...
            data.dist_snd_layer(cus.old_before, cus.old_after) - ...
            data.dist_snd_layer(cus.old_before, cus.ind) - ...
            data.dist_snd_layer(cus.ind, cus.old_after);

        % second route provides a position
        for snd_ind = 1:length(route.length)
            if fst.ind == snd_ind
                continue
            end

            fst_store = route.waypoints{fst.ind}(1);
            snd_store = route.waypoints{snd_ind}(1);
            fst_node_num = length(route.waypoints{fst.ind});
            snd_node_num = length(route.waypoints{snd_ind});
            if fst_store == snd_store && fst_node_num == 3 && snd_node_num == 2
                continue
            end

            for pos_ind = 1:length(route.waypoints{snd_ind}) - 1
                cus.new_before = route.waypoints{snd_ind}(pos_ind);
                cus.new_after = route.waypoints{snd_ind}(pos_ind + 1);
                cus.pos_ind = pos_ind;

                [route_neighbor, route_arcs, route_general_cost] = ...
                    Relocate_Cus(fst, cus, snd_ind, 0, ...
                    employ_num, route, data, tabu_list, frequency, ...
                    frequency_sum, param_ts, route_neighbor, route_arcs, ...
                    route_general_cost, false);
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

function [neighbor, arcs, general_cost] = Relocate_Cus(fst, cus, ...
    snd_ind, ~, employ_num, route, data, tabu_list, frequency, ...
    frequency_sum, param_ts, neighbor, arcs, general_cost, is_random)
% Relocate the customer and update neighbor

% tabu condition
if ~is_random && any(Tabu_List_Is_Member(tabu_list, [ ...
        cus.new_before, cus.ind; ...
        cus.ind, cus.new_after; ...
        cus.old_before, cus.old_after]))
    return
end

% granularity condition
increase_length = [data.dist_snd_layer(cus.new_before, cus.ind); ...
    data.dist_snd_layer(cus.ind, cus.new_after); ...
    data.dist_snd_layer(cus.old_before, cus.old_after)];
if ~is_random && any(increase_length > param_ts.GRN)
    return
end

% insert the customer at the position
snd_route = [route.waypoints{snd_ind}(1:cus.pos_ind), cus.ind, ...
    route.waypoints{snd_ind}(cus.pos_ind + 1:end)];
snd_route_len = route.length(snd_ind) - ...
    data.dist_snd_layer(cus.new_before, cus.new_after) + ...
    data.dist_snd_layer(cus.new_before, cus.ind) + ...
    data.dist_snd_layer(cus.ind, cus.new_after);
snd_route_cap = route.occupied_capacity(snd_ind) + cus.dmd;
snd_route_cus = snd_route(2:end-1) - data.num_store;

% update employ number
employ_num = employ_num - (length(route.waypoints{fst.ind}) > 2) - ...
    (length(route.waypoints{snd_ind}) > 2) + ...
    (length(fst.route) > 2) + (length(snd_route) > 2);

% [DEBUG]
% if ~is_random
%     if length(fst.route) == length(route.waypoints{snd_ind}) && ...
%             all(fst.route == route.waypoints{snd_ind})
%         error("same route");
%     end
%     if length(snd_route) == length(route.waypoints{fst.ind}) && ...
%             all(snd_route == route.waypoints{fst.ind})
%         error("same route");
%     end
% end

% update cost for the new route structure
cost = route.cost;

% update fixed cost
cost.fixed(fst.ind) = fst.fixed_cost;
cost.fixed(snd_ind) = data.fixed_vhc;

% update routing cost
cost.route(fst.ind) = fst.route_len * data.coef_sfs;
cost.route(snd_ind) = snd_route_len * data.coef_sfs;

% update total cost
cost.total = sum(cost.fixed+cost.route);

% update capacity penalty cost because param_ts.PEN is mutable
fst_exceed_cap = max([fst.route_cap - data.cap_vhc, 0]);
snd_exceed_cap = max([snd_route_cap - data.cap_vhc, 0]);
cost.penalty_capacity(fst.ind) = param_ts.PEN * fst_exceed_cap;
cost.penalty_capacity(snd_ind) = param_ts.PEN * snd_exceed_cap;

% update diversity cost
is_inferior = cost.total + sum(cost.penalty_capacity) > ...
    route.cost.total + sum(route.cost.penalty_capacity);
if is_inferior
    f = param_ts.DIV * cost.total * sqrt(data.num_cus*employ_num);
    cost.diversity = f * frequency_sum;
    cost.diversity(fst.ind) = f * sum(frequency(fst.ind, fst.route_cus));
    cost.diversity(snd_ind) = f * sum(frequency(snd_ind, snd_route_cus));
else
    cost.diversity(:) = 0;
end

% generalized cost
cost.generalized = cost.total + sum(cost.penalty_capacity+cost.diversity);

% not a better neighbor -> return
if cost.generalized >= general_cost
    return
end

% a better neighbor -> update before return
neighbor = route;
neighbor.cost = cost;
neighbor.waypoints{fst.ind} = fst.route;
neighbor.length(fst.ind) = fst.route_len;
neighbor.occupied_capacity(fst.ind) = fst.route_cap;
neighbor.exceeded_capacity(fst.ind) = fst_exceed_cap;

neighbor.waypoints{snd_ind} = snd_route;
neighbor.length(snd_ind) = snd_route_len;
neighbor.occupied_capacity(snd_ind) = snd_route_cap;
neighbor.exceeded_capacity(snd_ind) = snd_exceed_cap;

arcs = [cus.old_before, cus.ind; cus.ind, cus.old_after; ...
    cus.new_before, cus.new_after];
general_cost = cost.generalized;

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end

function r_info = Get_Route_Info()
% Create an empty route information

r_info = struct();
r_info.ind = 0;
r_info.route = zeros(1, 0);
r_info.route_len = 0;
r_info.route_cap = 0;
r_info.route_cus = zeros(1, 0);
r_info.fixed_cost = 0;

coder.varsize("r_info.route", [1, inf]);
coder.varsize("r_info.route_cus", [1, inf]);
end

function cus = Get_Cus_Info()
% Create an empty customer information

cus = struct();
cus.ind = 0;
cus.dmd = 0;
cus.old_before = 0;
cus.old_after = 0;
cus.new_before = 0;
cus.new_after = 0;
cus.pos_ind = 0;
end
