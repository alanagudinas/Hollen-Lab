% Author: Alana Gudinas
% 8 August 2018
%
% bestcost = ShapeSimilarity(defCoordsX, defCoordsY, ImFlatSmooth) generates a vector
% of the best_cost value between a target shape and all the identified 
% defects in an image. 
%
% The inputs must be the coordinates of the defects and a processed STM 
% image, and the output is a vector containing a similarity value 
% associated with each defect. The user must select a target defect shape.
%
% defCoordsX/Y and ImFlatSmooth must be matrices. 

function [ bestcost ] = ShapeSimilarity( defCoordsX, defCoordsY, ImFlatSmooth ) 

figure; imshow(ImFlatSmooth,[]);
hold on
plot(defCoordsX,defCoordsY,'Color','cyan');
hold off

[~,nd] = size(defCoordsX);
rect = getrect; % allow user to draw rectangle around reference shape in the image

for i = 1:nd % find the coordinates that lie within that shape
    xint = defCoordsX(:,i);
    yint = defCoordsY(:,i);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = []; 
    if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4))))
        xi = xint;
        yi = yint;
    end
end
close 

Y1 = [xi,yi]; % variable for shape matching algorithm
bestcost = [];

% now need to loop through all the other coordinates and compare shape to
% template shape

for i = 1:nd
    xint = defCoordsX(:,i);
    yint = defCoordsY(:,i);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = []; 
    Y2 = [xint, yint];
    [~,~, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare');
    bestcost = [bestcost, best_cost]; % add new values to vector
end

figure; imshow(ImFlatSmooth,[]);
hold on
plot(defCoordsX,defCoordsY,'Color','cyan');
hold off

formatSpec = "%.8f";
str = compose(formatSpec,bestcost);

x = min(defCoordsX);
y = max(defCoordsY);

text(x,y,str,'Color','yellow');

end