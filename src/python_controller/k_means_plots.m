%% load the data file
clear;
clc;
% close all;
% load('data/grasp_response2020_11_12_15.52.30.mat');
% raw_data = load('data/two_finger_pinch_sliding/merged_two_finger_pinch_sliding_with_gradient.mat');
raw_data = load('data/two_finger_pinch/merged_two_finger_pinch_with_gradient.mat');
trail_length = 400; % every trail has 400 time-steps

%% for three-fingered grasp, drop out the data of little finger
% data_name_list = fieldnames(raw_data);
% for i = 1:numel(data_name_list)
%     raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:8 13:16], :);
% end

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

%% prepare the data
dt = 0.02;
time_window = 0.1 / dt;

% torque, position, torque', position'
data = zeros(size(desired_joint_torque,1)*time_window*4, ...
            size(desired_joint_torque,2)/trail_length * ...
            (trail_length-time_window+1));
for i = 1 : size(desired_joint_torque,2)/trail_length
    for j = 1 : trail_length-time_window+1
        idx_s = (i-1) * trail_length + j;
        idx_e = (i-1) * trail_length + j + time_window - 1;
        data(:, (i-1)*(trail_length-time_window+1)+j ) = ...
        [reshape(desired_joint_torque(:,idx_s:idx_e), size(data,1)/4, 1);...
        reshape(real_joint_position(:,idx_s:idx_e), size(data,1)/4, 1);...
        reshape(desired_joint_torque_gradient(:,idx_s:idx_e), size(data,1)/4, 1);...
        reshape(real_joint_velocity(:,idx_s:idx_e), size(data,1)/4, 1)];
    end    
end
data = data';

%% clustering the data with k-means
num_cluster = 4;
[idx, cluster_centre, sum_distance, distance] = kmeans(data, num_cluster,... 
                          'Display', 'final',...
                          'Distance', 'sqeuclidean',...
                          'MaxIter', 100,...
                          'OnlinePhase', 'On',...
                          'Replicates', 10,...
                          'Start', 'plus'); %data([25,85,242],:)

% get the index                      
Idx = zeros(size(desired_joint_torque, 2),1);
for i = 1:size(desired_joint_torque,2)/trail_length
    Idx( (i-1)*trail_length+(time_window-1)/2 + 1 : ...
        i*trail_length - (time_window-1)/2) = ...
        idx( (i-1)*(trail_length-time_window+1)+1 : ...
        i*(trail_length-time_window+1));
    Idx((i-1)*trail_length+1 : (i-1)*trail_length+(time_window-1)/2+1)...
        = idx( (i-1)*(trail_length-time_window+1)+1 );
    Idx( i*trail_length-(time_window-1)/2 : i*trail_length ) = ...
        idx( i*(trail_length-time_window+1) );
end


% for i = 1:(time_window-1)/2
%     Idx(i) = idx(1);
%     Idx(end-i+1) = idx(end);
% end
% Idx((time_window-1)/2+1 : end-(time_window-1)/2) = idx;

% get the changing state position
ch_pos = [];
for i = 1:size(Idx, 1) - 1
    if Idx(i) ~= Idx(i+1)
        ch_pos = [ch_pos, i];
    end
end

%% plot the results; at one of the trials
trail = 8; %size(desired_joint_torque, 2) / trail_length; % in 2-finger pinch experiments there are 20 trials
trail_desired_joint_torque = desired_joint_torque(:, (trail-1)*trail_length+1:trail*trail_length);
trail_real_joint_position = real_joint_position(:, (trail-1)*trail_length+1:trail*trail_length);
trail_desired_joint_torque_gradient = desired_joint_torque_gradient(:, (trail-1)*trail_length+1:trail*trail_length);
trail_real_joint_velocity = real_joint_velocity(:, (trail-1)*trail_length+1:trail*trail_length);
trail_ch_pos = ch_pos(ch_pos>(trail-1)*trail_length & ch_pos<trail*trail_length);
trail_ch_pos = trail_ch_pos - (trail-1)*trail_length - 1;
trail_time = 0:0.02:0.02*(length(trail_desired_joint_torque)-1);

