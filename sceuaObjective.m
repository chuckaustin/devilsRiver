function f = sceuaObjective(rawIntensity, idxPoint, idxFile, pointFrequency, nopt, b)
% an objective function to be used with the script STABILIZEIMAGES

numPoints   = size(idxPoint,2);
numFiles    = size(idxFile,2);
pointStd    = zeros(numPoints,1);

for j = 1:numFiles
    rawIntensity(idxFile(:,j)) = rawIntensity(idxFile(:,j)) * b(j) + ...
                                 b(numFiles + j);
end

for j = 1:numPoints
    pointStd(j) = std(rawIntensity(idxPoint(:,j))) * pointFrequency(j);
end

f   = sum(pointStd) / sum(pointFrequency);

end

