function partitionDomain (imFol, maskRatio)
%the number image to use to mask
referenceFrameNumber = 100;
partitionReferenceNumber = 920;
centerReferenceNumber = 1390;
%the name of the images
imName = 'Image*';
%the amount of the mask that you should use
%make the directory
imDir = dir([imFol filesep imName]);


referenceFrame = im2double(imread([imFol filesep ...
    imDir(referenceFrameNumber).name]));
[referenceMask, referenceXCenter, referenceYCenter, referenceRadius] = ...
    WellMask (referenceFrame, 10000);

xCoords = round(referenceXCenter-maskRatio*referenceRadius):...
    round (referenceXCenter+maskRatio*referenceRadius);
yCoords = round(referenceYCenter-maskRatio*referenceRadius):...
    round (referenceYCenter+maskRatio*referenceRadius);

referenceFrame (~referenceMask) = 0;
activeFrame = referenceFrame(xCoords, yCoords);

centerFrame = im2double(imread([imFol filesep...
    imDir(centerReferenceNumber).name]));
centerFrame(~referenceMask) = 0;
activeCenter = centerFrame(xCoords, yCoords);

partitionFrame = im2double(imread([imFol filesep...
    imDir(partitionReferenceNumber).name]));
partitionFrame(~referenceMask) = 0;
partitionCenter = partitionFrame(xCoords, yCoords);


%prompt user input to identify centers
[xCenters, yCenters] = identifyCentersUI(centerFrame);
imshow (partitionFrame);
a = gca;
hold on;

voronoi (a, xCenters, yCenters);
set (gca, 'Ydir', 'reverse');
figure;


end 