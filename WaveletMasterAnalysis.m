%this function performs the wavelet analysis
function [waveData, period, scale, coi] = ...
    WaveletMasterAnalysis (signal, signalTimes,...
    significanceLevel, plotWavelet)

if nargin<4
    plotWavelet = false;
end 

%wavelet variable stuff - be very careful here
wavName = 'Morlet';%define wavelet family
lag1 = .72; %autocorrelation for red noise background
%define minimum scale
subOctaves = .01;%number of subOctaves per octave
totOctaves = 7/subOctaves;%total number of samples in frequency space
%plotWavelet = false;

%reconstruction factor for morlet wavelet - torrence et al 1998
reconstructionFactor = .776;



%initialize a struct waveData to store wavelet data
emptycell.normalizedSignal = [];
emptycell.power = [];
emptycell.powerSig = [];
emptycell.powerPeaks = [];
emptycell.globalWS = [];
emptycell.globalSig = [];
emptycell.scaleAvg = [];
emptycell.scaleAvgSig = [];
waveData(1) = deal (emptycell);

numSignals = size(signal,1)*size(signal,2);%make your life easier w indices

%convert times from days into minutes
% sampling rate for wavelet transforms
dTime = signalTimes(2) -signalTimes(1);
minScale = 2*dTime;


%define min and max scales to scale average - in minutes
minScaleAverage = 2;
maxScaleAverage = 10;
%preform wavelet transform for all signals
%wavelet analysis code adapted from wavlet toolbox from C. Torrence and G.
%compo - see torrence et al 1997


%define length to make life easier
sigLength = size(signal,3);
areaFilter = 10;%define area filter to attempt to get rid of false positive

%define threshold for finding peaks in the significance of the power
%spectra
significanceThreshold = 1;

for j = 1: size(signal,1)
    for k = 1: size (signal,2)
        
        %make life easier by initializing a signal counter
        countSignal = (j-1)*size(signal,1)+k;

%         %update waitbar
%         message = ['Postprocessing Signal ' num2str(countSignal) ' of ' ...
%             num2str(size(signal,1)*size(signal,2)) ':'];
%         waitbar(.5 + countSignal/(size(signal,1)*size(signal,2)),...
%             w, message);
%         
        %normalize with mean and variance
        signalVariance = std (squeeze (signal(j,k, :)))^2;

        %catch empty signals
        if signalVariance == 0
            waveData(countSignal).normalizedSignal=squeeze(signal(j,k,:));
            
        else
            waveData(countSignal).normalizedSignal = ...
                (squeeze(signal(j,k,:))-...
                mean (squeeze(signal (j,k,:))))./ sqrt(signalVariance);
        end
        %perform continuous wavelet transform and store coefficients
        
        %if this is the first signal then extract everything that is the
        %same for all of the wavelets
        if countSignal ==1
            [waveCoefs,period,scale, coi] = ...
                wavelet(waveData(countSignal).normalizedSignal,dTime,...
                true,subOctaves,minScale, totOctaves, wavName);
        %otherwise just get the wavelet coefficients
        else
            [waveCoefs, ~, ~, ~] = ...
                wavelet(waveData(countSignal).normalizedSignal,dTime,...
                true, subOctaves,minScale, totOctaves, wavName);
            
        end
        
        
        % compute wavelet power spectrum from wavelet coefficients
        waveData(countSignal).power= (abs(waveCoefs)).^2 ;

        %if we are on the first iteration then calculate the significance
        %levels (the same for every one)
        
        if countSignal==1
            
            %determine significance levels of transform
            [tempSignif, fftTheor] = wave_signif (1.0, dTime, ...
                scale, 0, lag1 ,...
                significanceLevel, -1, wavName);
            
            % expand tempSignif --> (J+1)x(N) array
            sigArray = (tempSignif')*(ones(1,sigLength));
%             
%             % where ratio > 1, power is significant
%             waveData(countSignal).powerSig = ...
%              waveData(countSignal).power./waveData(countSignal).powerSig;
%             
        end
        
        %find the global wavelet spectrum + corresponding significance
        %time average and normalize with variance
        waveData(countSignal).globalWS = signalVariance * ...
            sum(waveData(countSignal).power')/sigLength;
        %define number of degrees of freedom
        degreesOfFreedom = sigLength-scale;
        waveData(countSignal).globalSig = ...
            wave_signif (signalVariance, dTime,...
            scale, 1,lag1, -1, ...
            degreesOfFreedom, wavName);

        %scale average over periods
        avg = find ((scale >= minScaleAverage)&...
            (scale < maxScaleAverage));
        %expand
        waveData(countSignal).scaleAvg = scale'*...
            (ones(1, sigLength));
        waveData(countSignal).scaleAvg = waveData(countSignal).power./...
            waveData(countSignal).scaleAvg;

        waveData(countSignal).scaleAvg=signalVariance* subOctaves *...
            dTime/ reconstructionFactor* ...
            sum (waveData(countSignal).scaleAvg(avg,:));
        
        %find significance of the scale average
        waveData(countSignal).scaleAvgSig = wave_signif(signalVariance,...
            dTime,scale, 2,lag1, significanceLevel,...
            [minScaleAverage, maxScaleAverage], wavName);
                

        %get power peak and area info
        [waveData(countSignal).powerPeaks] =...
            WaveletPeakFinder(waveData(countSignal), areaFilter, ...
            signalTimes, sigArray, period, false);
% 
%         %plot wavelet
%         if plotWavelet
%             figure; WaveletPlot (waveData, countSignal);
%         end


    end
end

end 