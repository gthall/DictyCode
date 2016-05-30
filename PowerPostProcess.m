%this script will loop through

perStart = 0;
perEnd = 16;
windowAverage = 20;
timeStart = 60;
timeEnd = 550;
powerMovieBool = false;

for i = 1: length (nameDataTracker{1})
    curr = i;
    wellData = load (nameDataTracker{1}{i});
    wellData = wellData.wellData;
    [powerAvgMaxLocations{curr}, ...
        powerAvgMaxUncertainty{curr},...
        totPower(:,:,curr), totSTD(:,:,curr), totStErr(:,:,curr)] =...
        WellPowerAverage (wellData, timeStart, timeEnd, ...
        perStart, perEnd, windowAverage,powerMovieBool, 10,...
        [], []);
    referencePeriod = wellData.period;
    referenceTime = wellData.times;
    clear wellData;
end


[meanExperimentPower, meanExperimentSTD, meanExperimentStErr] = ...
    MeanPowerAnalysis(totPower, totSTD, totStErr, ...
     powerAvgMaxLocations,powerAvgMaxUncertainty, referencePeriod,...
     referenceTime,perStart, perEnd, timeStart, []);