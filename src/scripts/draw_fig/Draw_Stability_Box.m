function Draw_Stability_Box(result_tb)
%DRAW_STABILITY_BOX Draw the stability boxplot for a dataset
% (c) Copyright 2025 Runfeng Yu

result_tb.InstanceID = repmat("", size(result_tb, 1), 1);
result_tb.InstanceSize = repmat("", size(result_tb, 1), 1);
for i = 1:size(result_tb, 1)
    result_tb.InstanceID{i} = ...
        [num2str(result_tb.CusNum(i)), '-', ...
        num2str(result_tb.StoreNum(i)), '-', ...
        result_tb.Suffix{i}, '-', ...
        num2str(result_tb.SrvLv(i))];
    result_tb.InstanceSize(i) = ...
        [num2str(result_tb.CusNum(i)), '$\times$', ...
        num2str(result_tb.StoreNum(i))];
end
dataset_catagory = unique(result_tb.InstanceID);
size_catagory = natsort(unique(result_tb.InstanceSize));
size_catagory = size_catagory(end:-1:1);

data_for_fig = cell(length(size_catagory), 1);

data_value = [];
data_size = [];

% find results for each dataset and for each set of paramter
for i = 1:length(dataset_catagory)
    sub_table = result_tb(result_tb.InstanceID == dataset_catagory(i), :);
    temp_obj_value = sub_table.Obj_Val;
    temp_obj_value = ((temp_obj_value ./ min(temp_obj_value)) - 1) * 100;

    % append temp_obj_value
    index = find(size_catagory == sub_table.InstanceSize(1));
    data_for_fig{index} = [data_for_fig{index}; temp_obj_value];

    % test
    data_value = [data_value; temp_obj_value];
    data_size = [data_size; sub_table.InstanceSize];
end

figure
boxplot(data_value, data_size, "GroupOrder", natsort(size_catagory))

ax = gca;
set(ax, 'Units', 'pixels');
set(ax, 'Position', [150, 150, 500, 400]);

set(findobj('Tag', 'Box'), 'LineWidth', 1.5)
bx = findobj('Tag', 'boxplot');
set(bx.Children, 'LineWidth', 1.5)
set(gca, 'TickLabelInterpreter', 'latex');
set(gca, 'ytick', 0.0:0.02:0.20)
set(gca, 'yTickLabel', num2str(get(gca, 'yTick')', '%.2f'))

ylabel('relative percentage deviation', 'FontName', 'Times New Roman')

t = text(0.45, 0.195, '%');
t.FontName = 'Times New Roman';
t.FontSize = 12;
t.FontWeight = 'normal';
t.HorizontalAlignment = 'right';

ax = gca;
ax.XAxis.FontName = 'Times New Roman';
ax.XAxis.FontSize = 14;
ax.XAxis.FontWeight = 'normal';
ax.YAxis.FontName = 'Times New Roman';
ax.YAxis.FontSize = 14;
ax.YAxis.FontWeight = 'normal';
end
