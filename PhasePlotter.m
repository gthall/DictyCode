startTimeIndex = 666;
endTimeIndex = 702;

bigDir = uigetdir;
imName = 'Image*';
imDir = dir ([bigDir filesep imName]);

[firstFrameBW, ~, ~, ~] = WellMask (im2double (imread([bigDir filesep imDir(60).name])), 10000);

signal = zeros (1, endTimeIndex-startTimeIndex-8);
signal2 = zeros (1, endTimeIndex-startTimeIndex-8);
for i =startTimeIndex:endTimeIndex-8
    frame = im2double (imread([bigDir filesep imDir(i).name]));
    curr = frame ((round(size (frame, 1)/2))-1:round (size (frame, 1)/2)+1, ...
        size (frame,2)/(4/3)-1: size(frame,2)/(4/3)+1);
    signal(i-startTimeIndex+1) = mean(mean(curr));
    frame = im2double (imread([bigDir filesep imDir(i+8).name]));
    curr = frame (round (size (frame, 1)/2)-1:round (size (frame, 1)/2)+1, ...
        size (frame,2)/(4/3)-1: size(frame,2)/(4/3)+1);
    signal2(i-startTimeIndex+1) = mean(mean(curr)) ;
    
end 

figure;plot (signal-mean(signal), signal2-mean(signal), '*-');
xlabel ('Grey Scale Intensity(t)');
ylabel ('Grey Scale Intensity(t+\tau)');
title ('Example of Phase Trace From Raw Images(\tau \approx 4 min)')
set (gca, 'FontSize', 16)