%this function will act as the analysis function for comparing power
%spectra. The function takes as input the power spectra as well as time and
%period parameters and then returns the smoothed power spectra at a
%particular time pt as well as the locations of the peaks in that smoothed
%power spectra and a figure handle. To be extra explicit - this function is
%localized in time but not over frequency - that is, it looks at one chunk
%of time and then looks at how the wavelet power spectra look over that
%time
function [ peakLocations, peaksUncertainty, totPower, totSTD, totStErr, ...
    varargout] = ...
    PowerComparison ...
    (waveData, signalTimes, period, timeStartIndex, timeEndIndex,...
    perStartIndex, perEndIndex, figureBool, distBool)

if nargin <9
    distBool = false;
    if nargin<8
        if nargout <3
            figureBool = false;
        else
            figureBool = true;
        end
    end
end

%loop through the signal data and pull out, smooth, normalize and store the
%spectral densities from the interesting region

%declare storage array for vectors - columns are sections of wavelet power
%spectra, rows are measurements from each power spectra
powerStorage = zeros (length(waveData), perEndIndex-perStartIndex+1);
powerStorageNormalized = zeros (length(waveData), ...
    perEndIndex-perStartIndex+1);


%loop through all of the wavelet transforms
for i = 1: length(waveData)
    %average across the given time interval
    temp = mean (waveData(i).power(perStartIndex:perEndIndex, ...
        timeStartIndex: timeEndIndex), 2)';
    powerStorage (i,:) = temp;
    powerStorageNormalized(i, :) = temp./sum(temp);
end
%sum accross all measurements
totPower = mean(powerStorage,1);
%keep track of standard deviation and standard error for this sum
totSTD = std (powerStorage, 0,1);
totStErr = std (powerStorage, 0,1)./sqrt(size(powerStorage,1));

%find the local maxima in your power spectra
[pks, locs] = findpeaks (totPower);
%find the local minima to restrict your search
[mins, minlocs] = findpeaks (-totPower);
%find the uncertainty on your peaks - that is, find the width around each
%peak st the peak is less than one standard error above its neighbors 
%define the height that the uncertainty will have to be greater than 
referencePeaks = pks - totStErr (locs);
referencePower = totPower + totStErr;
%declare a storage array to store your uncertainty estimates 
peaksUncertainty = zeros (length(pks), 2);

%loop through peaks and find the uncertainty for each one
for i = 1: length (pks)
    %for each peak, find the uncertainty interval
    %determine lower bound of search - start of signal or most recent local
    %minima
    startMinima = minlocs(minlocs <locs(i));
    if ~ isempty (startMinima)
        searchStart = max(startMinima);
    else 
        searchStart = 1;
    end
    endMinima = minlocs (minlocs > locs (i));
    if ~ isempty (endMinima)
        searchEnd = min(endMinima);
    else
        searchEnd = length(totPower);
    end
    
    tempUncertainty =  find (referencePower (searchStart:searchEnd)>...
        referencePeaks(i)) + searchStart;
    peaksUncertainty (i,1) = min(tempUncertainty);
    peaksUncertainty(i,2) = max(tempUncertainty);
end 

%convert your values back to units of minutes 
peakLocations = period(locs+perStartIndex-1);
peaksUncertainty = period(peaksUncertainty);

if figureBool
    cla;
    plot (period(perStartIndex:perEndIndex),totPower);
    hold on;
    plot (period(locs +perStartIndex-1), pks, '*');
    xlabel ('Period (minutes)', 'FontSize', 20);
    ylabel ('Power (AU)', 'FontSize', 20);
    title (gca, ['Mean Power Spectra Across Well at Time t = ' ...
        num2str(signalTimes (timeStartIndex)) 'minutes Post Starvation'])
    axis ([period(perStartIndex) period(perEndIndex) 0 1.1*max(totPower)])
    hold off;
    figureHandle = gcf;
    %disp(period(locs+perStartIndex-1));
    
end

if distBool
    jsStorage = zeros (1, nchoosek(length(waveData), 2));
    jsStorageNormalized = zeros (1, nchoosek(length(waveData), 2));
    
    counter=1;
    %calculate a bunch of pairwise js divergences
    for i = 2: size(powerStorage,1)
        for j = 1:i-1
            jsStorage(counter) = JensenShannonDiv...
                (powerStorage(i,:), powerStorage(j,:));
            jsStorageNormalized= JensenShannonDiv...
                (powerStorage(i,:), powerStorage(j,:));
            counter  = counter+1;
            
        end
    end
    
end

%deal with output
totPower = totPower';
if nargout >3
    if figureBool
        varargout{1} = figureHandle;
    end
end 


%this subfunction calculates the JS Divergence between 2 vectors
    function [divergence] = JensenShannonDiv (vector1, vector2)
        midpoint = .5* (vector1+ vector2);
        divergence = .5*(KullbackLeibler(vector1, midpoint))+...
            .5*(KullbackLeibler (vector2, midpoint));
        
    end
%this subfunction calculates the KL divergence between 2 vectors
    function [KL] = KullbackLeibler (vector1, vector2)
        KL = sum (vector1 .* log(vector1./vector2));
        
    end

%this subfunction calculates the earth movers distance between 2 vectors

    function [EMD] = EarthMover (vector1, vector2)
        emd  = zeros (length(vector1, 1));
        for m = 1: length(vector1)
           if m==1
              emd(1) = vector1(1)- vector2(1);
           else 
               emd(m) = vector1;
           end
            
        end
        
    end




end 