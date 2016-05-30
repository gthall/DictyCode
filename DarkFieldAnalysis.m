function [signalTimes, varargout] = DarkFieldAnalysis ...
    (imFol, metadata, numPlates, referenceFrameNum, ...
    significanceLevel, movieBool, timeDelay)



%this is a total cop out for now (7-10-15)  - mask defaults to the first
% frame unless told otherwise

if nargin <6
    movieBool = false;
    if nargin<5
        significanceLevel = .95;
        if nargin < 4
            referenceFrameNum = 1;
            if nargin < 3
               error('Not Enough Input Arguments');
            end
        end
    end
end

nOutputs = nargout;

%variables
%--------------------------------------------------------------------------
% %ok to play with
imName = 'Image_*.tiff';
startFrame = 1;%180;%frame of the image to start analysis
endFrame = 1000;%frame of the image to end analysis
averagingBinSize = 4;%number of frames to average over to reduce noise
%conversion factor between pixels and cm. Highly dependent on optical...
%setup always check!!
pixToCm = 3.5/418;
animationFPS = 15;%fps for angular animation

%less ok to play with - exercise caution
gaussSigma = 15;%std for gaussian filter
regionSize = 3;% size of sampling regions per frame - from sawai(2005)
regionInterval = 20;%distance between sampling regions - from sawai(2005)
minArea = 10000; %minimum size for thresholding particles
tau = 6;%how many frames ahead to do comparisons - should really be even
%note 9-16-15 this tau is taken by looking at the zeros of the
%autocorrelation function to find at what delay the data is generally
%uncorrelated w itself
circleRatio = .5;%how much of the circular mask to compute over. This 
%allows us to chop off any weird edge effects.

%define where to begin and end wavelet analysis of signal - we are
%interested in a subset of the time imaging (around ~3to~9 hours) where
%there are interesting oscillations. These variables define the start and
%end frame for wavelet analysis. Can change depending on temporal
%resolution of optical setup. Must lie within total analysis parameters
%startFrame and endFrame
signalStart = 1;
signalEnd = 999;
%--------------------------------------------------------------------------

%set up waitbar
%--------------------------------------------------------------------------
w = waitbar(0, 'Please wait...');
message = 'Preprocessing Images';
waitbar((1/(endFrame-tau-startFrame)), w, message);
%--------------------------------------------------------------------------


%set up directories for reading in files
%--------------------------------------------------------------------------
%user inputted image directory
imDir = dir ([imFol filesep imName]);
%--------------------------------------------------------------------------

%make sure everything works -- set up easy catches so that you dont waste
%your time
%--------------------------------------------------------------------------
%make sure that you are able to analyze the signals
if (signalStart < startFrame)|| (signalEnd >endFrame)
    error('Bounds of Signal Must be Within Start and End Frames')
    
end

if length (imDir) < endFrame
    endFrame = length(imDir)-1;
end 

%--------------------------------------------------------------------------


%make an angular plot 
%--------------------------------------------------------------------------
%loop through frames
 
firstFrame = im2double(imread([imFol filesep imDir(startFrame).name]));

%get reference frame for mask
referenceFrame = im2double(imread([imFol filesep ...
    imDir(referenceFrameNum).name]));
%get initial time

stringFinder = zeros (1, numPlates);
%Find the data in metadata for the time stamp of the first frame
for m = 1: numPlates
    stringFinder  (m) = strncmp (imDir(startFrame).name,...
        metadata.rowheaders{m}, length(imDir(startFrame).name));
end
timeIndex = find(stringFinder); timeIndex = m;

firstFrameTime = datenum(datetime (metadata.data(timeIndex, 1),...
metadata.data(timeIndex,2), metadata.data(timeIndex,3),...
metadata.data(timeIndex, 4), metadata.data(timeIndex,5),...
metadata.data(timeIndex,6)));


[tempx, tempy] = size(firstFrame);
%get mask for first Frame
[firstFrameBW, xCenter, yCenter, maskRadius]=WellMask(referenceFrame, ...
    minArea);
firstFrame(~firstFrameBW) = 0;
%initialize storage matrix for raw images
imageHolder = zeros (tempx, tempy, tau+(2*averagingBinSize)+1);
imageHolder (:,:,1) = firstFrame;

%initialize processed storage matrices

