% Author: Alana Gudinas
% 31 July 2018
%
% [appHeightVec,areaVec] = DefectStats(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,ImUniBg,nmWidth) 
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

function [defStats,regionStats,xCoords,yCoords] = DefectStats(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,ImUniBg,nmWidth,ImZ) 

%%%%%%%you need to include dark defects as well%%%%%%%%%

global help_dlg
global output_graph
global metaDataFile

defStats = [];

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

ImBW = zeros(rI,cI);
defX = defCoordsX;
defY = defCoordsY;
[ny,nx] = size(defX);
defArea = [];
centDef = [];

for i = 1:nx    
    xi = defX(:,i);
    yi = defY(:,i);
    xi(isnan(xi)) = [];
    yi(isnan(yi)) = [];
    polyin = polyshape(xi,yi);
    [centX,centY] = centroid(polyin);
    centDef(i,:) = [centX , centY];
    Im_binR = poly2mask(xi,yi,rI,cI); % Im_binR is a binary image containing only the selected defect in white.
    defArea(i) = bwarea(Im_binR);
    ImBW = imfuse(ImBW,Im_binR);
end

ImBW = rgb2gray(ImBW);
ImBW = imbinarize(ImBW);

s = regionprops(ImBW,'Centroid','Eccentricity','MajorAxisLength','MinorAxisLength','Orientation'); % Find coordinates of center of defect.
centData = cat(1, s.Centroid);

if output_graph
    imshow(ImBW,[]);
    hold on
end

xMat = [];
yMat = [];
thetaVec = [];

%------------------
% the following is from Steve Eddins: https://blogs.mathworks.com/steve/2010/07/30/visualizing-regionprops-ellipse-measurements/
phi = linspace(0,2*pi,50);
cosphi = cos(phi);
sinphi = sin(phi);

for k = 1:length(s)
    xbar = s(k).Centroid(1);
    ybar = s(k).Centroid(2);

    a = s(k).MajorAxisLength/2;
    b = s(k).MinorAxisLength/2;

    theta = pi*s(k).Orientation/180;
    thetaVec(k) = s(k).Orientation;
    
    R = [ cos(theta)   sin(theta)
         -sin(theta)   cos(theta)];

    xy = [a*cosphi; b*sinphi];
    xy = R*xy;

    x = xy(1,:) + xbar;
    y = xy(2,:) + ybar;

    thetaT = -theta;
    xuM = xbar + a*cos(thetaT);
    xbM = xbar - a*cos(thetaT);
    yuM = ybar + a*sin(thetaT);
    ybM = ybar - a*sin(thetaT);
    xM = [xuM, xbM];
    yM = [yuM, ybM];
    
    dev = 7;
    xMat(1,k) = xbM-dev;
    xMat(2,k) = xuM+dev;
    yMat(1,k) = ybM-dev;
    yMat(2,k) = yuM+dev;
    
   % thetaVec(k) = thetaT;
    
    if output_graph
        plot(x,y,'r','LineWidth',2);
        hold on
        plot(xM,yM,'Color','blue')
    end
end
%------------------
hold off

% Next, compute apparent height statistics.
% Start by rescaling the line-flattened image to recover original pixel
% brightnes data.

ImLine = ImLineFlat;
ImLine = ImLine + abs(min(min(ImLine))); % In case of negative brightness values, normalize data so that the darkest spots are 0.

minlim = min(min(ImLine));
maxlim = max(max(ImLine)); % For rescaling image.

maxHeightVec = zeros(length(s),1); % Empty variables for apparent height stats.
meanHeightVec = zeros(length(s),1);

prompt = 'Specify whether to take a cross-section of the defects along the major or horiztontal axis for statistical analysis. [Major/H]';
definput = {'Major'};
titleBox = 'Apparent Height Statistics';
dims = [1 60];
vh = inputdlg(prompt,titleBox,dims,definput);
vh = vh{1};

