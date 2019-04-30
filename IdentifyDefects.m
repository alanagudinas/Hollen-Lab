% Author: Alana Gudinas
% July 9, 2018
%
% [defCoordsX, defCoordsY, defCount] = IdentifyDefects( ImUniBig, Method )
%
% The purpose of this function is to accurately identify all the defects
% (regardless of brightness) within an STM image, after its background
% uniformity has been improved.
%
% The inputs are: (Method) the chosen method of defect identification, 
% (ImUniBg) an image with a uniform background created by UNIFORM BACKGROUND,
% (ImLineFlat) the line flattened image, (ImFlatSmooth) the processed
% image, and (meanPix) an output of UNIFORM BACKGROUND.
%
% The function returns defCoords, the coordinates of all the defect
% contours, and defCount, the number of identified defects.
% 
% "Method" can either be Height Comparison or Shape Matching. 
%
%------------------------------------------------------------------------------------%

function [ defCoordsX, defCoordsY, defCount] = IdentifyDefects(Method,ImUniBg,ImLineFlat,meanPix)

global metaDataFile
fileID = fopen(metaDataFile,'a+');

if strcmp(Method,'Filters')
    [defCoordsX,defCoordsY] = FilterData(ImUniBg,ImLineFlat,meanPix);
elseif strcmp(Method, 'Shape')
    [defCoordsX,defCoordsY] = ShapeData(ImUniBg,ImLineFlat,meanPix);
end

figure; imshow(ImLineFlat,[]); title('Identified Defects');
hold on
plot(defCoordsX,defCoordsY,'Color','red','LineWidth',4);

defCount = numel(findobj(gcf,'Type','line')); % counts all the plotted defects in the image

formatSpec = 'Number of identified defects: %d\n';
fprintf(fileID,formatSpec,defCount);

waitfor(close) 
end
