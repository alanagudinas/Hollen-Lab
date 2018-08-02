% Author: Alana Gudinas
% July 9, 2018
%
% function [ ] = IdentifyDefects( ImUniBig, Method )
%
% The purpose of this function is to accurately identify all the defects
% (regardless of brightness) within an STM image, after its background
% uniformity has been improved.
%
% The input is ImUniBg, an image with a uniform background created by
% "UniformBackground."
% The function returns ContCoords, the coordinates of all the defect
% contours.
% "Method" can either be Height Comparison or Shape Matching. 
%
%------------------------------------------------------------------------------------%

function [ defCoordsX, defCoordsY, defCount] = IdentifyDefects(Method,ImUniBg,ImLineFlat,ImFlatSmooth,meanPix)

if strcmp(Method,'Filters')
    [defCoordsX,defCoordsY] = FilterData(ImUniBg,ImLineFlat,ImFlatSmooth,meanPix);
elseif strcmp(Method, 'Shape')
    [defCoordsX,defCoordsY] = ShapeData(ImUniBg,ImLineFlat,ImFlatSmooth,meanPix);
end

figure; imshow(ImFlatSmooth,[]); title('Identified Defects');
hold on
plot(defCoordsX,defCoordsY,'Color','yellow');

defCount = numel(findobj(gcf,'Type','line'));
% also need to include some advice and guidance, like how to select the
% most useful defects etc. I think that will provide a happy medium between
% user input and automation. nothing competes with the human eye and it's
% okay to utilize that, especially to store info for batch processing in
% the future