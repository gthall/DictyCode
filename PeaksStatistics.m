function [perMean, perStd, timeMean, timeStd, peaksHist] = ...
    PeaksStatistics (allPeaks, plotBool, figureDir)

if nargin < 3
    saveBool = false;
else
    saveBool = true;
    if nargin <2
        plotBool = true
    end
end

%plot the distributions of peaks
if plotBool
    figure1 = figure;
    plot (allPeaks(:,1), allPeaks(:,2), 'k.');
    xlabel('Time(minutes)');
    ylabel('Period(minutes)');
    hold on;
    plot (mean(allPeaks(:,1)), mean(allPeaks(:,2)), 'g*', 'LineWidth', 3)
    plot (mean(allPeaks(:,1)) * ones(1,40), ...
        linspace (mean(allPeaks(:,2)) - std(allPeaks(:,2)), ...
        mean(allPeaks(:,2)) + std(allPeaks(:,2)), 40), 'b', 'LineWidth', 2)
    plot (linspace(mean(allPeaks(:,1)) - std(allPeaks(:,1)), ...
        mean(allPeaks(:,1))+ std(allPeaks(:,1)), 40), ...
        mean(allPeaks(:,2))*ones(1,40), 'b', 'LineWidth',2)
    hold off;
    if saveBool
       saveas(figure1, [figureDir filesep 'PeaksRaw.png']);
    end
end

% lets see if we can bin the peaks and make a histogram - produce 2
% figures
peaksHist = hist3(allPeaks, [50,28]);
peaksHist (1, :) = [];peaksHist (size(peaksHist,1),:) = [];
if plotBool
    figure2 = figure; 
    hist3(allPeaks, [50,28]);
    set (gca, 'FontSize', 16)
    xlabel('Time(minutes)');
    ylabel('Period(minutes)');
    zlabel('Probability of Finding a Peak');
    figure3 = figure;
    imagesc(linspace(min(allPeaks(:,2)), max(allPeaks(:,2)), 28),...
        linspace (min(allPeaks(:,1)), max(allPeaks(:,1)), 50), peaksHist);
    colormap jet;h = colorbar;
    xlabel ('Period(minutes)');ylabel('Time(minutes)');
    ylabel (h, 'Number of Peaks Detected')
    set (gca, 'FontSize', 16)
    if saveBool
       saveas(figure2, [figureDir filesep 'PeaksHistogram.png']);
       saveas(figure3, [figureDir filesep 'PeaksHeatmap.png']);
    end 

end


%get the means and stds for time and period localization
perMean = mean(allPeaks(:,2));perStd = std(allPeaks(:,2));
timeMean = mean(allPeaks(:,1));timeStd = std(allPeaks(:,1));


end 