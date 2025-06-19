% Dataset result analyze
% (c) Copyright 2025 Runfeng Yu

clc
clear
close all

% file name resolution
% log_path = './result/matlab/nguyen/';
log_path = './result/matlab/prodhon/';

file_list = dir([log_path, '*.mat']);
file_list = natsortfiles({file_list.name})';
segment_list = cell(length(file_list), 3);

for i = 1:length(file_list)
    f_name = file_list{i};
    temp = split(f_name, '-r-');
    segment_list{i, 1} = temp{1};

    temp = split(temp{2}, '-');
    segment_list{i, 2} = str2double(temp{1});
    segment_list{i, 3} = str2double(temp{2}(1:end - 4));
end
dataset_name = segment_list(:, 1);
dataset_name = unique(dataset_name);

clear i f_name temp file_list

% find best results
sz = [length(dataset_name), 5];
var_types = {'string', 'double', 'double', 'double', 'double'};
var_names = {'name', 'min-val', 'min-run', 'max-value', 'LR-gap'};
result_tb = table('Size', sz, 'VariableTypes', var_types, ...
    'VariableNames', var_names);

for j = 1:length(dataset_name)
    d_name = dataset_name{j};
    min_value = inf;
    max_value = -inf;
    ind = -1;

    for i = 1:size(segment_list, 1)
        if ~strcmp(d_name, segment_list{i, 1})
            continue
        end

        value = segment_list{i, 3};
        if value < min_value
            min_value = value;
            ind = segment_list{i, 2};
        end

        if value > max_value
            max_value = value;
        end
    end

    % read log and calculate the average LR-gap
    best_log_path = [log_path, d_name, '-r-', num2str(ind), '.txt'];
    f = fopen(best_log_path);
    count = 0;
    gap_sum = 0;
    while ~feof(f)
        line = fgetl(f);
        tokens = regexp(line, 'Gap:\s*([\d.]+)%', 'tokens');
        if ~isempty(tokens)
            gap_value = str2double(tokens{1}{1});
            count = count + 1;
            gap_sum = gap_sum + gap_value;
        end
    end

    temp = [{string(d_name)}, {min_value}, {ind}, {max_value}, {gap_sum/count}];
    result_tb(j, :) = temp;
end
