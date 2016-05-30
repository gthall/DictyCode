%this function will prompt a gui in which the user can input the centers of
%aggregation 

function [xCenters,yCenters] = identifyCentersUI(image)
%create figure and hide it until gui is fully initialized
f = figure('Units','Normalized', 'Position', [.2, .2, .8, .8]) ;
imshow(image);
[xCenters, yCenters] = ginput;



end