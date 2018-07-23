function [ ] = NestedShapeMatching( ImUniBg )

[NestedContoursCell, xdataC, ydataC] = NestedContours(ImUniBg);

meanP = mean(ImUniBg(:));

figure; imshow(ImUniBg,[]);
hold on
plot(xdataC,ydataC,'Color',[173/255;255/255;47/255]) % Plot all the contour lines in the image.
hold off

rect = getrect; % Prompt user to use rectangle selection to choose a region with a defect of interest.

disp('Please select a region containing a defect of interest.');
    
close all

for k = 1:length(xdataC(1,:))
    xint = xdataC(:,k);
    yint = ydataC(:,k);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = []; 
    if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xint;
        yi = yint;
        plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
        drawnow
        hold on
    end
end
hold off

disp('Please select which brightness level you are interested in. The bigger loop represents a darker region. The lowest brightness line will automatically be selected within the rectangle.');

rect = getrect; % Prompt user to make another selection.

close all

figure; imshow(ImUniBg,[]);
hold on

for k = 1:length(xdataC(1,:))
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

pause(1)

Y1 = [xi, yi]; % variable for shape-matching function.

% create new vertex vector 
vtx = [];
for i = 1:length(xdataC(1,:))
    xfd = xdataC(:,i);
    xfd(isnan(xfd)) = [];
    num = length(xfd);
    vtx(i) = num;
end
xint = [];
yint = [];
diffArea = AreaDifference(xi,yi,xdataC,ydataC);

xFilt = [];
yFilt = [];
k = 1;

for i = 1:length(xdataC(1,:))
    xint = xdataC(:,i);
    yint = ydataC(:,i);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = [];
    if ((diffArea(i)<100) && (vtx(i)>20)) && (xint(1) == xint(end))
        xFilt(:,k) = xdataC(:,i);
        yFilt(:,k) = ydataC(:,i);
        k = k + 1;
    end
end

[rFilt,cFilt] = size(xFilt);

coNest = NestedContoursCell;
[rN,cN] = size(coNest);
bestcost = [];

figure; imshow(ImUniBg,[])
hold on

for j = 1:cN
    [~,ct] = size(coNest{1,j});
    for i = 1:ct
        xCoord = coNest{1,j}(:,i);
        yCoord = coNest{2,j}(:,i);
        xCoord(isnan(xCoord)) = [];
        yCoord(isnan(yCoord)) = [];
        Y2 = [xCoord, yCoord];
        [~,~, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare');
        bestcost = [bestcost, best_cost];
    end
    [minB,idxB] = min(bestcost);
    plot(coNest{1,j}(:,idxB),coNest{2,j}(:,idxB),'Color','yellow')
    bestcost = [];
end
hold off


end

