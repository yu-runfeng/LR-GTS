function tabu_list = Tabu_List_Insert(tabu_list, items, max_length)
% TABU_LIST_INSERT Insert items in the tabu-list
% (c) Copyright 2025 Runfeng Yu

% calculate hash values
hash_val_vec = repmat(uint64(0), size(items, 1), 1);
for i = 1:size(items, 1)
    hash_val_vec(i) = Hash_Double_Vector(items(i, :));
end

% dictionary in Matlab is ORDERED, see:
% https://blogs.mathworks.com/matlab/2022/09/15/an-introduction-to-dictionaries-associative-arrays-in-matlab/
current_length = numEntries(tabu_list);
surplus_length = current_length + size(items, 1) - max_length;
if surplus_length > 0
    k = cell2mat(keys(tabu_list, "cell")); % "cell" argument for coder
    tabu_list(k(1:surplus_length)) = []; % delete the oldest items
end

% insert new items
for i = 1:length(hash_val_vec)
    tabu_list(hash_val_vec(i)) = {items(i, :)};
end

% assert(numEntries(tabu_list) <= max_length);
end