% figure;
% cprofile = gca;
% 
% [ ImUniFl, ImUniFl2 ] = UniformBackground(ImZ);
% 
% imshow(ImUniFl,[])

nx = length(defCoordsX(1,:));
vt = 0;
figure;

if strcmp(vh,'Major')
    for i = 1:length(s)
        c = improfile(ImLineFlat,xMat(:,i),yMat(:,i)); % improfile records the brightness data along a line in the image.
        maxHeightVec(i) = max(c);
        meanHeightVec(i) = mean(c);
        xprof = 1:1:length(c);
        plot(xprof,c+vt)% this is returning a figure for every single defect--beware!!
        hold on
        grid on
        xlabel('Pixels','FontSize',15);
        ylabel('Apparent height (nm)','FontSize',15);
        vt = vt + 0.5e-11;
    end
    hold off
elseif strcmp(vh,'Minor')
    %nothing yet
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

if output_graph
    figure;imshow(ImLine); title('Line Flattened Image Data');
    colorbar
    clim = caxis;
    caxis([minlim maxlim]); % Change image scale for visualization and calculations.
    hold on
    plot(defCoordsX,defCoordsY,'Color','yellow')
    hold off
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
xrange = [1:1:length(s)];
axrange = [1:1:length(defArea)];

if output_graph
    figure; scatter(axrange,defAreaScale,szV,[102/255,0/255,204/255],'filled'); %title('Identified Defect Areas','FontSize',15); 
    hold on
    xlabel('Index','FontSize',15);
    ylabel('Area (nm^2)','FontSize',15);
    hold off
end

maxHSort = sort(maxHeightVec);
meanHSort = sort(meanHeightVec);

if output_graph
    sz = 50;
    figure; scatter(xrange,maxHSort,sz,[0/255,0/255,204/255],'filled'); %title('Defect Apparent Heights','FontSize',15);
    hold on
    scatter(xrange,meanHSort,sz,[225/255,116/255,7/255],'filled'); 
    xlabel('Index','FontSize',15);
    ylabel('Apparent Height (nm)','FontSize',15);
    legend('Maximum Height (nm)','Average Height (nm)','Location','northwest')
    grid on
    hold off
end

fprintf(fileID,formatSpec,'Apparent height and area vectors computed');
areaVec = defAreaScale;

%%%% option to add other line profiles

regionStats = s;


% finally, re-order both sets so that they match.
% need two vectors of the centroid data

centReg = centData;

nR = length(centReg(:,1));
nD = length(centDef(:,1));
centDefCorrect = NaN(nD,2);
maxHeightCorr = NaN(nD,1);
meanHeightCorr = NaN(nD,1);
xCoords = NaN(ny,nD);
yCoords = NaN(ny,nD);


for i = 1:nR
 %Calculate the shortest distance and select that index
    distanceFromSet = sqrt((centReg(i,1)-centDef(:,1)).^2 + (centReg(i,2)-centDef(:,2)).^2);
    
    %pull out the index of the closest location from set two
    [~,min_index] = min(distanceFromSet);
    
    centDefCorrect(i,1:2) = centDef(min_index,1:2);
    maxHeightCorr(i) = maxHeightVec(min_index);
    meanHeightCorr(i) = meanHeightVec(min_index);
    xCoords(:,i) = defX(:,min_index);
    yCoords(:,i) = defY(:,min_index);
    
end

maxHeightVec = maxHeightCorr;
meanHeightVec = meanHeightCorr;
defStats = [maxHeightVec , meanHeightVec];

% figure; histogram(thetaVec)
% hold on
% a = 40;
% b = 100;
% line([b, b], [0, 10], 'Color', 'r', 'LineWidth', 2);
% line([a, a], [0, 10], 'Color', 'r', 'LineWidth', 2);
% hold off
% 
% figure; imshow(ImUniBg,[])
% hold on
% 
% for i = 1:nx
%     if thetaVec(nx) > a
%         plot(defX(:,nx),defY(:,nx),'Color','cyan')
%         drawnow
%         hold on
%     end
% end

end