%% Stabilize Imagery

% a script to stabilize imagery of groundwater-surface water mixing at the
% Devils River in west Texas, collected using a FLIR Vue Pro microbolometer
% attached to a small UAV. This script follows the methods of the paper
% "UAV-based monitoring of groundwater inputs to surface waters using an
% economical thermal infrared camera," submitted by C Abolt et al. to the
% Journal of Applied Remote Sensing.

% author:       cabolt
% date:         12.29.2017, Austin TX

clear; clc; close all

%% Import tie points into a table, and sort by flight time

tiepts      = readtable('devils_tiepts.txt');
tiepts      = tiepts(:,1:4);
tiepts.Properties.VariableNames = {'file' 'point' 'x' 'y'};
tiepts.x    = tiepts.x + 320 + 0.5;
tiepts.y    = 512.5 - (tiepts.y + 256);

[frames, ~, tiepts.flightTime]  = unique(tiepts.file);

%% Read in intensity of each point from raw data 

tiepts.rawIntensity = zeros(size(tiepts.file));

for i = 1:numel(frames)
    dataFile    = [pwd '\TIFFs - pixel bias removed\' frames{i}(1:15) '.tiff'];
    data        = imread(dataFile);
    data        = imfilter(data, fspecial('disk', 10), 'symmetric');
    idx         = strcmp(frames{i}, tiepts.file);
    datapts     = sub2ind(size(data), round(tiepts.y(idx)), ...
                  round(tiepts.x(idx)));
    tiepts.rawIntensity(idx) = (data(datapts))';
end

clear dataFile data idx datapts

%% First pass -- optimize images in groups of fifteen

cameras     = readtable('devils_cameras.txt');
cameras     = cameras(1:230, 1:3);
cameras.Properties.VariableNames = {'file' 'x' 'y'};

[~, northidx]   = sort(cameras.y);
tiepts.northidx = zeros(size(tiepts.x));
for i = 1:numel(frames)
    tiepts.northidx(tiepts.flightTime == northidx(i)) = i;
end

northStart  = 1:16:numel(frames);
northEnd    = northStart + 15;
northEnd(end) = numel(frames);
bestxRound1 = zeros(numel(frames), 2);
bestfRound1 = zeros(numel(frames), 1);

for i = 1:numel(northStart)
    [bestx, bestf]  = optimizeFrames(tiepts, northStart(i), northEnd(i));
    meanAdd         = mean(bestx( (numel(bestx)/2 + 1):end));
    bestx((numel(bestx)/2 + 1):end) = bestx((numel(bestx)/2 + 1):end) - meanAdd;
    for j = 1:(northEnd(i) - northStart(i) + 1)
        frame   = unique(tiepts.file(tiepts.northidx == northStart(i) + j - 1));
        frameID = find(strcmp(frames, frame));
        bestxRound1(frameID, 1) = bestx(j);
        bestxRound1(frameID, 2) = bestx(j + (northEnd(i) - northStart(i)) + 1);
        bestfRound1(frameID) = bestf;
    end
end

clear frameStart frameEnd i bestx bestf cameras northidx meanAdd frame frameID j northEnd northStart

%% Second pass -- optimize groups

chunkpts    = tiepts;
for i = 1:numel(frames)
    frameidx    = strcmp(chunkpts.file, frames{i});
    chunkpts.rawIntensity(frameidx) = ...
        chunkpts.rawIntensity(frameidx) * bestxRound1(i,1) + bestxRound1(i,2);
end

chunkpts.chunk = ceil(chunkpts.northidx / 16);

chunkStart  = 1:16:(max(chunkpts.chunk)-1);
chunkEnd    = chunkStart + 15;
chunkEnd(end) = max(chunkpts.chunk);

bestxRound2 = zeros(numel(frames), 2);
bestfRound2 = zeros(numel(frames), 1);

for i = 1:numel(chunkStart)
    [bestx, bestf]  = optimizeChunks(chunkpts, chunkStart(i), chunkEnd(i));
    meanAdd         = mean(bestx( (numel(bestx)/2 + 1):end));
    bestx((numel(bestx)/2 + 1):end) = bestx((numel(bestx)/2 + 1):end) - meanAdd;
    for j = 1:(chunkEnd(i) - chunkStart(i) + 1)
        chunkFrames = unique(chunkpts.file(chunkpts.chunk == chunkStart(i) + j - 1));
        frameIdx    = ismember(frames, chunkFrames);
        bestxRound2(frameIdx, 1) = bestx(j);
        bestxRound2(frameIdx, 2) = bestx(j + numel(bestx)/2);
        bestfRound2(frameIdx)    = bestf;
    end
end

clear i frameidx chunkStart chunkEnd i bestx bestf j chunkFrames frameIdx meanAdd

%% Apply corrections

mkdir('TIFFs - corrected');

for i = 1:numel(frames)
    data    = imread([pwd '/TIFFs - pixel bias removed/' frames{i}(1:15) '.tiff']);
    data    = data * bestxRound1(i,1) + bestxRound1(i,2);
    data    = data * bestxRound2(i,1) + bestxRound2(i,2);
    imwrite(data, [pwd '/TIFFs - corrected/' frames{i}(1:15) '.tiff']);   
end

clear i data cmap image

disp ' '
disp 'You''re done!'
disp ' '

