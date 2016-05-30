function [allPeaks] =  BigDatatoPeaks(dataDir)


load ([dataDir filesep 'Data.mat']);

allPeaks = PeakConcatenator (plateData, true, dataDir);
end 