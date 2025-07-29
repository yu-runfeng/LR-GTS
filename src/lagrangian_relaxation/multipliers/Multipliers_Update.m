function multipliers = Multipliers_Update(multipliers, l_bnd, ub_val, constant)
% MULTIPLIERS_UPDATE Update multipliers (subgradient method)
% (c) Copyright 2025 Runfeng Yu

% step size
denominator = sum(abs(l_bnd.upd_dir.gamma), "all") + ...
    sum(abs(l_bnd.upd_dir.kappa), "all");
step = (ub_val - l_bnd.value) / denominator;

% update
multipliers.gamma = multipliers.gamma + constant * step * l_bnd.upd_dir.gamma;
multipliers.gamma(multipliers.gamma(:) < 0) = 0;

multipliers.kappa = multipliers.kappa + constant * step * l_bnd.upd_dir.kappa;
multipliers.kappa(multipliers.kappa(:) < 0) = 0;
end
