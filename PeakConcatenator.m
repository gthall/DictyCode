%this function is very simple and just to make your life easier - this will
%take in master data and then save the variable peaks in a location of your
%choosing
function [allPeaks] = PeakConcatenator (wellData, saveBool, saveDir)

%make sure that you have a save directory if youre going to be saving
%anything - if you are not given a save directory then dont save anything
if nargin <3
    if saveBool
        disp ('No save directory given - no data saved to disk');
    end
    saveBool = false;
end 

%set up saving stuff if need be
if saveBool
    saveLocation = saveDir;
    saveName = 'AllPeaks.mat';
end

%for each element of the struct(wells), loop through each signal
for j = 1: length(wellData.waveData)
    %concatenate all of the found peaks together
    if j==1
        allPeaks = cat(1, wellData.waveData(j).powerPeaks.Centroid);
    else
        allPeaks = vertcat(allPeaks, ...
            cat(1, wellData.waveData(j).powerPeaks.Centroid));
    end
end


%save only the peaks if need be
if saveBool
    save ([saveLocation filesep saveName], 'allPeaks');
end

end 