%% load the data file
clear;
clc;
close all;
load('grasp_response_0.mat');

%% plot the desired joint position and real joint position
figure;hold on;title('joint position step response');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_position(i,:), 'r', ...
    time, real_joint_position(i,:), 'b', 'linewidth', 2.5);
end

%legend('epoch reward', 'contact reward', 'Location','NorthWest');%'collision penalty', 'centre distance',
%xlabel('epoch');

%% plot the desired and real joint position
figure;hold on;sgtitle('joint position');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_position(i,:), 'r', ...
    time, real_joint_position(i,:), 'b', 'linewidth', 2.5);
end

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
    plot(time, desired_joint_torque(i,:)*800, 'r',...
        time, real_joint_torque(i,:), 'b','linewidth', 2.5);
end

%%


figure;hold on;sgtitle('torque error');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_torque(i,:)-desired_joint_torque(i,:)*800, 'b', 'linewidth', 2.5);
end

%{
figure;hold on;sgtitle('joint velocity');
set(gca, 'FontSize', 20);
time = 0:0.02:0.02*(length(desired_joint_position)-1);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_velocity(i,:), 'r', 'linewidth', 2.5);
end
%}