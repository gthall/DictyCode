%this is a function to calculate and (if you want) plot the power spectra 
%over time from a wavelet and
%return the average power spectra for all of the signals over the well.
%The function takes as input a wellData struct 
function [powerAvgMaxLocations, powerAvgMaxUncertainty, totPower,...
    totSTD, totStErr] =...
    WellPowerAverage(wellData, timeStart,timeEnd,perStart, perEnd,...
    smoothTime, movieBool, fps, movieDir, movieName)

%parse inputs
if nargin <7
    movieBool = false;
end 

if movieBool
    if nargin<10
        movieName = 'PowerSpectraDynamics';
        if nargin <9
            movieDir = uigetdir;
            if nargin <8
                fps = 7;
            end
        end
    end
end


%define what scales of the power spectra you want
period = wellData.period;
[~, perStartIndex] = min (abs(period - perStart));
[~, perEndIndex] = min(abs(period - perEnd));
%find where you want to be on the time axis
[~, timeStartIndex] = min(abs(wellData.times-timeStart));
[~, timeEndIndex] = min(abs(wellData.times - timeEnd));

%create a videowriter object if you are making a movie
if movieBool
    writerObj = VideoWriter ([movieDir filesep movieName]);
    writerObj.FrameRate = fps;
    open(writerObj);
    figure;
end

%declare array to keep track of where local maxima are in the well-averaged
%power spectra at each time point
powerAvgMaxLocations = cell (1, timeEndIndex-timeStartIndex-smoothTime);
powerAvgMaxUncertainty = cell (1, timeEndIndex-timeStartIndex-smoothTime);
%declare array to keep track of the well averaged power spectra itself
totPower = zeros(perEndIndex-perStartIndex+1,...
    timeEndIndex-timeStartIndex-smoothTime);
totSTD = zeros(size(totPower));
totStErr =zeros(size(totPower));

%loop through time pts that you wants
for i = timeStartIndex:timeEndIndex-smoothTime
    
    %for each time pt get the local maxima for that time pt and the 
    %well averaged power spectra for that time pt
    [powerAvgMaxLocations{i-timeStartIndex+1}, ...
        powerAvgMaxUncertainty{i-timeStartIndex+1},...
        totPower(:,i-timeStartIndex+1), ...
        totSTD(:, i-timeStartIndex+1), totStErr(:,i-timeStartIndex+1), ...
        figureHandle] = ...
        PowerComparison (wellData.waveData, wellData.times, ...
        wellData.period, i, i+smoothTime, perStartIndex, perEndIndex);
    
    if movieBool
        figure(figureHandle);
        set(gca, 'Units', 'Normalized', 'OuterPosition', [ 0, 0, 1, 1]);
        
        coords = figureHandle.Position;
        rect = [0,0,coords(3), coords(4)];
        
        movieFrame = getframe(figureHandle, rect);
        writeVideo (writerObj, movieFrame);
    end

    
end

figure;
imagesc (wellData.times (timeStartIndex:timeEndIndex), ...
    log2(period (perStartIndex:perEndIndex)), totPower);
colormap jet;
colorbar;
Yticks = 2.^(fix(log2(min(period(perStartIndex:perEndIndex)))):....
    fix(log2(max(period(perStartIndex:perEndIndex)))));
set(gca,'YLim',log2([min(period(perStartIndex:perEndIndex)),...
    max(period(perStartIndex:perEndIndex))]),'YDir','reverse', ...
    'YTick',log2(Yticks(:)), 'YTickLabel',Yticks)

hold on;
for i = 1:length (powerAvgMaxLocations)
   for j = 1: length(powerAvgMaxLocations{i})
       if powerAvgMaxLocations{i}(j)>4
           errorbar (wellData.times(i), log2(powerAvgMaxLocations{i}(j)),...
               abs(log2(abs (powerAvgMaxUncertainty{i}(j,1) - ...
               powerAvgMaxLocations{i}(j)))), ...
               abs(log2(abs (powerAvgMaxUncertainty{i}(j,2) - ...
               powerAvgMaxLocations{i}(j)))), 'k');
       end
   end 
end


if movieBool
    close (writerObj);
end
end