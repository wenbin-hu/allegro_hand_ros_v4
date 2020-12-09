%% this file evaluates the result of the cluster results

%% load and prepare the data of two finger pinch
% load the data file
clear;
clc;
% close all;
% load('data/grasp_response2020_11_12_15.52.30.mat');
% raw_data = load('data/two_finger_pinch_sliding/merged_two_finger_pinch_sliding_with_gradient.mat');
raw_data = load('data/two_finger_pinch/merged_two_finger_pinch_with_gradient.mat');
trail_length = 400; % every trail has 400 time-steps

% for three-fingered grasp, drop out the data of little finger
% data_name_list = fieldnames(raw_data);
% for i = 1:numel(data_name_list)
%     raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:8 13:16], :);
% end

% for two-fingered grasp, drop out the data of last two fingers, and choosing only index finger
data_name_list = fieldnames(raw_data);
for i = 1:numel(data_name_list)
%     raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:4 13:16], :);
    raw_data.(data_name_list{i}) = raw_data.(data_name_list{i})([1:4], :);
end

% Normalize all the data to 0-1

% since I am processing the concatenated data. I have to normalize every
% trail individually. Here is the merged data of 20 trials.
for i = 1:numel(data_name_list)
    data_name = data_name_list{i};
    for j = 1 : size(raw_data.(data_name), 2) / trail_length
        raw_data.(data_name)(:, 1+(j-1)*trail_length:j*trail_length) = ...
            normalize(raw_data.(data_name)(:, 1+(j-1)*trail_length:j*trail_length), 2, 'range');
    end
end

% get the variables out of the struct
for i = 1:numel(data_name_list)
    assignin('caller', data_name_list{i}, raw_data.(data_name_list{i}));
end

% prepare the data
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

%% cluster the data with k-means
num_cluster = 3;
[idx, cluster_centre, sum_distance, distance] = kmeans(data, num_cluster,... 
                          'Display', 'off',...
                          'Distance', 'sqeuclidean',...
                          'MaxIter', 100,...
                          'OnlinePhase', 'On',...
                          'Replicates', 10,...
                          'Start', 'plus');

data_cluster = cell(1, num_cluster);
for i = 1:num_cluster
    data_cluster{i} = data(find(idx==i), :);
end

%% Silhouette width. Reference: Pattern recognition P229
% sil_sum = zeros(1, num_cluster);
% sil_vector = zeros(size(data, 1), 1);
% count = 1;
% for i = 1:num_cluster
%     for j = 1:size(data_cluster{i}, 1)
%         tempA = data_cluster{i};
%         tempA(j,:) = [];
%         a_j = mean(vecnorm((data_cluster{i}(j, :) - tempA)'), 2);
%         % find out which cluster is the nearest to point j
%         % initialize the index for nearest cluster
%         idx_nst = 0;
%         dist_nst = 100;
%         for k = 1:num_cluster
%             if k == i
%                 continue
%             end
%             if min(vecnorm((data_cluster{i}(j, :) - data_cluster{k})')) < dist_nst
%                 dist_nst = min(vecnorm((data_cluster{i}(j, :) - data_cluster{k})'));
%                 idx_nst = k;
%             end
%         end
%         % compute b_j
%         b_j = mean(vecnorm((data_cluster{i}(j, :) - ...
%                              data_cluster{idx_nst})'), 2);
%         % compute S_j
%         S_j = (b_j - a_j) / max(b_j, a_j);
%         sil_sum(i) = sil_sum(i) + S_j;
%         sil_vector(count) = S_j;
%         count = count + 1;
%     end
% end
% sil_width = sum(sil_sum) / size(data, 1);

%% Silhouette width (MATLAB version)
sil_vec = silhouette(data, idx, 'Euclidean');

%% Dunn index from online forum
distM = squareform(pdist(data));
dunn = dunns(num_cluster, distM, idx);