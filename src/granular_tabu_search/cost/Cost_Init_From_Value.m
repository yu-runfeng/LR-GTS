function cost = Cost_Init_From_Value(data, trans_cost, route_len, penalty_cap)
% COST_INIT_FROM_VALUE Initialize cost structure from given values
% (c) Copyright 2025 Runfeng Yu

cost = Cost_Init();
cost.trans = trans_cost;
cost.fixed = data.fixed_vhc * ones(length(route_len), 1);
cost.route = route_len * data.coef_sfs;
cost.total = sum(cost.trans+cost.fixed+cost.route);

cost.penalty_capacity = penalty_cap;
cost.diversity = zeros(length(penalty_cap), 1);

cost.generalized = cost.total + sum(cost.penalty_capacity+cost.diversity);
end
