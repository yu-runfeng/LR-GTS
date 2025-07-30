% This script processes log files containing performance results, extracts
% relevant metrics, organizes them into a table, and generates analysis figures.
% (c) Copyright 2025 Runfeng Yu

clc;
clear;
close all;

log_path = './results/nguyen/matlab/try_times/log/';
% log_path = './results/nguyen/matlab/service_level/log/';

log_list = dir([log_path, '*.txt']);
log_list = natsortfiles({log_list.name})';

% read files
% name format: "[CusNum]-[StoreNum(Suffix)]-run-[Num]-try-[Num]-srv-[Num].txt"
segment_list = cell(length(log_list), 11);
for i = 1:length(log_list)
    log_name = log_list{i};
    seg = split(log_name, '-')';
    seg{8} = erase(seg{8}, '.txt'); % delete '.txt'
    segment_list(i, 1:8) = seg;

    % read elapsed time and objective value from the .txt file
    elapsed_time = -1;
    obj_val = -1;
    lines = readlines([log_path, log_name]);
    for j = length(lines):-1:length(lines) - 2
        % read the last three line
        % If any assertion fails, the file is not complete.
        ln = lines(j);
        if j == length(lines)
            assert(isequal(ln, ""));
            continue
        end

        if j == length(lines) - 1
            assert(startsWith(ln, "Total", 'IgnoreCase', false));
            obj_val = regexp(ln, '\d+\.\d+', 'match');
            continue
        end

        if j == length(lines) - 2
            assert(startsWith(ln, "Elapsed time", 'IgnoreCase', false));
            elapsed_time = regexp(ln, '\d+\.\d+', 'match');
        end
    end
    segment_list{i, 9} = elapsed_time;
    segment_list{i, 10} = obj_val;
end
segment_list(:, [3, 5, 7]) = []; % delete 'run', 'try', 'srv'

% convert to double
for i = 1:length(log_list)
    temp_str = segment_list{i, 2};
    segment_list{i, 1} = str2double(segment_list{i, 1});
    segment_list{i, 2} = str2double(strjoin(regexp(temp_str, '\d+', 'match')));
    segment_list{i, 3} = str2double(segment_list{i, 3});
    segment_list{i, 4} = str2double(segment_list{i, 4});
    segment_list{i, 5} = str2double(segment_list{i, 5});
    segment_list{i, 6} = str2double(segment_list{i, 6});
    segment_list{i, 7} = str2double(segment_list{i, 7});
    segment_list(i, 8) = join(regexp(temp_str, '[a-zA-Z]', 'match'), "");
end

% convert to table
segment_list_cp = segment_list;
segment_list = cell2mat(segment_list(:, 1:7));
result_tb = array2table(segment_list, 'VariableNames', ...
    {'CusNum', 'StoreNum', 'Run', 'Try', 'SrvLv', 'CpuTime', 'Obj_Val'});
result_tb.Suffix = segment_list_cp(:, 8);

% draw figures
Draw_Time_And_Try_Times(result_tb);

% Draw_Time_And_Srv_Lv(result_tb);
% Draw_Stability_Box(result_tb);
% Draw_Time_And_Data_Size(result_tb);