% Run Tuzun's dataset
% source: http://prodhonc.free.fr/Instances/instancesLRP2E_us.htm
% (c) Copyright 2025 Runfeng Yu

clc;
clear;
close all;

data_path = './data/tuzun/';
log_path = './result/matlab/tuzun/';
file_list = dir([data_path, '*.dat']);
file_list = natsortfiles({file_list.name})';

for i = 1:length(file_list)
    file_name = file_list{i};
    data = Read_Tuzun([data_path, file_name]);
    [param_lr, param_ts, param_lr_gts] = Param_Setting(data);

    for run_time = 1:10
        rng(run_time);
        disp([file_name(1:end - 4), '-r-', num2str(run_time)]);
        log_name = [file_name(1:end - 4), '-r-', num2str(run_time), '.txt'];
        disp(log_name);

        try
            diary([log_path, log_name]);
        catch
            mkdir(log_path);
            diary([log_path, log_name]);
        end

        try
            solution = Lr_Gts_mex(data, param_lr_gts, param_lr, param_ts);
            disp(['Total: ', num2str(solution.value)]);
        catch
            disp('FATAL error with mex');
        end

        mat_name = [log_name(1:end - 4), '-', num2str(solution.value), '.mat'];
        try
            save([log_path, mat_name], 'solution');
        catch
            mkdir(log_path);
            save([log_path, mat_name], 'solution');
        end
        diary off;
        clear mex;
    end
end