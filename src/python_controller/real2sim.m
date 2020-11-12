%% load the data file
clear;
clc;

%% plot the simulation data
time = 0:0.02:0.02*(length(desired_joint_torque)-1);
figure;hold on;sgtitle('simulation joint position');
set(gca, 'FontSize', 20);
for i = 1:16
    subplot(4,4,i);
    plot(time, sim_real_joint_position(i,:), 'r','linewidth', 2.5);
end

figure;hold on;sgtitle('simulation joint torque');
set(gca, 'FontSize', 20);
for i = 1:16
    subplot(4,4,i);
    plot(time, sim_desired_joint_torque(i,:), 'r','linewidth', 2.5);
end

%% plot the real data
figure;hold on;sgtitle('real joint position');
set(gca, 'FontSize', 20);
for i = 1:16
    subplot(4,4,i);
    plot(time, real_joint_position(i,:), 'r','linewidth', 2.5);
end

figure;hold on;sgtitle('real joint torque');
set(gca, 'FontSize', 20);
for i = 1:16
    subplot(4,4,i);
    plot(time, desired_joint_torque(i,:), 'r','linewidth', 2.5);
end