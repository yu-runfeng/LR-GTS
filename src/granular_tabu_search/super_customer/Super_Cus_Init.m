function sp_cus = Super_Cus_Init()
% SUPER_CUS_INIT Initialize empty super-customers
% provide a template and a field sequence for code generation
% (c) Copyright 2025 Runfeng Yu

sp_cus.cycle = {0};
sp_cus.dist_mat = zeros(0, 1);
sp_cus.demand = zeros(0, 1);
sp_cus.num = 0;
sp_cus.insert_position = zeros(0, 1);
sp_cus.is_feasible = false;

coder.varsize('sp_cus.cycle', [inf, 1]);
coder.varsize('sp_cus.dist_mat', 'sp_cus.demand', 'sp_cus.insert_position');
end
