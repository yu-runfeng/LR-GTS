% Run Nguyen's data set with varied max try times
% source: http://prodhonc.free.fr/Instances/instancesLRP2E_us.htm
% see /src/data_reader/Read_Nguyen.m for more data generation details
% (c) Copyright 2025 Runfeng Yu

clc;
clear;
close all;

data_path = './data/nguyen/';
data_list = dir([data_path, '*.txt']);
data_list = natsortfiles({data_list.name})';

result_path = './result/matlab/nguyen/temp/';
result_mat = dir([result_path, '*.mat']);
result_mat = {result_mat.name}';
result_log = dir([result_path, '*.txt']);
result_log = {result_log.name}';

for i = 1:length(data_list)
    file_name = data_list{i};
    data = Read_Nguyen([data_path, file_name]);
    [param_lr, param_ts, param_lr_gts] = Param_Setting(data);

    for max_try = [2, 3, 4, 5, 6]
        data.max_try = max_try;

        for run_time = 1:10
            rng(run_time);

            disp([file_name(1:end - 4), '-r-', num2str(run_time)]);
            log_name = [file_name(1:end - 4), ...
                '-run-', num2str(run_time), ...
                '-try-', num2str(max_try), '.txt'];
            disp(log_name);

            id_name = log_name(1:end - 4);

            % if log file and mat file both exist, skip it
            if any(contains(result_log, id_name)) && ...
                    any(contains(result_mat, id_name))
                continue
            end

            try
                diary([result_path, log_name]);
            catch
                mkdir(result_path);
                diary([result_path, log_name]);
            end

            solution = Lr_Gts_mex(data, param_lr_gts, param_lr, param_ts);
            disp(['Total: ', num2str(solution.value)]);

            mat_name = ...
                [log_name(1:end - 4), '-', num2str(solution.value), '.mat'];
            try
                save([result_path, mat_name], 'solution');
            catch
                mkdir(result_path);
                save([result_path, mat_name], 'solution');
            end

            diary off;
        end
    end
end
