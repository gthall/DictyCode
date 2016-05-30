%this function analyzes the mean power spectrum from 18 wells - it returns
%the mean power spectra over time as well as a standard error and standard
%deviation from between wells
function [peakLocations, meanExperimentPower, meanExperimentSTD, ...
    meanExperimentStErr] = MeanPowerAnalysis ...
    (totPower,totSTD, totStErr,  powerAvgMaxLocations, ...
    powerAvgMaxUncertainty, period, times,perStart, ...
    perEnd, timeStart, figureDir, saveDir, movieBool)

if nargin < 13
    movieBool = false;
    if nargin<12
        saveDir = [];
        if nargin<11
           saveBool = false; 
        end
    end
end


%propagate error to get best estimate of mean and standard deviation
%accross all wells
meanExperimentPower = sum (totPower./(totSTD.^2), 3)./sum(1./totSTD.^2,3);
meanExperimentSTD = 1./(sum (1./totSTD.^2,3));
meanExperimentStErr = meanExperimentSTD./sqrt(size(totPower,3));

if movieBool
    powerName = 'MeanPowerDynamicsPks';
    fps  = 15;
    %first lets visualize and save a movie to the disk
    
    
    %initialize movie maker
    writerObj = VideoWriter ([saveDir filesep powerName]);
    writerObj.FrameRate = fps;
    open(writerObj);
    figureHandle =figure;
end

%find your indices for time and period
[~, perStartIndex] = min (abs(period - perStart));
perStartIndex = perStartIndex-1;
[~, perEndIndex] = min(abs(period - perEnd));
[~, timeStartIndex] = min(abs(times-timeStart));

%initialize cells to keep track of (1) the positions of local maxima
%in the power spectra and (2) the uncertainty associated with those
%maxima
peakLocations = cell (1, size (totPower,2));
peaksUncertainty = cell(1, size (totPower,2));

%loop through time and make a movie
for i =1: size (meanExperimentPower, 2)
    
    %if youre making a movie then plot the std at a given time pt and
    %then
    if movieBool
        ErrorBars (period (perStartIndex:perEndIndex)', ...
            meanExperimentPower (:,i), meanExperimentStErr (:,i));
        hold on;
        plot (period (perStartIndex:perEndIndex)', ...
            meanExperimentPower (:,i));
    end
    %find the local maxima at that time pt
    [pks, locs] = findpeaks (meanExperimentPower(:,i));
    [mins, minlocs]  = findpeaks (-meanExperimentPower(:,i));
    %find the uncertainty on your peaks
    referencePeaks = pks - meanExperimentStErr (locs,i);
    referencePower = meanExperimentPower(:,i)+meanExperimentStErr(:,i);
    
    for j =1: length (pks)
        %loop through each peak and find where the st err is larger
        %than the peak
        startMinima = minlocs(minlocs <locs(j));
        if ~ isempty (startMinima)
            searchStart = max(startMinima);
        else
            searchStart = 1;
        end
        endMinima = minlocs (minlocs > locs (j));
        if ~ isempty (endMinima)
            searchEnd = min(endMinima);
        else
            searchEnd = size(totPower, 1);
        end
        
        tempUncertainty =find(referencePower(searchStart:searchEnd)>...
            referencePeaks(j)) + searchStart;
        peaksUncertainty{i}(j,1) = period(min(tempUncertainty)+perStartIndex);
        peaksUncertainty{i}(j,2) = period(max(tempUncertainty)+perStartIndex);
        
    end
    
    if movieBool
        plot (period (perStartIndex+locs - 1), pks, '*')
    end
    
    peakLocations{i} = period(perStartIndex+locs-1);
    if movieBool
        axis ([period(perStartIndex) , period(perEndIndex), ...
            0,max(max(meanExperimentPower))])
        xlabel ('Period(min)')
        ylabel('Power (AU)')
        title (num2str (['Mean Power Spectra at minute ' ...
            num2str(times (i+timeStart)) ' Post Starvation']));
        set (gca, 'FontSize', 16)
        set (gca , 'Units', 'Normalized', 'OuterPosition', [0,0,1,1]);
        coords = figureHandle.Position;
        rect = [0,0,coords(3), coords(4)];
        
        movieFrame = getframe(figureHandle, rect);
        writeVideo (writerObj, movieFrame);
        cla
    end
end
if movieBool
    close (writerObj);
    
end

%trace the peaks in frequency through time
figure;
for i = 1: length (peakLocations)-11
    for j  =1: length(peakLocations{i})
        if peakLocations{i}(j)>4
            ErrorBars (times(timeStartIndex+i), peakLocations{i}(j), ...
                abs (peakLocations{i}(j) - peaksUncertainty{i}(j,1)), ...
                abs (peakLocations{i}(j) - peaksUncertainty{i}(j,2)), ...
                [0 1 1]);
            hold on
        end
    end
end


xlabel('Time (minutes)');ylabel('Period(minutes)');
axis ([150 420 4 16])
title ('Trace Of Peaks In Power Spectra Over Time')
set (gca, 'FontSize', 16);
hold on


for i = 1: length (peakLocations)-11
    for j  =1: length(peakLocations{i})
        if peakLocations{i}(j)>4
            plot (times(timeStartIndex+i), peakLocations{i}(j), '.c')
            hold on
        end
    end
