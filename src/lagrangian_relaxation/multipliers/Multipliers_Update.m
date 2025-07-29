function multipliers = Multipliers_Update(multipliers, l_bnd, ub_val, constant)
% MULTIPLIERS_UPDATE Update multipliers (subgradient method)
% (c) Copyright 2025 Runfeng Yu

% step size
denominator = sum(abs(l_bnd.upd_dir.alpha), "all");
step = (ub_val - l_bnd.value) / denominator;

% update
multipliers.alpha = multipliers.alpha + constant * step * l_bnd.upd_dir.alpha;
multipliers.alpha(multipliers.alpha(:) < 0) = 0;
end
