function data = Read_Nguyen(file_path)
% READ_NGUYEN Read from Nguyen's dataset
% (c) Copyright 2025 Runfeng Yu
% ref: http://prodhonc.free.fr/Instances/instances_us.htm

% node number
f = fopen(file_path);
count = 1;
while ~feof(f)
    line = fgetl(f);

    if count == 2
        num = sscanf(line, "%f")';
        data.num_store = num(1);
        data.num_cus = num(2);
    end

    if count == 3
        num = sscanf(line, "%f")';
        data.cap_vhc = num(2);
    end

    if count == 4
        num = sscanf(line, "%f")';
        data.fixed_vhc = num(2);
    end

    if count == 5
        coord_warehouse = sscanf(line, "%f")';
        break
    end
    count = count + 1;
end
fclose(f);

count = 6;
range_store = count:count + data.num_store - 1;

count = count + data.num_store;
range_cus = count:count + data.num_cus - 1;

f = fopen(file_path);
coord_cus = [];
coord_store = [];
data.dmd_sfs = [];
data.fixed_store = [];

count = 1;
while ~feof(f)
    line = fgetl(f);

    if ismember(count, range_store)
        num = sscanf(line, "%f")';
        coord_store = [coord_store; num(1:2)];
        data.fixed_store = [data.fixed_store; num(4) * 10];
    end

    if ismember(count, range_cus)
        num = sscanf(line, "%f")';
        coord_cus = [coord_cus; num(1:2)];
        data.dmd_sfs = [data.dmd_sfs; num(3)];
    end

    count = count + 1;

end
fclose(f);

clear count range_store range_cus;

% calculate distance
dist_fst_layer = -1 * ones(data.num_store, 1);
for i = 1:size(coord_warehouse, 1)
    for j = 1:data.num_store
        temp_x = (coord_warehouse(i, 1) - coord_store(j, 1))^2;
        temp_y = (coord_warehouse(i, 2) - coord_store(j, 2))^2;
        dist_fst_layer(j, i) = ceil(sqrt(temp_x+temp_y)*10);
    end
end

dist_snd_layer = -1 * ones(data.num_store+data.num_cus);
coord_temp = [coord_store; coord_cus];
for i = 1:data.num_store + data.num_cus
    for j = 1:data.num_store + data.num_cus
        temp_x = (coord_temp(i, 1) - coord_temp(j, 1))^2;
        temp_y = (coord_temp(i, 2) - coord_temp(j, 2))^2;
        dist_snd_layer(j, i) = ceil(sqrt(temp_x+temp_y)*20);
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
data.num_vhc = ceil(sum(data.dmd_sfs)/data.cap_vhc*2);
data.ind_cus = data.num_store + 1:data.num_store + data.num_cus;
data.ind_store = 1:data.num_store;

data.farthest = ceil(3*mean(dist_snd_layer, "all"));
data.max_try = 4;
data.srv_lv = 0.95;
data.coef_penalty = max(dist_snd_layer, [], "all") * data.coef_bops;

data = orderfields(data);
end
