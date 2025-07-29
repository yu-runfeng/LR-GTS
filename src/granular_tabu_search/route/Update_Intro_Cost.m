function cost = Update_Intro_Cost(cost, data, route, changed_ind, ...
    changed_len, employed_num, frequency_sum, param_ts)
% UPDATE_INTRO_COST Update cost for intro-route operator
% (c) Copyright 2025 Runfeng Yu

% fields in cost struct, see src/granular_tabu_search/cost/Cost_Init.m
%   - trans
%   - fixed
%   - route
%   - total = trans + fixed + route
%   - penalty_capacity
%   - diversity
%   - generalized = total + penalty_capacity + diversity

% transportation cost and fixed cost do not change in intro-route operation

% update route cost
old_route_cost = cost.route(changed_ind);
cost.route(changed_ind) = changed_len * data.coef_sfs;

% update total cost
cost.total = cost.total - old_route_cost + cost.route(changed_ind);

% update capacity penalty cost because param_ts.PEN is mutable
cost.penalty_capacity = param_ts.PEN * route.exceeded_capacity;

% diversity cost
is_inferior = cost.total + sum(cost.penalty_capacity) > ...
    route.cost.total + sum(route.cost.penalty_capacity);
if is_inferior
    cost.diversity = param_ts.DIV * cost.total * ...
        sqrt(data.num_cus*employed_num) * frequency_sum;
else
    cost.diversity(:) = 0;
end

% generalized cost
cost.generalized = cost.total + sum(cost.diversity+cost.penalty_capacity);
end
