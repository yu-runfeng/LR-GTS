function [neighbor, break_arcs] = Route_Get_Random_Neighbor(route, data, ...
    tabu_list, freq, param_ts)
% ROUTE_GET_RANDOM_NEIGHBOR Find a random neighbor of the current route
% (c) Copyright 2025 Runfeng Yu

% summarize frequency for each vehicle-customer pair
freq_sum = zeros(length(route.length), 1);
for k = 1:length(route.length)
    temp = route.waypoints{k}(2:end - 1) - data.num_store;
    freq_sum(k) = sum(freq(k, temp));
end

switch randi(5)
    case 1
        [neighbor, break_arcs, ~] = Route_Intro_Relocate(route, data, ...
            tabu_list, freq, freq_sum, param_ts, true);
    case 2
        [neighbor, break_arcs, ~] = Route_Intro_Exchange(route, data, ...
            tabu_list, freq, freq_sum, param_ts, true);
    case 3
        [neighbor, break_arcs, ~] = Route_Inter_Relocate(route, data, ...
            tabu_list, freq, freq_sum, param_ts, true);
    case 4
        [neighbor, break_arcs, ~] = Route_Inter_Exchange(route, data, ...
            tabu_list, freq, freq_sum, param_ts, true);
    case 5
        [neighbor, break_arcs, ~] = Route_Two_Optimize(route, data, ...
            tabu_list, freq, freq_sum, param_ts, true);
    otherwise
        neighbor = route;
        break_arcs = zeros(2, 2);
end

% clear diversity cost
neighbor.cost.generalized = ...
    neighbor.cost.generalized - sum(neighbor.cost.diversity(:));
neighbor.cost.diversity(:) = 0;
end
