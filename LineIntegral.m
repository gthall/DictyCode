%this function computes a line integral about a box centered at xCenter,
%yCenter with side length of size over the vector field 'field'. the box
%should really be odd, at least that is the only case I have debugged for
%note 7-1-15 Ok this is honestly pretty fucked -I will try to meaningfully
%debug later but for now this works ok. Basically the indexing for the
%fields and the centers do not match. Fieldx is left right and field y is
%up down but xCenter is vertical and yCenter is horizantal. I will fix this
%so that it makes sense I promise!
function [value, value1, value2, value3, value4] = LineIntegral(fieldx,...
    fieldy, xCenter, yCenter, size)

%right side
value1 = trapz (fieldy(xCenter+floor(size/2):-1:xCenter-floor(size/2), ...
    yCenter+floor(size/2)));

%top
value2 = -trapz (fieldx(xCenter-floor(size/2),...
    yCenter+floor (size/2):-1:yCenter-floor(size/2)));

%left side
value3= -trapz (fieldy(xCenter -floor (size/2):1:xCenter+floor(size/2),...
    yCenter-floor(size/2)));

%bottom
value4 = trapz (fieldx(xCenter+floor(size/2), ...
    yCenter-floor (size/2):yCenter+floor(size/2)));

value = value1+value2+value3+value4;
end 