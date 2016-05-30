%function [data] = TREDtracker()%(iDir, rFol, rNam, wFol, wNam, cFol, cNam, yFol, yNam, fFol, fNam, iNumImg, mBoo, mDir)
tic
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
sImgDir = 'Users/gavinhall/Documents/Gregor Lab/';
sRedFol = 'TRED';
sRedNam = 'TRED-*.tif';
sWavFol = 'WAVE';
sWavNam = 'FRET-*.tif';
sCfpFol = 'ECFP';
sCfpNam = 'ECFP-*.tif';
sYfpFol = 'EYFP';
sYfpNam = 'EYFP-*.tif';
sFrtFol = 'FRET';
sFrtNam = 'FRET-*.tif';
iNumImg = 1000;
lMovBoo = 1;
sMovDir = 'E:\Darvin\MarsRedMix\201403111700Results';
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%---------DESCRIPTION------------------------------------------------------
%TREDtracker takes in a movie of TRED images and FRET images of Dicty
%cells.  It then proceeds to track each cell in the TRED channel, find its
%positions, velocities, areas, roundness, ECFP intensities, EYFP
%intensities, FRET intensities, cAMP intensities, and mean Optical Flow
%velocities.
%   sImgDir = Main image directory.
%   s***Fol = Folder of that stream of images.  r/w/c/y/f =
%          TRET/WAVE/ECFP/EYFP/FRET.
%   s***Nam = Name of the images.  RegEx used.
%   iNumImg = 0 for all images.
%   lMovBoo = 1 for a movie.
%   sMovDir = Directory of the movie.
%   data = This is basically the final goal of the program.  It will
%       contain all the information of each cell's tracks.  It will contain
%       the centroid of the cell at each frame it was found (x and y), the 
%       velocity of the cell at each frame it was found (vx and vy), the
%       area of the cell at each frame (area), the roundness of the cell at
%       each frame (round), the frames that the cell was found in (frame),
%       the background subtracted values of the YFP, CFP, and the CFP/YFP
%       ratio (yfp, cfp, and ratio respectively), and the raw values of the
%       YFP, CFP, and the CFP/YFP ratio (rawy, fawc, and rawr
%       respectively).  Spelled TRACKS in all lowercase.
%--------------------------------------------------------------------------


%---------SETTING VARIABLES------------------------------------------------
%This section will make some changes to predefined variables and also make
%other new variables from those predefined variables.  A lot of the time,
%it is just setting up some arrays or something along those lines.  Some
%things just should not be in the input arguments, as if we put everything
%into the input arguments, we'd be inputting input arguments all day long.
%Thus, the few hard-coded things will be here in the code.
% Section 1: Mutable Variables
dTimInt = 1;
iSrtImg = 1;
iTimFor = 1;
iTimBac = 1;

% Section 2: Immutable Variables
dayC = 0;
dayS = 1;
cntD = 0;
oRedDir = dir([sImgDir filesep sRedFol filesep sRedNam]);
oWavDir = dir([sImgDir filesep sWavFol filesep sWavNam]);
oCfpDir = dir([sImgDir filesep sCfpFol filesep sCfpNam]);
oYfpDir = dir([sImgDir filesep sYfpFol filesep sYfpNam]);
oFrtDir = dir([sImgDir filesep sFrtFol filesep sFrtNam]);

% Converts tau into frames.
iSeeFor = ceil(iTimFor/dTimInt);
iSeeBac = ceil(iTimBac/dTimInt);

% A lot of the hard-coded variables.
iMinSiz = 25;
iErrMrg = 25;
iMatCrp = 15;
iCrpRad = 5;
dMatPwr = 1.25;
iBwCrpr = 10;
iMovFps = 24;

% This section will initialize the final variable "tracks."
emptycell.x     = [];
emptycell.y     = [];
emptycell.vx    = [];
emptycell.vy    = [];
emptycell.ofvx  = [];
emptycell.ofvy  = [];
emptycell.area  = [];
emptycell.time  = [];
emptycell.frame = [];
emptycell.wave  = [];
emptycell.ecfp  = [];
emptycell.eyfp  = [];
emptycell.fret  = [];
data(1)         = deal(emptycell);
iYesDat         = [];
%--------------------------------------------------------------------------


