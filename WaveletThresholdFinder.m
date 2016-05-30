function [threshFinal] = WaveletThresholdFinder(currIm, figureBool)

if nargin<2
    figureBool = false;
end 

%keep the original image for later use
powerCrop = currIm;

counter = 0;laplaceFilter = -fspecial('laplacian');

%numLevels = 4;
maxPeaks = 4;

%note-7-15-15. The basic idea is to build a (modestly) robust blob detector
%to work on the power spectra. That way, we can find peaks in the power
%spectra in a region we define and store them for later

nPeaks = maxPeaks+1;%this is the max number of peaks that one could find...
%in a given image



while nPeaks>maxPeaks
    counter = counter+1;%keep track of what level of the pyramid we are at
    %go down one level of the pyramid
    currIm = impyramid(currIm, 'reduce');
    %apply laplacian as an edge detecto
    spotIm = imfilter(currIm, laplaceFilter, 'replicate');
    %zero out the number of particles currently found
    nPeaks = 0;
    %extract size of current power spectrum image in the pyramid
    [height width] = size(spotIm);
    %loop through pyramid image
    for h = 2:height -1
        for w = 1:width
            if spotIm(h,w) >= .5*max(max(spotIm));
                nPeaks = nPeaks+1;
            end
        end
    end
end


%for debug,show image
if figureBool
    figure('Units', 'normalized', 'Position', [0 0 .3 .4]);
    imagesc(currIm);colormap jet;colorbar;


%look through the spots to find the brightest one
%for debug plot the bottom level of the pyramid
figure('Units', 'normalized', 'Position', [0 .5 .3 .4]);
imagesc (spotIm); colormap jet ; colorbar;

end
[height, width] = size(spotIm);

for h = 1: height
    for w = 1:width
        if spotIm(h,w) ==max(max(spotIm))
            xIndex = h;
            yIndex = w;
        elseif spotIm(h,w) == max(max(spotIm(spotIm~=max(max(spotIm)))))
            xIndex2 = h;yIndex2 = w;
        end
    end
end


%map back to the original image
[height, width] = size(powerCrop);
origX = min([xIndex*(2^counter), height]);
origY = min([yIndex *(2^counter), width]);
topLeftX = origX - ((2^(counter -1))-1);
topLeftY = origY - ((2^(counter - 1)) -1);

origX2 = min([xIndex2*(2^counter), height]);
origY2 = min([yIndex2 *(2^counter), width]);
topLeftX2 = origX2 - ((2^(counter -1))-1);
topLeftY2 = origY2 - ((2^(counter - 1)) -1);



%make sure that you are not going to have negative values
if topLeftX <1
    topLeftX = 1;
end
if topLeftY <1
    topLeftY = 1;
end

if topLeftX2<1
   topLeftX2 = 1; 
end

if topLeftY2 <1
    topLeftY2 = 1;
end


%define a region of the power spectra where there is a likely peak
regionOfInterest = powerCrop(topLeftX:origX, topLeftY:origY);
regionOfInterest2 = powerCrop(topLeftX2:origX2, topLeftY2:origY2);

%try 2 different thresholds and see which one is better
localThresh = mean2(regionOfInterest);
globalThresh = mean2(powerCrop);
%turn these into more usable quantities
bigThresh = max(localThresh, globalThresh);
smallThresh = min(localThresh, globalThresh);


localThresh2 = mean2(regionOfInterest2);
globalThresh2 = mean2(powerCrop);
bigThresh2 = max(localThresh2, globalThresh2);
smallThresh2 = min(localThresh2, globalThresh2);

%see how these 2 thresholds do to the region ofinterest/total image
%histogram

[powerHistogram powerBins]= imhist(powerCrop, 100);
[~, smallThreshBinIndex] = min(abs(powerBins-smallThresh));
[~, bigThreshBinIndex] = min(abs(powerBins- bigThresh));
[~, smallThreshBinIndex2] = min(abs(powerBins - smallThresh2));
[~, bigThreshBinIndex2] = min(abs(powerBins - bigThresh2));
powerHistogram1 = powerHistogram(smallThreshBinIndex:bigThreshBinIndex);
Bins = powerBins(smallThreshBinIndex:bigThreshBinIndex);
powerHistogram2 = powerHistogram(smallThreshBinIndex2:bigThreshBinIndex2);
Bins2 = powerBins(smallThreshBinIndex2:bigThreshBinIndex2);

%calculate your final threshold edges
[~, threshMin] = min(powerHistogram1);
threshMin = Bins(threshMin);
testThresh1 = smallThresh+threshMin;

[~, threshMin2] = min(powerHistogram2);
threshMin2 = Bins2(threshMin2);
testThresh2 = smallThresh2+ threshMin2;

thresh1 = min ([testThresh1, testThresh2]);
thresh2 = max([testThresh1, testThresh2]);
%catch any errant thresholds greater than one
if thresh2>1
    if thresh1 <1
        thresh2 = thresh1;
    else
        thresh2 = 1;
        thresh1 = 1;
    end
end
[~, thresh1Index] = min(abs(powerBins-thresh1));
[~, thresh2Index] = min(abs(powerBins-thresh2));


