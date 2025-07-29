function super_cus = Granular_Tabu_Search(data, current_sol, param_ts)
% GRANULAR_TABU_SEARCH Granular tabu search for improving route quality
% (c) Copyright 2025 Runfeng Yu

% initialization
opened_store = find(current_sol.binary_location == true);
route = Route_Init_From_Sol(data, current_sol, param_ts.PEN);
frequency = zeros(data.num_cus); % row: vehicle, col: customer
for i = 1:length(route.waypoints)
    cus_ind = route.waypoints{i}(2:end - 1) - data.num_store;
    frequency(i, cus_ind) = frequency(i, cus_ind) + 1;
end
arc_num = sum(cellfun(@length, route.waypoints)) - length(route.waypoints);
init_granularity = sum(route.length) / arc_num;
param_ts.GRN = init_granularity;
best_feasible_route = route;
tabu_list = Tabu_List_Init();
max_granularity = max(data.dist_snd_layer, [], "all");

% counter
unimproved_global_count = 0;
unimproved_granular_count = 0;
feasible_count = 0;
infeasible_count = 0;

% flag
is_random_status = false;

% iteration
current_route = route;
iter_rec = 0;
for iter = 1:param_ts.ITER_MAX
    is_better_solution = false;
    tabu_len = param_ts.TABU_MIN + ...
        ceil(rand * (param_ts.TABU_MAX - param_ts.TABU_MIN));
    tabu_list_seg = Tabu_List_Get_Segment(tabu_list, tabu_len);

    if is_random_status
        % random search, approximately restart
        break_arcs = [0, 0];
        for random_iter = 1:param_ts.DIV_ITER_RAND
            current_route = Route_Append_Empty(current_route, opened_store);
            [current_route, break_arcs] = Route_Get_Random_Neighbor( ...
                current_route, data, tabu_list_seg, frequency, param_ts);
            tabu_list = ...
                Tabu_List_Insert(tabu_list, break_arcs, param_ts.TABU_MAX);
        end
        is_random_status = false;
        unimproved_global_count = 0;
        unimproved_granular_count = 0;
        param_ts.GRN = init_granularity;
    else
        % general search
        current_route = Route_Append_Empty(current_route, opened_store);
        [current_route, break_arcs, is_success] = Route_Get_Best_Neighbor( ...
            current_route, data, tabu_list_seg, frequency, param_ts);
        if ~is_success
            param_ts.GRN = min([param_ts.GRN * param_ts.GRN_INC, ...
                max_granularity]);
            continue
        end
    end

    % update frequency
    for i = 1:length(current_route.waypoints)
        cus_ind = current_route.waypoints{i}(2:end - 1) - data.num_store;
        frequency(i, cus_ind) = frequency(i, cus_ind) + 1;
    end

    % update tabu list
    tabu_list = Tabu_List_Insert(tabu_list, break_arcs, param_ts.TABU_MAX);

    % update best-known solution and counters
    if current_route.cost.penalty_capacity == 0
        feasible_count = feasible_count + 1;
        infeasible_count = 0;

        if current_route.cost.total < best_feasible_route.cost.total
            % if the current solution is better than the best-known solution,
            % update the best-known solution
            best_feasible_route = current_route;
            unimproved_global_count = 0;
            unimproved_granular_count = 0;
            is_better_solution = true;
        else
            unimproved_global_count = unimproved_global_count + 1;
            unimproved_granular_count = unimproved_granular_count + 1;
        end
    else
        feasible_count = 0;
        infeasible_count = infeasible_count + 1;
        unimproved_global_count = unimproved_global_count + 1;
        unimproved_granular_count = unimproved_granular_count + 1;
    end

    % update granularity
    if unimproved_granular_count >= param_ts.GRN_ITER_UNIMP
        param_ts.GRN = min([param_ts.GRN * param_ts.GRN_INC, max_granularity]);
        unimproved_granular_count = 0;
    end

    % restore granularity
    if is_better_solution
        param_ts.GRN = init_granularity;
    end

    % update capacity penalty and generalized cost
    old_pen_cap = param_ts.PEN;
    if feasible_count >= param_ts.INTER_FEAS
        param_ts.PEN = ...
            max([param_ts.PEN * param_ts.PEN_DEC; param_ts.PEN_MIN]);
        feasible_count = 0;
    end
    if infeasible_count >= param_ts.INTER_INFS
        param_ts.PEN = ...
            min([param_ts.PEN * param_ts.PEN_INC, param_ts.PEN_MAX]);
        infeasible_count = 0;
    end
    if old_pen_cap ~= param_ts.PEN
        current_route.cost.generalized = current_route.cost.generalized - ...
            sum(current_route.cost.penalty_capacity);
        current_route.cost.penalty_capacity = ...
            current_route.cost.penalty_capacity / old_pen_cap * param_ts.PEN;
        current_route.cost.generalized = current_route.cost.generalized + ...
            sum(current_route.cost.penalty_capacity);
    end

    % update random status
    if unimproved_global_count >= param_ts.DIV_ITER_UNIMP
        is_random_status = true;
    end

    % terminate condition
    if unimproved_global_count >= param_ts.ITER_UNIMP
        iter_rec = iter;
        break
    end
    iter_rec = iter;
end

% print GTS conclusion
fprintf('GTS Iter: %04d BKSCost: %.2f\n', ...
    int64(iter_rec), best_feasible_route.cost.total);

% convert the best feasible route to the super-customer
num = length(best_feasible_route.waypoints);
customer_cycle = cell(num, 1);
for i = 1:num
    customer_cycle{i} = best_feasible_route.waypoints{i}(2:end - 1);
end
customer_cycle(cellfun(@isempty, customer_cycle)) = [];
super_cus = Super_Cus_Get_From_Cycle(customer_cycle, data);
end
