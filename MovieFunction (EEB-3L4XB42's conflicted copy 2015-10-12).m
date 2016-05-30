%function writes a movie from a given image directory
%pathFile = 1 means choose from file directory, pathFile = 0 means choose
%from figures w in matlab
%bigDir is image directory, movieDir is where to put movie, theta is 3d
%array of images to animate, movieName is self explanatory, fps is self
%explanatory, imNam is an re specifying what the image directory should
%include
function MovieFunction(bigDir, movieDir,theta, movieName, ...
    fps, pathFile, imNam, times)
close all;
%choose to make from files or from directories

if pathFile
    % set up directories
    imDir = dir([bigDir filesep imNam]);
end

%create a videowriter object
cd (movieDir);
writerObj = VideoWriter(movieName);
writerObj.FrameRate = fps;
open(writerObj);


%loop through every picture and add it to the movie

if pathFile
    figureHandle = figure;
    for i = 1: 2000
        frame = im2double (imread ([bigDir filesep imDir(i).name]));
        %normalize the frame from 0 to 1
        frame = frame - min(min(frame));
        frame = frame ./ max (max (frame));
        imshow (frame);
        coords = figureHandle.Position;
        rect = [0,0,coords(3), coords(4)];
        
        hold on
        %text (round (size (frame, 1)*(.7)), round (size (frame, 2)*...
            %(.9)),[num2str(times(i), '%6.0f') ' minutes'],  'Color', 'w', 'FontSize', 28)
        movieFrame = getframe(figureHandle, rect);
        
        writeVideo (writerObj, movieFrame);
        hold off;
    end
end

if ~pathFile
    figureHandle = figure;
    for i = 30:size (theta,3)
        
        set(gca, 'Units', 'Normalized', 'Position', [ 0, 0, 1, 1]);
        imshow (theta(:,:,i));colormap hsv; colorbar;
        set (gca, 'clim', [-pi pi]);
        hold on;

        text (round (size (theta, 1)*(.5)), round (size (theta, 2)*...
            (.9)),[num2str(times(i), '%6.0f') ' minutes'],  ...
            'Color', 'w', 'FontSize', 28)
        
        coords = figureHandle.Position;
        rect = [0,0,coords(3), coords(4)];
        
        movieFrame = getframe(figureHandle, rect);
        writeVideo (writerObj, movieFrame);
    end
    
    
end
close (writerObj);
end