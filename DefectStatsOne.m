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
% The outputs are:
% maxHeightVec: a vector of the maximum apparent brightness of each defect
% (the brightness data is taken over a line drawn vertically across the
% defect contour)
% meanHeightVec: a vector of the avearage apparent brightness of each
% defect
% areaVec: a vector of the area (to scale) of each defect, based on the
% contour plot
% centData: an array of the coordinates of the centroid of each defect
% contour

function [maxHeightVec,meanHeightVec,areaVec,centData] = DefectStatsOld(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,nmWidth) 
%you need to include dark defects as well
global help_dlg
global output_graph
global metaDataFile

fileID = fopen(metaDataFile,'a+'); % open txt file
formatSpec = '%s\n';

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
    if ~isempty(xInt)
        imBi = poly2mask(xInt,yInt,rI,cI); % Creates binary image from contour coordinates.
        defArea(i) = bwarea(imBi); % Compute area of any white pixels in binary image.
        s = regionprops(imBi,'Centroid'); % Find coordinates of center of defect.
        centRef = cat(1, s.Centroid);
        centData(i,1) = centRef(:,1);
        centData(i,2) = centRef(:,2);
    end
end

% Next, compute apparent height statistics.
% Start by rescaling the line-flattened image to recover original pixel
% brightnes data.

ImLine = ImLineFlat;
ImLine = ImLine + abs(min(min(ImLine))); % In case of negative brightness values, normalize data so that the darkest spots are 0.

minlim = min(min(ImLine));
maxlim = max(max(ImLine)); % For rescaling image.


if output_graph
    figure;imshow(ImLine); title('Line Flattened Image Data');
    colorbar
    lim = caxis;
    caxis([minlim maxlim]); % Change image scale for visualization and calculations.
    hold on
end

maxHeightVec = zeros(nx,1); % Empty variables for apparent height stats.
meanHeightVec = zeros(nx,1);

prompt = 'Specify whether to take a vertical or horizontal cross-section of the defects for apparent height statistics: [V/H]';
definput = {'V'};
titleBox = 'Apparent Height Statistics';
dims = [1 60];
vh = inputdlg(prompt,titleBox,dims,definput);
vh = vh{1};

cdata = [];
cxdata = [];
cydata = [];

if strcmp(vh,'V')
    for i = 1:nx
        defY = defCoordsY(:,i);
        defY(isnan(defY)) = [];
        if ~isempty(defY)
            [y(2),yIdx(2)] = max(defY); % Find the max and min y value of each contour.
            [y(1),yIdx(1)] = min(defY);
            x(2) = defCoordsX(yIdx(2),i);
            x(1) = defCoordsX(yIdx(1),i);
            y(2) = y(2) + 5;
            y(1) = y(1) - 5;
            c = improfile(ImLine,x,y); % improfile records the brightness data along a line in the image.
            maxHeightVec(i) = max(c);
            meanHeightVec(i) = mean(c);
            if output_graph
                plot(x,y,'Color','red') % Plot the crossection of the defect for user visualization.
                hold on
            end
        end
    end
elseif strcmp(vh,'H')
    for i = 1:nx
        defX = defCoordsX(:,i);
        defX(isnan(defX)) = [];
        if ~isempty(defX)
            [x(2),xIdx(2)] = max(defX); % Find the max and min y value of each contour.
            [x(1),xIdx(1)] = min(defX);
            y(2) = defCoordsY(xIdx(2),i);
            y(1) = defCoordsY(xIdx(1),i);
            x(2) = x(2) + 5;
            x(1) = x(1) - 5;
            [cx,cy,c] = improfile(ImLine,x,y,50); % improfile records the brightness data along a line in the image.
            maxHeightVec(i) = max(c);
            meanHeightVec(i) = mean(c);
            cdata(:,i) = c;
            cxdata(:,i) = cx;
            cydata(:,i) = cy;
            if output_graph
                plot(x,y,'Color','red') % Plot the crossection of the defect for user visualization.
                hold on
            end
        end
    end
end

if output_graph
    plot(defCoordsX,defCoordsY,'Color','yellow')
    hold off
end

% for j = 1:nx
%     figure; plot3(cxdata(:,j),cydata(:,j),cdata(:,j),'Color','blue')
% end

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

fprintf(fileID,formatSpec,'Apparent height and area vectors computed');
areaVec = defAreaScale;

end