% plot the torque
figure;hold on;sgtitle('normalized desired joint torque, position, torque'', position''');
set(gca, 'FontSize', 20);
% set(groot,'defaultfigureposition',[400 250 900 750]);
for i = 1:size(trail_desired_joint_torque, 1)
    % joint torque
    subplot(4,size(trail_desired_joint_torque, 1),i);
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
    
    % joint position
    subplot(4,size(trail_desired_joint_torque, 1),i + size(trail_desired_joint_torque, 1));
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
    
    % joint torque'
    subplot(4,size(trail_desired_joint_torque, 1),i + 2*size(trail_desired_joint_torque, 1));
    plot(trail_time, trail_desired_joint_torque_gradient(i,:), 'r','linewidth', 2.5);
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
    
    % joint velocity
    subplot(4,size(trail_desired_joint_torque, 1),i + 3*size(trail_desired_joint_torque, 1));
    plot(trail_time, trail_real_joint_velocity(i,:), 'r','linewidth', 2.5);
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
% figure;hold on;sgtitle('normalized real joint position');
% set(gca, 'FontSize', 20);
% set(groot,'defaultfigureposition',[400 250 900 750]);
% for i = 1:size(trail_desired_joint_torque, 1)
%     subplot(size(trail_desired_joint_torque, 1)/4,4,i);
%     plot(trail_time, trail_real_joint_position(i,:), 'r','linewidth', 2.5);
%     yl = ylim;
%     xl = xlim;
%     patch([xl(1), xl(1), trail_time(trail_ch_pos(1)), trail_time(trail_ch_pos(1)), xl(1)], ...
%         [yl(1), yl(2), yl(2), yl(1), yl(1)],...
%         'black', 'FaceColor', 'green', 'FaceAlpha', 0.1);
%     for j = 1:length(trail_ch_pos)-1
%         patch([trail_time(trail_ch_pos(j)), trail_time(trail_ch_pos(j)), ...
%             trail_time(trail_ch_pos(j+1)), trail_time(trail_ch_pos(j+1)), trail_time(trail_ch_pos(j+1))], ...
%         [yl(1), yl(2), yl(2), yl(1), yl(1)],...
%         'black', 'FaceColor', 'green', 'FaceAlpha', 0.2);
%     end    
%     patch([trail_time(trail_ch_pos(end)), trail_time(trail_ch_pos(end)), xl(2), xl(2), trail_time(trail_ch_pos(end))], ...
%         [yl(1), yl(2), yl(2), yl(1), yl(1)],...
%         'black', 'FaceColor', 'green', 'FaceAlpha', 0.3);
% end

%% 3-D view of the results within one trail
trail = 8; %size(desired_joint_torque, 2) / trail_length; % in 2-finger pinch experiments there are 20 trials
trail_data = [desired_joint_torque; real_joint_position; desired_joint_torque_gradient; real_joint_velocity];
trail_data = trail_data(:, (trail-1)*trail_length+1:trail*trail_length);
trail_ch_pos = ch_pos(ch_pos>(trail-1)*trail_length & ch_pos<trail*trail_length);
trail_ch_pos = trail_ch_pos - (trail-1)*trail_length - 1;

trail_time = 0:0.02:0.02*(length(trail_data)-1);

figure, hold on; title('normalized joint data');
set(gca, 'FontSize', 20);
axis tight
surf(trail_time, 1:size(trail_data, 1), trail_data);
set(gca, 'YTick', 1:size(trail_data, 1), ...
    'YTickLabel', {'torque1','torque2','torque3','torque4',...
                   'position1','position2','position3','position4',...
                   'torque''1','torque''2','torque''3','torque''4',...
                   'velocity1','velocity2','velocity3','velocity4'});
set(gca, 'YDir','reverse')
colorbar
shading interp
for i = 1 : length(trail_ch_pos)
    a = trail_time(trail_ch_pos(i));
    geoshow([1 size(trail_data, 1); ...
        1 size(trail_data, 1)], [a a; a a], [0 0; 1 1], ...
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

%% compute the distances between clusters
max_cluster_num = 5;
dist_between_cluster = cell(1, max_cluster_num);
for num_cluster = 2:max_cluster_num
    [idx, cluster_centre, ~, ~] = kmeans(data, num_cluster,... 
                          'Display', 'final',...
                          'Distance', 'sqeuclidean',...
                          'MaxIter', 100,...
                          'OnlinePhase', 'On',...
                          'Replicates', 10,...
                          'Start', 'plus');
    data_cluster = cell(1, num_cluster);
    for i = 1:num_cluster
        data_cluster{i} = data(find(idx==i), :);
    end
    dis_bet_clus = zeros(1, num_cluster);
    for i = 1:num_cluster
        min_dist_nb = 1e+3;
        for j = 1:num_cluster
            if i == j
                continue
            else
                % data_cluster{i}(idx_i, :) is the point in cluster i which
                % is nearest to cluster j
                [~, idx_i] = min(vecnorm((data_cluster{i} - cluster_centre(j,:))'));
                % data_cluster{j}(idx_j, :) is the point in cluster j which
                % is nearest to cluster i
                [~, idx_j] = min(vecnorm((data_cluster{j} - cluster_centre(i,:))'));               
                dist_ij = norm(data_cluster{i}(idx_i, :) - data_cluster{j}(idx_j, :));
                if dist_ij < min_dist_nb
                    min_dist_nb = dist_ij;
                end
            end
        end
        dis_bet_clus(i) = min_dist_nb;
    end
    dist_between_cluster{num_cluster} = dis_bet_clus;
end

%%
clc
for i = 2:size(dist_between_cluster, 2)
    disp(dist_between_cluster{i});
%     disp(sum(dist_between_cluster{i}));
end
%%
% clc
for i = 2:size(dist_between_cluster, 2)
    disp(sum(dist_between_cluster{i}));
end