%---------FINDING INITIAL CELL INFORMATION---------------------------------
% In order to analyze the rest of the images and make a nice for-loop, we
% need to get the initial properties of the first frame.  We also start the
% troubleshooting movie here.
% Setting up the video.
if lMovBoo
    wObj = VideoWriter([sMovDir filesep 'Tracker.avi']);
    wObj.FrameRate = iMovFps;
    open(wObj)
end

% Setting up the waitbar.
w = waitbar(0, 'Please wait...');
i = iSrtImg;
timT = toc;
remT = ceil(timT*((iNumImg - i + 1)/i));
if remT > 3600
    hourT = (remT - mod(remT, 3600))/3600;
    if hourT < 10
        hour = ['0' num2str(hourT)];
    else
        hour = num2str(hourT);
    end
else
    hourT = 0;
    hour = '00';
end
remT = remT - 3600*hourT;
if remT > 60
    minsT = (remT - mod(remT, 60))/60;
    if minsT < 10
        mins = ['0' num2str(minsT)];
    else
        mins = num2str(minsT);
    end
else
    minsT = 0;
    mins = '00';
end
remT = remT - 60*minsT;
secsT = remT;
if secsT < 10
    secs = ['0' num2str(secsT)];
else
    secs = num2str(secsT);
end
mesg = ['Tracking frame ' num2str(i) ' out of ' num2str(iNumImg) ' (' hour ':' mins ':' secs ' Left):'];
waitbar((i/iNumImg), w, mesg);

% Reading in the images.
dRedImg = im2double(imread([sImgDir filesep sRedFol filesep oRedDir(iSrtImg).name]));
dRedImg = dRedImg - min(min(dRedImg));
dRedImg = dRedImg/max(max(dRedImg));
dWavImg = im2double(imread([sImgDir filesep sWavFol filesep oWavDir(iSrtImg).name]));
dCfpImg = im2double(imread([sImgDir filesep sCfpFol filesep oCfpDir(iSrtImg).name]));
dYfpImg = im2double(imread([sImgDir filesep sYfpFol filesep oYfpDir(iSrtImg).name]));
dFrtImg = im2double(imread([sImgDir filesep sFrtFol filesep oFrtDir(iSrtImg).name]));

% Setting the time
info = imfinfo([sImgDir filesep sRedFol filesep oRedDir(iSrtImg).name]);
time = info.ImageDescription;
info = time;
iniT = str2double(info(13:14))*60 + str2double(info(16:17)) ...
    + str2double(info(19:20))/60;

% Finding Optical Flow
dRedIm1 = double(imread([sImgDir filesep sRedFol filesep oRedDir(iSrtImg).name]));
dRedIm2 = double(imread([sImgDir filesep sRedFol filesep oRedDir(iSrtImg+1).name]));
dMaxScl = double(max(max(max(dRedIm1, dRedIm2))));
dRedIm1 = dRedIm1/dMaxScl(1, 1);
dRedIm2 = dRedIm2/dMaxScl(1, 1);
[u, v]  = OpticalFlow(dRedIm1, dRedIm2, 1);

% Finding the binary image.
lBinImg = im2bw(dRedImg, graythresh(dRedImg));% & movingAverageThresh(uint16(65535*dRedImg), iMatCrp, iMinSiz, dMatPwr);
lBinImg = bwareaopen(lBinImg, iMinSiz);

% Finding the information of the initial cells.
iLabImg = bwlabel(lBinImg, 4);
oSttImg = regionprops(iLabImg, 'Area', 'Centroid');
if lMovBoo
    cmap = hsv(length(oSttImg));
    [r, c] = size(dRedImg);
    dRedChn = zeros(r, c);
    dBluChn = zeros(r, c);
    dGreChn = zeros(r, c);
    totalmasks = zeros(r, c);
    totalmasks = repmat(totalmasks, [1 1 3]);
