% Author: Alana Gudinas
% July 20, 2018
%
% [defCoordsX, defCoordsY] = NestedShapeMatching(ImUniBg, NestedContoursCell, xdataC, ydataC)
%
% This function performs shape matching on groups of nested contours to
% prevent more than one contour in the same region from being identified.
% The shape matching is done with Oliver Van Kaick's ACO algorithm. 
%
% https://www.mathworks.com/matlabcentral/fileexchange/24094-contour-correspondence-via-ant-colony-optimization
%
% The inputs are: (ImUniBg) the output of UNIFORM BACKGROUND,
% (NestedContoursCell) a cell array, and (dataC) matrices of the contour
% data.
% The outputs are (defCoords) the coordinates of the defect plots resulting
% from the shape matching.
%------------------------------------------------------------------------------------%


function [defCoordsX, defCoordsY] = NestedShapeMatching(ImUniBg, NestedContoursCell, xdataC, ydataC)

global hMethod

nx = length(xdataC(1,:));

if hMethod
    idxN = [1:1:nx];
else
    idxN = [nx:-1:1];
end

figure; imshow(ImUniBg,[]); title('Defect that will be used in shape-matching comparison');
hold on
plot(xdataC,ydataC,'Color',[173/255;255/255;47/255]); % Plot all the contour lines in the image.


shapehelp = 'Select a rectangular region of the image that contains contour lines you are interested in.';
h1 = helpdlg(shapehelp,'Contour Selection');
waitfor(h1);

rect = getrect; % Prompt user to use rectangle selection to choose a region with a defect of interest.
    
close all

for k = idxN
    xint = xdataC(:,k); % temporary variable
    yint = ydataC(:,k);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = []; % if statement below checks if the contour lies within the rectangle
    if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xint;
        yi = yint;
        plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
        drawnow
        hold on
    end
end
hold off

shapehelp2 = 'Of the cluster of contour lines, select the shape of the defect you are interested. Be sure to completely enclose the shape of interest with the rectangle. The largest line completely inside the rectangle will be chosen as the template defect.';
h2 = helpdlg(shapehelp2,'Template Selection');
waitfor(h2);

rect = getrect; % Prompt user to select which line they are interested in. 

close all

figure; imshow(ImUniBg,[]);
hold on

for k = idxN
    xint = xdataC(:,k);
    yint = ydataC(:,k);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = [];
    if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xint;
        yi = yint;
        plot(xi,yi,'Color','cyan') % Plot template on image so user can see their selection. 
        break
    end
end
hold off

shapehelp3 = 'The template defect is displayed on the uniform background image.';
h3 = helpdlg(shapehelp3,'Display');
waitfor(h3);
pause(2)
close all

Y1 = [xi, yi]; % variable for shape-matching function.

% create new vertex vector 
vtx = [];
for i = 1:nx
    xfd = xdataC(:,i);
    xfd(isnan(xfd)) = [];
    num = length(xfd);
    vtx(i) = num;
end

coNest = NestedContoursCell;
[rN,cN] = size(coNest);
bestcost = [];
defCoordsX = [];
defCoordsY = [];

figure; imshow(ImUniBg,[]);
hold on
plot(xdataC,ydataC,'Color',[173/255;255/255;47/255]);

shapehelp4 = 'The shape matching process will begin once this window is closed. It may take a while to run through all of the defects. Once the best fitting shape within each contour cluster has been identified, it will be plotted on the image in yellow.';
h4 = helpdlg(shapehelp4,'Shape Matching');
waitfor(h4);

bestvec = [];
for j = 1:cN
    [rt,ct] = size(coNest{1,j});
    for i = 1:ct
        xCoord = coNest{1,j}(:,i); % temporary variable 
        yCoord = coNest{2,j}(:,i);
        if all(isnan(xCoord))
            bestcost = [bestcost, NaN]; % placeholder for indexing purposes
            continue
        end
        xCoord(isnan(xCoord)) = []; % can't have NaN entries for shape-matching 
        yCoord(isnan(yCoord)) = [];
        if (xCoord(1) == xCoord(end)) && (yCoord(1) == yCoord(end)) % only identify closed loops
            Y2 = [xCoord, yCoord];
            [~,~, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare');
            bestcost = [bestcost, best_cost]; % create vector of "best cost" for each shape within one nest
        end
    end
    [minB,idxB] = min(bestcost); % the lowest cost indicates the best matching shape 
    plot(coNest{1,j}(:,idxB),coNest{2,j}(:,idxB),'Color','magenta'); % plot the shape that best matches the template
    drawnow
    defCoordsX = [defCoordsX, coNest{1,j}(:,idxB)]; % add coordinates to output
    defCoordsY = [defCoordsY, coNest{2,j}(:,idxB)];
    bestcost = []; % reset
end
hold off


end

