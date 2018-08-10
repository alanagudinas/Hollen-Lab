% Author: Alana Gudinas
% July 17, 2018
%
% [ diffArea ] = AreaDifference( xi, yi, xdata, ydata)
%
% This is a function that creates a binary image from every contour plot in
% an image and then compares the area of each image to a reference plot. 
%
% The inputs are:
% (xi,yi): the template contour coordinates
% (xdata,ydata): vectors containing the coordinates of all the plots that should be compared
% (imX,imY): the dimensions of the image
% 
%  The output is a vector (diffArea) containing the difference in area 
% between the template contour and all other contours.
%
%------------------------------------------------------------------------------------%


function [ diffArea ] = AreaDifference( xi, yi, xdata, ydata, imX, imY)


Im_binR = poly2mask(xi,yi,imX,imY); % Im_binR is a binary image containing only the selected defect in white.

s = regionprops(Im_binR,'Centroid'); % Find coordinates of center of defect.

centRef = cat(1, s.Centroid);

xR = centRef(:,1);
yR = centRef(:,2);
xC = [];
yC = [];

diffArea = zeros(1,length(xdata(1,:)));

for k = 1:length(xdata(1,:))
    xint = xdata(:,k);
    yint = ydata(:,k);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = []; 
    if ~isempty(xint)
        Im_bin = poly2mask(xint,yint,imX,imY); % binary image of each defect
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
            Im_binC = poly2mask(xAd,yAd,imX,imY);
            ImDiff = imsubtract(Im_binC,Im_bin); % subtract the overlayed image from the test image.
            diffArea(k) = bwarea(ImDiff);  % difference in area between template defect and test defect.
        end
    end
end
end