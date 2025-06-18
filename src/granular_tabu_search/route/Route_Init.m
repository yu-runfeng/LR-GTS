function route = Route_Init()
% ROUTE_INIT Create a route structure and define its field sequence for Coder
% (c) Copyright 2025 Runfeng Yu

x = zeros(0, 1);
coder.varsize("x");
y = cell(0, 1);
coder.varsize("y");

route.waypoints = y;
route.length = x;
route.occupied_capacity = x;
route.exceeded_capacity = x;
route.cost = Cost_Init();
end