end
iYesDat = [];
for j = 1:length(oSttImg)
    iYesDat = [iYesDat j];
    lBwMask       = (iLabImg == j);
    data(j).x     = oSttImg(j).Centroid(1);
    data(j).y     = oSttImg(j).Centroid(2);
    data(j).vx    = 0;
    data(j).vy    = 0;
    data(j).ofvx  = mean(u(lBwMask));
    data(j).ofvy  = mean(v(lBwMask));
    data(j).frame = 1;
    data(j).time  = 0;
    data(j).area  = oSttImg(j).Area;
    data(j).wave  = mean(dWavImg(lBwMask));
    data(j).ecfp  = mean(dCfpImg(lBwMask));
    data(j).eyfp  = mean(dYfpImg(lBwMask));
    data(j).fret  = mean(dFrtImg(lBwMask));
    dBwMask       = double(lBwMask);
    if lMovBoo
        dRedChn(lBwMask) = cmap(j, 1);
        dBluChn(lBwMask) = cmap(j, 2);
        dGreChn(lBwMask) = cmap(j, 3);
    end
end

% Adding the first frame to the movie.
if lMovBoo
    totalmasks(:, :, 1) = dRedChn;
    totalmasks(:, :, 2) = dBluChn;
    totalmasks(:, :, 3) = dGreChn;
    totalmasks = imresize(totalmasks, 1/3);
    totalmasks(totalmasks > 1) = 1;
    totalmasks(totalmasks < 0) = 0;
    writeVideo(wObj, totalmasks);
    modder = length(data);
end
%--------------------------------------------------------------------------


