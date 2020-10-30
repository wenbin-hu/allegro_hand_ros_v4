%% load the data file
clear;
clc;
close all;
load('grasp_response.mat');

%% plot the desired joint position and real joint position
figure;hold on;title('joint position response');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_position(i,:), 'r', ...
    time, real_joint_position(i,:), 'b', 'linewidth', 2.5);
end

%legend('epoch reward', 'contact reward', 'Location','NorthWest');%'collision penalty', 'centre distance',
%xlabel('epoch');

%% plot desired torque command from Bhand and torque I computed separately
figure;hold on;sgtitle('desired joint torque');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_torque(i,:), 'r', 'linewidth', 2.5);
end

figure;hold on;sgtitle('real joint torque');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_torque(i,:), 'b', 'linewidth', 2.5);
end

%% plot desired torque command from Bhand and torque I computed
figure;hold on;sgtitle('desired joint torque');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_torque(i,:), 'r',...
        time, computed_joint_torque(i,:)/800, 'b', ...
        time, computed_joint_torque_vel(i,:)/800, 'g', 'linewidth', 2.5);
end

%%


figure;hold on;sgtitle('torque error');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_torque(i,:)-desired_joint_torque(i,:)*800, 'b', 'linewidth', 2.5);
end

%% plot logged velocity and computed velocity
figure;hold on;sgtitle('logged joint velocity');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_velocity(i,:), 'r', 'linewidth', 2.5);
end

computed_joint_velocity = zeros(size(real_joint_position));
for j = 1:16
    for i = 2:length(real_joint_position)
        computed_joint_velocity(j, i) = (real_joint_position(j, i) - ...
            real_joint_position(j, i-1)) / 0.02;
    end
end
figure;hold on;sgtitle('computed joint velocity');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, computed_joint_velocity(i,:), 'r', 'linewidth', 2.5);
end