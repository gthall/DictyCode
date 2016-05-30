%this function takes in the first frame of the movie and then identifies
%the rough area of the plate. The function preprocesses and then thresholds
%the frame and then fits this threashold to a circle
function [circularMask, cx, cy, r] = WellMask (firstFrame, minArea)

%define filter and filter image
averageFilter = fspecial('average', [100 100]);
firstFrameFilter = imfilter (firstFrame, averageFilter, 'replicate');
firstFrameFilter = imfilter (firstFrameFilter, averageFilter, 'replicate');
firstFrameFilter = imfilter (firstFrameFilter, averageFilter, 'replicate');
firstFrameFilter = imfilter (firstFrameFilter, averageFilter, 'replicate');
firstThresh = graythresh(firstFrameFilter);
firstFrameBW = im2bw(firstFrameFilter, firstThresh);
firstFrameBW = bwareaopen(firstFrameBW, minArea);
%take note of centroid
maskInfo = regionprops (firstFrameBW, 'Area', 'Centroid',...
    'MajorAxisLength', 'MinorAxisLength', 'Eccentricity',...
    'Orientation', 'ConvexHull');

%make a circular mask through the center and the maximum distance
cx = maskInfo(1).Centroid(1); 
cy = maskInfo(1).Centroid(2); 
%find the point that is fartest away
maskDist = maskInfo(1).ConvexHull;
%normalize to centroid 
maskDist (:,1) = maskDist(:,1) - cx; maskDist(:,2) = maskDist(:,2)-cy;
%convert to distance from radius
maskDistance = (maskDist(:,1).^2 + maskDist(:,2).^2);
[maxDist, maxIndex] = max(maskDistance);
%find radius
r = sqrt(maxDist);
%cast center to integers corresponding to pixels in the image
cx = round(cx);
cy = round(cy);
%define image axes
[x, y] = size (firstFrame);
circularMask = zeros(x,y);
%make circularmask 

for i = 1: x
    
    for j = 1:y 
        circularMask (i,j) = ((i-cy)^2 + (j-cx)^2 <= r^2);
    end 
    
end 


end




