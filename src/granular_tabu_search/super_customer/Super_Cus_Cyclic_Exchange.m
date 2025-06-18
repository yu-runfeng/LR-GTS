function sp_cus = Super_Cus_Cyclic_Exchange(sp_cus, data)
% sp_cus_CYCLIC_EXCHANGE Cyclic exchange for cycles
% (c) Copyright 2025 Runfeng Yu

if length(sp_cus.cycle) <= 1
    return
end

% initialization
num_vhc = length(sp_cus.cycle);
rand_num = 0;
while rand_num < 2
    rand_num = randi(num_vhc);
end

cycle_ind = randperm(num_vhc);
cycle_ind = cycle_ind(1:rand_num);
selected_cycle = cell(rand_num, 1);
for i = 1:rand_num
    selected_cycle{i} = sp_cus.cycle{cycle_ind(i)}; % coder need initialization
end

% get segments from selected cycles
remain = cell(rand_num, 1);
segment = cell(rand_num, 1);
pos_ind = zeros(rand_num, 1);
for i = 1:rand_num
    cycle = selected_cycle{i};
    temp_m_ind = randi(length(cycle));
    temp_n_ind = randi(length(cycle));

    start_pos = min([temp_m_ind, temp_n_ind]);
    end_pos = max([temp_m_ind, temp_n_ind]);

    segment{i} = cycle(start_pos:end_pos);
    pos_ind(i) = start_pos;
    cycle(start_pos:end_pos) = [];
    remain{i} = cycle;
end

% cyclic exchange
last_item = segment{end};
a = segment{1};
for i = 2:length(segment)
    b = segment{i};
    segment{i} = a;
    a = b;
end
segment{1} = last_item;

for i = 1:rand_num
    remain{i} = ...
        [remain{i}(1:pos_ind(i) - 1), segment{i}, remain{i}(pos_ind(i):end)];
end
new_cycle = sp_cus.cycle;

% Coder cannot handle cell array assignment with "()"
% new_cycle(cycle_ind) = remain;
for i = 1:rand_num
    new_cycle{cycle_ind(i)} = remain{i};
end
sp_cus = Super_Cus_Get_From_Cycle(new_cycle, data);

% [DEBUG] check integrality
sequence = zeros(1, data.num_cus);
count = 1;
for i = 1:length(new_cycle)
    len = length(new_cycle{i});
    sequence(count:count+len-1) = new_cycle{i};
    count = count + len;
end
assert(all(sort(unique(sequence))-data.num_store == 1:data.num_cus));
end
