
exFol = uigetdir;
imFol = uigetdir;
metadata = importdata([exFol filesep 'metadata.csv']);
[~,~, theta] = DarkFieldAnalysis(false, true, false, imFol,metadata, 18,...
    60, .95);

%extract information from angualar data
[height, width, ~] = size (theta);
vertStep = floor (height/5);horzStep = floor(width/5);
signal = zeros (vertStep-1, horzStep-1, size(theta, 3));
for i = 1: vertStep-1
    for j = 1: horzStep-1
        %put the signal in terms of
        signal (i,j,:) = sin (squeeze(theta (i*5,j*5, :)));

    end 
    
end

clear theta
waveData = WaveletMasterAnalysis (signal, 1:size(signal,3), ...
    .95, false);