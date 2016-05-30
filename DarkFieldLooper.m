clear variables;close all;
tic
%get master directory as user input
referenceFrame = 60;%taken by looking at the data set. Change w each time!
totExperiments = 1;%how many experiments to analyze on a given run
%figure out what parts of the code to run adjust as you please
angularBool = true;
singularityBool = false;
waveBool = true;
angularToWaveletBool = false;
significanceLevel = .03;
%plate name using wildcards. Feel free to change for different set ups
plateName = 'Plate*';
wellName = {'A1', 'A2', 'A3', 'B1', 'B2', 'B3'};
peakAnimationDir = uigerdir (cd, 'Where to Put your peak stuff');

%set up a waitbar (why not?)
w = waitbar(0, 'Please wait...');
message = 'Preprocessing, Please Wait';
waitbar(0, w, message);


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
if totExperiments>1
    saveDir = uigetdir(cd, 'Pick Save Directory');
end

%this is how we keep track of what exactly everything is=
nameDataTracker = cell (1, totExperiments);


%loop through different days
for plates = 1:totExperiments 
%set up a directory for all of the plates in a given day's experiments
plateDir = dir ([experimentFol{plates} filesep plateName]);

%import metadata for those experiments
metadata = importdata([experimentFol{plates} filesep 'metadata.csv']);

%establish the max number of plates that you could have
numPlates = size(plateDir,1)* 6;
%initialize a cell array to keep track of the addresses where you put all
%of this data
wellAddress = cell (1, numPlates);

%loop through plates
for i = 1:size(plateDir,1)
    %within each plate loop through each well
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
             num2str(numPlates) ' in Experiment ' num2str(i) ' of ' ...
             num2str(totExperiments) ' : ' ];
         waitbar(((i-1)./totExperiments) + ...
             ((curr-1)/(numPlates *totExperiments)) , w, message);
         
         
         %initialize struct to keep track of the data for the well
         emptycell.timer = [];
         if angularBool
             emptycell.theta = [];
         end
         if singularityBool
             emptycell.singularities = [];
             emptycell.singularityTracker = [];
         end
         if waveBool
             emptycell.waveData = [];
             emptycell.period = [];
             emptycell.scales = [];
             emptycell.coi = [];
         end
         
         wellData(1) = deal(emptycell);
         
        %get all of the data for the given well
        [wellData(1).timer, wellData(1).waveData, wellData(1).period,...
            wellData(1).scales, wellData(1).coi, wellData(1).theta] = ...
            DarkFieldAnalysis(singularityBool, ...
            angularBool, waveBool, ...
            [experimentFol{plates} filesep plateDir(i).name ...
            filesep wellName{j}], metadata, numPlates, referenceFrame, ...
            significanceLevel);
        
        %save data to disk for the well and save the address. If its empty
        %(nonexistant directory) 
        if ~isempty(wellData)
            save([experimentFol{plates} filesep plateDir(i).name filesep...
                'wellData' plateDir(i).name wellName{j} 'sigfilter' ...
                num2str(significanceLevel) '.mat'], 'wellData', '-v7.3');
            wellAddress{curr} = [experimentFol{plates} filesep ...
                plateDir(i).name filesep 'wellData' plateDir(i).name...
                wellName{j} 'sigfilter' num2str(significanceLevel) '.mat'];
        end
        clear wellData;        
        disp(curr);
    end 
end 

%clean up any blank spots left in wellAddresses
wellAddress = wellAddress(~cellfun('isempty', wellAddress));


nameDataTracker{plates} = wellAddress;
clear wellAddress;

end 


%clean up your directory of directories
nameDataTracker = nameDataTracker(~cellfun('isempty', nameDataTracker));

%figure out just how many real wells you have
wellCounter = 0;
for i = 1: totExperiments
    wellCounter = wellCounter + length (nameDataTracker{i});
end

%initialize some storage variables - for cross experiment comparisons...
perMeansExp = zeros (1, totExperiments);
perStdsExp = zeros(1, totExperiments);
timeMeansExp = zeros(1, totExperiments);
timeStdsExp = zeros(1,totExperiments);

%and for cross well comparisons
perMeansWell = zeros (1, wellCounter);
perStdsWell = zeros (1, wellCounter);
timeMeansWell = zeros (1, wellCounter);
timeStdsWell = zeros (1, wellCounter);

%combine all of the detected peaks into one place
totalPeaks = [];
experimentPeaks = cell(1, totExperiments);
experimentHist = cell(1, totExperiments);
wellPeaks = cell(1, wellCounter);
wellHist = cell(1, wellCounter);
peakLocations = cell(1, wellCounter);
counter = 0;
%get all peaks in one place and visualize them
for i = 1: totExperiments
    experimentPeaks{i} = [];
    for j = 1: length(nameDataTracker{i})
       
        counter = counter+1;%keep track of where you are
        
        %do the thing
        message = 'Processing Peaks Data';
        waitbar( counter/wellCounter , w, message);
        

        %load in the specific dataset for a well
        load (nameDataTracker{i}{j}, 'wellData');
        
        %look at smoothed power spectra
        peakLocations{counter} = PowerMovie (wellData, 200, 550, 10,...
            peakAnimationDir);
        %extract peak information for this well
        wellPeaks{counter} = PeakConcatenator (wellData, false);
        %add the peak information into the total pool
        experimentPeaks{i}= vertcat(experimentPeaks{i},wellPeaks{counter});
        
        
        %get means and stds for each well to see how they vary from ...
        %place to place
        [perMeansWell(counter), perStdsWell(counter), ...
            timeMeansWell(counter), timeStdsWell(counter),...
            wellHist{i}] = PeaksStatistics(wellPeaks{counter}, false);
    end
    %get means and stds for each experiment to see variance etc etc 
    [perMeansExp(i), perStdsExp(i), timeMeansExp(i), timeStdsExp(i), ...
        experimentHist{i}] = PeaksStatistics (experimentPeaks{i}, false);
    
    totalPeaks = vertcat (totalPeaks, experimentPeaks{i});
end 

%get means/stds and visualize data
[perMeanTot, perSTDTot, timeMeanTot, timeSTDTot, totHist] = ...
    PeaksStatistics (totalPeaks, true);



close (w);
timer = toc;
disp (['Time = ' num2str(timer)]);
