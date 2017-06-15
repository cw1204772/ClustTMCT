function result = evaluateDukeMTMC(resMat, iou_threshold, world, testSet)

ROI = getROIs();

if strcmp(testSet,'easy')
    load('gt/testData.mat');
    gtMat = testData;
    testInterval = [263504:356648];
elseif strcmp(testSet,'hard')
    load('gt/testHardData.mat');
    gtMat = testHardData;
    testInterval = [227541:263503];
elseif strcmp(testSet,'trainval')
    load('gt/trainval.mat');
    gtMat = trainData;
    testInterval = [49700:227540]; % takes too long
elseif strcmp(testSet,'trainval_mini') % shorter version of trainval
    load('gt/trainval.mat');
    gtMat = trainData;
    testInterval = [127720:187540];
elseif strcmp(testSet,'val') % appox. last 25 min. of trainval
    load('gt/trainval.mat');
    gtMat = trainData;
    testInterval = [139611:227540];
else
    fprintf('Unknown test set %s\n',testSet);
    return;
end



% Filter rows by frame interval
startTimes = [5543, 3607, 27244, 31182, 1, 22402, 18968, 46766];
for cam = 1:8
    gtMat(gtMat(:,1) == cam & ~ismember(gtMat(:,3) + startTimes(cam) - 1, testInterval),:) = [];
    resMat(resMat(:,1) == cam & ~ismember(resMat(:,3) + startTimes(cam) - 1, testInterval),:) = [];
end

% Filter rows by feet position within ROI
feetpos = [ resMat(:,4) + 0.5*resMat(:,6), resMat(:,5) + resMat(:,7)];
keep = false(size(resMat,1),1);
for cam = 1:8
    camFilter = resMat(:,1) == cam;
    keep(camFilter & inpolygon(feetpos(:,1),feetpos(:,2), ROI{cam}(:,1),ROI{cam}(:,2))) = true;
end

resMat = resMat(keep,:);

% Single-Cam
for camera = 1:8
    fprintf('Processing camera %d...\n',camera);
    resMatSingle = resMat(resMat(:,1)==camera, 2:7);
    gtMatSingle = gtMat(gtMat(:,1)==camera, 2:7);
    clust_measures = CLUSTmeasures(resMatSingle, gtMatSingle, iou_threshold, world);
    measures = IDmeasures(resMatSingle, gtMatSingle, iou_threshold, world);
    result{camera}.CLUSTmeasures = clust_measures;
    result{camera}.IDmeasures = measures;
    result{camera}.description = sprintf('Cam_%d',camera);
end
fprintf('\n');


% Multi-Cam

% Convert data format to:
% ID, frame, left, top, width, height, worldX, worldY
SHIFT_CONSTANT = 100000000;

gtMatMulti  = gtMat(:,2:7);
resMatMulti = resMat(:,2:7);
gtMatMulti(:,2) = gtMat(:,3) + gtMat(:,1)*SHIFT_CONSTANT; % frame + cam*1000000 for frame uniqueness
resMatMulti(:,2) = resMat(:,3) + resMat(:,1)*SHIFT_CONSTANT; 
result{10}.description = 'Multi-cam';
result{10}.IDmeasures = IDmeasures(resMatMulti, gtMatMulti, iou_threshold, world);

%result{10}.CLUSTmeasures = CLUSTmeasures(resMatMulti, gtMatMulti, iou_threshold, world);
% Constructing clust_mat from clust_mat from each camera is faster than reconstructing
result{10}.CLUSTmeasures = CLUSTmeasures_aggregate(result, 8);

% AllCameraSingle (MC Upper bound) 
gtMatSingleAll = gtMat(:,2:7);
resMatSingleAll = resMat(:,2:7);

gtMatSingleAll(:,1) = gtMatSingleAll(:,1) + gtMat(:,1)*SHIFT_CONSTANT; % ID + cam*1000000 for ID uniqueness
resMatSingleAll(:,1) = resMatSingleAll(:,1) + resMat(:,1)*SHIFT_CONSTANT;

for cam = 1:8 % frame uniqueness
    gtMatSingleAll(gtMat(:,1)==cam,2) = gtMatSingleAll(gtMat(:,1)==cam,2) + (cam-1) * numel(testInterval);
    resMatSingleAll(resMat(:,1)==cam,2)  = resMatSingleAll(resMat(:,1)==cam,2) + (cam-1) * numel(testInterval);
end


result{9}.description = 'Single-all';
if false
    measures = IDmeasures(resMatSingleAll, gtMatSingleAll, iou_threshold, world);
    result{9}.IDmeasurs = measures;
    result{9}.allMets = evaluateTracking(result{9}.description, gtMatSingleAll, resMatSingleAll);
else
    % It is faster to aggregate scores from all cameras than to re-evaluate
    MT = 0; PT = 0; ML = 0; FRA = 0;
    falsepositives = 0; missed = 0; idswitches = 0;
    Fgt = 0; iousum = 0; Ngt = 0; sumg = 0;
    Nc = 0;
    numGT = 0; numPRED = 0; IDTP = 0; IDFP = 0; IDFN = 0;
    CLUSTTP = 0; CLUSTFP = 0; CLUSTFN = 0; CLUSTTN = 0;
    
    for cam = 1:8
        
        numGT = numGT + result{cam}.IDmeasures.numGT;
        numPRED = numPRED + result{cam}.IDmeasures.numPRED;
        IDTP = IDTP + result{cam}.IDmeasures.IDTP;
        IDFN = IDFN + result{cam}.IDmeasures.IDFN;
        IDFP = IDFP + result{cam}.IDmeasures.IDFP;
        CLUSTTP = CLUSTTP + result{cam}.CLUSTmeasures.TP;
        CLUSTFP = CLUSTFP + result{cam}.CLUSTmeasures.FP;
        CLUSTFN = CLUSTFN + result{cam}.CLUSTmeasures.FN;
        CLUSTTN = CLUSTTN + result{cam}.CLUSTmeasures.TN;
        
    end
    
    CLUSTPrecision = CLUSTTP / (CLUSTTP + CLUSTFP);
    CLUSTRecall = CLUSTTP / (CLUSTTP + CLUSTFN);
    CLUSTF1 = 2 * CLUSTPrecision * CLUSTRecall /(CLUSTPrecision + CLUSTRecall);
    CLUSTRI = (CLUSTTP + CLUSTTN) / (CLUSTTP + CLUSTFP + CLUSTFN + CLUSTTN);
    
    IDPrecision = IDTP / (IDTP + IDFP);
    IDRecall = IDTP / (IDTP + IDFN);
    IDF1 = 2*IDTP/(numGT + numPRED);

    clust_measures.clustP = CLUSTPrecision * 100;
    clust_measures.clustR = CLUSTRecall * 100;
    clust_measures.clustF1 = CLUSTF1 * 100;
    clust_measures.clustRI = CLUSTRI * 100;
    result{9}.CLUSTmeasures = clust_measures;
    
    measures.IDP = IDPrecision * 100;
    measures.IDR = IDRecall * 100;
    measures.IDF1 = IDF1 * 100;
    measures.numGT = numGT;
    measures.numPRED = numPRED;
    measures.IDTP = IDTP;
    measures.IDFP = IDFP;
    measures.IDFN = IDFN;
    result{9}.IDmeasures = measures;
    
end


