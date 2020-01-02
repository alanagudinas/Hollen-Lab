function [NestedContoursCell,defCoordsX,defCoordsY] = FilterNest(xdata, ydata, ImUniBg)

global hMethod 
nd = length(xdata(1,:));
k = 1;
NestC = [];
[rU, cU] = size(ImUniBg);

% Contour data is arranged in order from lowest to highest brightness
% levels. The indexing order depends on interest in either bright or dark
% defects.

if hMethod
    idxVec = [1:1:nd];
else
    idxVec = [nd:-1:1];
end

for i = idxVec
    if ~all(isnan(xdata(:,i)))
        NestC{1,k} = [xdata(:,i)];
        NestC{2,k} = [ydata(:,i)];
        Xmax = max(xdata(:,i));
        Xmin = min(xdata(:,i));
        Ymax = max(ydata(:,i));
        Ymin = min(ydata(:,i));
        for j = 1:nd
            if j ~= i
                xmax = max(xdata(:,j));
                xmin = min(xdata(:,j));
                ymax = max(ydata(:,j));
                ymin = min(ydata(:,j)); % If the coordinates of a contour plot falls within another, store them in the same cell.
                if ((Xmax > xmax) & (Xmin < xmin)) & ((Ymax > ymax) & (Ymin < ymin)) % then the ith contour is nested inside the jth contour
                    xC = xdata(:,j);
                    yC = ydata(:,j);
                    NestC{1,k} = [ NestC{1,k} , xC ];
                    NestC{2,k} = [ NestC{2,k} , yC ];
                    xdata(:,j) = NaN(length(xdata(:,1)),1);
                    ydata(:,j) = NaN(length(ydata(:,1)),1);        
                end  
            end
        end
        k = k + 1;
    end
end

coNest = NestC;

areaVec = [];

[rN, cN] = size(coNest);

defCoordsX = [];
defCoordsY = [];

for j = 1:cN 
    [rt,ct] = size(coNest{1,j});
    areaVec = [];
    for i = 1:ct
        xCoord = coNest{1,j}(:,i);
        yCoord = coNest{2,j}(:,i);
        xCoord(isnan(xCoord)) = [];
        yCoord(isnan(yCoord)) = [];
        if ~isempty(xCoord)
            if ((xCoord(1) == xCoord(end)) && (yCoord(1) == yCoord(end))) % only store closed loops
                ImBWComp = poly2mask(xCoord,yCoord,rU,cU); % binary image of contours
                imA = bwarea(ImBWComp);
                areaVec = [areaVec; imA];
            end
        end
    end
    [~,idm] = max(areaVec);
    defCoordsX = [defCoordsX, coNest{1,j}(:,idm)]; % add coordinates to output
    defCoordsY = [defCoordsY, coNest{2,j}(:,idm)];
end

NestedContoursCell = coNest;

end