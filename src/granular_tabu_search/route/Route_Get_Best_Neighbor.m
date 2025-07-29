function [best_neighbor, break_arcs, is_success] = Route_Get_Best_Neighbor( ...
    route, data, tabu_list, freq, param_ts)
% ROUTE_GET_BEST_NEIGHBOR Find the best neighbor of the current route
% (c) Copyright 2025 Runfeng Yu

% summarize frequency for each vehicle-customer pair
freq_sum = zeros(length(route.length), 1);
for k = 1:length(route.length)
    temp = route.waypoints{k}(2:end - 1) - data.num_store;
    freq_sum(k) = sum(freq(k, temp));
end

% find neighbor
neighbor = cell(5, 1);
arc = cell(5, 1);
cost = zeros(5, 1);

[neighbor{1}, arc{1}, cost(1)] = Route_Intro_Relocate(route, data, ...
    tabu_list, freq, freq_sum, param_ts, false);
[neighbor{2}, arc{2}, cost(2)] = Route_Intro_Exchange(route, data, ...
    tabu_list, freq, freq_sum, param_ts, false);
[neighbor{3}, arc{3}, cost(3)] = Route_Inter_Relocate(route, data, ...
    tabu_list, freq, freq_sum, param_ts, false);
[neighbor{4}, arc{4}, cost(4)] = Route_Inter_Exchange(route, data, ...
    tabu_list, freq, freq_sum, param_ts, false);
[neighbor{5}, arc{5}, cost(5)] = Route_Two_Optimize(route, data, ...
    tabu_list, freq, freq_sum, param_ts, false);

% get the neighbor with the minimal generalized cost
[min_cost, best_ind] = min(cost);
best_neighbor = neighbor{best_ind};
break_arcs = arc{best_ind};
is_success = min_cost ~= inf;

if ~is_success
    % assert(all(break_arcs(:) == 0));
    return
end

% clear diversity cost
best_neighbor.cost.generalized = ...
    best_neighbor.cost.generalized - sum(best_neighbor.cost.diversity(:));
best_neighbor.cost.diversity(:) = 0;
end
