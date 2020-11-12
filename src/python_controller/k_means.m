%% load the data file
clear;
clc;
close all;
% load('data/grasp_response2020_11_12_15.52.30.mat');
raw_data = load('data/two_finger_pinch/merged_two_finger_pinch.mat');
trail_length = 400;

%% for three-fingered grasp, drop out the data of little finger
data_name_list = fieldnames(raw_data);
for i = 1:numel(data_name_list)
    raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:8 13:16], :);
end

%% for two-fingered grasp, drop out the data of last two fingers, and choosing only index finger
data_name_list = fieldnames(raw_data);
for i = 1:numel(data_name_list)
%     raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:4 13:16], :);
    raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:4], :);
end

%% Normalize all the data to 0-1

% since I am processing the concatenated data. I have to normalize every
% trail individually. Here is the merged data of 20 trials.
for i = 1:numel(data_name_list)
    data_name = data_name_list{i};
    for j = 1 : size(raw_data.(data_name), 2) / trail_length
        raw_data.(data_name)(:, 1+(j-1)*trail_length:j*trail_length) = ...
            normalize(raw_data.(data_name)(:, 1+(j-1)*trail_length:j*trail_length), 2, 'range');
    end
end

%% get the variables out of the struct
for i = 1:numel(data_name_list)
    assignin('caller', data_name_list{i}, raw_data.(data_name_list{i}));
end

%% clustering the data with k-means
dt = 0.02;
time_window = 0.1 / dt;
num_cluster = 3;

% todo: the sliding window should avoid include data from two neighbour
% trails

% only torque
% data = zeros(size(desired_joint_torque,1)*time_window, ...
%             size(desired_joint_torque,2)-time_window+1);
% for i = 1:size(data,2)
%     data(:,i) = reshape(desired_joint_torque(:,i:i+time_window-1), ...
%         size(data,1), 1);
% end
% data = data';

% % only position
% data = zeros(size(real_joint_position,1)*time_window, ...
%             size(real_joint_position,2)-time_window+1);
% for i = 1:size(data,2)
%     data(:,i) = reshape(real_joint_position(:,i:i+time_window-1), ...
%         size(data,1), 1);
% end
% data = data';

% torque + position
data = zeros(size(desired_joint_torque,1)*time_window*2, ...
            size(desired_joint_torque,2)-time_window+1);
for i = 1:size(data,2)
    data(:,i) = [reshape(desired_joint_torque(:,i:i+time_window-1), ...
        size(data,1)/2, 1); reshape(real_joint_position(:,i:i+time_window-1), ...
        size(data,1)/2, 1)];
end
data = data';

% torque, position, torque', position'


[idx, cluster_centre, sum_distance, distance] = kmeans(data, num_cluster,... 
                          'Display', 'final',...
                          'Distance', 'sqeuclidean',...
                          'MaxIter', 100,...
                          'OnlinePhase', 'On',...
                          'Replicates', 10,...
                          'Start', 'plus'); %data([25,85,242],:)

% get the index                      
Idx = zeros(size(desired_joint_torque, 2),1);
for i = 1:(time_window-1)/2
    Idx(i) = idx(1);
    Idx(end-i+1) = idx(end);
end
Idx((time_window-1)/2+1 : end-(time_window-1)/2) = idx;

% get the changing state position
ch_pos = [];
for i = 1:size(Idx, 1) - 1
    if Idx(i) ~= Idx(i+1)
        ch_pos = [ch_pos, i];
    end
end

%% plot the results; at one of the trials
trail = 20; % in 2-finger pinch experiments there are 20 trials
trail_desired_joint_torque = desired_joint_torque(:, (trail-1)*trail_length+1:trail*trail_length);
trail_real_joint_position = real_joint_position(:, (trail-1)*trail_length+1:trail*trail_length);
trail_ch_pos = ch_pos(ch_pos>(trail-1)*trail_length & ch_pos<trail*trail_length);
% manual remove the change position between two trails. This is caused by
% including data from two neighbour trails into one sliding window.
% This bug should be fixed.
trail_ch_pos = trail_ch_pos(2:3) - (trail-1)*trail_length - 1;
trail_time = 0:0.02:0.02*(length(trail_desired_joint_torque)-1);