end


figure;
for i = 1: length (peakLocations)-1
    for j  =1: length(peakLocations{i})
        if peakLocations{i}(j)>4
            plot (times(timeStartIndex+i), peakLocations{i}(j), '.k')
            hold on
        end
    end
end
xlabel('Time (minutes)');ylabel('Period(minutes)');
axis ([150 420 4 16])
title ('Trace Of Peaks In Power Spectra Over Time')
set (gca, 'FontSize', 16);
hold on



meanExperimentPower = meanExperimentPower(1:perEndIndex-perStartIndex,...
    :);
meanExperimentSTD = meanExperimentSTD(1:perEndIndex-perStartIndex,...
    :)
meanExperimentStErr = meanExperimentStErr(1:perEndIndex-perStartIndex,...
    :)

%trace frequency peaks through time on top of total mean heatmap
figure;
imagesc (times (timeStartIndex:length(times)), ...
    log2(period (perStartIndex:perEndIndex)), meanExperimentPower);
colormap jet;
h = colorbar;
ylabel (h, 'Power (AU)');
% Yticks = 2.^(fix(log2(min(period(perStartIndex:perEndIndex)))):....
%     fix(log2(max(period(perStartIndex:perEndIndex)))));
Yticks = 4:2:16;
set(gca,'YLim',log2([min(period(perStartIndex:perEndIndex)),...
    max(period(perStartIndex:perEndIndex))]),'YDir','reverse', ...
    'YTick',log2(Yticks(:)), 'YTickLabel',Yticks)

xlabel ('Time(minutes)')
ylabel ( 'Period (minutes)')
title ('Mean Power Spectra Over 18 Wells')
set (gca, 'FontSize', 16)


figure;
imagesc (times (timeStartIndex:length(times)), ...
    log2(period (perStartIndex:perEndIndex)), meanExperimentPower);
colormap jet;
h = colorbar;
ylabel (h, 'Power (AU)');
% Yticks = 2.^(fix(log2(min(period(perStartIndex:perEndIndex)))):....
%     fix(log2(max(period(perStartIndex:perEndIndex)))));
Yticks = 4:2:16;
set(gca,'YLim',log2([min(period(perStartIndex:perEndIndex)),...
    max(period(perStartIndex:perEndIndex))]),'YDir','reverse', ...
    'YTick',log2(Yticks(:)), 'YTickLabel',Yticks)

hold on;
for i = 1:length (peakLocations)-1
    for j = 1: length(peakLocations{i})
        if peakLocations{i}(j)>4
            errorbar (times(timeStartIndex+ i), log2(peakLocations{i}(j)),...
                abs(log2(peaksUncertainty{i}(j,1)) - ...
                log2(peakLocations{i}(j))), ...
                abs(log2(peaksUncertainty{i}(j,1)) - ...
                log2(peakLocations{i}(j))), 'k');
        end
    end
end

xlabel ('Time(minutes)')
ylabel ( 'Period (minutes)')
title ('Mean Power Spectra Over 18 Wells')
set (gca, 'FontSize', 16)


%plot standard deviation and noise of the mean measurement

%std

figure;
imagesc (times (timeStartIndex:length(times)), ...
    log2(period (perStartIndex:perEndIndex)), meanExperimentSTD);
colormap jet;
h = colorbar;
ylabel (h, 'Standard Deviation of Power (AU)');
%Yticks = 2.^(fix(log2(min(period(perStartIndex:perEndIndex)))):.5:....
%    fix(log2(max(period(perStartIndex:perEndIndex)))));

Yticks = 4:2:16;
set(gca,'YLim',log2([min(period(perStartIndex:perEndIndex)),...
    max(period(perStartIndex:perEndIndex))]),'YDir','reverse', ...
    'YTick',log2(Yticks(:)), 'YTickLabel',Yticks);
xlabel ('Time(minutes)')
ylabel ( 'Period (minutes)')
title ('Standard Deviation in Mean Power Spectra Over 18 Wells')
set (gca, 'FontSize', 16)


%noise
figure;
imagesc (times (timeStartIndex:length(times)), ...
    log2(period (perStartIndex:perEndIndex)), ...
    meanExperimentSTD./meanExperimentPower);
colormap jet;
h = colorbar;
ylabel (h, 'Noise')
%Yticks = 2.^(fix(log2(min(period(perStartIndex:perEndIndex)))):....
%   fix(log2(max(period(perStartIndex:perEndIndex)))));
Yticks = 4:2:16;

set(gca,'YLim',log2([min(period(perStartIndex:perEndIndex)),...
    max(period(perStartIndex:perEndIndex))]),'YDir','reverse', ...
    'YTick',log2(Yticks(:)), 'YTickLabel',Yticks)
xlabel ('Time(minutes)')
ylabel ( 'Period (minutes)')
title ('Noise in Mean Power Spectra Over 18 Wells')
set (gca, 'FontSize', 16)

%plot only the maxima
% figure;
% [~, perMaxIndex] = max (meanExperimentPower, [], 1);
% plot (times (250:800), period(perMaxIndex(250-timeStartIndex:800-timeStartIndex), 'k.'))
%

end