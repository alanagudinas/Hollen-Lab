% Author: Alana Gudinas
% July 17, 2018
%
% This is a function that creates a binary image from every contour line.


function [ diffArea ] = AreaDifference( xi, yi, xdata, ydata)

if xi == 0
    s = 'Please select region containing (1) valid defect.';
    disp(s)
else
    Im_binR = poly2mask(xi,yi,512,512); % Im_binR is a binary image containing only the selected defect in white.
end

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
    Im_bin = poly2mask(xint,yint,512,512); % binary image of each defect
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
end