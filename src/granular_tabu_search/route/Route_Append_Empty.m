function route = Route_Append_Empty(route, opened_store)
% ROUTE_APPEND_EMPTY Ensure each store has an empty route
% (c) Copyright 2025 Runfeng Yu

% find stores do not have empty vehicles
has_empty = dictionary(opened_store, false(length(opened_store), 1));
for i = 1:length(route.waypoints)
    has_empty(route.waypoints{i}(1)) = length(route.waypoints{i}) <= 2;
end

% select store which does not have empty vehicles
% values(): For code generation, you must use the "cell" argument.
selected_store = opened_store(~cell2mat(values(has_empty, "cell")));

% append an empty route for each selected store
selected_num = length(selected_store);
zero_vec = zeros(selected_num, 1);
empty_routes = cell(selected_num, 1);
for i = 1:selected_num
    empty_routes{i} = [selected_store(i), selected_store(i)];
end

route.waypoints = [route.waypoints; empty_routes];
route.length = [route.length; zero_vec];
route.occupied_capacity = [route.occupied_capacity; zero_vec];
route.exceeded_capacity = [route.exceeded_capacity; zero_vec];
route.cost.trans = [route.cost.trans; zero_vec];
route.cost.fixed = [route.cost.fixed; zero_vec];
route.cost.route = [route.cost.route; zero_vec];
route.cost.penalty_capacity = [route.cost.penalty_capacity; zero_vec];
route.cost.diversity = [route.cost.diversity; zero_vec];
end
