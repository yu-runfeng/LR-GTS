function cost = Cost_Init()
% COST_INIT Create empty cost structure
% (c) Copyright 2025 Runfeng Yu

x = zeros(0, 1);
coder.varsize("x");

cost = struct();
cost.fixed = x;
cost.route = x;

% total cost (contribute to the objective function) is the sum of transportation
% cost, fixed cost, and routing cost.
cost.total = 0;

cost.penalty_capacity = x;
cost.diversity = x;

% generalized cost (guiding tabu search) is the sum of total cost, penalty cost,
% and diversity cost
cost.generalized = 0;
end
