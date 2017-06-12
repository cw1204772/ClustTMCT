%% Fetching data

mex assignmentoptimal.c

% Fetching data
if ~exist('gt/trainval.mat','file')
    fprintf('Downloading ground truth...\n');
    url = 'http://vision.cs.duke.edu/DukeMTMC/data/ground_truth/trainval.mat';
    filename = 'gt/trainval.mat';
    outfilename = websave(filename,url);
end
if ~exist('res/baseline.txt','file')
    fprintf('Downloading baseline tracker output...\n');
    url = 'http://vision.cs.duke.edu/DukeMTMC/data/misc/tracker_output.zip';
    filename = 'res/tracker_output.zip';
    outfilename = websave(filename,url);
    unzip(outfilename,'res');
    delete(filename);
end

%% Evaluation
addpath(genpath('devkit'));

trackerOutput = dlmread('res/baseline.txt');
%trackerOutput = dlmread('res/CLUSTmeasure/toy.txt');
%trackerOutput = dlmread('res/ICT/AR/DGDCNN-AVG_mahal_th316.txt');
%trackerOutput = dlmread('res/ICT/GT/HistLBP-AVG_kissme_th283.txt');

% Note that if you are testing AR, it is recommended to turn on id amount
% filtering to speed up the evaluation

world = false; % Image plane
iou_threshold = 0.5;
%testSets = {'trainval_mini_1min'}; 
testSets = {'val'}; 
%testSets = {'toy'}; 

% Evaluate
for i = 1:length(testSets)
    testSet = testSets{i};
    results{i} = myevaluateDukeMTMC(trackerOutput, iou_threshold, world, testSet);

end

%% Display

% Print
for i = 1:length(testSets)
    
    result = results{i};
    fprintf('\n-------Results-------\n');
    fprintf('Test set: %s\n', testSets{i});
    % Single cameras all
    
    fprintf('%s\n',result{9}.description);
    %printMetrics(result{9}.allMets.mets2d.m); 
    fprintf('IDF1  \t IDP \t IDR \t clustF1\t clustP\t clustR\t clustRI\n');
    fprintf('%.2f\t', result{9}.IDmeasures.IDF1);
    fprintf(' %.2f\t', result{9}.IDmeasures.IDP);
    fprintf(' %.2f\t', result{9}.IDmeasures.IDR);
    fprintf(' %.2f\t\t', result{9}.CLUSTmeasures.clustF1);
    fprintf(' %.2f\t', result{9}.CLUSTmeasures.clustP);
    fprintf(' %.2f\t', result{9}.CLUSTmeasures.clustR);
    fprintf(' %.2f\n', result{9}.CLUSTmeasures.clustRI);
    
    
    % Multi-cam
    k = 10;    
    fprintf('%s\n', result{k}.description);
    fprintf('IDF1  \t IDP \t IDR \t clustF1\t clustP\t clustR\t clustRI\t linkF1\t linkP \t linkR \n');
    fprintf('%.2f\t', result{k}.IDmeasures.IDF1);
    fprintf(' %.2f\t', result{k}.IDmeasures.IDP);
    fprintf(' %.2f\t', result{k}.IDmeasures.IDR);
    fprintf(' %.2f\t\t', result{k}.CLUSTmeasures.clustF1);
    fprintf(' %.2f\t', result{k}.CLUSTmeasures.clustP);
    fprintf(' %.2f\t', result{k}.CLUSTmeasures.clustR);
    fprintf(' %.2f\t\t', result{k}.CLUSTmeasures.clustRI);
    fprintf(' %.2f\t', result{k}.LINKmeasures.linkF1)
    fprintf(' %.2f\t', result{k}.LINKmeasures.linkP);
    fprintf(' %.2f\n', result{k}.LINKmeasures.linkR);
    
    % All individual cameras
    %{
    fprintf('\n'); 
    for k = 1:8
       fprintf('%s\n',result{k}.description);
       fprintf('IDF1  \t IDP \t IDR \t clustF1\t clustP\t clustR\t clustRI\n');
       fprintf('%.2f\t', result{k}.IDmeasures.IDF1);
       fprintf(' %.2f\t', result{k}.IDmeasures.IDP);
       fprintf(' %.2f\t', result{k}.IDmeasures.IDR);
       fprintf(' %.2f\t\t', result{k}.CLUSTmeasures.clustF1);
       fprintf(' %.2f\t', result{k}.CLUSTmeasures.clustP);
       fprintf(' %.2f\t', result{k}.CLUSTmeasures.clustR);
       fprintf(' %.2f\n', result{k}.CLUSTmeasures.clustRI);
    end
    %}
end
