
peakTracker = struct('trace',[], 'times',[]);
for i = 1: length (peakLocations)
    if i==1
       for j = 1: length(peakLocations{i})
           peakTracker(j).trace(1) = peakLocations{i}(j);
           peakTracker(j).times(i) = referenceTimes
       end
    end
end 