

clear variables;close all;
tic

%set variables
%--------------------------------------------------------------------------
%set your phone number for updates about your code !
phoneNumber = '505-379-5053';

%get master directory as user input
referenceFrame = 1;%taken by looking at the data set. Change w each time!
totExperiments = 1;%how many experiments to analyze on a given run
%figure out what parts of the code to run adjust as you please
singularityBool = false;
significanceLevel = .95;

%plate name using wildcards. Feel free to change for different set ups
plateName = 'Plate*';
wellName = {'A1', 'A2', 'A3', 'B1', 'B2', 'B3'};

%parameters for comparing power spectra
perStart = 0;
perEnd = 16;
windowAverage = 10;
timeStart = 60;
timeEnd = 550;
%should the program save a movie of the power spectra - change based on
%need
powerMovieBool = true;
%should the movie save an animation of the angular wave representation
angularMovieBool = false;

%set up a waitbar (why not?)
w = waitbar(0, 'Please wait...');
message = 'Preprocessing, Please Wait';
waitbar(0, w, message);
%--------------------------------------------------------------------------


%set up your directories
%--------------------------------------------------------------------------

%declare cell array to keep track of different directories for different
%experiments to analyze
experimentFol = cell(1, totExperiments);


%request user input to get the directories
for i = 1: totExperiments
    experimentFol{i} = uigetdir(cd, ...
        ['Pick ' num2str(i) ' th Experiment Directory']);
end 

%if we are trying to get aggregate data for multiple experiments select the
%save directory for that information
saveDir = uigetdir(cd, 'Pick Save Directory For Total Peak Information');

%this is how we keep track of what exactly everything is
nameDataTracker = cell (1, totExperiments);
%--------------------------------------------------------------------------

%initialize storage variables
%--------------------------------------------------------------------------
%initialize some storage variables - for cross experiment comparisons...

%the means and stds in time and space for the individually detected peaks
%in the power spectra
perMeansExp = zeros (1, totExperiments);
perStdsExp = zeros(1, totExperiments);
timeMeansExp = zeros(1, totExperiments);
timeStdsExp = zeros(1,totExperiments);
%keeping track of the total peaks detected
experimentPeaks = cell(1, totExperiments);
experimentHist = cell(1, totExperiments);
%combine all of the detected peaks into one place
totalPeaks = [];

%and now for cross well comparisons

%count the total number of wells
wellCounter = totExperiments * 18;

%store means and stds of detected single peaks for each well
perMeansWell = zeros (1, wellCounter);
perStdsWell = zeros (1, wellCounter);
timeMeansWell = zeros (1, wellCounter);
timeStdsWell = zeros (1, wellCounter);
wellPeaks = cell(1, wellCounter);
wellHist = cell(1, wellCounter);

%keep track of where the peaks in the globally averaged power spectra are
powerAvgMaxLocations = cell(1, wellCounter);
powerAvgMaxUncertainty = cell(1, wellCounter);
totPower = [];
totSTD = [];
totStErr = [];

%--------------------------------------------------------------------------
%do preprocessing and extract data from videos
%--------------------------------------------------------------------------

%%
%loop through different days
for plates = 1:totExperiments 
%set up a directory for all of the plates in a given day's experiments
plateDir = dir ([experimentFol{plates} filesep plateName]);

%import metadata for those experiments
metadata = importdata([experimentFol{plates} filesep 'metadata.csv']);

%establish the max number of plates that you could have
numPlates = size(plateDir,1)* 6;

%initialize a cell array to keep track of the addresses where you put all
%of this data to the disk
wellAddress = cell (1, numPlates);

%loop through plates within each experiment
for i = 1:size(plateDir,1)
    
    %within each plate loop through each well
    %%
    for j = 1:6
         %use try catch to deal with variable number of plates - if
         %opening the directory causes an error (aka there is in fact not a
         %directory there) then the program will continue to the next
         %iteration of the loop. Likewise, if the directory doesnt cause an
         %error but is empty, the script will continue to the next
         %iteration of the loop. This means that you can delete specific
         %wells and the program (hopefully) shouldnt crash
         try
             testDir = dir ([experimentFol{plates} filesep ...
                 plateDir(i).name filesep wellName{j}]);
             if isempty(testDir)
                 continue
             end
         catch
             continue
         end
         curr = (i-1)*6+j;
         
         
         %first lets do the waitbar
         message = ['Analyzing Image Set ' num2str(curr) ' of ' ...
             num2str(numPlates) ' in Experiment ' num2str(plates) ' of '...
             num2str(plates) ' : ' ];
         waitbar(((i-1)./totExperiments) + ...
             ((curr-1)/(numPlates *totExperiments)) , w, message);
         
         
         %initialize struct to keep track of the data for the well
         emptycell.timer = [];
         emptycell.theta = [];
         emptycell.waveData = [];
         emptycell.period = [];
         emptycell.scales = [];
         emptycell.coi = [];
         emptycell.times = [];
         
         if singularityBool
             emptycell.singularities = [];
             emptycell.singularityTracker = [];
         end

         wellData(1) = deal(emptycell);
         
        %get the data for the given well
        [wellData(1).timer, wellData(1).times, wellData(1).waveData, ...
            wellData(1).period, ...
            wellData(1).scales, wellData(1).coi, wellData(1).theta] = ...
            DarkFieldAnalysis(...
            [experimentFol{plates} filesep plateDir(i).name ...
            filesep wellName{j}], metadata, numPlates, referenceFrame, ...
            significanceLevel, angularMovieBool);