%---------ANALYZING ALL OTHER FRAMES TO CONNECT CELLS----------------------
% We will now go through all the other images.  At each image, we'll read
% in the corresponding image, and then do analysis on it.  First, we'll
% stalk the previous cells we found.  Then, we'll add cells that we found
% new.
for i = iSrtImg+1:iNumImg
    % Displaying the waitbar.
    timT = toc;
    remT = ceil(timT*((iNumImg - i + 1)/i));
    if remT > 3600
        hourT = (remT - mod(remT, 3600))/3600;
        if hourT < 10
            hour = ['0' num2str(hourT)];
        else
            hour = num2str(hourT);
        end
    else
        hourT = 0;
        hour = '00';
    end
    remT = remT - 3600*hourT;
    if remT > 60
        minsT = (remT - mod(remT, 60))/60;
        if minsT < 10
            mins = ['0' num2str(minsT)];
        else
            mins = num2str(minsT);
        end
    else
        minsT = 0;
        mins = '00';
    end
    remT = remT - 60*minsT;
    secsT = remT;
    if secsT < 10
        secs = ['0' num2str(secsT)];
    else
        secs = num2str(secsT);
    end
    mesg = ['Tracking frame ' num2str(i) ' out of ' num2str(iNumImg) ' (' hour ':' mins ':' secs ' Left):'];
    waitbar((i/iNumImg), w, mesg);
    
    % Reading in the images.
    dRedImg = im2double(imread([sImgDir filesep sRedFol filesep oRedDir(i).name]));
    dRedImg = dRedImg - min(min(dRedImg));
    dRedImg = dRedImg/max(max(dRedImg));
    dWavImg = im2double(imread([sImgDir filesep sWavFol filesep oWavDir(i).name]));
    dCfpImg = im2double(imread([sImgDir filesep sCfpFol filesep oCfpDir(i).name]));
    dYfpImg = im2double(imread([sImgDir filesep sYfpFol filesep oYfpDir(i).name]));
    dFrtImg = im2double(imread([sImgDir filesep sFrtFol filesep oFrtDir(i).name]));
    
    % Setting the time.
    info = imfinfo([sImgDir filesep sRedFol filesep oRedDir(i).name]);
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
    
    % Finding Optical Flow
    dRedIm1 = double(imread([sImgDir filesep sRedFol filesep oRedDir(iSrtImg).name]));
    dRedIm2 = double(imread([sImgDir filesep sRedFol filesep oRedDir(iSrtImg+1).name]));
    dMaxScl = double(max(max(max(dRedIm1, dRedIm2))));
    dRedIm1 = dRedIm1/dMaxScl(1, 1);
    dRedIm2 = dRedIm2/dMaxScl(1, 1);
    [u, v]  = OpticalFlow(dRedIm1, dRedIm2, 1);
    
    % Setting up totalmasks.
    if lMovBoo
        dRedChn = zeros(r, c);
        dBluChn = zeros(r, c);
        dGreChn = zeros(r, c);
        totalmasks = zeros(r, c);
        totalmasks = repmat(totalmasks, [1 1 3]);
    end
    
    % Finds the binary image.
    lBinImg = im2bw(dRedImg, graythresh(dRedImg));% & movingAverageThresh(uint16(65535*dRedImg), iMatCrp, iMinSiz, dMatPwr);
    lBinImg = bwareaopen(lBinImg, iMinSiz);
    lBinTot = lBinImg;
    iLabImg = bwlabel(lBinTot, 4);
    oSttImg = regionprops(iLabImg, 'Area', 'Centroid');
    
    iYesDa2 = iYesDat;
    iYesDat = [];
    % We will now go through all the cells we have previously found.
    for iCountr = 1:length(iYesDa2)
        % We look at the cell only if it was found recently.
        j = iYesDa2(iCountr);
        % Find some important values.
        iMaxExt = length(data(j).frame);
        dPrevCx = data(j).x(iMaxExt);
        dPrevCy = data(j).y(iMaxExt);
        iPrevCx = round(dPrevCx);
        iPrevCy = round(dPrevCy);
        dDifTim = time - data(j).time(iMaxExt);
        if iLabImg(iPrevCy, iPrevCx) ~= 0
            iYesDat = [iYesDat j];
            k = iLabImg(iPrevCy, iPrevCx);
            lBwMask       = (iLabImg == k);
            data(j).x(iMaxExt+1)     = oSttImg(k).Centroid(1);
            data(j).y(iMaxExt+1)     = oSttImg(k).Centroid(2);
            data(j).vx(iMaxExt+1)    = (oSttImg(k).Centroid(1) - dPrevCx)/dDifTim;
            data(j).vy(iMaxExt+1)    = (oSttImg(k).Centroid(2) - dPrevCy)/dDifTim;
            data(j).ofvx(iMaxExt+1)  = mean(u(lBwMask));
            data(j).ofvy(iMaxExt+1)  = mean(v(lBwMask));
            data(j).frame(iMaxExt+1) = i;
            data(j).area(iMaxExt+1)  = oSttImg(k).Area;
            data(j).time(iMaxExt+1)  = time;
            data(j).wave(iMaxExt+1)  = mean(dWavImg(lBwMask));
            data(j).ecfp(iMaxExt+1)  = mean(dCfpImg(lBwMask));
            data(j).eyfp(iMaxExt+1)  = mean(dYfpImg(lBwMask));
            data(j).fret(iMaxExt+1)  = mean(dFrtImg(lBwMask));
            if lMovBoo
                if mod(j, modder) ~= 0
                    dRedChn(lBwMask) = cmap(mod(j, modder), 1);
                    dBluChn(lBwMask) = cmap(mod(j, modder), 2);
                    dGreChn(lBwMask) = cmap(mod(j, modder), 3);
                else
                    dRedChn(lBwMask) = cmap(modder, 1);
                    dBluChn(lBwMask) = cmap(modder, 2);
                    dGreChn(lBwMask) = cmap(modder, 3);
                end
            end
            lBinTot(lBwMask)         = 0;
            iLabImg(lBwMask)         = 0;
        else
            [iRowPix, iColPix] = find(lBinTot);
            dDistan = sqrt((iRowPix - iPrevCy).^2 + (iColPix-iPrevCx).^2);
            if min(dDistan) < iErrMrg
                iYesDat = [iYesDat j];
                iMinCoo = find(dDistan == min(dDistan));
                iMinCoo = iMinCoo(1);
                k = iLabImg(iRowPix(iMinCoo), iColPix(iMinCoo));
                lBwMask       = (iLabImg == k);
                data(j).x(iMaxExt+1)     = oSttImg(k).Centroid(1);
                data(j).y(iMaxExt+1)     = oSttImg(k).Centroid(2);
                data(j).vx(iMaxExt+1)    = (oSttImg(k).Centroid(1) - dPrevCx)/dDifTim;
                data(j).vy(iMaxExt+1)    = (oSttImg(k).Centroid(2) - dPrevCy)/dDifTim;
                data(j).ofvx(iMaxExt+1)  = mean(u(lBwMask));
                data(j).ofvy(iMaxExt+1)  = mean(v(lBwMask));
                data(j).frame(iMaxExt+1) = i;
                data(j).area(iMaxExt+1)  = oSttImg(k).Area;
                data(j).time(iMaxExt+1)  = time;
                data(j).wave(iMaxExt+1)  = mean(dWavImg(lBwMask));
                data(j).ecfp(iMaxExt+1)  = mean(dCfpImg(lBwMask));
                data(j).eyfp(iMaxExt+1)  = mean(dYfpImg(lBwMask));
                data(j).fret(iMaxExt+1)  = mean(dFrtImg(lBwMask));
                if lMovBoo
                    if mod(j, modder) ~= 0
                        dRedChn(lBwMask) = cmap(mod(j, modder), 1);
                        dBluChn(lBwMask) = cmap(mod(j, modder), 2);
                        dGreChn(lBwMask) = cmap(mod(j, modder), 3);
                    else
                        dRedChn(lBwMask) = cmap(modder, 1);
                        dBluChn(lBwMask) = cmap(modder, 2);
                        dGreChn(lBwMask) = cmap(modder, 3);
                    end
                end
                lBinTot(lBwMask)         = 0;
                iLabImg(lBwMask)         = 0;
            end
        end
    end
    
    % Now we will search for cells that we have not yet found.  New cells.
    iLabImg = bwlabel(lBinTot, 4);
    oSttImg = regionprops(iLabImg, 'Area', 'Centroid');
    iCurLng = length(data);
    if ~isempty(oSttImg)
        for j = 1:length(oSttImg)
            iYesDat = [iYesDat (iCurLng+j)];
            lBwMask = (iLabImg == j);
            data(iCurLng+j).x     = oSttImg(j).Centroid(1);
            data(iCurLng+j).y     = oSttImg(j).Centroid(2);
            data(iCurLng+j).vx    = 0;
            data(iCurLng+j).vy    = 0;
            data(iCurLng+j).ofvx  = mean(u(lBwMask));
            data(iCurLng+j).ofvy  = mean(v(lBwMask));
            data(iCurLng+j).frame = i;
            data(iCurLng+j).time  = time;
            data(iCurLng+j).area  = oSttImg(j).Area;
            data(iCurLng+j).wave  = mean(dWavImg(lBwMask));
            data(iCurLng+j).ecfp  = mean(dCfpImg(lBwMask));
            data(iCurLng+j).eyfp  = mean(dYfpImg(lBwMask));
            data(iCurLng+j).fret  = mean(dFrtImg(lBwMask));
            if lMovBoo
                if mod(iCurLng+j, modder) ~= 0
                    dRedChn(lBwMask) = cmap(mod(iCurLng+j, modder), 1);
                    dBluChn(lBwMask) = cmap(mod(iCurLng+j, modder), 2);
                    dGreChn(lBwMask) = cmap(mod(iCurLng+j, modder), 3);
                else
                    dRedChn(lBwMask) = cmap(modder, 1);
                    dBluChn(lBwMask) = cmap(modder, 2);
                    dGreChn(lBwMask) = cmap(modder, 3);
                end
            end
        end
    end
    if lMovBoo
        totalmasks(:, :, 1) = dRedChn;
        totalmasks(:, :, 2) = dBluChn;
        totalmasks(:, :, 3) = dGreChn;
        totalmasks = imresize(totalmasks, 1/3);
        totalmasks(totalmasks > 1) = 1;
        totalmasks(totalmasks < 0) = 0;
        writeVideo(wObj, totalmasks);
    end
