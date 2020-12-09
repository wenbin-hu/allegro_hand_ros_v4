%% prepare the workspace
clc;
clear;
close all;

%% get the clustering results for all 4 types of input
[dist_between_cluster_4, sil_width_4, dunn_4] = func_k_means(4,'q,f,dq,df', 5);

%% get the clustering results for 3 types of input
dist_between_cluster_3 = zeros(4, 5, 4);
sil_width_3 = zeros(4,1,4);
dunn_3 = zeros(4,1,4);

[dist_between_cluster_3(:,:,1), sil_width_3(:,:,1), dunn_3(:,:,1)] = func_k_means(3, 'q,f,dq', 5);
[dist_between_cluster_3(:,:,2), sil_width_3(:,:,2), dunn_3(:,:,2)] = func_k_means(3, 'q,f,df', 5);
[dist_between_cluster_3(:,:,3), sil_width_3(:,:,3), dunn_3(:,:,3)] = func_k_means(3, 'q,dq,df', 5);
[dist_between_cluster_3(:,:,4), sil_width_3(:,:,4), dunn_3(:,:,4)] = func_k_means(3, 'f,dq,df', 5);

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