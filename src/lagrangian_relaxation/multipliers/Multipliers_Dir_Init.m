function update_direction = Multipliers_Dir_Init(multipliers)
%MULTIPLIERS_DIR_INIT Update directions of multipliers
% (c) Copyright 2025 Runfeng Yu

update_direction = struct();
update_direction.alpha = zeros(size(multipliers.alpha));
update_direction.beta = zeros(size(multipliers.beta));
update_direction.gamma = zeros(size(multipliers.gamma));
update_direction.mu = zeros(size(multipliers.mu));
update_direction.kappa = zeros(size(multipliers.kappa));
end
