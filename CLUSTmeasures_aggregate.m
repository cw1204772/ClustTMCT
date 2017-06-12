function [clust_measures] = CLUSTmeasures_aggregate(result, n_cameras)
% % Input: 
%    result    - A cell array of c cells, which c equals to n_cameras
%                Each cell contains a struct consisting: clust_mat, id_gt, id_pred, junk
%    n_cameras - number of results from each camera to aggregate the multi-cam CLUSTmeasures

% Starting from step 3
% However, we do not need to do tracklet matching
% Only need to construct GT/AR id matrix and FP/AR id matrix (a clust_mat)

% Calculate size of final clust_mat
id_gt = [];
id_pred = [];
junk = 0;  % junk == fp
for n = 1 : n_cameras
  id_gt = [id_gt; result{n}.CLUSTmeasures.id_gt];
  id_pred = [id_pred; result{n}.CLUSTmeasures.id_pred];
  junk = junk + result{n}.CLUSTmeasures.junk;
end
id_gt = unique(id_gt);
id_pred = unique(id_pred);
n_id_gt = length(id_gt);
n_id_pred = length(id_pred);

% Construct clust_mat
clust_mat = zeros(n_id_gt + junk, n_id_pred);
fp_counter = 0;
for n = 1 : n_cameras
  % iterate the clust_mat of result{n}.CLUSTmeasures
  single_clust_mat = result{n}.CLUSTmeasures.clust_mat;
  single_id_gt = result{n}.CLUSTmeasures.id_gt;
  single_id_pred = result{n}.CLUSTmeasures.id_pred;
  single_junk = result{n}.CLUSTmeasures.junk;
  assert(length(single_id_gt) + single_junk == size(single_clust_mat, 1));
  assert(length(single_id_pred) == size(single_clust_mat, 2));
  for i = 1 : size(single_clust_mat, 1)
    for j = 1 : size(single_clust_mat, 2)
      if single_clust_mat(i, j) == 0
        continue
      elseif i > length(single_id_gt) % pred is a fp tracklet
        fp_counter = fp_counter + 1;
        pred_id = single_id_pred(j, 1);
        i_ = n_id_gt + fp_counter;
        j_ = find(id_pred == pred_id);
        clust_mat(i_, j_) = clust_mat(i_, j_) + single_clust_mat(i, j);
      else % pred is a matched tracklet
        gt_id = single_id_gt(i, 1);
        pred_id = single_id_pred(j, 1);
        i_ = find(id_gt == gt_id);
        j_ = find(id_pred == pred_id);
        clust_mat(i_, j_) = clust_mat(i_, j_) + single_clust_mat(i, j);
      end
    end
  end
end
assert(junk == fp_counter);

% Compute TP, P, T 
fprintf('Step4\n');
TP = 0;
for i = 1 : size(clust_mat, 1)
  for j = 1 : size(clust_mat, 2)
    if clust_mat(i, j) >= 2
      TP = TP + nchoosek(clust_mat(i, j), 2);
    end
  end
end

P = 0;
P_clust = squeeze(sum(clust_mat, 1));
for i = 1 : size(P_clust, 2)
  if P_clust(i) >= 2
    P = P + nchoosek(P_clust(i), 2);
  end
end
FP = P - TP;

T = 0;
T_clust = squeeze(sum(clust_mat, 2));
for i = 1 : size(T_clust, 1)
  if T_clust(i) >= 2
    T = T + nchoosek(T_clust(i), 2);
  end
end
FN = T - TP;

total = 0;
total_tracklets = sum(clust_mat(:));
if total_tracklets >= 2
  total = nchoosek(total_tracklets, 2);
end
TN = total - TP - FP - FN;
assert(TN >= 0);

clustP = TP / (TP + FP) * 100.;
clustR = TP / (TP + FN) * 100.;
clustF1 = (2.0 * clustP * clustR) / (clustP + clustR);
clustRI = (TP + TN) / total * 100;
clust_measures.clustP = clustP;
clust_measures.clustR = clustR;
clust_measures.clustF1 = clustF1;
clust_measures.clustRI = clustRI;
clust_measures.TP = TP;
clust_measures.FP = FP;
clust_measures.FN = FN;
clust_measures.TN = TN;
clust_measures.clust_mat = clust_mat;
clust_measures.id_gt = id_gt;
clust_measures.id_pred = id_pred;
clust_measures.junk = junk;

end