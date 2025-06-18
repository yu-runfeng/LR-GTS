function data = Read_Tuzun(file_path)
% READ_TUZUN Read from Tuzun's dataset
% (c) Copyright 2025 Runfeng Yu
% ref: http://prodhonc.free.fr/Instances/instances_us.htm

% node number
f = fopen(file_path);
count = 1;
while ~feof(f)
    line = fgetl(f);

    if count == 1
        num = sscanf(line, "%f")';
        data.num_cus = num;
    end

    if count == 2
        num = sscanf(line, "%f")';
        data.num_store = num;
        break
    end

    count = count + 1;
end
fclose(f);

% index
count = 4;
range_store_coord = count:count + data.num_store - 1;

count = count + data.num_store;
range_cus_coord = count:count + data.num_cus - 1;

count = count + data.num_cus + 1;
ind_cap_vhc = count;

count = count + 2;
% range_cap_store = count:count + data.num_store -1;

count = count + data.num_store + 1;
range_dmd = count:count + data.num_cus - 1;

count = count + data.num_cus + 1;
range_fix_store = count:count + data.num_store - 1;

count = count + data.num_store + 1;
ind_fix_vhc = count;

f = fopen(file_path);
coord_cus = [];
coord_store = [];
data.dmd_sfs = [];
data.fixed_store = [];

count = 1;
while ~feof(f)
    line = fgetl(f);
    num = sscanf(line, "%f")';

    if ismember(count, range_store_coord)
        coord_store = [coord_store; num(1:2)];
    end

    if ismember(count, range_cus_coord)
        coord_cus = [coord_cus; num(1:2)];
    end

    if count == ind_cap_vhc
        data.cap_vhc = num;
    end

    if ismember(count, range_dmd)
        data.dmd_sfs = [data.dmd_sfs; num];
    end

    if ismember(count, range_fix_store)
        data.fixed_store = [data.fixed_store; num];
    end

    if count == ind_fix_vhc
        data.fixed_vhc = num;
    end

    count = count + 1;
end
fclose(f);

clear count range_store range_cus;

% calculate distance
dist_fst_layer = zeros(data.num_store, 1);

dist_snd_layer = -1 * ones(data.num_store+data.num_cus);
coord_temp = [coord_store; coord_cus];
for i = 1:data.num_store + data.num_cus
    for j = 1:data.num_store + data.num_cus
        temp_x = (coord_temp(i, 1) - coord_temp(j, 1))^2;
        temp_y = (coord_temp(i, 2) - coord_temp(j, 2))^2;
        dist_snd_layer(j, i) = sqrt(temp_x+temp_y);
    end
end

% parameter setting
data.coef_trans = inf;
data.coef_sfs = 1;
data.coef_bops = inf;
data.coef_os = inf;

data.dist_fst_layer = dist_fst_layer;
data.dist_snd_layer = dist_snd_layer;
data.dmd_bops = data.dmd_sfs;
data.dmd_os = data.dmd_sfs;
data.num_vhc = ceil(sum(data.dmd_sfs)/data.cap_vhc*2);
data.ind_cus = data.num_store + 1:data.num_store + data.num_cus;
data.ind_store = 1:data.num_store;

data.farthest = inf;
data.max_try = inf;
data.srv_lv = 1;
data.coef_penalty = inf;

data = orderfields(data);

end
