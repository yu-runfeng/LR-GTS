function super_cus = Super_Cus_Init_From_Data(data, param_lr)
% SUPER_CUS_INIT_FROM_DATA Create routes and initialize the super_cus structure
% (c) Copyright 2025 Runfeng Yu

% initialize a location plan
ub_sol = Lagrangian_Relaxation(data, Get_Trivial_Super_Cus(data), param_lr);
opened_store = find(ub_sol.binary_location == true);

% assign each customer to the nearest opened store
assignment = zeros(1, data.num_cus);
for counter = 1:data.num_cus
    [~, min_ind] = ...
        min(data.dist_snd_layer(data.ind_cus(counter), ub_sol.binary_location));
    assignment(counter) = opened_store(min_ind);
end

% routing with Clarke-Wright saving
utilized_store = unique(opened_store);

% initialize the super_cus structure, suitable for Coder
temp = zeros(1, 0);
coder.varsize("temp", [1, inf]);
customer_cycles = {temp};
coder.varsize("customer_cycles", [inf, 1]);

counter = 1;
for i = 1:length(utilized_store)
    store_ind = utilized_store(i);
    cus_of_store = data.ind_cus(assignment == store_ind);
    temp_cycles = Cw_Saving(store_ind, cus_of_store, data);

    % Coder does not support "()" for cell array assignment
    % customer_cycles(counter:counter + length(temp_cycles) - 1) = temp_cycles;

    % dynamically expand the cell array
    if counter + length(temp_cycles) - 1 > length(customer_cycles)
        num = counter + length(temp_cycles) - 1 - length(customer_cycles);
        temp_cell = repmat({zeros(1, 0)}, num, 1);
        customer_cycles = [customer_cycles; temp_cell];
    end
    % assert(length(customer_cycles) == counter+length(temp_cycles)-1);
    for j = 1:length(temp_cycles)
        customer_cycles{counter+j-1, 1} = temp_cycles{j};
    end

    counter = counter + length(temp_cycles);
end

customer_cycles(cellfun(@isempty, customer_cycles)) = [];
if length(customer_cycles) > data.num_vhc
    warning('vehicle number may be NOT sufficient large');
end

super_cus = Super_Cus_Get_From_Cycle(customer_cycles, data);
end

function super_cus = Get_Trivial_Super_Cus(data)
% GET_SUPER_CUS_STRUCT Treat every customer as a super customer.
super_cus = Super_Cus_Init();
super_cus.cycle = cell(data.num_cus, 1);
super_cus.dist_mat = ...
    data.dist_snd_layer(data.ind_ws, data.ind_cus) + ...
    data.dist_snd_layer(data.ind_cus, data.ind_ws)';
super_cus.demand = data.dmd_sfs;
super_cus.num = length(data.dmd_sfs);
super_cus.insert_position = zeros(data.num_store, data.num_cus);
end

function routes_of_store = Cw_Saving(store_ind, cus_of_store, data)
% Route vehicles for visiting customers of the store with Clarke-Wright
% savings heuristics.
% Ref: Laporte, G., Semet, F., 2002. Classical Heuristics for the Capacitated
% VRP. chapter 5. pp. 109-128.

% initialize, suitable for Coder
routes_of_store = {0};
coder.varsize('routes_of_store', [inf, 1]);
coder.varsize('routes_of_store{:}', [1, inf]);
direct_dist = ...
    data.dist_snd_layer(cus_of_store, store_ind) + ...
    data.dist_snd_layer(store_ind, cus_of_store)';
route_counter = 1;

while ~isempty(cus_of_store)
    cus_sequence = zeros(1, length(cus_of_store));
    cus_num_in_route = 1; % customer numbers in the route (matlab starts from 1)
    carrying_demand = 0;

    % add customers in the route
    while true
        if isempty(cus_of_store)
            % dynamically expand the cell array
            if route_counter > length(routes_of_store)
                % assert(route_counter == length(routes_of_store)+1);
                routes_of_store = [routes_of_store; {0}];
            end
            routes_of_store{route_counter, 1} = cus_sequence;
            break
        end

        if cus_num_in_route == 1
            [~, max_ind] = max(direct_dist);
            cus_sequence(cus_num_in_route) = cus_of_store(max_ind); % farthest
            carrying_demand = ...
                data.dmd_sfs(cus_of_store(max_ind)-data.num_store);

            cus_num_in_route = cus_num_in_route + 1;
            cus_of_store(max_ind) = [];
            direct_dist(max_ind) = [];
            continue
        end

        full_route = [store_ind, cus_sequence(cus_sequence ~= 0), store_ind];
        num_position = length(full_route) - 1;
        num_cus_left = length(cus_of_store);

        increase_len = zeros(num_cus_left, num_position);
        decrease_len = repmat(direct_dist, 1, num_position);

        % insert each customer at every position
        for pos = 1:num_position
            node_before_pos = full_route(pos);
            node_after_pos = full_route(pos+1);
            decrease_len(:, pos) = decrease_len(:, pos) + ...
                data.dist_snd_layer(node_before_pos, node_after_pos);
            for j = 1:num_cus_left
                insert_cus_ind = cus_of_store(j);
                if data.cap_vhc < carrying_demand + ...
                        data.dmd_sfs(insert_cus_ind-data.num_store)
                    increase_len(j, pos) = inf; % infeasible insert
                    continue
                end
                increase_len(j, pos) = ...
                    data.dist_snd_layer(node_before_pos, insert_cus_ind) + ...
                    data.dist_snd_layer(insert_cus_ind, node_after_pos);
            end
        end

        % calculate the max savings
        saved_dist = decrease_len - increase_len;
        if all(saved_dist(:) < 0)
            % all position causes a distance increment -> open a new route
            if route_counter > length(routes_of_store)
                % dynamically expand the cell array
                % assert(route_counter == length(routes_of_store)+1);
                routes_of_store = [routes_of_store; {0}];
            end

            routes_of_store{route_counter, 1} = cus_sequence(cus_sequence ~= 0);
            route_counter = route_counter + 1;
            break
        else
            % find the max savings
            [select_ind, position] = find(saved_dist == max(saved_dist(:)), 1);

            % coder needs an extra '(1)' index.
            % It seems that it can not identify '1' in find()
            insert_cus_ind = cus_of_store(select_ind(1));

            % update
            cus_sequence(1:cus_num_in_route) = [full_route(2:position(1)), ...
                insert_cus_ind, full_route(position(1)+1:end-1)];
            carrying_demand = carrying_demand + ...
                data.dmd_sfs(insert_cus_ind-data.num_store);
            cus_num_in_route = cus_num_in_route + 1;

            % delete the customer
            cus_of_store(select_ind(1)) = [];
            direct_dist(select_ind(1)) = [];
        end
    end
end
end
