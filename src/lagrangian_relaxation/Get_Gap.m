function gap = Get_Gap(u_bound_val, l_bound_val)
% GET_GAP Returns a gap between the upper bound and the lower bound
% (c) Copyright 2025 Runfeng Yu

gap = (u_bound_val - l_bound_val) / u_bound_val;
end
