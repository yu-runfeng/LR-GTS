function [neighbor, break_arcs, best_general_cost] = Route_Two_Optimize( ...
    route, data, tabu_list, frequency, frequency_sum, param_ts, is_random)
% ROUTE_TWO_OPTIMIZE Two-Opt between two routes
% (c) Copyright 2025 Runfeng Yu

% initialization
route_num = length(route.length);
employ_num = sum(cellfun(@(x) length(x) > 2, route.waypoints));

% random move mode
if is_random
    neighbor = route;
    break_arcs = zeros(2, 2);
    best_general_cost = inf;

    if route_num < 2
        return
    end

    % the first route
    fst = Get_Route_Info();
    fst.ind = randi(route_num);
    demand = data.dmd_sfs(route.waypoints{fst.ind}(2:end - 1)-data.num_store);
    sum_demand = sum(demand);
    fst.cap_ascend = [0, cumsum(demand)', sum_demand];
    ind = sub2ind(size(data.dist_snd_layer), ...
        route.waypoints{fst.ind}(1:end - 1), route.waypoints{fst.ind}(2:end));
    distance = data.dist_snd_layer(ind);
    fst.dist_ascend = [0, cumsum(distance)];
    fst.dist_descend = fst.dist_ascend(end) - fst.dist_ascend;
    fst.cap_descend = [sum_demand, flip(cumsum(flip(demand'))), 0];
    fst.pos = randi([1, length(route.waypoints{fst.ind}) - 1]);
    fst.before = route.waypoints{fst.ind}(fst.pos);
    fst.after = route.waypoints{fst.ind}(fst.pos + 1);

    % the second route
    snd = Get_Route_Info();
    snd.ind = randi(route_num);
    % assert(any(employ_num > 0));
    while (length(route.waypoints{fst.ind}) == 2 && ...
            length(route.waypoints{snd.ind}) == 2) || fst.ind == snd.ind
        snd.ind = randi(route_num);
    end
    demand = data.dmd_sfs(route.waypoints{snd.ind}(2:end - 1)-data.num_store);
    sum_demand = sum(demand);
    snd.cap_ascend = [0, cumsum(demand)', sum_demand];
    ind = sub2ind(size(data.dist_snd_layer), ...
        route.waypoints{snd.ind}(1:end - 1), route.waypoints{snd.ind}(2:end));
    distance = data.dist_snd_layer(ind);
    snd.dist_ascend = [0, cumsum(distance)];
    snd.dist_descend = snd.dist_ascend(end) - snd.dist_ascend;
    snd.cap_descend = [sum_demand, flip(cumsum(flip(demand'))), 0];
    snd.pos = randi([1, length(route.waypoints{snd.ind}) - 1]);
    snd.before = route.waypoints{snd.ind}(snd.pos);
    snd.after = route.waypoints{snd.ind}(snd.pos + 1);

    % swap the last node
    if fst.pos == length(route.waypoints{fst.ind}) - 1 && ...
            snd.pos == length(route.waypoints{snd.ind}) - 1
        return
    end

    % only swap identical first nodes
    if route.waypoints{fst.ind}(1) == route.waypoints{snd.ind}(1) && ...
            fst.pos == 1 && snd.pos == 1
        return
    end

    % swap the segments
    [neighbor, break_arcs, best_general_cost] = Exchange_Segments(route, ...
        data, fst, snd, tabu_list, frequency, frequency_sum, param_ts, ...
        employ_num, neighbor, break_arcs, best_general_cost, true);
    return
end

% general search mode
nhbr_par = repmat({route}, route_num, 1);
arcs_par = repmat({zeros(2, 2)}, route_num, 1);
cost_par = inf(route_num, 1);

parfor fst_ind = 1:length(route.length)
    route_neighbor = route;
    route_arcs = zeros(2, 2);
    route_general_cost = inf;

    fst = Get_Route_Info();
    fst.ind = fst_ind;

    % cumulative sum of demands and distance (ascend)
    demand = data.dmd_sfs(route.waypoints{fst_ind}(2:end - 1)-data.num_store);
    fst.cap_ascend = zeros(1, length(demand)+2);
    cumsum_demand = cumsum(demand)';
    sum_demand = sum(demand);
    fst.cap_ascend = [0, cumsum_demand, sum_demand];

    ind = sub2ind(size(data.dist_snd_layer), ...
        route.waypoints{fst_ind}(1:end - 1), route.waypoints{fst_ind}(2:end));
    fst.dist_ascend = [0, cumsum(data.dist_snd_layer(ind))];

    % descend demands and distance
    fst.dist_descend = fst.dist_ascend(end) - fst.dist_ascend;
    fst.cap_descend = [sum_demand, flip(cumsum(flip(demand'))), 0];

    for snd_ind = fst_ind + 1:length(route.length)
        snd = Get_Route_Info();
        snd.ind = snd_ind;

        % cumulative sum of demands and distance (ascend)
        demand = ...
            data.dmd_sfs(route.waypoints{snd_ind}(2:end - 1)-data.num_store);
        snd.cap_ascend = zeros(1, length(demand)+2);
        cumsum_demand = cumsum(demand)';
        sum_demand = sum(demand);
        snd.cap_ascend = [0, cumsum_demand, sum_demand];

        ind = sub2ind(size(data.dist_snd_layer), ...
            route.waypoints{snd_ind}(1:end - 1), ...
            route.waypoints{snd_ind}(2:end));
        snd.dist_ascend = [0, cumsum(data.dist_snd_layer(ind))];

        % descend demands and distance
        snd.dist_descend = snd.dist_ascend(end) - snd.dist_ascend;
        snd.cap_descend = [sum_demand, flip(cumsum(flip(demand'))), 0];

        for m = 1:length(route.waypoints{fst_ind}) - 1
            fst.before = route.waypoints{fst_ind}(m);
            fst.after = route.waypoints{fst_ind}(m + 1);
            fst.pos = m;

            for n = 1:length(route.waypoints{snd_ind}) - 1
                % will be identical after 2-opt swap (only swap endpoints)
                if m == length(route.waypoints{fst_ind}) - 1 && ...
                        n == length(route.waypoints{snd_ind}) - 1
                    continue
                end

                % only swap identical start-points
                if route.waypoints{fst.ind}(1) == ...
                        route.waypoints{snd.ind}(1) && m == 1 && n == 1
                    continue
                end

                snd.before = route.waypoints{snd_ind}(n);
                snd.after = route.waypoints{snd_ind}(n + 1);
                snd.pos = n;

                % swap the segments
                [route_neighbor, route_arcs, route_general_cost] = ...
                    Exchange_Segments(route, data, fst, snd, tabu_list, ...
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

% [DEBUG]
% Route_Validate(neighbor, route, data, frequency, param_ts);
end

function info = Get_Route_Info()
% Create an empty route information

info = struct();
info.ind = 0;
info.before = 0;
info.after = 0;
info.pos = 0;
info.cap_ascend = [];
info.dist_ascend = [];
info.cap_descend = [];
info.dist_descend = [];

coder.varsize('info.cap_ascend', 'info.dist_ascend', ...
    'info.cap_descend', 'info.dist_descend');
end

function [neighbor, arcs, general_cost] = Exchange_Segments(route, data, ...
    fst, snd, tabu_list, frequency, frequency_sum, param_ts, employ_num, ...
    neighbor, arcs, general_cost, is_random)
% swap the segments between two routes

% newly connected arcs and tabu conditions
new_arc = [fst.before, snd.after; snd.before, fst.after];
if ~is_random && any(Tabu_List_Is_Member(tabu_list, new_arc))
    return
end

% granularity condition
increase_len = [data.dist_snd_layer(fst.before, snd.after), ...
    data.dist_snd_layer(snd.before, fst.after)];
if ~is_random && any(increase_len > param_ts.GRN)
    return
end

% new routes
fst_route = [route.waypoints{fst.ind}(1:fst.pos), ...
    route.waypoints{snd.ind}(snd.pos + 1:end)];
old_end = fst_route(end);
new_end = fst_route(1);
new_1st_len = fst.dist_ascend(fst.pos) + snd.dist_descend(snd.pos+1) + ...
    data.dist_snd_layer(fst.before, snd.after) - ...
    data.dist_snd_layer(fst_route(end-1), old_end) + ...
    data.dist_snd_layer(fst_route(end-1), new_end);
new_1st_cap = fst.cap_ascend(fst.pos) + snd.cap_descend(snd.pos+1);
new_1st_cus = fst_route(2:end-1) - data.num_store;
fst_route(end) = fst_route(1);

snd_route = [route.waypoints{snd.ind}(1:snd.pos), ...
    route.waypoints{fst.ind}(fst.pos + 1:end)];
old_end = snd_route(end);
new_end = snd_route(1);
new_2nd_len = snd.dist_ascend(snd.pos) + fst.dist_descend(fst.pos+1) + ...
    data.dist_snd_layer(snd.before, fst.after) - ...
    data.dist_snd_layer(snd_route(end-1), old_end) + ...
    data.dist_snd_layer(snd_route(end-1), new_end);
new_2nd_cap = snd.cap_ascend(snd.pos) + fst.cap_descend(fst.pos+1);
new_2nd_cus = snd_route(2:end-1) - data.num_store;
snd_route(end) = snd_route(1);

employ_num = employ_num - (length(route.waypoints{fst.ind}) > 2) - ...
    (length(route.waypoints{snd.ind}) > 2) + ...
    (length(fst_route) > 2) + (length(snd_route) > 2);

% [DEBUG]
% if ~is_random
%     if length(fst_route) == length(route.waypoints{snd.ind}) && ...
%             all(fst_route == route.waypoints{snd.ind})
%         error("same route");
%     end
%     if length(snd_route) == length(route.waypoints{fst.ind}) && ...
%             all(snd_route == route.waypoints{fst.ind})
%         error("same route");
%     end
%     if length(fst_route) == length(route.waypoints{fst.ind}) && ...
%             all(fst_route == route.waypoints{fst.ind})
%         error("same route");
%     end
%     if length(snd_route) == length(route.waypoints{snd.ind}) && ...
%             all(snd_route == route.waypoints{snd.ind})
%         error("same route");
%     end
% end

% update the new cost
new_cost = route.cost;

% update fixed cost
new_cost.fixed(fst.ind) = ~isempty(new_1st_cus) * data.fixed_vhc;
new_cost.fixed(snd.ind) = ~isempty(new_2nd_cus) * data.fixed_vhc;

% update routing cost
new_cost.route(fst.ind) = new_1st_len * data.coef_sfs;
new_cost.route(snd.ind) = new_2nd_len * data.coef_sfs;

% update total cost
new_cost.total = sum(new_cost.fixed+new_cost.route);

% update capacity penalty cost because param_ts.PEN is mutable
fst_exceed = max([new_1st_cap - data.cap_vhc, 0]);
snd_exceed = max([new_2nd_cap - data.cap_vhc, 0]);
new_cost.penalty_capacity(fst.ind) = param_ts.PEN * fst_exceed;
new_cost.penalty_capacity(snd.ind) = param_ts.PEN * snd_exceed;

% diversity cost
is_inferior = new_cost.total + sum(new_cost.penalty_capacity) > ...
    route.cost.total + sum(route.cost.penalty_capacity);
if is_inferior
    f = param_ts.DIV * new_cost.total * sqrt(data.num_cus*employ_num);
    new_cost.diversity = f * frequency_sum;
    new_cost.diversity(fst.ind) = f * sum(frequency(fst.ind, new_1st_cus));
    new_cost.diversity(snd.ind) = f * sum(frequency(snd.ind, new_2nd_cus));
else
    new_cost.diversity(:) = 0;
end

% update generalized cost
new_cost.generalized = ...
    new_cost.total + sum(new_cost.penalty_capacity+new_cost.diversity);

% a better neighbor is found
if new_cost.generalized >= general_cost
    return
end

neighbor = route;
neighbor.cost = new_cost;
neighbor.waypoints{fst.ind} = fst_route;
neighbor.length(fst.ind) = new_1st_len;
neighbor.occupied_capacity(fst.ind) = new_1st_cap;
neighbor.exceeded_capacity(fst.ind) = fst_exceed;

neighbor.waypoints{snd.ind} = snd_route;
neighbor.length(snd.ind) = new_2nd_len;
neighbor.occupied_capacity(snd.ind) = new_2nd_cap;
neighbor.exceeded_capacity(snd.ind) = snd_exceed;

arcs = [fst.before, fst.after; snd.before, snd.after];
general_cost = new_cost.generalized;

% [DEBUG] check if the new route is valid
% Route_Validate(neighbor, route, data, frequency, param_ts);
end
