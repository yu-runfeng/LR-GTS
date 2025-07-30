function Draw_Time_And_Data_Size(result_tb)
%DRAW_TIME_AND_DATA_SIZE Plot lines showing data sizes and CPU time
% (c) Copyright 2025 Runfeng Yu

% line color and marker
color_set = [90, 111, 191; 131, 190, 218; 221, 110, 106; ...
    89, 159, 118; 242, 200, 107; 193, 55, 22] ./ 256;
marker_set = ["hexagram", ">", "d", "v", "o", "s"];

% generate instance size and service level catagory
result_tb.Size = zeros(size(result_tb, 1), 1);
for i = 1:size(result_tb, 1)
    result_tb.Size(i) = ...
        result_tb.CusNum(i) * (result_tb.CusNum(i) + result_tb.StoreNum(i));
end
size_catagory = unique(result_tb.Size);
srv_lv_catagory = unique(result_tb.SrvLv);

data_for_fig = cell(length(srv_lv_catagory), 1);
for i = 1:length(srv_lv_catagory)
    % find results in the same service level
    srv_lv = srv_lv_catagory(i);
    extract_ind = result_tb.SrvLv == srv_lv;
    sub_tb = result_tb(extract_ind, :);

    % mean cpu time of same dataset size for each data size
    data = zeros(1, length(size_catagory));
    for j = 1:length(size_catagory)
        sz = size_catagory(j);
        temp_tb = sub_tb(sub_tb.Size == sz, :);
        data(j) = mean(temp_tb.CpuTime);
    end
    data_for_fig{i} = data;
end

% plot lines
figure
for i = 1:length(data_for_fig)
    plot(size_catagory, data_for_fig{i}, ...
        LineWidth = 1.5, ...
        Color = color_set(i, :), ...
        Marker = marker_set(i), ...
        MarkerFaceColor = "auto");
    hold on
end
hold off

% limits, ticks, labels, lengends
xlim([0, 45100])
ylim([0, 1300])

xticks(0:5000:45100)
yticks(0:100:1300)

xlabel('$|J^S|(|J^S| + |I|)$', ...
    'FontName', 'Times', 'Interpreter', 'latex')
ylabel('runtime', 'FontName', 'Times')

legend(num2str(srv_lv_catagory(1)), ...
    num2str(srv_lv_catagory(2)), ...
    num2str(srv_lv_catagory(3)), ...
    num2str(srv_lv_catagory(4)), ...
    num2str(srv_lv_catagory(5)), ...
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

% mean time
figure
data_for_fig = cell2mat(data_for_fig);
data_for_fig_mean = mean(data_for_fig);
plot(size_catagory, data_for_fig_mean, ...
        LineWidth = 1.5, ...
        Color = color_set(1, :), ...
        Marker = marker_set(5), ...
        MarkerFaceColor = "auto");
hold on

% limits, ticks, labels, lengends
xlim([0, 45100])
ylim([0, 1300])

xticks(0:5000:45100)
yticks(0:100:1300)

xlabel('$|J^S|(|J^S| + |I|)$', ...
    'FontName', 'Times', 'Interpreter', 'latex')
ylabel('runtime', 'FontName', 'Times')

ax = gca;
set(ax, 'Units', 'pixels');
set(ax, 'Position', [150, 150, 500, 200]);
ax.XAxis.FontName = 'Times New Roman';
ax.XAxis.FontSize = 14;
ax.XAxis.FontWeight = 'normal';
ax.YAxis.FontName = 'Times New Roman';
ax.YAxis.FontSize = 14;
ax.YAxis.FontWeight = 'normal';

% polyfit
poly_param = polyfit(size_catagory, data_for_fig_mean, 2);
x = size_catagory(1):1:size_catagory(end);
y = poly_param(1)*x.^2 + poly_param(2)*x + poly_param(3);
plot(x, y, '--', 'LineWidth', 0.8);
hold off

poly_param(1)
poly_param(2)
poly_param(3)
end