% plot the torque
figure;hold on;sgtitle('normalized desired joint torque');
set(gca, 'FontSize', 20);
% set(groot,'defaultfigureposition',[400 250 900 750]);
for i = 1:size(trail_desired_joint_torque, 1)
    subplot(size(trail_desired_joint_torque, 1)/4,4,i);
    plot(trail_time, trail_desired_joint_torque(i,:), 'r','linewidth', 2.5);
    yl = ylim;
    xl = xlim;
    patch([xl(1), xl(1), trail_time(trail_ch_pos(1)), trail_time(trail_ch_pos(1)), xl(1)], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.1);
    for j = 1:length(trail_ch_pos)-1
        patch([trail_time(trail_ch_pos(j)), trail_time(trail_ch_pos(j)), ...
            trail_time(trail_ch_pos(j+1)), trail_time(trail_ch_pos(j+1)), trail_time(trail_ch_pos(j+1))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.2);
    end    
    patch([trail_time(trail_ch_pos(end)), trail_time(trail_ch_pos(end)), xl(2), xl(2), trail_time(trail_ch_pos(end))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.3);
end

% plot the postion
figure;hold on;sgtitle('normalized real joint position');
set(gca, 'FontSize', 20);
set(groot,'defaultfigureposition',[400 250 900 750]);
for i = 1:size(trail_desired_joint_torque, 1)
    subplot(size(trail_desired_joint_torque, 1)/4,4,i);
    plot(trail_time, trail_real_joint_position(i,:), 'r','linewidth', 2.5);
    yl = ylim;
    xl = xlim;
    patch([xl(1), xl(1), trail_time(trail_ch_pos(1)), trail_time(trail_ch_pos(1)), xl(1)], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.1);
    for j = 1:length(trail_ch_pos)-1
        patch([trail_time(trail_ch_pos(j)), trail_time(trail_ch_pos(j)), ...
            trail_time(trail_ch_pos(j+1)), trail_time(trail_ch_pos(j+1)), trail_time(trail_ch_pos(j+1))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.2);
    end    
    patch([trail_time(trail_ch_pos(end)), trail_time(trail_ch_pos(end)), xl(2), xl(2), trail_time(trail_ch_pos(end))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.3);
end

%% 3-D view of the results within one trail
trail = 20; % in 2-finger pinch experiments there are 20 trials
trail_desired_joint_torque = desired_joint_torque(:, (trail-1)*trail_length+1:trail*trail_length);
trail_real_joint_position = real_joint_position(:, (trail-1)*trail_length+1:trail*trail_length);
trail_ch_pos = ch_pos(ch_pos>(trail-1)*trail_length & ch_pos<trail*trail_length);
% manual remove the change position between two trails. This is caused by
% including data from two neighbour trails into one sliding window.
% This bug should be fixed.
trail_ch_pos = trail_ch_pos(2:3) - (trail-1)*trail_length - 1;
trail_time = 0:0.02:0.02*(length(trail_desired_joint_torque)-1);

figure, hold on; title('normalized joint torque');
set(gca, 'FontSize', 20);
axis tight
surf(trail_time, 1:size(trail_desired_joint_torque, 1), trail_desired_joint_torque);
set(gca, 'YTick', 1:size(trail_desired_joint_torque, 1), ...
    'YTickLabel', 1:size(trail_desired_joint_torque, 1));
colorbar
shading interp
for i = 1 : length(trail_ch_pos)
    a = trail_time(trail_ch_pos(i));
    geoshow([1 size(trail_desired_joint_torque, 1); ...
        1 size(trail_desired_joint_torque, 1)], [a a; a a], [0 0; 1 1], ...
        'displaytype','mesh','facecolor','red','facealpha',0.5);
end

figure, hold on; title('normalized joint position');
set(gca, 'FontSize', 20);
axis tight
surf(trail_time, 1:size(trail_desired_joint_torque, 1), trail_real_joint_position);
set(gca, 'YTick', 1:size(trail_desired_joint_torque, 1),...
    'YTickLabel', 1:size(trail_desired_joint_torque, 1));
colorbar
shading interp
for i = 1 : length(trail_ch_pos)
    a = trail_time(trail_ch_pos(i));
    geoshow([1 size(trail_desired_joint_torque, 1);...
        1 size(trail_desired_joint_torque, 1)], [a a; a a], [0 0; 1 1], ...
        'displaytype','mesh','facecolor','red','facealpha',0.5);
end

%% analyse the number of clusters; reference: Pattern Recognition P195
sum_error = zeros(1, 10);

for num_cluster = 1:10
    [idx, cluster_centre, sum_distance, distance] = kmeans(data, num_cluster,... 
                          'Display', 'final',...
                          'Distance', 'sqeuclidean',...
                          'MaxIter', 100,...
                          'OnlinePhase', 'On',...
                          'Replicates', 10,...
                          'Start', 'plus');
    sum_error(num_cluster) = sum(sum_distance);
end
figure;hold on;
plot(sum_error,'-o','MarkerFaceColor','b','LineWidth',2);
set(gca, 'FontSize', 20);
xlabel('number of clusters');
ylabel('sum of error');