end
if lMovBoo
    close(wObj);
end
delete(w);
save([sMovDir filesep 'Data.mat'], 'data');
%--------------------------------------------------------------------------


% %---------FUNCTION: MovingAverageThresh------------------------------------
%     function [binaryImg] = MovingAverageThresh(Img, Cropper, MINarea, Power)
%         % Defining the average image filter.
%         hfilter = fspecial('average', Cropper*2 + 1);
%         
%         % Finding the doubly average subtracted image.
%         tempImg = imfilter(Img, hfilter, 'replicate');
%         tempImg = imfilter(tempImg, hfilter, 'replicate');
%         tempImg = Img - tempImg;
%         
%         % Raising the image to a power to exagerate the difference.
%         tempImg = uint16(floor(double(tempImg).^Power));
%         
%         % Making the image binary.
%         binaryImg = im2bw(tempImg, graythresh(tempImg));
%         binaryImg = bwareaopen(binaryImg, MINarea, 4);
%     end        
% %--------------------------------------------------------------------------
% 
% 
% %---------FUNCTION: min2---------------------------------------------------
%     function [matrixMIN] = min2(inputMIN)
%         matrixMIN = min(min(inputMIN));
%     end
% %--------------------------------------------------------------------------
% 
% 
% %---------FUNCTION: max2---------------------------------------------------
%     function [matrixMAX] = max2(inputMAX)
%         matrixMAX = max(max(inputMAX));
%     end
% %--------------------------------------------------------------------------
% 
% 
% %---------FUNCTION: sum2---------------------------------------------------
%     function [matrixSUM] = sum2(inputSUM)
%         matrixSUM = sum(sum(inputSUM));
%     end
% %--------------------------------------------------------------------------


