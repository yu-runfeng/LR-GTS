function upd_dir = Multipliers_Get_Dir(multipliers, l_bound, data)
%MULTIPLIERS_GET_DIR Get multipliers update directions
% (c) Copyright 2025 Runfeng Yu

% update direction
upd_dir = Multipliers_Dir_Init(multipliers);
upd_dir.alpha = Get_Dir_Alpha(l_bound.sfs_assign, l_bound.binary_location, ...
    size(multipliers.alpha));
upd_dir.beta = Get_Dir_Beta(l_bound.bops_attempt, l_bound.binary_location, ...
    size(multipliers.beta));
upd_dir.gamma = Get_Dir_Gamma(l_bound.os_attempt, l_bound.binary_location, ...
    size(multipliers.gamma));
upd_dir.mu = Get_Dir_Mu(l_bound.bops_attempt, l_bound.binary_location, ...
    size(multipliers.mu), data);
upd_dir.kappa = Get_Dir_Kappa(l_bound.os_attempt, l_bound.binary_location, ...
    size(multipliers.kappa), data);
end

function dir_alpha = Get_Dir_Alpha(sfs_assign, binary_location, alpha_sz)
% get update directions of multipliers-alpha
% Dir_{ip} = X_{ip} - v_i
dir_alpha = zeros(alpha_sz); % build X_{ip}
for p = 1:alpha_sz(2)
    dir_alpha(sfs_assign(p), p) = 1;
end
dir_alpha = bsxfun(@minus, dir_alpha, binary_location); % subtract v_i
end

function dir_beta = Get_Dir_Beta(bops_attempt, binary_location, beta_sz)
% get update directions of multipliers-beta
% Dir_{im} = \sum_{r=1}^{R} y_{imr} - v_i
dir_beta = zeros(beta_sz); % \sum_{r=1}^{R} y_{imr}: times of customer m use i
for m = 1:beta_sz(2)
    attempt = bops_attempt(m, :);
    attempt(attempt == 0 | attempt == -1) = [];
    for i = 1:length(attempt)
        store_ind = attempt(i);
        dir_beta(store_ind, m) = dir_beta(store_ind, m) + 1;
    end
end
dir_beta = bsxfun(@minus, dir_beta, binary_location); % subtract v_i
end

function dir_gamma = Get_Dir_Gamma(os_attempt, binary_location, gamma_sz)
% get update directions of multipliers-gamma
% \sum_{k\in I_{ni}^+}z_{ki}^{n} (times of customer n use i) - v_i
dir_gamma = zeros(gamma_sz);
for n = 1:gamma_sz(2)
    attempt = os_attempt(n, :);
    attempt(attempt == 0 | attempt == -1) = [];
    for i = 1:length(attempt)
        store_ind = attempt(i);
        dir_gamma(store_ind, n) = dir_gamma(store_ind, n) + 1;
    end
end
dir_gamma = bsxfun(@minus, dir_gamma, binary_location); % subtract v_i
end

function dir_mu = Get_Dir_Mu(bops_attempt, binary_location, mu_sz, data)
% get update directions of multipliers-mu
% \sum_{j:d_{mj}>d_{mi}}y_{j1}^m (customer n use j) + v_i - 1
dir_mu = zeros(mu_sz);
for m = 1:mu_sz(2)
    temp_dist = data.dist_snd_layer(m, data.ind_store);
    for i = 1:mu_sz(1)
        temp_length = data.dist_snd_layer(m, i);
        j_set_ind = temp_dist > temp_length;
        if ~isempty(j_set_ind)
            if bops_attempt(m, 1) ~= 0 && j_set_ind(bops_attempt(m, 1))
                dir_mu(i, m) = 1;
            end
        end
    end
end
dir_mu = bsxfun(@minus, dir_mu, binary_location) - 1;
end

function dir_kappa = Get_Dir_Kappa(os_attempt, binary_location, kappa_sz, data)
% get update directions of multipliers-kappa
% \sum_{j: d_{n j}>d_{n i}} z_{n j}^{n}+v_{i} - 1
dir_kappa = zeros(kappa_sz);
for m = 1:kappa_sz(2)
    for i = 1:kappa_sz(1)
        j_set = find(data.dist_snd_layer(m, data.ind_store) > ...
            data.dist_snd_layer(m, i));
        if any(j_set == os_attempt(m, 1))
            dir_kappa(i, m) = 1;
        end
    end
end
dir_kappa = bsxfun(@minus, dir_kappa, binary_location) - 1;
end
