function super_cus = Super_Cus_Get_From_Cycle(cycles, data)
% SUPER_CUS_GET_FROM_CYCLE Aggregate cycles (without stores) to super-customers
% (c) Copyright 2025 Runfeng Yu

% assert(size(cycles, 2) == 1); % cycles should be a column cell array
super_cus_num = size(cycles, 1);
super_demand = zeros(super_cus_num, 1);

insert_position = zeros(super_cus_num, data.num_store);
dist_to_store = zeros(super_cus_num, data.num_store); % find insert position

for i = 1:super_cus_num
    % get a customer sequence
    cus_sequence = cycles{i};
    % assert(all(cus_sequence > data.num_store));
    % assert(~isempty(cus_sequence));

    position_num = length(cus_sequence);
    super_demand(i) = sum(data.dmd_sfs(cus_sequence-data.num_store));

    % calculate the length of a cycle (sequence)
    arc_end = [cus_sequence(2:end), cus_sequence(1)];
    temp_ind = sub2ind(size(data.dist_snd_layer), cus_sequence, arc_end);
    cycle_len = sum(data.dist_snd_layer(temp_ind));

    % insert each store at each position
    dist_store_at_pos = zeros(data.num_store, position_num);
    for store = 1:data.num_store
        for position = 1:position_num
            % the 1st position is after the 1st customer
            node_before = cus_sequence(position);
            if position + 1 > length(cus_sequence)
                node_after = cus_sequence(1); % out-of-bounds -> go to the first
            else
                node_after = cus_sequence(position+1);
            end

            dist_store_at_pos(store, position) = cycle_len - ...
                data.dist_snd_layer(node_before, node_after) + ...
                data.dist_snd_layer(node_before, store) + ...
                data.dist_snd_layer(store, node_after);
        end
        [dist_to_store(i, :), insert_position(i, :)] = ...
            min(dist_store_at_pos, [], 2);
    end
end

% keep the sequence of fields in super-customer
super_cus = struct();
super_cus.cycle = cycles;
super_cus.dist_mat = dist_to_store';
super_cus.demand = super_demand;
super_cus.num = super_cus_num;
super_cus.insert_position = insert_position';
super_cus.is_feasible = all(super_demand <= data.cap_vhc);
end