%---------GLOSSERY---------------------------------------------------------
% a
% aviobj
% backavgIc
% backavgIy
% bw
% bw_crop
% bwt
% bwcrppr
% c
% c1
% c1lower
% c1upper
% cfiles
% circ
% cmap
% cmprs
% comp
% comp1
% counter
% croprad
% cropxh
% cropxl
% cropyh
% cropyl
% cx
% cy
% dist
% emarg
% emptycell
% frameps
% Ic
% Icr
% Iy
% Iyr
% i
% i1
% im
% im_crop
% j
% j1
% k
% L
% MATcrop
% masks
% maxf
% maxf2
% maxl
% maxt
% message
% minArea
% modder
% power
% r
% r1
% r1lower
% r1upper
% rad
% stats
% stats12
% t
% tempim
% temptracks
% totalmasks
% w
% yfiles
% MovingAverageThresh
%   binaryImg
%   Cropper
%   hfilter
%   Img
%   MINarea
%   Power
%   tempImg
% max2
%   inputMAX
%   matrixMAX
% min2
%   inputMIN
%   matrixMIN
% sum2
%   inputSUM
%   matrixSUM
%--------------------------------------------------------------------------


%---------HISTORY----------------------------------------------------------
% Created by Darvin Yi.                                          2012-08-07
% Modified by Darvin Yi.                                         2012-08-07
%--------------------------------------------------------------------------


%---------INDEX------------------------------------------------------------
% DESCRIPTION
% SETTING VARIABLES
% FINDING INITIAL CELL INFORMATION
% ANALYZING ALL OTHER FRAMES TO CONNECT CELLS
% FUNCTION: MovingAverageThresh
% GLOSSERY
% HISTORY
% INDEX
%--------------------------------------------------------------------------
%end

