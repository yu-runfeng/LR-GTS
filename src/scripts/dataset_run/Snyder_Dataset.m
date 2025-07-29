% Run Snyder's data set
% see /src/data_reader/Read_Snyder.m for more data generation details
% (c) Copyright 2025 Runfeng Yu

clc;
clear;
close all;

data_path = './data/snyder/';
log_path = './result/matlab/snyder/';

for service_level = [0.8, 0.85, 0.9, 0.95]
    for max_try = 3:5
        for node_num = [15, 49, 88, 150]
            file_path = [data_path, num2str(node_num), 'nodes/'];
            data = Read_Snyder(file_path);

            log_name = [num2str(node_num), '-', num2str(service_level), '-', ...
                num2str(max_try), '.txt'];

            data.srv_lv = service_level;
            data.max_try = max_try;

            try
                diary([log_path, log_name]);
            catch
                mkdir(log_path);
                diary([log_path, log_name]);
            end

            solution = Lagrangian_Relaxation_mex(data, Param_Setting());
            disp(['Total: ', num2str(solution.value)]);

            mat_name = ...
                [log_name(1:end-4), '-', num2str(solution.value), '.mat'];
            try
                save([log_path, mat_name], 'solution');
            catch
                mkdir(log_path);
                save([log_path, mat_name], 'solution');
            end
            diary off;
        end
    end
end
