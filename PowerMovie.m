%this is a script to plot the power spectra over time from a wavelet and
%return the average power spectra for all of the signals over the well.
%The function takes as input a wellData struct 
function [powerAvgMaxLocations, totPower] = PowerMovie (wellData, timeStart,...
    timeEnd,perStart, perEnd, movieBool, fps, movieDir, movieName)

if nargin<8
    movieName = 'PowerSpectraDynamics';
    if nargin <7
        movieDir = uigetdir;
        if nargin <6
            fps = 5;
        end
    end
end

smoothTime = 1;%amount of time over which to smooth power spectra 

%define what scales of the power spectra you want

period = wellData.period;
[~, perStartIndex] = min (abs(period - perStart));
[~, perEndIndex] = min(abs(period - perEnd));



%create a videowriter object
writerObj = VideoWriter ([movieDir filesep movieName]);
writerObj.FrameRate = fps;
open(writerObj);

figure;
powerAvgMaxLocations = cell (1, timeEnd-timeStart-smoothTime);
totPower = zeros(perEndIndex-perStartIndex+1,...
    timeEnd-timeStart-smoothTime);

for i = timeStart:timeEnd-smoothTime
    
    [powerAvgMaxLocations{i-timeStart+1}, ...
        totPower(:,i-timeStart+1), figureHandle] = ...
        PowerComparison (wellData.waveData, wellData.times, ...
        wellData.period, i, i+smoothTime, perStart, perEnd);
    figure(figureHandle);
    set(gca, 'Units', 'Normalized', 'OuterPosition', [ 0, 0, 1, 1]);

    coords = figureHandle.Position;
    rect = [0,0,coords(3), coords(4)];
    
    movieFrame = getframe(figureHandle, rect);
    writeVideo (writerObj, movieFrame);

    
end

close (writerObj);

end