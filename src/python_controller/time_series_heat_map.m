%% load the data file
clear;
clc;
close all;
load('data/grasp_response2020_11_03_15.21.37.mat');
%load('data/grasp_response2020_11_03_15.26.43.mat');

%% 
time = 0:0.02:0.02*(length(desired_joint_torque)-1);
figure, hold on; title('joint torque');
set(gca, 'FontSize', 20);
axis tight
for i = 1:16
imagesc(time, i*ones(size(time)), desired_joint_torque(i,:));
end
set(gca, 'YTick', 1:16, 'YTickLabel', 1:16);
colorbar

%%
time = 0:0.02:0.02*(length(real_joint_position)-1);
figure, hold on; title('joint position');
set(gca, 'FontSize', 20);
axis tight
for i = 1:16
imagesc(time, i*ones(size(time)), real_joint_position(i,:));
end
set(gca, 'YTick', 1:16, 'YTickLabel', 1:16);
colorbar

%%
time = 0:0.02:0.02*(length(real_joint_velocity)-1);
figure, hold on; title('joint velocity');
set(gca, 'FontSize', 20);
axis tight
for i = 1:16
imagesc(time, i*ones(size(time)), real_joint_velocity(i,:));
end
set(gca, 'YTick', 1:16, 'YTickLabel', 1:16);
colorbar