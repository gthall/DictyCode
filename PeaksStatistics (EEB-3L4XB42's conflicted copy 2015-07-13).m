function [perMean, perStd, timeMean, timeStd] = PeaksStatistics (allPeaks)

%plot the distributions of peaks
    figure;plot (allPeaks(:,1), allPeaks(:,2), 'k.');
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
    
    % lets see if we can bin the peaks and make a histogram
    peaksHist = hist3(allPeaks, [50,28])
    figure; hist3(allPeaks, [50,28]);
    xlabel('Time(minutes)');ylabel('Period(minutes)');zlabel('Frequency');
    figure; imagesc (linspace (min(allPeaks(:,1)), max(allPeaks(:,1)), 50),...
        linspace (min(allPeaks(:,2)), max(allPeaks(:,2)), 28), peaksHist);
%     xlabel ('Period(minutes)');ylabel('Time(minutes)');
%     currentAxes = gca;
%     currentAxes.YTickLabel = linspace(round(min(allPeaks(:,2))), round(max(allPeaks(:,2))), 10);
%     currentAxes.XTickLabel = linspace (round(min (allPeaks(:,1))), round(max(allPeaks(:,1))), 10);
%     


    perMean = mean(allPeaks(:,2));perStd = std(allPeaks(:,2));
    timeMean = mean(allPeaks(:,1));timeStd = std(allPeaks(:,1));
end 