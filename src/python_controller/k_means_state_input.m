%% prepare the workspace
clc;
clear;
close all;

%% get the clustering results for all 4 types of input
dist_between_cluster_4 = func_k_means_state(4);

%% get the clustering results for 3 types of input
dist_between_cluster_3 = zeros(4, 5, 4);

dist_between_cluster_3(:,:,1) = func_k_means_state(3, 'q,f,dq');
dist_between_cluster_3(:,:,2) = func_k_means_state(3, 'q,f,df');
dist_between_cluster_3(:,:,3) = func_k_means_state(3, 'q,dq,df');
dist_between_cluster_3(:,:,4) = func_k_means_state(3, 'f,dq,df');

%% get the sum of distances between clusters
sum_dist_4 = sum(dist_between_cluster_4, 2);
sum_dist_3 = sum(dist_between_cluster_3, 2);

%% get the average of distances between clusters
mean_dist_4 = zeros(size(dist_between_cluster_4, 1), 1);
for i = 1:size(mean_dist_4, 1)
    mean_dist_4(i) = sum_dist_4(i) / (i+1);
end

mean_dist_3 = zeros(size(sum_dist_3));
for i = 1:size(mean_dist_3, 3)
    for j = 1:size(mean_dist_3, 1)
        mean_dist_3(j,1,i) = sum_dist_3(j,1,i) / (j+1);
    end
end