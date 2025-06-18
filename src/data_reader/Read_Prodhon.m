function data = Read_Prodhon(file_path)
% READ_PRODHON Read from Prodhon's dataset
% (c) Copyright 2025 Runfeng Yu
% ref: http://prodhonc.free.fr/Instances/instances_us.htm

% node number
f = fopen(file_path);
count = 1;
while ~feof(f)
    line = fgetl(f);

    if count == 1
        data.num_cus = str2double(line);
    end

    if count == 2
        data.num_store = str2double(line);
        break
    end
    count = count + 1;
end
fclose(f);

count = 5;
range_coord_store = count:count + data.num_store - 1;

count = count + data.num_store + 1;
range_coord_cus = count:count + data.num_cus - 1;

count = count + data.num_cus + 1;
range_cap_veh = count;

count = count + 3;
range_cap_store = count:count + data.num_store - 1;

count = count + data.num_store + 1;
range_dmd_cus = count:count + data.num_cus - 1;

count = count + data.num_cus + 1;
range_fixed_store = count:count + data.num_store - 1;

count = count + data.num_store + 1;
range_fixed_vhc = count;

f = fopen(file_path);
coord_cus = [];
coord_store = [];
data.dmd_sfs = [];
data.fixed_store = [];

count = 1;
while ~feof(f)
    line = fgetl(f);
    if count == 4
        coord_warehouse = sscanf(line, "%f")';
    end

    if ismember(count, range_coord_store)
        coord_store = [coord_store; sscanf(line, "%f")'];
    end

    if ismember(count, range_coord_cus)
        coord_cus = [coord_cus; sscanf(line, '%f')'];
    end

    if count == range_cap_veh
        data.cap_vhc = sscanf(line, '%f');
    end

    if ismember(count, range_cap_store)
        % nothing with capacity of store
    end

    if ismember(count, range_dmd_cus)
        data.dmd_sfs = [data.dmd_sfs; sscanf(line, '%f')];
    end

    if ismember(count, range_fixed_store)
        data.fixed_store = [data.fixed_store; sscanf(line, '%f') * 10];
    end

    if count == range_fixed_vhc
        data.fixed_vhc = sscanf(line, '%f');
    end

    count = count + 1;
end
fclose(f);

clear range_cap_veh range_cap_store range_coord_cus range_coord_store;
clear range_dmd_cus range_fixed_vhc range_fixed_store;

% calculate distance
dist_fst_layer = -1 * ones(data.num_store, 1);
for i = 1:size(coord_warehouse, 1)
    for j = 1:data.num_store
        temp_x = (coord_warehouse(i, 1) - coord_store(j, 1))^2;
        temp_y = (coord_warehouse(i, 2) - coord_store(j, 2))^2;
        dist_fst_layer(j, i) = ceil(sqrt(temp_x+temp_y)*100);
    end
end

dist_snd_layer = -1 * ones(data.num_store+data.num_cus);
coord_temp = [coord_store; coord_cus];
for i = 1:data.num_store + data.num_cus
    for j = 1:data.num_store + data.num_cus
        temp_x = (coord_temp(i, 1) - coord_temp(j, 1))^2;
        temp_y = (coord_temp(i, 2) - coord_temp(j, 2))^2;
        dist_snd_layer(j, i) = ceil(sqrt(temp_x+temp_y)*200);
    end
end

% parameter setting
data.coef_trans = 0.1;
data.coef_sfs = 1;
data.coef_bops = 0.1;
data.coef_os = 0.1;

data.dist_fst_layer = dist_fst_layer;
data.dist_snd_layer = dist_snd_layer;
data.dmd_bops = data.dmd_sfs;
data.dmd_os = data.dmd_sfs;
data.num_vhc = ceil(sum(data.dmd_sfs)/data.cap_vhc*1.5);
data.ind_cus = data.num_store + 1:data.num_store + data.num_cus;
data.ind_store = 1:data.num_store;

data.farthest = ceil(3*mean(dist_snd_layer, "all"));
data.max_try = 4;
data.srv_lv = 0.95;
data.coef_penalty = max(dist_snd_layer, [], "all") * data.coef_bops;

data = orderfields(data);
end
