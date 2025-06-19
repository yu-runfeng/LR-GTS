function u_bound = Ub_Improve(u_bound, data, super_cus, l_bound, param_lr)
% UB_IMPROVE Improve the upper bound with local search
% (c) Copyright 2025 Runfeng Yu

% binary_location may changed during the search
binary_location = u_bound.binary_location;
neighbors = repmat(u_bound, 1, 3);
neighbor_vals = zeros(1, 3);
while 1
    neighbors(1) = Close_Store(data, super_cus, binary_location, u_bound);
    neighbor_vals(1) = neighbors(1).value;
    if Get_Gap(neighbors(1).value, l_bound.value) < param_lr.LR_GAP
        u_bound = neighbors(1);
        return
    end

    neighbors(2) = Open_Store(data, super_cus, binary_location, u_bound);
    neighbor_vals(2) = neighbors(2).value;
    if Get_Gap(neighbors(2).value, l_bound.value) < param_lr.LR_GAP
        u_bound = neighbors(2);
        return
    end

    neighbors(3) = Switch_Store(data, super_cus, binary_location, u_bound);
    neighbor_vals(3) = neighbors(3).value;
    if Get_Gap(neighbors(3).value, l_bound.value) < param_lr.LR_GAP
        u_bound = neighbors(3);
        return
    end

    [~, min_ind] = min(neighbor_vals);
    if neighbors(min_ind).value >= u_bound.value
        break
    else
        u_bound = neighbors(min_ind);
        binary_location = neighbors(min_ind).binary_location;
    end
end
end

function best_neighbor = Close_Store(data, super_cus, binary_location, ub)
% close an opened store

best_neighbor = ub;
opened_shops = find(binary_location == 1);
if opened_shops ~= 0
    open_num = length(opened_shops);
    result = cell(open_num, 1);
    rec_val_ub = inf * ones(open_num, 1);
    for i = 1:open_num
        result{i} = ub; % Coder requires
    end

    if open_num > 1
        for i = 1:length(opened_shops)
            closed_shops = opened_shops(i);
            location_copy = binary_location;
            location_copy(closed_shops) = 0;
            result{i} = Ub_Get_Value(data, super_cus, location_copy);
            rec_val_ub(i) = result{i}.value;
        end

        [min_val, min_ind] = min(rec_val_ub);
        if min_val < best_neighbor.value
            best_neighbor = result{min_ind};
        end
    end
end
end

function best_neighbor = Open_Store(data, super_cus, binary_location, ub)
% open a closed store

best_neighbor = ub;
closed_shops = find(binary_location == 0);
if closed_shops ~= 0
    close_num = length(closed_shops);
    cell_close = cell(close_num, 1);
    rec_val_ub = inf * ones(close_num, 1);
    for i = 1:close_num
        cell_close{i} = ub; % Coder requires
    end

    for i = 1:close_num
        opened_shop = closed_shops(i);
        location_copy = binary_location;
        location_copy(opened_shop) = 1;
        temp_ub = Ub_Get_Value(data, super_cus, location_copy);
        cell_close{i} = temp_ub;
        rec_val_ub(i) = temp_ub.value;
    end
    [min_val, min_ind] = min(rec_val_ub);
    if min_val < best_neighbor.value
        best_neighbor = cell_close{min_ind};
    end
end
end

function best_neighbor = Switch_Store(data, super_cus, binary_location, ub)
% close one but open another

best_neighbor = ub;
opened_shops = find(binary_location == 1);
open_num = length(opened_shops);
closed_shops = find(binary_location == 0);
close_num = length(closed_shops);
opened_shops = repmat(opened_shops', close_num, 1);

cell_exchange = cell(close_num, open_num);
for i = 1:close_num
    for j = 1:open_num
        cell_exchange{i, j} = ub;
    end
end
rec_val_ub = inf * ones(close_num, open_num);

if open_num ~= 0 && close_num ~= 0
    for i = 1:close_num
        open_ind = closed_shops(i);
        for j = 1:open_num
            close_ind = opened_shops(i, j);
            location_copy = binary_location;
            location_copy([open_ind, close_ind]) = ...
                location_copy([close_ind, open_ind]);
            temp_ub = Ub_Get_Value(data, super_cus, location_copy);
            cell_exchange{i, j} = temp_ub;
            rec_val_ub(i, j) = temp_ub.value;
        end
    end
    [min_val, min_ind] = min(rec_val_ub(:));
    if min_val < best_neighbor.value
        best_neighbor = cell_exchange{min_ind};
    end
end
end
