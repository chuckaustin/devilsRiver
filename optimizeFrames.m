function [bestx, bestf] = optimizeFrames(tiepts, frameStart, frameEnd)

% Winnow tie points table to only include the specified range

north  = frameStart:frameEnd;
tiepts(~ismember(tiepts.northidx, north), :) = [];
frames = cell(size(north));
for i = 1:numel(frames)
    frames{i} = unique(tiepts.file(tiepts.northidx==north(i)));
end

% Calculate a time range and number of instances for each geographic point

upoints     = unique(tiepts.point);
timeRange   = zeros(size(upoints)); 
pointFreq   = zeros(size(upoints));
for i = 1:numel(upoints)
    timeRange(i) = range(tiepts.flightTime(tiepts.point==upoints(i)));
    pointFreq(i) = sum(tiepts.point==upoints(i));    
end

clear i

% Eliminate all points appearing in only one image

idx             = pointFreq < 2;
tiepts(ismember(tiepts.point, upoints(idx)), :) = [];
upoints(idx)    = [];
pointFreq(idx)  = [];
timeRange(idx)  = [];

% For each frame, select (up to) thirty points with the greatest time range

selection   = false(size(upoints));
[~,iTime]   = sort(timeRange, 'descend');
upoints     = upoints(iTime);
pointFreq   = pointFreq(iTime);

for i = 1:numel(frames)
    frameidx    = strcmp(tiepts.file, frames{i});
    pointidx    = find(ismember(upoints, tiepts.point(frameidx)));
    for j = 1:min([numel(pointidx) 30])
        selection(pointidx(j)) = true;
    end
end
        
clear iTime i frameidx pointidx j

% Create a table extracting intensity from each high point instance

hiPoints    = upoints(selection);
highpts     = tiepts(ismember(tiepts.point, hiPoints), :);

% Prepare objective function to be passed to SCEUA

idximage    = false(size(highpts,1), numel(frames));
idxpoint    = false(size(highpts,1), numel(hiPoints));
hiPtFreq    = pointFreq(selection);

for j = 1:numel(frames)
    idximage(:,j) = strcmp(frames{j}, highpts.file); end
for j = 1:numel(hiPoints)
    idxpoint(:,j) = highpts.point == hiPoints(j); end

functn = @(nopt, b)sceuaObjective(highpts.rawIntensity, ...
         idxpoint, idximage, hiPtFreq, nopt, b);
     
clear j idximage idxpoint
     
% Set up and run shuffled complex algorithm

x0      = [ones(1, numel(frames)) zeros(1, numel(frames))];
lb      = [1 0.8*ones(1, numel(frames)-1) 0 -40*ones(1, numel(frames)-1)];
ub      = [  1.2*ones(1, numel(frames))      40*ones(1, numel(frames))];
ngs     = 4;
maxn    = 5e5;
kstop   = 20;
pcento  = 0.01;
peps    = 1e-4;
iseed   = 1;
iniflg  = 1;

[bestx, bestf] = sceua(x0, lb, ub, maxn, kstop, pcento, peps, ngs, ...
                 iseed, iniflg, functn);
             
end