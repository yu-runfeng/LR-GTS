function best_sol = Lagrangian_Relaxation(data, super_customers, param_lr)
% LAGRANGIAN_RELAXATION Lagrangian relaxation for the reformulated model
% (c) Copyright 2025 Runfeng Yu

% initialize
multipliers = Multipliers_Init(data, super_customers.num);
best_sol = Ub_Init(data, super_customers);
best_sol.value = inf;
best_lb_val = -inf;

step_scalar = param_lr.STEP_SCALAR;
history_sol = dictionary(uint64(0), {best_sol});
is_local_search = true;
counter_local_search = 1;
counter_ub_remain = 1;
start_time = tic;
format_spec = 'LR  Iter: %04d UB: %10.2f Const: %8.6f Gap: %5.2f%%\n';
for iter = 1:param_lr.ITER_MAX
    % lower bound
    l_bound = Lb_Get_Value(data, super_customers, multipliers);
    if l_bound.value > best_lb_val
        best_lb_val = l_bound.value;
    end

    % upper bound
    if is_local_search
        % assert(size(l_bound.binary_location, 2) == 1);
        key_hash = Hash_Logical_Array(l_bound.binary_location);
        is_in_history = isKey(history_sol, key_hash);
        if is_in_history
            temp_cell = lookup(history_sol, key_hash);
            if any(temp_cell{1}.binary_location ~= l_bound.binary_location)
                is_in_history = false; % hash collision
            end
        end

        if ~is_in_history || iter == 1
            u_bound = ...
                Ub_Get_Value(data, super_customers, l_bound.binary_location);
            u_bound = ...
                Ub_Improve(u_bound, data, super_customers, l_bound, param_lr);
        else
            temp_cell = lookup(history_sol, key_hash);
            u_bound = temp_cell{1};

            % [DEBUG]
            % test = Ub_Get_Value(data, super_customers, l_bound.binary_location);
            % assert(test.value == u_bound.value);
        end

        counter_local_search = counter_local_search + 1;
        if counter_local_search > param_lr.ITER_SEARCH
            is_local_search = false;
        end
    else
        u_bound = Ub_Get_Value(data, super_customers, l_bound.binary_location);
    end

    if u_bound.value < best_sol.value
        best_sol = u_bound;
        is_local_search = true;
        counter_local_search = 1;
        counter_ub_remain = 0;
    end

    % update
    multipliers = Multipliers_Update(multipliers, l_bound, best_sol.value, ...
        step_scalar);

    if counter_ub_remain > param_lr.ITER_UNIMP
        step_scalar = step_scalar / param_lr.STEP_DEC;
        counter_ub_remain = 0;
    end
    counter_ub_remain = counter_ub_remain + 1;

    gap = Get_Gap(best_sol.value, l_bound.value);
    history_sol(Hash_Logical_Array(u_bound.binary_location)) = {u_bound};

    % print each step
    if param_lr.PRINT_FLAG
        fprintf(format_spec, ...
            int16(iter), best_sol.value, step_scalar, gap*100);
    end

    % terminate condition
    if gap < param_lr.LR_GAP
        Print_Log(format_spec, iter, best_sol.value, ...
            best_sol.binary_location, step_scalar, gap, 1);
        return
    end

    if step_scalar < param_lr.STEP_MIN
        Print_Log(format_spec, iter, best_sol.value, ...
            best_sol.binary_location, step_scalar, gap, 2);
        return
    end

    elapsed_time = toc(start_time);
    if elapsed_time > param_lr.TIME_LIMIT
        Print_Log(format_spec, iter, best_sol.value, ...
            best_sol.binary_location, step_scalar, gap, 3);
        return
    end

    if iter == param_lr.ITER_MAX
        Print_Log(format_spec, iter, best_sol.value, ...
            best_sol.binary_location, step_scalar, gap, 4);
        return
    end
end
end

function Print_Log(format_spec, iter, sol_value, binary_location, ...
    step_scalar, gap, number)
fprintf(format_spec, int16(iter), sol_value, step_scalar, gap*100);
switch number
    case 1
        % disp('LR terminate with an acceptable gap');
    case 2
        % disp('LR terminate with a sufficient small scalar');
    case 3
        % disp('LR terminate with max time limit');
    case 4
        % disp('LR terminate with max iteration limit');
    otherwise
end
disp('Location: ');
disp(find(binary_location == true)');
end