%first, initialize some size variables to make your future debugging
%easier
%how long it takes to move across the chosen mask in steps of 3
a = length(round(xCenter - circleRatio*maskRadius) : 3:...
    round(xCenter+circleRatio*maskRadius));
%number of total timepts
b =floor (endFrame - startFrame - 2*averagingBinSize - tau/...
    averagingBinSize);
%initialize further storage matrices
%differences of frames
imageDifference  = zeros (tempx, tempy, tau+(2*averagingBinSize)-1);
%processed differences - past and future, separated by tau
processedImage = zeros (tempx, tempy, 2);


%storage matrix for angular representation of waves
%initialize 3-d array to store calculations - first 2 dimensions are
%spatial and correspond to the image, 3rd dimension is temporal and
%corresponds to the box intensities over time

theta = zeros (a, a, b);
%rawSignal = zeros (16,16,b);
imageTimes = zeros (a,a,b);
%initialize a storage matrix to keep track of times
signalTimes = zeros (1, signalEnd-signalStart-tau);%times for signal


for i = startFrame+1:endFrame - tau
    
    %first lets do the waitbar
    message = ['Analyzing Frame ' num2str(i - startFrame) ' of ' ...
        num2str(endFrame - tau - startFrame) ':'];
    waitbar(((i - startFrame)/(2*(endFrame-tau-startFrame))), w, message);
    
    %read in frames into raw image holder always
    %replace previous frames
    for j = size(imageHolder,3): -1: 2
        imageHolder(:,:,j) = imageHolder (:,:,j-1);
    end
    
    %read in new frame and time
    temp = im2double(imread([imFol filesep imDir(i).name]));
    stringFinder = zeros (1, numPlates);
    %Find the data in metadata
    for m = 1: numPlates
        stringFinder  (m) = strncmp (imDir(i).name,...
            metadata.rowheaders{numPlates*(i-1)+m},...
            length(imDir(i).name));
    end
    %extract the time from the metadata
    timeIndex = find(stringFinder); timeIndex = numPlates*(i-1)+m;
    imageTimes(i-startFrame)=datenum(datetime(metadata.data(timeIndex,1)...
        , metadata.data(timeIndex,2), metadata.data(timeIndex,3),...
        metadata.data(timeIndex, 4), metadata.data(timeIndex,5),...
        metadata.data(timeIndex,6))) - firstFrameTime;
    
    %note the time for the signal if need be
    if (i>=signalStart)&&(i<= signalEnd)
        signalTimes(i-signalStart+1)= imageTimes(i-startFrame);
    end
    
    
    %mask image
    temp(~firstFrameBW) = 0;
    %place into array
    imageHolder(:,:,1) = temp;
    
