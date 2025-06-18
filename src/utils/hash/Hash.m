function seed = Hash(seed, num)
% HASH Get hash value for a double number
% (c) Copyright 2025 Runfeng Yu

% prime1 = uint64(0x9e3779b1);
% prime2 = uint64(0x85ebca6b);
% mixed = uint64(num) * prime1;
% seed = bitxor(seed, mixed+prime2+bitshift(seed, 6)+bitshift(seed, -2));

% prime1 = uint64(0x9e3779b1);
% prime2 = uint64(0x85ebca6b);
% mixed = uint64(num) * uint64(0x9e3779b1);

coder.inline("always");
seed = bitxor(seed, ...
    uint64(num)*uint64(0x9e3779b1)+ ...
    uint64(0x85ebca6b)+bitshift(seed, 6)+bitshift(seed, -2));
end
