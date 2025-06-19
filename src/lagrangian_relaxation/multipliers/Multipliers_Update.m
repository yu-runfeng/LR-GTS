function multipliers = ...
    Multipliers_Update(multipliers, upd_dir, ub_val, lb_val, coef)
% MULTIPLIERS_UPDATE Update multipliers (subgradient method)
% (c) Copyright 2025 Runfeng Yu

% step size
denominator = sum(abs(upd_dir.alpha), "all") + ...
    sum(abs(upd_dir.beta), "all") + sum(abs(upd_dir.mu), "all") + ...
    sum(abs(upd_dir.gamma), "all") + sum(abs(upd_dir.kappa), "all");
step = (ub_val - lb_val) / denominator;

% update
multipliers.alpha = multipliers.alpha + coef * step * upd_dir.alpha;
multipliers.alpha(multipliers.alpha(:) < 0) = 0;

multipliers.beta = multipliers.beta + coef * step * upd_dir.beta;
multipliers.beta(multipliers.beta(:) < 0) = 0;

multipliers.mu = multipliers.mu + coef * step * upd_dir.mu;
multipliers.mu(multipliers.mu(:) < 0) = 0;

multipliers.gamma = multipliers.gamma + coef * step * upd_dir.gamma;
multipliers.gamma(multipliers.gamma(:) < 0) = 0;

multipliers.kappa = multipliers.kappa + coef * step * upd_dir.kappa;
multipliers.kappa(multipliers.kappa(:) < 0) = 0;
end
