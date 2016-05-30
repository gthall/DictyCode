function [ data ] = trackTRED( iDir, rFol, rNam, fFol, fNam, numI, fBoo, type, mBoo, mDir )
%trackTRED Tracks red cells and records information about traces.
%   iDir - folder with all the image directories.
%   rFol - folder name with the tracking cells.
%   rNam - general name of the cells to be tracked.
%   fFol - folder name with the FRET images.
%   fNam - general name of the FRET images.
%   numI - number of images to analyze.  0 means all of them.
%   fBoo - boolean to decide whether or not to add FRET traces.
%   type - type of FRET signal to find.
%   mBoo - boolean to decide to make movie or not.
%   mDir - Place to store the movie if it is to be made.
%
%Made by Darvin Yi (yidarvin[at]gmail.com)

% Section _: Mutable Variables
eThr = 0.25;
dThr = 10;

% Section _: Immutable Variables
rFil = dir([iDir filesep rFol filesep rNam]);
wBar = waitbar(0, 'Please wait...');
wObj = VideoWriter('movie.avi');
wObj.FrameRate = 24;
open(wObj);
dayC = 0;
dayS = 1;
cntD = 0;

% Section _: Initializing an Empty Cell
cell.xPos = [];
cell.yPos = [];
cell.time = [];
cell.area = [];
cell.imag = [];
cell.fret = [];
temp(1) = deal(cell);
data(1) = deal(cell);

% Section _: Dealing with the First Image
i = 1;
mesg = ['Analyzing Frame ' num2str(i) ' of ' num2str(numI) ':'];
waitbar((i/numI), wBar, mesg);
TRim = imread([iDir filesep rFol filesep rFil(i).name]);
info = imfinfo([iDir filesep rFol filesep rFil(i).name]);
time = info.ImageDescription;
info = time;
iniT = str2double(info(13:14))*60 + str2double(info(16:17)) ...
    + str2double(info(19:20))/60;
TRim = im2double(TRim);
TRim = TRim - min(min(TRim));
TRim = TRim/max(max(TRim));
[xGrd, yGrd] = computegradients(TRim);
edge = detectedges(xGrd, yGrd);
imbw = imfill(im2bw(edge, eThr), 'holes');
imbw = 1 - imerode(1 - imbw, strel('disk', 3));
writeVideo(wObj, 255*uint8(imbw));
stat = regionprops(imbw, 'Area', 'Centroid');
for j = 1:length(stat)
    temp(j).xPos = stat(j).Centroid(1);
    temp(j).yPos = stat(j).Centroid(2);
    temp(j).time = 0;
    temp(j).area = stat(j).Area;
    temp(j).imag = i;
    temp(j).fret = 0;
end

for i = 2:numI
    % Section _: Finding Info on Other Images
    mesg = ['Analyzing Frame ' num2str(i) ' of ' num2str(numI) ':'];
    waitbar((i/numI), wBar, mesg);
    TRim = imread([iDir filesep rFol filesep rFil(i).name]);
    info = imfinfo([iDir filesep rFol filesep rFil(i).name]);
    time = info.ImageDescription;
    info = time;
    time = str2double(info(13:14))*60 + str2double(info(16:17)) ...
        + str2double(info(19:20))/60;
    if dayS == 1
        if time - iniT < 0
            dayS = 0;
            dayC = dayC + 1;
        end
    else
        if time - iniT > 0
            dayS = 1;
        end
    end
    time = dayC*24*60 + time - iniT;
    TRim = im2double(TRim);
    TRim = TRim - min(min(TRim));
    TRim = TRim/max(max(TRim));
    [xGrd, yGrd] = computegradients(TRim);
    edge = detectedges(xGrd, yGrd);
    imbw = imfill(im2bw(edge, eThr), 'holes');
    imbw = 1 - imerode(1 - imbw, strel('disk', 3));
    writeVideo(wObj, 255*uint8(imbw));
    stat = regionprops(imbw, 'Area', 'Centroid');
    
    % Section _: Linking (or Oraganizing) Previous Cells
    j = 1;
    while j <= length(temp)
        minD = inf;
        cnt1 = 0;
        leng = length(temp(j).xPos);
        k = 1;
        while k <= length(stat)
            dist = sqrt((stat(k).Centroid(1) - temp(j).xPos(leng))^2 ...
                + (stat(k).Centroid(2) - temp(j).yPos(leng))^2);
            if dist < minD && dist < dThr
                minD = dist;
                cnt1 = k;
                tmpS = stat(k);
                stat(k) = [];
            else
                k = k + 1;
            end
        end
        if cnt1 > 0
            temp(j).xPos = [temp(j).xPos tmpS.Centroid(1)];
            temp(j).yPos = [temp(j).xPos tmpS.Centroid(2)];
            temp(j).time = [temp(j).time time];
            temp(j).area = [temp(j).area tmpS.Area];
            temp(j).imag = [temp(j).imag i];
            temp(j).fret = [temp(j).fret 0];
            j = j + 1;
        else
            cntD = cntD + 1;
            data(cntD) = temp(j);
            temp(j) = [];
        end
    end
    cntT = length(temp);
    for j = 1:length(stat)
        cntT = cntT + 1;
        temp(cntT).xPos = stat(j).Centroid(1);
        temp(cntT).yPos = stat(j).Centroid(2);
        temp(cntT).time = time;
        temp(cntT).area = stat(j).Area;
        temp(cntT).imag = i;
        temp(cntT).fret = 0;
    end
end
for j = 1:length(temp)
    cntD = cntD + 1;
    data(cntD) = temp(j);
end

delete(wBar)

end

