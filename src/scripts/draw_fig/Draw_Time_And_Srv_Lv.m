function Draw_Time_And_Srv_Lv(result_tb)
%DRAW_TIME_AND_SRV_LV Plot lines showing service levels and CPU time
% (c) Copyright 2025 Runfeng Yu

% line color and marker
color_set = [90, 111, 191; 131, 190, 218; 221, 110, 106; ...
    89, 159, 118; 242, 200, 107; 193, 55, 22] ./ 256;
marker_set = ["hexagram", ">", "d", "v", "o", "s"];

% default max try is 5
del_ind = result_tb.Try ~= 5;
result_tb(del_ind, :) = [];

% generate instance size and service level catagory
result_tb.InstanceSize = repmat("", size(result_tb, 1), 1);
for i = 1:size(result_tb, 1)
    result_tb.InstanceSize(i) = [num2str(result_tb.CusNum(i)), '$\times$', ...
        num2str(result_tb.StoreNum(i))];
end
size_catagory = natsort(unique(result_tb.InstanceSize));
size_catagory = size_catagory(end:-1:1);
srv_lv_catagory = unique(result_tb.SrvLv);

data_for_fig = cell(length(size_catagory), 1);
for i = 1:length(size_catagory)
    % find results in the same dataset size
    extract_ind = result_tb.InstanceSize == size_catagory(i);
    sub_tb = result_tb(extract_ind, :);

    % mean cpu time of same dataset size for each service level
    data = zeros(1, length(srv_lv_catagory));
    for j = 1:length(srv_lv_catagory)
        srv_lv = srv_lv_catagory(j);
        temp_tb = sub_tb(sub_tb.SrvLv == srv_lv, :);
        data(j) = mean(temp_tb.CpuTime);
    end

    data_for_fig{i} = data;
end

% plot lines
figure
for i = 1:length(data_for_fig)
    plot(srv_lv_catagory, data_for_fig{i}, ...
        LineWidth = 1.5, ...
        Color = color_set(i, :), ...
        Marker = marker_set(i), ...
        MarkerFaceColor = "auto");
    hold on
end
hold off

% limits, ticks, labels, lengends
xlim([0.74, 0.96])
ylim([0, 1200])

xticks(0.75:0.05:0.95)
yticks(0:100:1200)

xlabel('$q$', 'Interpreter', 'latex')
ylabel('runtime', 'FontName', 'Times')

legend(size_catagory{1}, size_catagory{2}, size_catagory{3}, ...
    size_catagory{4}, size_catagory{5}, size_catagory{6}, ...
    'Interpreter', 'latex', 'Location', 'northeastoutside')

ax = gca;
set(ax, 'Units', 'pixels');
set(ax, 'Position', [150, 150, 500, 200]);
ax.XAxis.FontName = 'Times New Roman';
ax.XAxis.FontSize = 14;
ax.XAxis.FontWeight = 'normal';
ax.YAxis.FontName = 'Times New Roman';
ax.YAxis.FontSize = 14;
ax.YAxis.FontWeight = 'normal';
end
