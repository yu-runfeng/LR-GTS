function seed = Hash_Double_Vector(array)
% HASH_DOUBLE_VECTOR Get hash value for a double array
% (c) Copyright 2025 Runfeng Yu

% Matlab Coder does not support keyHash() function
seed = uint64(0);
for i = 1:length(array)
    seed = Hash(seed, array(i));
end
end
