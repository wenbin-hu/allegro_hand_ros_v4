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