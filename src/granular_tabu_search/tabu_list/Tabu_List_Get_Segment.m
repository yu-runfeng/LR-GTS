function tabu_list_seg = Tabu_List_Get_Segment(tabu_list, seg_len)
% TABU_LIST_GET_SEGMENT Get a segment of the tabu list with a given length
% (c) Copyright 2025 Runfeng Yu

assert(seg_len > 0);
num_entries = numEntries(tabu_list);
seg_len = min([seg_len, num_entries]);

tabu_list_seg = tabu_list;
key_vec = cell2mat(keys(tabu_list_seg, "cell")); % for coder

% Incompatibility with MATLAB in Vector-Vector Indexing:
% tabu_list_seg(key_vec(1:num_entries-seg_len)) = [];
% substitute with:
for i = 1:num_entries - seg_len
    key_val = key_vec(i);
    tabu_list_seg = remove(tabu_list_seg, key_val);
end
end
