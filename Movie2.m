
close all;
%choose to make from files or from directories
pathFile = true;
pathFigure = false;

if pathFile
    % set up directories
    bigDir = uigetdir (pwd, 'Choose Directory for Images');%'C:\Users\labadmin\Desktop\TestRun\gavintest20160618\Plate1';
    imNam = 'Image*.tiff';
    imDir = dir([bigDir filesep imNam]);
end

movieDir = uigetdir(pwd, 'Choose Location for Movie');%'C:\Users\labadmin\Desktop\TestRun\gavintest20160618\Plate1\B2';
movieName = 'A3DFMovie'

%create a videowriter object
writerObj = VideoWriter ([movieDir filesep movieName]);
writerObj.FrameRate = 25;
open(writerObj);


%loop through every picture and add it to the movie

if pathFile
    for i = 1: length (imDir)
        frame = im2double (imread ([bigDir filesep imDir(i).name]));
        %normalize the frame from 0 to 1
        frame = frame - min(min(frame));
        frame = frame ./ max (max (frame));
        writeVideo (writerObj, frame);
    end
end

if pathFigure
    figureHandle = figure;
    for i = 1:size (theta,3)
        
        set(gca, 'Units', 'Normalized', 'Position', [ 0, 0, 1, 1]);
        imshow (theta(:,:,i));colormap hsv; colorbar;set (gca, 'clim', [-pi pi]);
        coords = figureHandle.Position;
        rect = [0,0,coords(3), coords(4)];
        
        movieFrame = getframe(figureHandle, rect);
        writeVideo (writerObj, movieFrame);
    end
    
    
end
close (writerObj);