% ShapeMatching( idx, vtx, C, Im_proc )
%
% This program allows a user to select a target defect shape in an image
% and compare it to all other defects in an image to determine how many
% "match" the template image.
%
% Oliver Van Kaick's "Contour Correspondence Via Ant Colony Optimization
% (ACO) is used to perform the shape matching.
%
% NOTE: To run this program, the aforementioned file must be downloaded in
% the current path.
% https://www.mathworks.com/matlabcentral/fileexchange/24094-contour-correspondence-via-ant-colony-optimization

function [] = ShapeMatching(idx, vtx, C, Im_proc)

% Im_proc must be the topography data of a processed image (use
% "ImageProcess"). 
%
% The other inputs are outputs of GetContourData, which should run prior to
% this program.
%
% The following does the same thing as the beginning of GetContourData, plotting lines
% around defects that exceed the pixel value threshold computed in
% "BrightnessThresholds." This is for visualization purposes to allow the
% user to select the target defect.

Im = Im_proc;

figure; imshow(Im,[])
hold on

% The following loop draws contour lines around the prominent defects
% present in Im.

for k = 1:length(idx)
    if vtx(k)<=25
        continue
    else
    xdata = C(1,idx(k)+1:idx(k)+vtx(k));
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    plot(xdata,ydata,'Color',[173/255;255/255;47/255])
    hold on
    drawnow
    end
end
hold off
rect = getrect; % Allows user to draw rectangle in current figure.

%--------------------------------------------------------------
% Selected rectangle is returned as a 4-element numeric vector 
% with the form [xmin ymin width height].
%--------------------------------------------------------------

% Next step is to find coordinates of plot inside the rectangle.
xi = 0;
yi = 0;

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k));
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4))))
        xi = xdata;
        yi = ydata;
    end
end

Y1 = [ xi', yi']; % for implementing ACO algorithm 

% MATLAB's poly2mask creates binary image with area inside contour plot marked with '1', and
% any region outside polygon with '0'.

if xi == 0
    s = 'Please select region containing (1) valid defect.';
    disp(s)
else
    Im_binR = poly2mask(xi,yi,512,512); % Im_binR is a binary image containing only the selected defect in white.
    figure; imshow(Im_binR,[])
    hold on
end

s = regionprops(Im_binR,'Centroid'); % Find coordinates of center of defect.

centRef = cat(1, s.Centroid);
plot(centRef(:,1), centRef(:,2), 'r*')
hold off

xR = centRef(:,1);
yR = centRef(:,2);
xC = [];
yC = [];

diffArea = zeros(1,length(idx));
diffBound = zeros(1,length(idx));

% Looping yet again through the contour data to find all the difference in area
% between the user-selected defect and all other defects in the image:

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k));
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
  
    Im_bin = poly2mask(xdata,ydata,512,512); % binary image of each defect
    sdata = regionprops(Im_bin,'Centroid');
    centroid = cat(1, sdata.Centroid);
    if isempty(centroid)
        continue
    else
        xC = centroid(1);
        yC = centroid(2);
        diffX = xC - xR;
        diffY = yC - yR;
        xAd = xi + diffX; % overlay the target defect on the test defect by doing change of coordinates.
        yAd = yi + diffY;
        Im_binC = poly2mask(xAd,yAd,512,512);
        ImDiff = imsubtract(Im_binC,Im_bin); % subtract the overlayed image from the test image.
        diffArea(k) = bwarea(ImDiff);  % difference in area between template defect and test defect.
    end
end

figure; imshow(Im,[])
hold on

for i = 1:length(diffArea)
    if diffArea(i)<200 % Filter out defects that are not even close in area to the template defect.
        xSh = C(1,idx(i)+1:idx(i)+vtx(i));
        ySh = C(2,idx(i)+1:idx(i)+vtx(i));
        % plot(xSh,ySh,'Color','cyan')
        % hold on
        % drawnow,
        Y2 = [xSh', ySh']; % for implementing in ACO algorithm, the contour data from each defect is recorded and used as an input.
        [K,S, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare'); % ACO program. This is where the magic happens.
       if best_cost<0.4 % best_cost represents how close in match two shapes are. 
            plot(xSh,ySh,'Color','red') % If the shape is a close match, plot it.
            hold on
            drawnow
       end
    end
end
hold off
numShape = numel(findobj(gcf,'Type','line'))


% rect = getrect; % Allows user to draw rectangle in current figure.

% For the purpose of testing ACO algorithm, find a decent match in image.
% I'm lazy so just going to copy getrect script.

%{
x2 = 0;
y2 = 0;

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k));
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4))))
        x2 = xdata;
        y2 = ydata;
    end
end

xi = xi';
yi = yi';
x2 = x2';
y2 = y2';

Y1 = [xi,yi];
Y2 = [x2,y2];
%}

end

