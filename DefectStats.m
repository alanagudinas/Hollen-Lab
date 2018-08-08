% Author: Alana Gudinas
% 31 July 2018
%
% [appHeightVec,areaVec] = DefectStats(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,nmWidth) 
%
% This function outputs statistical information about the defects in an STM
% image. The inputs are: (defCoords) the x and y coordinates of the defects, 
% (ImLineFlat) the line flattened image, (ImFlatSMooth) the fully processed
% image, and (nmWidth) the width of the image in nanometers, calculated in 
% STM DEFECT ANALYSIS.
%
%------------------------------------------------------------------------------------%

function [maxHeightVec,meanHeightVec,areaVec,centData] = DefectStats(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,nmWidth) 

global help_dlg
global output_graph

if help_dlg
    dastr = 'The apparent height and area statistics of the identified defects will now be computed.';
    hd = helpdlg(dastr,'Defect Analysis');
    waitfor(hd);
end

% Start by calculating the area of each defect by creating a binary image
% of each contour plot (which represents a defect) 

[rI,cI] = size(ImFlatSmooth);

nx = length(defCoordsX(1,:));
defArea = zeros(nx,1); % Create empty vector to store the area data.
centData = zeros(nx,2);
xInt = defCoordsX;
yInt = defCoordsY;

for i = 1:nx
    xInt = defCoordsX(:,i);
    yInt = defCoordsY(:,i);
    xInt(isnan(xInt)) = [];
    yInt(isnan(yInt)) = [];
    imBi = poly2mask(xInt,yInt,rI,cI); % Creates binary image from contour coordinates.
    defArea(i) = bwarea(imBi); % Compute area of any white pixels in binary image.
    s = regionprops(imBi,'Centroid'); % Find coordinates of center of defect.
    centRef = cat(1, s.Centroid);
    centData(i,1) = centRef(1);
    centData(i,2) = centRef(2);
end

% Next, compute apparent height statistics.
% Start by rescaling the line-flattened image to recover original pixel
% brightnes data.

ImLine = ImLineFlat;
ImLine = ImLine + abs(min(min(ImLine))); % In case of negative brightness values, normalize data so that the darkest spots are 0.

minlim = min(min(ImLine));
maxlim = max(max(ImLine)); % For rescaling image.

close all

if output_graph
    figure;imshow(ImLine); title('Line Flattened Image Data');
    colorbar
    lim = caxis;
    caxis([minlim maxlim]); % Change image scale for visualization and calculations.

    hold on
end

maxHeightVec = zeros(nx,1); % Empty variables for apparent height stats.
meanHeightVec = zeros(nx,1);

for i = 1:nx
    defY = defCoordsY(:,i);
    defY(isnan(defY)) = [];
    if ~isempty(defY)
        [y(2),yIdx(2)] = max(defY); % Find the max and min y value of each contour.
        [y(1),yIdx(1)] = min(defY);
        x(2) = defCoordsX(yIdx(2),i);
        x(1) = defCoordsX(yIdx(1),i);
        c = improfile(ImLine,x,y); % improfile records the brightness data along a line in the image.
        maxHeightVec(i) = max(c);
        meanHeightVec(i) = mean(c);
        if output_graph
            plot(x,y,'Color','red') % Plot the crossection of the defect for user visualization.
            hold on
        end
    end
end

if output_graph
    plot(defCoordsX,defCoordsY,'Color','yellow')
end

maxHeightVec = maxHeightVec * 1e9; % Change units to nm, since original data is in m. 
meanHeightVec = meanHeightVec * 1e9;

% The previously computed area vector is not accurate, need to compute a
% scale for the image. The size of the image represents the number of
% pixels in the width and height. The width data is in the original .mat
% structure.

imScale = rI/nmWidth; % imScale represents what 1 nm is in the image.
imSq = (imScale)^2; % imSq represents 1 nm^2. 

% For example: if scale is 1 nm = 512/50 pixels
% 1 nm^2 = (512/50)^2 pixels^2

defAreaScale = defArea/imSq;

% For plotting purposes:
%szV = defAreaScale .* 5;
szV = 40;
xrange = [1:1:nx]';

if output_graph
    figure; scatter(xrange,defAreaScale,szV,[102/255,0/255,204/255],'filled'); title('Identified Defect Areas','FontSize',15); 
    hold on
    xlabel('Index','FontSize',15);
    ylabel('Area (nm^2)','FontSize',15);
    hold off
end

maxHSort = sort(maxHeightVec);
meanHSort = sort(meanHeightVec);

if output_graph
    sz = 50;
    figure; scatter(xrange,maxHSort,sz,[0/255,0/255,204/255],'filled'); title('Defect Apparent Heights','FontSize',15);
    hold on
    scatter(xrange,meanHSort,sz,[225/255,116/255,7/255],'filled');
    xlabel('Index','FontSize',15);
    ylabel('Apparent Height (nm)','FontSize',15);
    legend('Maximum Height (nm)','Average Height (nm)','Location','northwest')
    hold off
end

areaVec = defAreaScale;

end