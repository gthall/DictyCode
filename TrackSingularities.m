%this function will return the singularities found from the angular
%representaiton over time. The function takes as input the angular
%representation matrix, theta, a time vector, the time you want to start
%and stop tracking singularities (should be around 50 minutes per sawai et
%al 2005) and the threshold for finding singularities.
function [singularities] = TrackSingularities (theta, times, ...
    startTime, endTime, singularityMeasure)


[~, startTimeIndex] = min (abs (times-startTime));
[~, endTimeIndex] = min(abs(times-endTime));


 %declare storage matrices for the x and y components of the gradient
 delThetaX = zeros (size(theta, 1), size (theta, 2), ...
     endTimeIndex-startTimeIndex);
 delThetaY = zeros (size(theta, 1), size (theta, 2), ...
     endTimeIndex-startTimeIndex);
 
 
 %loop through theta and calculate the gradient
 
 [delThetaX, delThetaY] = gradient(theta(:,:,startTimeIndex:endTimeIndex));
 
 for i = 1: size (delThetaX, 3)
quiver (delThetaX(:,:,i), delThetaY(:,:,i));
axis ([ 0 103 0 103])
pause (.2)
 end 
 
 %initialize time average matrix - this matrix will hold the values for
 %each time point integral for theta - at the end we will then divide
 %by the number of timepts to get the time averaged singularities
 
 singularityTracker = zeros (size (theta (:,:,1)));
 
 %loop through all the frames to find singularities
 for i = 1: size (delThetaX, 3)
     %loop through individual frames - dont touch the edges because we
     %need to do a line integral around a 3* 3 box
     for j = 2:size(theta,1)-1
         for k = 2:size(theta,2)-1
             %calculate line integral around box - Note 7-1-15 there is
             %something weird here -need to switch the x and y gradients
             %because of the order of how gradient outputs it things
             singularityTracker(j,k) = singularityTracker(j,k) + ...
                 LineIntegral (delThetaX(:,:,i), delThetaY(:,:,i), j,...
                 k, 3);
         end
     end
     
 end
 
 %divide by number of additions to take the mean
 singularityTracker = singularityTracker./ size(delThetaX,3);
 %find masks of singular points
 singularities = zeros (size (theta,1), size(theta, 2), 3);
 %find the points that have zero as a singular value
 findZeros = find (singularityTracker>-...
     singularityMeasure & singularityTracker<singularityMeasure);
 [findZerosRow, findZerosCol] = find (singularityTracker>-...
     singularityMeasure & singularityTracker<singularityMeasure);
 
 %get rid of edge cases
 %find which indexes of zero pts are along the edge
 boolHolderRow =(findZerosRow == 1|...
     findZerosRow==size(singularityTracker,1)|...
     findZerosRow==size(singularityTracker,1)-1);
 boolHolderCol=(findZerosCol ==1|...
     findZerosCol==size(singularityTracker,1)|...
     findZerosCol==size(singularityTracker,1)-1);
 boolHolder = boolHolderRow|boolHolderCol;
 %eliminate edge pts
 findZeros (boolHolder) = [];
 findZerosRow(boolHolder) = [];
 findZerosCol(boolHolder) = [];
 
 %mask using the singular pts into the first plane of singularities
 temp=singularities (:,:,1);temp(findZeros) = 1;
 singularities(:,:,1) = temp;
 
 %do the same thing for positive 2 pi
 findPis = find (singularityTracker> 2*pi-singularityMeasure...
     & singularityTracker<2*pi+singularityMeasure);
 temp=singularities (:,:,2);temp(findPis) = 1;
 singularities(:,:,2) = temp;
 
 %and for negative 2 pi
 findNegPis=find(singularityTracker>-2*pi-singularityMeasure...
     &singularityTracker< -2*pi+singularityMeasure);
 temp=singularities(:,:,3);temp(findNegPis)=1;
 singularities(:,:,3) = temp;
 
 
 %animate singular points on top of angular plot
 for i = 1: size(theta,3)
     set(gca, 'Units', 'Normalized', 'Position', [ 0, 0, 1, 1]);
     imshow (theta(:,:,i));colormap hsv; colorbar;set (gca, 'clim',...
         [-pi pi]);
     hold on
     plot(findZerosRow, findZerosCol, 'r*', 'MarkerSize', 10)
     %plot time on the frame
     %note - 7-6-15 : This only works on the computer where the
     %files are originally saved, otherwise you get the mod date,
     %which is generally speaking no good
%      tempTime = datestr (imageTimes(i), 13);
%      text (round (size (theta, 1)*(4/5)), round (size (theta, 2)*...
%          (.9)),tempTime, 'Color', 'w', 'FontSize', 28)
%      hold off
     pause (.1)
 end
 
 
 
 
 
 
end