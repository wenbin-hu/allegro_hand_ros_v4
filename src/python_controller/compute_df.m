%% load the data file
clear;
clc;
close all;
raw_data = load('data/two_finger_pinch_sliding/merged_two_finger_pinch_sliding.mat');
trail_length = 400; % every trail has 400 time-steps

%% get the data out of the struct
data_name_list = fieldnames(raw_data);
for i = 1:numel(data_name_list)
    assignin('caller', data_name_list{i}, raw_data.(data_name_list{i}));
end

%% low-pass filter the joint torque data
lp_desired_joint_torque = zeros(size(desired_joint_torque));
for j = 1:size(desired_joint_torque, 2)/trail_length
    for i = 1:size(desired_joint_torque, 1)
        % trick to remove the edge effect of low-pass filter
        % https://uk.mathworks.com/matlabcentral/answers/161223-how-to-remove-transient-effect-in-the-beginning-of-the-filtered-signal
        temp_torque = [flipud(desired_joint_torque(i,(j-1)*trail_length+1:(j-1)*trail_length+25)),...
            desired_joint_torque(i,(j-1)*trail_length+1:j*trail_length),...
            flipud(desired_joint_torque(i,j*trail_length-24:j*trail_length))];
        lp_temp_torque = lowpass(temp_torque, 5, 50);
        lp_desired_joint_torque(i,(j-1)*trail_length+1:j*trail_length) = ...
        lp_temp_torque(26:end-25);
%         lp_desired_joint_torque(i,(j-1)*trail_length+1:j*trail_length) = ...
%             lowpass(desired_joint_torque(i,(j-1)*trail_length+1:j*trail_length), 5, 50);               
    end
end

time = 0:0.02:0.02*399;
figure;hold on;sgtitle('joint torque and its low-pass filtered data');
set(gca, 'FontSize', 20);
for i = 1:4
    subplot(2,4,i);
    plot(time, desired_joint_torque(i,1:400), 'r','linewidth', 2.5);
    subplot(2,4,i+4);
    plot(time, lp_desired_joint_torque(i,1:400), 'b','linewidth', 2.5);
    
end

%% compute the joint torque gradient based on the filterd torque
dt = 0.02; % 50Hz
desired_joint_torque_gradient = zeros(size(desired_joint_torque));
for i = 1:size(desired_joint_torque, 2)/trail_length
    for j = 1:trail_length
        idx = (i-1)*trail_length + j;
        if j == 1
            temp = (lp_desired_joint_torque(:, idx+1) - lp_desired_joint_torque(:, idx)) / dt;
        elseif j == trail_length
            temp = (lp_desired_joint_torque(:, idx) - lp_desired_joint_torque(:, idx-1)) / dt;
        else
            temp = (lp_desired_joint_torque(:, idx+1) - lp_desired_joint_torque(:, idx-1)) / (2*dt);
        end
        desired_joint_torque_gradient(:, idx) = temp;
    end
end

%% plot for debug
time = 0:0.02:0.02*399;
figure;hold on;sgtitle('joint torque and its gradient');
set(gca, 'FontSize', 20);
for i = 1:4
    subplot(2,4,i);
    plot(time, desired_joint_torque_gradient(i,1:400), 'r','linewidth', 2.5);
    subplot(2,4,i+4);
    plot(time, desired_joint_torque(i,1:400), 'b','linewidth', 2.5);    
end

%% save the data
save('data/two_finger_pinch_sliding/merged_two_finger_pinch_sliding_with_gradient.mat',... 
    'computed_joint_torque', 'computed_joint_torque_vel', ...
    'desired_joint_position', 'desired_joint_torque',...
    'desired_joint_torque_gradient','real_joint_position','real_joint_velocity');