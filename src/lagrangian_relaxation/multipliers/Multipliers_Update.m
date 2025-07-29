function multipliers = Multipliers_Update(multipliers, l_bnd, ub_val, constant)
% MULTIPLIERS_UPDATE Update multipliers (subgradient method)
% (c) Copyright 2025 Runfeng Yu

% step size
denominator = ...
    sum(abs(l_bnd.upd_dir.beta), "all") + sum(abs(l_bnd.upd_dir.mu), "all");
step = (ub_val - l_bnd.value) / denominator;

% update
multipliers.beta = multipliers.beta + constant * step * l_bnd.upd_dir.beta;
multipliers.beta(multipliers.beta(:) < 0) = 0;

multipliers.mu = multipliers.mu + constant * step * l_bnd.upd_dir.mu;
multipliers.mu(multipliers.mu(:) < 0) = 0;
end
