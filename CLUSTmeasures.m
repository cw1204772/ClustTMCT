function [clust_measures, predTraklet] = CLUSTmeasures( predictionMat, groundTruthMat, threshold, world )
% Input: 
%    predictionMat    - ID, frame, left, top, width, height
%    groundTruthMat   - ID, frame, left, top, width, height
%    threshold        - Ground plane distance (1m) or intersection_over_union 
%    world            - boolean parameter determining if the evaluation is
%                       done in the world ground plane or in the image plane
%                       Currently only support world=False

if size(predictionMat, 1) == 0
  error('You have 0 tracks in the prediction result of a camera!!');
end

% 1. Break down predictionMat into tracklets
fprintf('Step1\n');
predictionMat = sortrows(predictionMat);
groundTruthMat = sortrows(groundTruthMat);
t_idx = zeros(size(predictionMat, 1), 1);
counter = 1;
t_idx(1,1) = counter;
for i = 2:size(predictionMat,1)
  if predictionMat(i,1) == predictionMat(i-1,1) % same ID
    if predictionMat(i,2) ~= predictionMat(i-1,2)+1 % non-consecutive frame
      counter = counter + 1;
    end
  else
    counter = 1;
  end  
  t_idx(i,1) = counter;
end
predictionMat = [predictionMat t_idx]; % the 7th column is now tracklet idx

% 2. Frame matching
fprintf('Step2\n');
gt_id = ones(size(predictionMat, 1), 1) * -1;

frames_pred = unique(predictionMat(:, 2));
fn = length(frames_pred);
t0 = tic;
for i = 1 : length(frames_pred)
  curframe = frames_pred(i, 1);
  bbox_gt = groundTruthMat(groundTruthMat(:, 2)==curframe, :);
  if size(bbox_gt, 1) == 0
    continue;
  end
  pred_curframe_idx = predictionMat(:, 2)==curframe;
  bbox_pred = predictionMat(pred_curframe_idx, :);
  bbox_pred_idx = find(pred_curframe_idx);
  cost = zeros(size(bbox_gt, 1) + size(bbox_pred, 1)); % create square matrix for Hungarian algorithm
  for u = 1 : size(bbox_gt, 1)
    for v = 1 : size(bbox_pred, 1)
      cost(u, v) = distanceFunction(bbox_gt(u, [3 4 5 6]), bbox_pred(v, [3 4 5 6]), world);
    end
  end
  [assignment, ~] = assignmentoptimal(1 - cost); % perform Hungarian algorithm
  for j = 1 : size(bbox_gt, 1)
    if assignment(j) <= size(bbox_pred, 1) && cost(j, assignment(j)) > threshold
      gt_id(bbox_pred_idx(assignment(j)), 1) = bbox_gt(j, 1);
    end
  end
  if mod(i, floor(length(frames_pred)/10)) == 0
    fprintf('%d%% time spent: %.3g seconds\n', floor(100.*i/length(frames_pred)), toc(t0));
    t0 = tic;
  end
end
predictionMat = [predictionMat gt_id]; % add gt_id at 8th column
%predictionMat

% 3. Tracklet matching
% Construct GT/AR id matrix in first pass while construct FP/AR id matrix in second pass
% for better memory allocation.
fprintf('Step3\n');
HASH_ID_OFFSET = 1000;
key = predictionMat(:, 1) * HASH_ID_OFFSET + predictionMat(:, 7); % A key by hashing (ID, tracklet_idx)
predictionMat = [predictionMat key]; % add key at 9th column
tracklet_pred = unique(key); % each key represents a tracklet
id_pred = unique(predictionMat(:, 1));
id_gt = unique(groundTruthMat(:, 1));

n_tracklet_pred = size(tracklet_pred, 1);
n_id_pred = size(id_pred, 1);
n_id_gt = size(id_gt, 1);

% *****for Link-based measure*****
predTraklet = ones(n_tracklet_pred, 6) * -1; 
% format: ID, start frame, end frame, tracklet_idx, g_id, n_match_frames
% ********************************

junk = 0;
clust_mat = zeros(n_id_gt, n_id_pred); % Construct GT/AR id matrix
for i = 1 : n_tracklet_pred
  tracklet = predictionMat(key==tracklet_pred(i), :);
  most_freq_gt_id = mode(tracklet(:, 8));
  n_matched_frames = sum(tracklet(:, 8) == most_freq_gt_id);
  coverage = double(n_matched_frames) / double(size(tracklet, 1));
  if most_freq_gt_id ~= -1 && coverage > 0.5
    pred_id = floor(tracklet_pred(i) / HASH_ID_OFFSET); % revert key to obtain AR id
    pred_id_idx = find(id_pred==pred_id); % convert to column idx for clust_mat
    gt_id_idx = find(id_gt==most_freq_gt_id);
    clust_mat(gt_id_idx, pred_id_idx) = clust_mat(gt_id_idx, pred_id_idx) + 1;
    
    % *****for Link-based measure*****
    predTraklet(i, 1) =  pred_id;
    % ********************************
  else 
    junk = junk + 1;
    
    % *****for Link-based measure*****
    predTraklet(i, 1) = -1; 
    % ********************************
  end
  % *****for Link-based measure*****
  tracklet = sortrows(tracklet);
  predTraklet(i, 2) = tracklet(1, 2);
  predTraklet(i, 3) = tracklet(size(tracklet, 1), 2);
  predTraklet(i, 4) = mod(tracklet_pred(i), HASH_ID_OFFSET);
  predTraklet(i, 5) = most_freq_gt_id;
  predTraklet(i, 6) = n_matched_frames;
  % ********************************
end

clust_junk_mat = zeros(junk, n_id_pred); % Construct FP/AR id matrix
j = 0;
for i = 1 : n_tracklet_pred
  tracklet = predictionMat(key==tracklet_pred(i), :);
  most_freq_gt_id = mode(tracklet(:, 8));
  coverage = double(sum(tracklet(:, 8) == most_freq_gt_id)) / double(size(tracklet, 1));
  if most_freq_gt_id == -1 || coverage <= 0.5
    j = j + 1;
    pred_id = floor(tracklet_pred(i) / HASH_ID_OFFSET); % revert key to obtain AR id
    pred_id_idx = find(id_pred==pred_id); % convert to column idx for clust_mat
    clust_junk_mat(j, pred_id_idx) = 1;
  end
end
assert(j == junk); % Sanity check
clust_mat = [clust_mat; clust_junk_mat;];
fprintf('size of clust_mat:\n');
size(clust_mat)

% 4. Compute TP, P, T 
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
%clust_mat

end


% distanceFunction
function distance = distanceFunction(point1, point2, world)

if world
    % Euclidean distance
    distance = sqrt(sum(abs(point1 - point2).^2,2));
    
else
    % Intersection_over_union
    box1 = point1;
    box2 = point2;
    
    area1 = box1(:,3) .* box1(:,4);
    area2 = box2(:,3) .* box2(:,4);
    
    l1 = box1(:,1); r1 = box1(:,1) + box1(:,3); t1 = box1(:,2); b1 = box1(:,2) + box1(:,4);
    l2 = box2(:,1); r2 = box2(:,1) + box2(:,3); t2 = box2(:,2); b2 = box2(:,2) + box2(:,4);
    
    x_overlap = max(0, min(r1,r2) - max(l1,l2));
    y_overlap = max(0, min(b1,b2) - max(t1,t2));
    intersectionArea = x_overlap .* y_overlap;
    unionArea = area1 + area2 - intersectionArea;
    iou = intersectionArea ./ unionArea;
    
    distance = iou;
end

end