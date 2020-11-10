%% load the data file
clear;
clc;
%close all;
% load('data/grasp_response2020_11_03_15.21.37.mat');
% load('data/grasp_response2020_11_03_15.26.43.mat');
% load('data/grasp_response2020_11_10_14.11.05.mat');
% load('data/grasp_response2020_11_10_14.18.12.mat');
load('data/grasp_response2020_11_10_14.37.15.mat');
% load('data/grasp_response2020_11_10_14.56.48.mat');

%% clustering the data with k-means
dt = 0.02;
time = 0:0.02:0.02*(length(desired_joint_torque)-1);
time_window = 0.1 / dt;
num_cluster = 3;

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

% plot the torque
figure;hold on;sgtitle('desired joint torque');
set(gca, 'FontSize', 20);
set(groot,'defaultfigureposition',[400 250 900 750]);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_torque(i,:), 'r','linewidth', 2.5);
    yl = ylim;
    xl = xlim;
    patch([xl(1), xl(1), time(ch_pos(1)), time(ch_pos(1)), xl(1)], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.1);
    for j = 1:length(ch_pos)-1
        patch([time(ch_pos(j)), time(ch_pos(j)), ...
            time(ch_pos(j+1)), time(ch_pos(j+1)), time(ch_pos(j+1))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.2);
    end    
    patch([time(ch_pos(end)), time(ch_pos(end)), xl(2), xl(2), time(ch_pos(end))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.3);
end

% plot the postion
figure;hold on;sgtitle('real joint position');
set(gca, 'FontSize', 20);
set(groot,'defaultfigureposition',[400 250 900 750]);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_position(i,:), 'r','linewidth', 2.5);
    yl = ylim;
    xl = xlim;
    patch([xl(1), xl(1), time(ch_pos(1)), time(ch_pos(1)), xl(1)], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.1);
    for j = 1:length(ch_pos)-1
        patch([time(ch_pos(j)), time(ch_pos(j)), ...
            time(ch_pos(j+1)), time(ch_pos(j+1)), time(ch_pos(j+1))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.2);
    end    
    patch([time(ch_pos(end)), time(ch_pos(end)), xl(2), xl(2), time(ch_pos(end))], ...
        [yl(1), yl(2), yl(2), yl(1), yl(1)],...
        'black', 'FaceColor', 'green', 'FaceAlpha', 0.3);
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