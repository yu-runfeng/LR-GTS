function tabu_list = Tabu_List_Init()
% TABU_LIST_INIT Initialize a tabu list
% (c) Copyright 2025 Runfeng Yu

% C/C++ Code Generation Usage notes and limitations:
% You cannot use the configureDictionary function to configure dictionaries
% containing cells, structures, or user-defined objects.
% tabu_list = configureDictionary('uint64', 'cell'); % coder error

tabu_list = dictionary(Hash_Double_Vector([-1, -1]), {[-1, -1]});
end
