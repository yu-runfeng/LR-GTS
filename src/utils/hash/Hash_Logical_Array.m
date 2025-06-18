function seed = Hash_Logical_Array(array)
% HASH_LOGICAL_ARRAY Get a hash value for a logical array
% (c) Copyright 2025 Runfeng Yu

% Matlab Coder does not support keyHash() function
seed = uint64(0);
non_zero_ind = find(array == true);
for i = 1:length(non_zero_ind)
    seed = Hash(seed, non_zero_ind(i));
end
seed = Hash(seed, sum(non_zero_ind, "all"));

for i = 1:length(array)
    seed = Hash(seed, array(i));
end
end
