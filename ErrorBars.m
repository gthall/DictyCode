%varargin 
function [handle] = ErrorBars(x, y, bottomErr, topErr, varargin)
%Parse args (user-defined color)

if nargin == 5 && (ischar(varargin{1}) || length(varargin{1}) == 3)
    color = varargin{1};
else 
    %Default color
    color = [1 1 0.8];
end

%Remove NaN's
filter = ~isnan(x) & ~isnan(y) & ~isnan(bottomErr)&~isnan(topErr);
if any(~filter)
    warning('Ignoring entries with NaN')
end

x = x(filter);
y = y(filter);
bottomErr = bottomErr(filter);
topErr = topErr(filter);

%Flip if necessary
if size(x,1) ~= 1
    x = x';
end
if size(y,1) ~= 1
    y = y';
end
if size(bottomErr,1) ~= 1
    bottomErr = bottomErr';
end
if size(topErr,1) ~= 1
    topErr = topErr';
end

%Define vertices
upper = y + topErr;
lower = fliplr(y - bottomErr);

xbounds = [x fliplr(x)];
ybounds = [upper lower];

%Plot and return handle to patch object
handle = fill(xbounds, ybounds, color);