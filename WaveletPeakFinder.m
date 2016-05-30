%this function finds the peaks in a given wavelet power spectra 
function [peaksInfo] = WaveletPeakFinder(waveLevel,areaFilter,...
    signalTimes, sigArray, period, figureBool)

if nargin <6
    figureBool = false;
end 
if figureBool
    close all;
end

tic

currIm = waveLevel.power; 
currIm2 = waveLevel.power./sigArray;

%define where to look for peaks in the power spectra (in minutes)
peakStartTime = 100;
peakStopTime = 550;
peakStartPer = 3.5;
peakStopPer = 15;


%crop the current image
%to crop the current image we first convert the search parameters above to
%indices
[~, peakStartTimeIndex] = min(abs(signalTimes - peakStartTime));
[~, peakStopTimeIndex] = min(abs(signalTimes-peakStopTime));
[~, peakStartPerIndex] = min(abs(period -peakStartPer));
[~, peakStopPerIndex] = min(abs(period-peakStopPer));

if peakStopTimeIndex >= length (signalTimes)
   peakStopTimeIndex = length(signalTimes)-1; 
end

%now we crop the image along those indices
currIm = currIm(peakStartPerIndex:peakStopPerIndex, ...
    peakStartTimeIndex:peakStopTimeIndex);
%normalize 
currIm = IncreaseContrast(currIm);


%do the same thing for the significance image
%crop
currIm2 = currIm2(peakStartPerIndex:peakStopPerIndex, ...
    peakStartTimeIndex:peakStopTimeIndex);
%normalize 
currIm2 = IncreaseContrast(currIm2);

powerCrop = currIm;powerCrop2 = currIm2;%store images for later

threshFinal = WaveletThresholdFinder (currIm, figureBool);
threshFinalSig = WaveletThresholdFinder (currIm2, figureBool);

%find both binary images
binaryPower = im2bw (powerCrop, threshFinal);
binaryPower2 = im2bw(powerCrop2, threshFinalSig);
binaryPowerCombined = binaryPower&binaryPower2;
%plot binary im for debugging
if figureBool
    figure('Units', 'normalized', 'Position', [.3 .5 .3 .4]);
    subplot(2,1,1);imagesc(binaryPower);
    subplot(2,1,2); imagesc(powerCrop);colormap jet;colorbar;
end

%discard small peaks(as a noise filtration system)
binaryPowerCombined = bwareaopen(binaryPowerCombined, areaFilter);
%extract information about the peaks
peaksInfo = regionprops(binaryPowerCombined,'Centroid', 'Area', 'Extrema');

%put all of the peak centroids into one matrix - first columns is the
%equivalent of the time dimension while second column is the equivalent of
%the frequency dimension
deletionIndex = [];
if figureBool
    peakCenters = cat(1, peaksInfo.Centroid);
end
for i =1:length(peaksInfo)

    %convert centroids/extrema to lie in minutes in time/period space
    
    %normalize to the broader power spectra from the smaller search image
    peaksInfo(i).Centroid(1) = peaksInfo(i).Centroid(1)+...
        peakStartTimeIndex-1;
    peaksInfo(i).Extrema(:,1) = peaksInfo(i).Extrema(:,1)+...
        peakStartTimeIndex-1;
    try
        peaksInfo(i).Centroid(1) = signalTimes(...
            round(peaksInfo(i).Centroid(1)));
    catch ME
        switch ME.identifier
            case 'MATLAB:badsubscript'
                if round(peaksInfo(i).Centroid(1))>length(signalTimes)
                    peaksInfo(i).centroid(1) = ...
                        signalTimes(length(signalTimes));
                end
            otherwise
                rethrow (ME);
        end
    end
    peaksInfo(i).Extrema(:,1) = signalTimes(...
        round(peaksInfo(i).Extrema(:,1)));
    
    
    peaksInfo(i).Centroid(2) = peaksInfo(i).Centroid(2)+...
        peakStartPerIndex-1;
    peaksInfo(i).Extrema(:,2) = peaksInfo(i).Extrema(:,2)+...
        peakStartPerIndex-1; 
    peaksInfo(i).Centroid(2) = period(...
        round(peaksInfo(i).Centroid(2)));
     peaksInfo(i).Extrema(:,2) = period(...
        round(peaksInfo(i).Extrema(:,2)));
    
    
    %detect if the peak spans less than one full period
    if max (peaksInfo(i).Extrema(:,1)) - min(peaksInfo(i).Extrema(:,1))<...
            peaksInfo(i).Centroid(2)
        deletionIndex = horzcat (deletionIndex, i);
    end
    
end
% %delete the peaks that you kept track of 
% peaksInfo(deletionIndex) = [];
% 
% if figureBool
%     peakCenters(deletionIndex, :) = [];
% end

if figureBool && ~isempty(peakCenters)
    hold on;
    plot (round(peakCenters(:,1)),...
        round(peakCenters(:,2)), '*', 'LineWidth', 3);
    hold off;
end


% 
% 
% %renormalize to the broader image from the smaller search image



if figureBool
    if ~isempty(peakCenters)
        peakCenters(:,1) = peakCenters(:,1) + peakStartTimeIndex -1;
        peakCenters(:,2) = peakCenters(:,2) + peakStartPerIndex -1;
    end
    figure('Units', 'normalized', 'Position', [.6 0 .3 .4]);
    imagesc (waveLevel.power);colormap jet;colorbar;
    if ~isempty(peakCenters)
        hold on;
        plot(peakCenters(:,1), peakCenters(:,2), '*', 'LineWidth', 3)
        hold off;
    end
    
    figure('Units', 'normalized', 'Position', [.6 .5 .3 .4])
    subplot (3,1,1);imagesc (binaryPower);
    subplot (3,1,2);imagesc(binaryPower2);
    subplot(3,1,3); imagesc (binaryPowerCombined);
end


timer = toc;
% disp(toc)
% disp(threshFinal)
% disp (cat(1, peaksInfo.Centroid))

 end 