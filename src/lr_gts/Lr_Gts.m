function best_known_sol = Lr_Gts(data, param_lr_gts, param_lr, param_gts)
% LR_GTS Lagrangian relaxation and granular tabu search
% (c) Copyright 2025 Runfeng Yu

Print_Copyright(param_lr, param_gts);

% initialization
t = tic;
super_cus = Super_Cus_Init_From_Data(data, param_lr);
solution = Lagrangian_Relaxation(data, super_cus, param_lr);

best_known_sol = Ub_Init(data, super_cus);
best_known_sol.value = inf;
unimproved_count = 0;
format_spec = 'Unimproved count: %3d Global Best Objective value: %.2f\n';

disp("-------------------------------------------------------------------");
while 1
    super_cus = Granular_Tabu_Search(data, solution, param_gts);
    solution = Lagrangian_Relaxation(data, super_cus, param_lr);

    if solution.value < best_known_sol.value && super_cus.is_feasible
        % update best known solution
        best_known_sol = solution;
        unimproved_count = 0;
    else
        % rebuild super customers (Cyclic exchange disturbance)
        super_cus = Super_Cus_Cyclic_Exchange(super_cus, data);
        solution = Lagrangian_Relaxation(data, super_cus, param_lr);
        unimproved_count = unimproved_count + 1;
    end

    % terminate condition
    if unimproved_count > param_lr_gts.ITER_UNIMP
        toc(t);
        break
    end

    if toc(t) > param_lr_gts.TIME_LIMIT
        toc(t);
        break
    end

    % print log
    fprintf(format_spec, int64(unimproved_count), best_known_sol.value);
    toc(t);
    disp("-------------------------------------------------------------------");
end
end

function Print_Copyright(param_lr, param_gts)
disp("-------------------------------------------------------------------");
disp("LR-GTS by Runfeng Yu");
% disp(['Start at: ', char(datetime('now'))])
disp("Param setting: ");
disp(param_lr);
disp(param_gts);
disp("-------------------------------------------------------------------");
end
