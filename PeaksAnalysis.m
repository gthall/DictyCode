%this function takes in a struct with data of wavelet power spectra peaks
%and then analyzes the distribution of these peaks
function [allPeaks, pcaCoefs, score, latent, TSquare, VarExplained, mu]...
    =  PeaksAnalysis (masterData, masterDir)
%variables



%first lets aggregate all of the peaks into one array for statistical
%analysis

    allPeaks = PeakConcatenator(masterData, true, masterDir);

    %get the basic stuff on the localization of the peaks
    [perMean perSTD timeMean timeSTD] = PeaksStatistics(allPeaks);

    %attempt to preform pca on the wavelet power coefficients
    
    %define the bounds that you want to be comparing for pca
    timeStart = 200;%in minutes
    timeEnd = 500;%in minutes
    perStart = 4;%in minutes
    perEnd = 9;%in minutes
    %convert measurements in minutes to indexes in the matrix of power
    %coordinates
    perIndex = find (masterData(1).waveData(1).period > perStart |...
        masterData(1).waveData(1).period <perEnd);
    timeIndex = find (masterData(1).waveData(1).times >timeStart |...
        masterData(1).waveData(1).times <timeEnd);
    
    %now that we have the indexes lets concatenate the images into one big
    %vector
    %find out just how many degrees of freedom we will have
    dimensionality = (max (perIndex) - min(perIndex))* ...
        (max(timeIndex)-min(timeIndex));
    %determine how many measurements we are going to have
    numMeasurements = 0;
    for i = 1: length(masterData)
        numMeasurements = numMeasurements+size(masterData(i).waveData,2);
       
    end
    
    
    %declare storage array for pca 
    %measurementStorage = zeros (numMeasurements, dimensionality);
    %keep track of iterations
    counter = 1;
    %fill storage array
    for i =1: length(masterData)
        for j = 1: length(masterData(i).waveData)
            temp = [];
            for k = 1:size (masterData(i).waveData(j).power,1)
                temp = horzcat(temp, masterData(i).waveData(j).power(k,:));
            end
            measurementStorage(counter, :) = temp;
            counter = counter+1;
        end 
        
    end
    
    
    [pcaCoefs, score, latent, TSquare, VarExplained, mu] = ...
        pca (measurementStorage);
    
end 