%define a histogram of where you are interested in looking
pixelsOfInterest = powerHistogram(thresh1Index:thresh2Index);
binsOfInterest = powerBins(thresh1Index:thresh2Index);
%plot for debug
if figureBool
    figure('Units', 'normalized', 'Position', [.3 0 .3 .4]);
    subplot(3,1,1);bar(Bins, powerHistogram1);
    subplot(3,1,2);bar(Bins2, powerHistogram2);
    subplot(3,1,3);bar (binsOfInterest, pixelsOfInterest);
end

%find the local minima of the histogram
try
    [minValues, minIndex] = findpeaks (-pixelsOfInterest);
    minValues = -minValues;
    if figureBool
        hold on;
        plot (binsOfInterest(minIndex), minValues, '*');
    end
catch
   minIndex = max(thresh1Index, thresh2Index);
   minValues = pixelsOfInterest (minIndex-thresh1Index +1);
   if figureBool
       hold on
       plot (binsOfInterest (minIndex - thresh1Index+1), minValues, '+')
   end
end


%find sum to end for each local minima
sumOfTails = zeros (1, length(minIndex));%initialize array of sums to end
sumOfMins = zeros(1, length(minIndex));%find integrals between local minima
for i = 1: length (minIndex)
   sumOfTails(i) =sum(powerHistogram(minIndex(i)-1+thresh1Index:...
       length(powerHistogram)));
   if i ~= length(minIndex)
       sumOfMins(i) = sum(powerHistogram(minIndex(i)-1+thresh1Index:...
           minIndex(i+1) - 1+ thresh1Index));
   else
       sumOfMins(i) = sum(powerHistogram(minIndex(i)-1+thresh1Index:...
           length(powerHistogram)));
   end
end

%find out the minima with the biggest ratio and make that he final
%threshold

tailRatios = sumOfMins(1:length(sumOfMins)-1)./...
    sumOfTails(1:length(sumOfTails)-1);

[maxRatio, maxRatioIndex] = max(tailRatios);

%determine final threshold
if isempty(maxRatio)
    threshFinal = max(thresh1, thresh2);
    
%if there are both (1) very few pixels in the region we are looking at (aka
%the threshold value is high) and (2)there are other local minima that are
%competative the algorithm tends to choose the highest ones due to a sort
%of edge effect - there are basically so few tails that the ratio is highly
%inflated. This is a catch for that kind of situation, where we can find
%more suitable peaks in certain situations
elseif sumOfTails(maxRatioIndex)<50 & ...
        max(tailRatios(tailRatios~=max(tailRatios)))>=.75*maxRatio
    
    %determine which hump is really bigger/if its bigger by enough to make
    %a difference at all(these numbers are all basically arbitrary btw).
    if sumOfMins(tailRatios == ...
            max(tailRatios(tailRatios~=max(tailRatios))))>= ...
            1.5 *sumOfMins(tailRatios ==max(tailRatios))
        
        [~, maxRatioIndex] = max (tailRatios(tailRatios ...
            ~=(max(tailRatios))));
    end 
    
    threshFinal = powerBins ( minIndex (maxRatioIndex)+ thresh1Index);
    % catch any bad messes
    if threshFinal>1
        threshFinal = max(thresh1, thresh2);      
    end
    
    
%catch cases where the local min is basically a fluctuation- this
%usually results in a low threshold and lots of noisy peaks. I'm calling
%significant a 10% drop off on both sides
elseif (pixelsOfInterest(minIndex(maxRatioIndex)+1)-...
        pixelsOfInterest(minIndex(maxRatioIndex)))<...
        .1*pixelsOfInterest(minIndex(maxRatioIndex)+1)&&...
        (pixelsOfInterest(minIndex(maxRatioIndex)-1)-...
        pixelsOfInterest(minIndex(maxRatioIndex))<...
        .1*pixelsOfInterest(minIndex(maxRatioIndex)-1))
    %if the second lowest valley is reasonably close to the first lowest
    %valley and doesnt have the same kinds of problems then use that one
    if max(tailRatios(tailRatios~=max(tailRatios)))>=.75 * maxRatio
        %find the second biggest valley
        [~, testMaxIndex] = max (tailRatios(tailRatios ...
            ~=(max(tailRatios))));
        %if it doesnt have the same problem then keep it as the new
        %reference, otherwise do nothing
        if ~((pixelsOfInterest(minIndex(testMaxIndex)+1)-...
                pixelsOfInterest(minIndex(testMaxIndex)))<...
                .1*pixelsOfInterest(minIndex(testMaxIndex)+1)&&...
                (pixelsOfInterest(minIndex(testMaxIndex)-1)-...
                pixelsOfInterest(minIndex(testMaxIndex))<...
                .1*pixelsOfInterest(minIndex(testMaxIndex)-1)))
            
            maxRatioIndex = testMaxIndex;
        end
        
    end
    %define threshold
    threshFinal = powerBins ( minIndex (maxRatioIndex)+ thresh1Index);
    
    % catch any bad messes
    if threshFinal>1
        threshFinal = max(thresh1, thresh2);
    end
else
    
    %throw in a catch here - if none of the ratios are large(above .2) then
    %just discard and use the high end threshold.
    
    if maxRatio <.2
        %set the index for the threshold to be the high end threshold
        maxRatioIndex = length(sumOfTails);
    end
    
    %map back this max index to the full range of thresholds and then
    %finally threshold the thing
    
    threshFinal = powerBins ( minIndex (maxRatioIndex)+ thresh1Index);
    % catch any bad messes
    if threshFinal>1
        threshFinal = max(thresh1, thresh2);
    end
end



end 