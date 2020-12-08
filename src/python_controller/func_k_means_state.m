function [dist_between_cluster] = func_k_means_state(num_state, state_input)
%% load the data file
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
%     assignin('caller', data_name_list{i}, raw_data.(data_name_list{i}));
    eval([data_name_list{i} '=raw_data.' data_name_list{i} ]);
end

%% prepare the data
dt = 0.02;
time_window = 0.1 / dt;
data = zeros(size(desired_joint_torque,1)*time_window*num_state, ...
                size(desired_joint_torque,2)/trail_length * ...
                (trail_length-time_window+1));
if num_state == 4
    % torque, position, torque', position'    
    for i = 1 : size(desired_joint_torque,2)/trail_length
        for j = 1 : trail_length-time_window+1
            idx_s = (i-1) * trail_length + j;
            idx_e = (i-1) * trail_length + j + time_window - 1;
            data(:, (i-1)*(trail_length-time_window+1)+j ) = ...
            [reshape(desired_joint_torque(:,idx_s:idx_e), size(data,1)/num_state, 1);...
            reshape(real_joint_position(:,idx_s:idx_e), size(data,1)/num_state, 1);...
            reshape(desired_joint_torque_gradient(:,idx_s:idx_e), size(data,1)/num_state, 1);...
            reshape(real_joint_velocity(:,idx_s:idx_e), size(data,1)/num_state, 1)];
        end    
    end    
elseif num_state == 3
    if strcmp(state_input, 'q,f,dq')
        data_0 = desired_joint_torque;
        data_1 = real_joint_position;
        data_2 = real_joint_velocity;
    elseif strcmp(state_input, 'q,f,df')
        data_0 = desired_joint_torque;
        data_1 = real_joint_position;
        data_2 = desired_joint_torque_gradient;
    elseif strcmp(state_input, 'q,dq,df')
        data_0 = real_joint_position;
        data_1 = desired_joint_torque_gradient;
        data_2 = real_joint_velocity;
    elseif strcmp(state_input, 'f,dq,df')
        data_0 = desired_joint_torque;
        data_1 = desired_joint_torque_gradient;
        data_2 = real_joint_velocity;
    end
    % torque, position, torque', position'    
    for i = 1 : size(desired_joint_torque,2)/trail_length
        for j = 1 : trail_length-time_window+1
            idx_s = (i-1) * trail_length + j;
            idx_e = (i-1) * trail_length + j + time_window - 1;
            data(:, (i-1)*(trail_length-time_window+1)+j ) = ...
            [reshape(data_0(:,idx_s:idx_e), size(data,1)/num_state, 1);...
            reshape(data_1(:,idx_s:idx_e), size(data,1)/num_state, 1);...
            reshape(data_2(:,idx_s:idx_e), size(data,1)/num_state, 1)];
        end    
    end  
end
data = data';

%% compute the distances between clusters
max_cluster_num = 5;
% dist_between_cluster = cell(1, max_cluster_num);
dist_between_cluster = zeros(max_cluster_num-1, max_cluster_num);
for num_cluster = 2:max_cluster_num
    [idx, cluster_centre, ~, ~] = kmeans(data, num_cluster,... 
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
%     dist_between_cluster{num_cluster} = dis_bet_clus;
    dist_between_cluster(num_cluster-1, 1:num_cluster) = dis_bet_clus;
end

end
