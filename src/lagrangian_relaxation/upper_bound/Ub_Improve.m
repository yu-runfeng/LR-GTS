function u_bound = Ub_Improve(u_bound, data, super_cus, l_bound, param_lr)
% UB_IMPROVE Improve the upper bound with local search
% (c) Copyright 2025 Runfeng Yu

% binary_location may changed during the search
binary_location = u_bound.binary_location;
while 1
    best_neighbor = Get_Best_Neighbor(data, super_cus, binary_location, ...
        u_bound, l_bound.value, param_lr.LR_GAP);
    if best_neighbor.value >= u_bound.value
        break
    else
        u_bound = best_neighbor;
        binary_location = best_neighbor.binary_location;
    end
end
end

function best_neighbor = Get_Best_Neighbor(data, super_cus, binary_location, ...
    ub, lb_val, acceptable_gap)
best_neighbor = ub;
% close an opened store
opened_shops = find(binary_location == 1);
if opened_shops ~= 0
    open_num = length(opened_shops);
    cell_open = cell(open_num, 1);
    rec_val_ub = inf * ones(open_num, 1);
    for i = 1:open_num
        cell_open{i} = ub; % Coder requires
    end

    if open_num > 1
        for i = 1:open_num
            closed_shops = opened_shops(i);
            location_cp = binary_location;
            location_cp(closed_shops) = 0;
            cell_open{i} = Ub_Get_Value(data, super_cus, location_cp);
            rec_val_ub(i) = cell_open{i}.value;
        end
        [min_val, min_ind] = min(rec_val_ub);
        if min_val < best_neighbor.value
            best_neighbor = cell_open{min_ind};
        end
    end
end
gap = Get_Gap(best_neighbor.value, lb_val);
if gap < acceptable_gap
    return
end

% open a closed store
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
        location_cp = binary_location;
        location_cp(opened_shop) = 1;
        temp_ub = Ub_Get_Value(data, super_cus, location_cp);
        cell_close{i} = temp_ub;
        rec_val_ub(i) = temp_ub.value;
    end
    [min_val, min_ind] = min(rec_val_ub);
    if min_val < best_neighbor.value
        best_neighbor = cell_close{min_ind};
    end
end
gap = Get_Gap(best_neighbor.value, lb_val);
if gap < acceptable_gap
    return
end

% close one but open another
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
            location_cp = binary_location;
            location_cp([open_ind, close_ind]) = ...
                location_cp([close_ind, open_ind]);
            temp_ub = Ub_Get_Value(data, super_cus, location_cp);
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
