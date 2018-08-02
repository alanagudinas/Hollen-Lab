% Author: Alana Gudinas
% July 18, 2018

function [ NestedContoursCell, xdataC, ydataC,heightVec, Method] = NestedContours(ImUniBg,meanPix)

meanP = mean(ImUniBg(:));

str = 'Are you interested in first identifying bright or dark defects? Type "B" for bright defects, and "D" for dark defects.';
promptdef = {str};
titleBox = 'Defect Brightness Selection';
dims = [1 60];
definput = {'B'};
defAns = inputdlg(promptdef,titleBox,dims,definput);
defAns = defAns{1};


if strcmp(defAns,'B')
    Method = 'Bright';
elseif strcmp(defAns,'D')
    Method = 'Dark';
end

[ C, hdata, idx, vtx, xdata, ydata, heightVec ] = ContourData(ImUniBg,Method,meanPix);

xdataC = xdata;
ydataC = ydata;
nd = length(xdata(1,:));
k = 1;

if strcmp(Method, 'Bright')
    idxVec = [1:1:nd];
elseif strcmp(Method, 'Dark')
    idxVec = [nd:-1:1];
end

for i = idxVec
    if ~all(isnan(xdata(:,i)))
        NestC{1,k} = [ ];
        NestC{2,k} = [ ];
        Xmax = max(xdata(:,i));
        Xmin = min(xdata(:,i));
        Ymax = max(ydata(:,i));
        Ymin = min(ydata(:,i));
        for j = 1:nd
            if j ~= i
                xmax = max(xdata(:,j));
                xmin = min(xdata(:,j));
                ymax = max(ydata(:,j));
                ymin = min(ydata(:,j));
                if ((Xmax > xmax) & (Xmin < xmin)) & ((Ymax > ymax) & (Ymin < ymin)) % then the ith contour is nested inside the jth contour
                    xC = xdata(:,j);
                    yC = ydata(:,j);
                    NestC{1,k} = [ NestC{1,k} , xC ];
                    NestC{2,k} = [ NestC{2,k} , yC ];
                    xdata(:,j) = NaN;
                    ydata(:,j) = NaN;        
                end  
            end
        end
        k = k + 1;
    end
end

[rC, cC] = size(NestC);

for i = 1:cC
    NestC{1,i} = [NestC{1,i}, xdata(:,i)];
    NestC{2,i} = [NestC{2,i}, ydata(:,i)];
end
    

NestedContoursCell = NestC;

end
                        
                    
        
