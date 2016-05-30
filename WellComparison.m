%this function will basically serve as the analysis for comparing
%measurements of peaks between wells

function [] = WellComparison (wellPeaks, figureBool)

if nargin<2
    figureBool = false;
end 

%first get an internal guage of all of the peaks 
totalPeaks = [];
for i = 1: length(wellPeaks)
    totalPeaks = vertcat(totalPeaks, wellPeaks{i});
end 
temp = totalPeaks(:,2);
deletionIndex = temp<4.5;
totalPeaks(deletionIndex, :) = [];

%lets notmalize into a 2-d pdf
[~,~,~,~,totalHist] = PeaksStatistics (totalPeaks, false);
totalHist = totalHist ./ (sum(sum(totalHist)));

if figureBool
    figure;
    imagesc(linspace (min(totalPeaks(:,1)), max(totalPeaks(:,1)), 50), ...
        linspace(4.5,  max(totalPeaks(:,2)), 28),...
        totalHist');
    set(gca, 'CLim', [0 max(max(totalHist))])
    colormap (jet); h = colorbar;
    ylabel('Period (minutes)')
    xlabel('Time Since Starvation (minutes)')
    title ('High Power Regions in Wavelet Transform')
    ylabel (h, 'Number of Peaks Found (normalized)')
    set (gca, 'FontSize', 16);
end

wellHist = cell(size(wellPeaks));
normalizedHist = cell(size(wellPeaks));
for i  = 1:length(wellPeaks)
    [~,~,~,~,wellHist{i}] = PeaksStatistics(wellPeaks{i}, false);
    normalizedHist{i} = wellHist{i}./sum(sum(wellHist{i}));
end 

%define matrices to hold the std and the mean of these functions
wellStorage  = zeros(size(totalHist,1), size(totalHist, 2), ...
    length(normalizedHist));

%loop through the array and just find the noise at each point
for i = 1: size (totalHist,1)
    for j = 1: size(totalHist,2)
        for k = 1: length(normalizedHist)
            wellStorage (i,j,k) = normalizedHist{k}(i,j);
        end 
    end
end 
%get means and stds
wellMeans = mean(wellStorage, 3);
wellSTD = std (wellStorage, 0, 3);
wellNoise = wellSTD./wellMeans;
if figureBool
    figure;
    imagesc(linspace (min(totalPeaks(:,1)), max(totalPeaks(:,1)), 50), ...
        linspace(4.5, max(totalPeaks(:,2)), 28),...
        wellSTD'); 
    set(gca, 'CLim', [0 max(max(totalHist))]);
    colormap jet; h = colorbar;
    ylabel ('Period (minutes)');xlabel ('Time Since Starvation (minutes)');
    title ('STD in High Power Detection From Well to Well')
        ylabel (h, 'STD  Of Number of Peaks Found')
           set (gca, 'FontSize', 16);


    
    figure;
    imagesc(linspace (min(totalPeaks(:,1)), max(totalPeaks(:,1)), 50), ...
        linspace(4.5, max(totalPeaks(:,2)), 28),...
        wellNoise'); colormap jet; g = colorbar;
    
    ylabel ('Period (minutes)');xlabel ('Time Since Starvation (minutes)');
    title ('Noise in Peak Detection From Well to Well')
    set (gca, 'FontSize', 16);
        ylabel (g, 'Noise (Unitless)')


end
%lets see if we can 


end 