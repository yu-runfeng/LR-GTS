% Draw convergence curves for Tuzun's 36 instances
% (c) Copyright 2025 Runfeng Yu

clc;
clear;
close all;

log_path = './results/tuzun/matlab/log/';

file_list = dir([log_path, '*.txt']);
file_list = natsortfiles({file_list.name})';

figure
count = 1;
for i = 1:length(file_list)
    if ~contains(file_list{i}, 'r-1.')
        continue
    end
    file_path = [log_path, file_list{i}];
    lines = readlines(file_path);
    del_ind = ~contains(lines, "UB");
    lines(del_ind) = [];
    
    val_per_iter = zeros(length(lines), 1);
    for j = 1:length(lines)
        ub_match = regexp(lines(j), 'UB:\s*([\d\.]+)', 'tokens');
        val_per_iter(j) = str2double(ub_match{1});
    end
    bks_per_iter = zeros(size(val_per_iter));
    bks_val = inf;
    for j = 1:length(lines)
        if val_per_iter(j) < bks_val
            bks_val = val_per_iter(j);
        end
        bks_per_iter(j) = bks_val;
    end

    subplot(6, 6, count)
    count = count + 1;
    plot(val_per_iter ./ bks_val, LineWidth=0.8, Color='blue')
    hold on 
    plot(bks_per_iter ./ bks_val, LineWidth=1.0, Color='red')
    ylim([1, 1.8])
    xlim([0, 250])
    set(gca, 'FontSize', 6)
end
