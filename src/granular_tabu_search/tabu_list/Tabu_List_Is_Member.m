function is_member = Tabu_List_Is_Member(tabu_list, items)
% TABU_LIST_IS_MEMBER Check if the items are in the tabu list
% (c) Copyright 2025 Runfeng Yu

% as KeyMatch() is not supported by Coder, we need this function.
is_member = false(size(items, 1), 1);
for i = 1:size(items, 1)
    item = items(i, :);
    hash_val = Hash_Double_Vector(item);
    if isKey(tabu_list, hash_val)
        item_in_dict = tabu_list(hash_val);
        is_member(i) = ...
            item_in_dict{1}(1) == item(1) && item_in_dict{1}(2) == item(2);
    else
        is_member(i) = false;
    end
end
end