%--------------------------------------------------------------------------     
        
        %analyze and store wavelet data
%--------------------------------------------------------------------------        
        %perform wavelet analysis on the data that you just obtained        
        %aggregate all of the peaks found in that well for storage
        wellPeaks{curr} = PeakConcatenator (wellData, false);
        %aggregate all of the peaks from this well to be stored for each
        %experiment
        experimentPeaks{plates} = vertcat (experimentPeaks{plates},...
            wellPeaks{curr});
                
        %get means and stds for each well to see how they vary from ...
        %place to place
        [perMeansWell(curr), perStdsWell(curr), ...
            timeMeansWell(curr), timeStdsWell(curr),...
            wellHist{curr}] = PeaksStatistics(wellPeaks{curr}, false);
        
        
        %get the smoothed power spectra for this well as well as save a
        %movie of the power spectra evolving over time 
        saveName = ['PowerSpectraDynamics' num2str(curr)];
        
        %get the average power spectral dynamics over time for a well
        [peakLocations, powerAvgMaxLocations{curr}, ...
            powerAvgMaxUncertainty{curr},...
            totPower(:,:,curr), totSTD(:,:,curr), totStErr(:,:,curr)] =...
            WellPowerAverage (wellData, timeStart, timeEnd, ...
            perStart, perEnd, windowAverage,powerMovieBool, 10,...
            saveDir, saveName);


        %save welldata to the disk
%-------------------------------------------------------------------------- 
        %save data to disk for the well and save the address. If its empty
        %then dont save it and just move on to the next well
        if ~isempty(wellData)
            save([experimentFol{plates} filesep plateDir(i).name ...
                filesep 'wellDataAngular' plateDir(i).name wellName{j}...
                'sigfilter' num2str(significanceLevel) '.mat'], ...
                'wellData','-v7.3');
            wellAddress{curr} = [experimentFol{plates} filesep ...
                plateDir(i).name filesep 'wellDataAngular'...
                plateDir(i).name...
                wellName{j} 'sigfilter' num2str(significanceLevel) '.mat'];
            referencePeriod = wellData.period;
            referenceTime = wellData.times;
        end
        clear wellData;        
        disp(curr);
    end 
end 

%clean up any blank spots left in wellAddresses
wellAddress = wellAddress(~cellfun('isempty', wellAddress));

totalPeaks = vertcat (totalPeaks, experimentPeaks{plates});

nameDataTracker{plates} = wellAddress;
clear wellAddress;

end 

%perform global analysis
%--------------------------------------------------------------------------

%%
%clean up your directory of directories
nameDataTracker = nameDataTracker(~cellfun('isempty', nameDataTracker));

%get means/stds and visualize data
[perMeanTot, perSTDTot, timeMeanTot, timeSTDTot, totHist] = ...
    PeaksStatistics (totalPeaks, true);

%analyze and plot mean power spectrum data and then save movie
[meanExperimentPower, meanExperimentSTD, meanExperimentStErr] = ...
    MeanPowerAnalysis(totPower, totSTD, totStErr, ...
     powerAvgMaxLocations,powerAvgMaxUncertainty, referencePeriod,...
     referenceTime,perStart, perEnd, timeStart, saveDir);

save ([saveDir filesep 'TotalPeaks.mat'], 'totalPeaks', 'wellPeaks',...
    'nameDataTracker', 'meanExperimentPower', 'meanExperimentSTD',...
    'meanExperimentStErr', 'totPower', 'totSTD', 'totStErr', ...
    'powerAvgMaxLocations', 'powerAvgMaxUncertainty',...
    'referencePeriod', 'referenceTime');

close (w);
timer = toc;
disp (['Time = ' num2str(timer)]);

 
send_text_message (phoneNumber, 'Verizon', 'Congratulations', ...
    'Your code is done running!');