%     fill signal matrix for wavelet analysis
%     
%     figure out if you should fill the signal matrix for wavelet...
%         analysis or not
% if (i>=signalStart)&&(i<= signalEnd)
%     
%     %define temporary matrix to make your indexing easier - note...
%     %7-2-15 I am unsure about the efficiency of this method-once...
%     %you get everything else working come back and think about ...
%     %whether there is a more efficient implementation
%     
%     temp= imageHolder(round(xCenter-maskRadius*circleRatio): ...
%         round(xCenter+maskRadius*circleRatio),...
%         round(yCenter-maskRadius*circleRatio):...
%         round(yCenter+maskRadius*circleRatio), 1);
%     
% %     %loop through active part of image and fill signal storage array
% %     for j = 1:size(rawSignal,1)
% %         for k = 1:size (rawSignal,2)
% %             %define 3 x3 box to average over
% %             currBox=temp((j-1)*regionInterval+1:(j-1)*regionInterval...
% %                 + regionSize, (k-1)*regionInterval+1:...
% %                 (k-1)*regionInterval+regionSize, 1);
% %             rawSignal (j, k, i-signalStart+1) = mean2(currBox);
% %         end
% %     end
% %     
% end

    
    %fill array of image differences every  iterations
    for j = size(imageHolder,3)-1 :-1: 2
        %take difference to remove background
        imageDifference (:,:,j) = imageDifference (:,:,j-1);
    end
    imageDifference (:,:,1) = imageHolder( :,:,2) - imageHolder(:,:,1);
    
    %process array of images
    %take means of images
    %more recent
    processedImage (:,:,1) = ...
        mean (imageDifference (:,:,1: averagingBinSize),3);
    %more past
    processedImage(:,:,2) = ...
        mean (imageDifference (:,:,size(imageDifference,3)...
        -averagingBinSize:size(imageDifference,3)),3);
    %smooth with a gaussian filter
    gaussFilter = fspecial ('gaussian', [21 21], gaussSigma);
    for j = 1: 2
        processedImage(:,:,j) = imfilter (processedImage(:,:,j), ...
            gaussFilter, 'replicate');
    end
    %now we are going to move through the mask in 3 by 3 boxes
    %computing the average of each box
    
    
    %define mean intensity of total frame for reference
    temp = processedImage(:,:,1);
    meanIntensity = mean(temp(~(~firstFrameBW)));
    temp = processedImage(:,:,2);
    meanIntensityPast = mean(temp(~(~firstFrameBW)));
    
    
    %set up some coordinates so you can keep track of the map between
    %the big image and the 9x smaller wave image
    xCoords =  round(xCenter - circleRatio*maskRadius) : 3:...
        round(xCenter+circleRatio*maskRadius);
    yCoords = round(yCenter - circleRatio*maskRadius):3:...
        round(yCenter+circleRatio*maskRadius);
    
    %make the area a box and then loop through it
    for j = 1: length(xCoords)-3
        for k = 1: length(yCoords)-3
            %define current box spatially and temporally
            currBox = processedImage (xCoords(j):xCoords(j+3), ...
                yCoords(k):yCoords(k+3), 1);
            boxIntensity = mean2(currBox);%find intensity of box
            boxPast = processedImage(xCoords(j):xCoords(j+3),...
                yCoords(k): yCoords(k+3), 2);
            pastIntensity = mean2(boxPast);
            %define angular variable theta via gray et al nature 1997
            theta(j,k,i- startFrame) = arctangent ((boxIntensity - ...
                meanIntensity),(pastIntensity - meanIntensityPast));
        end
    end
end

%center data
%rawSignal = rawSignal - mean(rawSignal,3);


%now that you have your theta measurement figure out whether or not you are
%filling the signal matrix via angular measurements or not

[height, width, ~] = size (theta);
vertStep = floor (height/5);horzStep = floor(width/5);
signal = zeros (vertStep-1, horzStep-1, size(theta, 3));
for i = 1: vertStep-1
    for j = 1: horzStep-1
        %put the signal in terms of a sine wave instead of the phase
        signal (i,j,:) = sin(squeeze(theta (i*5,j*5, :)));
    end
end

%--------------------------------------------------------------------------
%perform wavelet analysis
%--------------------------------------------------------------------------

%convert your times to minutes from days
signalTimes = signalTimes*24*60;
signalTimes = signalTimes (1: size(theta,3));
%move times over to startpoint
signalTimes = signalTimes+ timeDelay;

[waveData, period, scales, coi] = ...
    WaveletMasterAnalysis (signal, signalTimes, ...
    significanceLevel);
%--------------------------------------------------------------------------
%save relevant variables into a matlab file and make movies
%--------------------------------------------------------------------------

if movieBool
    animationMovieName = strcat('Animation Tau = ',num2str(tau),'Avg =',...
        num2str(averagingBinSize), 'sigma = ', num2str(gaussSigma), ...
        'Frame', num2str(startFrame), 'to', num2str(endFrame));
    try
        MovieFunction([], imFol, theta, animationMovieName,...
            animationFPS, false, [], signalTimes);
    catch
        
    end
end

%deal with output
%if you are requesting both angular information and wavelet information
    if nOutputs >1, varargout{1} = waveData;
        if nOutputs >2, varargout{2} = period;
            if nOutputs>3, varargout{3} = scales;
                if nOutputs>4 varargout{4} = coi;
                    if nOutputs >5, varargout{5} = theta;
                    end
                end
            end
        end
    end
%     
%     %only wavelet no angular
%     elseif waveletBool &&~ angularBool
%         if nOutputs >2, varargout{1} = waveData;
%             if nOutputs>3 , varargout{2} = period;
%                 if nOutputs>4, varargout{3} = scales;
%                     if nOutputs>5, varargout{4} = coi;
%                         
%                     end
%                 end
%             end
%         end
%         
%         %only angular not wavelets
%         elseif angularBool &&~waveletBool
%             if nOutputs>2 , varargout{1} = theta;
%             end


%close the waitbar
close(w)
end