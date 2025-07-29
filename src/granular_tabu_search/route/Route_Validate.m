function Route_Validate(new_route, old_route, data, frequency, param_ts)
% ROUTE_VALIDATE Validate the route
% (c) Copyright 2025 Runfeng Yu

employ_num = sum(cellfun(@(x) length(x) > 2, new_route.waypoints));
for i = 1:length(new_route.waypoints)
    r = new_route.waypoints{i};

    % path length
    ind = sub2ind(size(data.dist_snd_layer), r(1:end-1), r(2:end));
    path_len = sum(data.dist_snd_layer(ind));
    assert(Is_Close(new_route.length(i), path_len, 1e-4));

    % occupied capacity
    customers = r(2:end-1);
    sum_demand = sum(data.dmd_sfs(customers-data.num_store));
    assert(Is_Close(sum_demand, new_route.occupied_capacity(i), 1e-4));

    % exceeded capacity
    exceeded = max([sum_demand - data.cap_vhc, 0]);
    assert(Is_Close(exceeded, new_route.exceeded_capacity(i), 1e-4));

    % cost - fixed
    fixed_cost = data.fixed_vhc * ~isempty(customers);
    assert(Is_Close(fixed_cost, new_route.cost.fixed(i), 1e-4));

    % cost - routing
    routing_cost = path_len * data.coef_sfs;
    assert(Is_Close(routing_cost, new_route.cost.route(i), 1e-4));

    % cost - penalty capacity
    penalty_capacity = exceeded * param_ts.PEN;
    assert(Is_Close(penalty_capacity, new_route.cost.penalty_capacity(i), ...
        1e-4));

    % cost - diversity
    f = param_ts.DIV * new_route.cost.total * sqrt(data.num_cus*employ_num);
    div_cost = f * sum(frequency(i, customers-data.num_store));

    is_inferior = ...
        new_route.cost.total + sum(new_route.cost.penalty_capacity) > ...
        old_route.cost.total + sum(old_route.cost.penalty_capacity);
    if is_inferior
        assert(Is_Close(new_route.cost.diversity(i), div_cost, 1e-4));
    else
        new_route.cost.diversity(i) = 0;
    end
end

% cost total cost
total = sum(new_route.cost.fixed+new_route.cost.route);
assert(Is_Close(total, new_route.cost.total, 1e-4));

% cost generalized
general_cost = ...
    total + sum(new_route.cost.diversity+new_route.cost.penalty_capacity);
assert(Is_Close(general_cost, new_route.cost.generalized, 1e-4));

% customer index
waypoints = new_route.waypoints;
sequence = zeros(1, data.num_cus);
count = 1;
for i = 1:length(waypoints)
    len = length(waypoints{i}(2:end - 1));
    sequence(count:count+len-1) = waypoints{i}(2:end - 1);
    count = count + len;
end
assert(all(sort(unique(sequence))-data.num_store == 1:data.num_cus));
end
