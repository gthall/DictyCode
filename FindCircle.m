function [x, y, R err] = FindCircle (firstFrameBW, firstFrame, minArea);
%extract information about particles
firstFrameInfo = regionprops (firstFrameBW, 'Area');
%find biggest one
[maxArea maxIndex] = max ([firstFrameInfo.Area]);
%filter area
firstFrameBW = xor (bwareaopen(firstFrameBW, maxArea),...
    bwareaopen (firstFrameBW, minArea));
figure;imshow(firstFrameBW); hold on;
firstFrameInfo = regionprops (firstFrameBW, ...
    'Centroid', 'Area', 'Image');
firstFrameLabel = bwlabel(firstFrameBW);
%loop through particles and try fitting a circle to them
xc = zeros(1, length(firstFrameInfo));
yx = zeros(1, length(firstFrameInfo));
R = zeros(1, length(firstFrameInfo));
err = zeros(1, length(firstFrameInfo));

for j = 1: length(firstFrameInfo)
    [row col] = find (firstFrameLabel ==j);
    [xc(j) yx(j) R(j) err(j)] = circfit (col, row)
    
end
%find the circle(s) with the lowest error

[minErr minIndex] = min (err);
%see if this circle has acceptable properties
if ~(R>100& R < 300)
    
end
%plot that circle

circle (mean(xc(minIndex)), mean(yx(minIndex)), mean(R(minIndex)));
hold off

figure;imshow (firstFrame);
circle (mean(xc(minIndex)), mean(yx(minIndex)), mean(R(minIndex)));

end