% Author: Alana Gudinas
% 29 December 2019
%
% [defCoordsX, defCoordsY, defCount, NestedContoursCell] = IdentifyDefects( Method,ImProc,ImLineFlat,meanPix )
%
% This function directs the image data to either SHAPEDATA or FILTERDATA
% based on the user's choice for defect identification.
%
% Inputs
% 'Method': S or F for shape matching or filtering.
% 'ImProc': processed image after using GUI.
% 'ImLineFlat': line-flattened image produced from GUI.
% 'meanPix': mean pixel value in the image.
%
% Outputs are described in 'DIST'.
%
%------------------------------------------------------------------------------------%

function [defCoordsX, defCoordsY, defCount, NestedContoursCell] = IdentifyDefects(Method,ImProc,ImLineFlat,meanPix)

global metaDataFile
fileID = fopen(metaDataFile,'a+');

if strcmp(Method,'Filters')
    [defCoordsX,defCoordsY,NestedContoursCell] = FilterData(ImProc,ImLineFlat,meanPix);
elseif strcmp(Method, 'Shape')
    [defCoordsX,defCoordsY,NestedContoursCell] = ShapeData(ImProc,ImLineFlat,meanPix);
end

figure; imshow(ImLineFlat,[]); title('Identified Defects');
hold on
plot(defCoordsX,defCoordsY,'Color','red','LineWidth',4);
hold off

defCount = numel(findobj(gcf,'Type','line')); % counts all the plotted defects in the image

formatSpec = 'Number of identified defects: %d\n';
fprintf(fileID,formatSpec,defCount);

% waitfor(close) 
end
