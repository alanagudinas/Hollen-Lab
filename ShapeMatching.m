% Author: Alana Gudinas
% July 10, 2018
%
% function [ ContCoordsX, ContCoordsY, defCount ] = ShapeMatching( ImUniBg, C )
% The purpose of this function is to isolate the defects in an STM image
% using a shape-matching algorithm. The contour correspondence between two
% defects is determined using an Ant Colony Optimization program written in
% MATLAB by Oliver Van Kaick. 
% 
% Reference: O. van Kaick, G. Hamarneh, H. Zhang, P. Wighton 
% "Contour Correspondence via Ant Colony Optimization" 
% Proc. 15th Pacific Conference on Computer Graphics and Applications (Pacific Graphics 2007), pp. 271-280, 2007. 
% http://dx.doi.org/10.1109/PG.2007.56
%
% The input ImUniBg is a uniform background image, and "C" is the contour
% plot data of the image. This function is used in "IdentifyDefects."
% The outputs are the contour plot coordinates for all the identified
% defects in the image. defCount is the number of defects identified in the
% image.


function [ ContCoordsX, ContCoordsY, defCount ] = ShapeMatching( ImUniBg )

meanP = mean(ImUniBg(:));

[ NestedContoursCell ] = NestedContours(ImUniBg,ImStruct)

xdata1 = zeros(500,length(idx));
ydata1 = zeros(500,length(idx));

xdata2 = zeros(500,length(idx));
ydata2 = zeros(500,length(idx));

figure; imshow(ImUniBg,[]);
hold on
plot(xdata,ydata,'Color',[173/255;255/255;47/255]) % Plot all the contour lines in the image.

hold off

rect = getrect; % Prompt user to use rectangle selection to choose a region with a defect of interest.

disp('Please select a region containing a reference defect.');

close all

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k)); % Generate contour plots.
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xdata;
        yi = ydata;
        plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
        drawnow
        hold on
    end
end
hold off

disp('Please select which brightness you are interested in. The bigger loop represents a darker region. The lowest brightness line will automatically be selected within the rectangle.');

rect = getrect; % Prompt user to make another selection.

close all

figure; imshow(ImUniBg,[]);
hold on

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k)); % Same process as above. Re-generating data because it is a pain to store. (will store eventually)
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4))))
        xi = xdata;
        yi = ydata;
        shapeH = C(1,idx(k));
        plot(xi,yi,'Color','cyan') % Plot template on image so user can see their selection. 
        break
    end
end
hold off

pause(1)

Y1 = [xi', yi']; % variable for shape-matching function. 

diffArea = AreaDifference(xi,yi,C,idx,vtx);

figure; imshow(ImUniBg,[])
hold on

% I want to see if shapeH is higher or lower than the average pixel value. 

avgH = mean(ImUniBg(:));

xIn = zeros(500,length(diffArea));
yIn = zeros(500,length(diffArea));

xdataI = zeros(500,length(diffArea));
ydataI = zeros(500,length(diffArea));

figure; imshow(ImUniBg,[]);
hold on

if shapeH > avgH
    for i = 1:length(diffArea)
        if ((diffArea(i)<250) && (vtx(i)>50)) && (C(1,idx(i)) == shapeH)
            xIn(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i)); % Store somewhat filtered contour data.
            yIn(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i)); 
            plot(xIn(1:vtx(i),i),yIn(1:vtx(i),i),'Color','cyan');
            drawnow
            hold on
           
        end
    end
    
    xIn( ~any(xIn,2), : ) = [];  
    xIn( :, ~any(xIn,1) ) = []; 
    yIn( ~any(yIn,2), : ) = [];  
    yIn( :, ~any(yIn,1) ) = []; 
    xIn(xIn == 0) = NaN;
    yIn(yIn == 0) = NaN;  
    [rIn,cIn] = size(xIn);
    % still need to remove contours WITHIN contours--via centroid method
    
rect = getrect;

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k)); % Generate contour plots.
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xdata;
        yi = ydata;
        plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
        drawnow
        hold on
    end
end
hold off

rect = getrect; % Prompt user to make another selection.

close all

figure; imshow(ImUniBg,[]);
hold on

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k)); % Same process as above. Re-generating data because it is a pain to store. (will store eventually)
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4))))
        xi = xdata';
        yi = ydata';
        xIn(1:vtx(k),cIn+1) = xi;
        yIn(1:vtx(k),cIn+1) = yi;
        plot(xi,yi,'Color','cyan') % Plot template on image so user can see their selection. 
        break
    end
end
hold off

close all

xIn( ~any(xIn,2), : ) = [];  
xIn( :, ~any(xIn,1) ) = []; 
yIn( ~any(yIn,2), : ) = [];  
yIn( :, ~any(yIn,1) ) = []; 
xIn(xIn == 0) = NaN;
yIn(yIn == 0) = NaN;  

[rIn,cIn] = size(xIn);

figure; imshow(ImUniBg,[])
hold on
plot(xIn,yIn,'Color','yellow')

rect = getrect;

for k = 1:length(idx)
    xdata = C(1,idx(k)+1:idx(k)+vtx(k)); % Same process as above. Re-generating data because it is a pain to store. (will store eventually)
    ydata = C(2,idx(k)+1:idx(k)+vtx(k));
    if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4))))
        xi = xdata';
        yi = ydata';
        xIn(1:vtx(k),cIn+1) = xi;
        yIn(1:vtx(k),cIn+1) = yi;
        plot(xi,yi,'Color','cyan') % Plot template on image so user can see their selection. 
        break
    end
end
hold off

close all

xIn( ~any(xIn,2), : ) = [];  
xIn( :, ~any(xIn,1) ) = []; 
yIn( ~any(yIn,2), : ) = [];  
yIn( :, ~any(yIn,1) ) = []; 
xIn(xIn == 0) = NaN;
yIn(yIn == 0) = NaN;  

figure; imshow(ImUniBg,[])
hold on
plot(xIn,yIn,'Color','yellow')


ContCoordsX = xIn;
ContCoordsY = yIn;

defCount = numel(findobj(gcf,'Type','line'));

    for i = 1:cIn
        xSh = xIn(:,i);
        ySh = yIn(:,i);
        xSh(isnan(xSh)) = [];
        ySh(isnan(ySh)) = []; 
        nd = length(xSh);
        Y2 = [xSh, ySh]; % for implementing in ACO algorithm, the contour data from each defect is recorded and used as an input.
        [K,S, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare'); % ACO program. This is where the magic happens.
        if best_cost<0.4 % best_cost represents how close in match two shapes are. 
            plot(xSh,ySh,'Color','yellow'); % Plot all the identified defects.
            drawnow
            hold on          
            xdataI(1:length(xSh),i) = xSh; % Store coordinates of identified plots.
            ydataI(1:length(ySh),i) = ySh;
            xdataI( ~any(xdataI,2), : ) = [];  
            xdataI( :, ~any(xdataI,1) ) = []; 
            ydataI( ~any(ydataI,2), : ) = [];  
            ydataI( :, ~any(ydataI,1) ) = []; 
            xdataI(xdataI == 0) = NaN;
            ydataI(ydataI == 0) = NaN;     
        end
    end
elseif shapeH < avgH % need to update this section accordingly
    for i = 1:length(diffArea)
        if ((diffArea(i)<150) && (vtx(i)>20)) && (C(1,idx(i)) <= shapeH)
            xIn(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            yIn(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i)); 
        end
    end
    xIn( ~any(xIn,2), : ) = [];  
    xIn( :, ~any(xIn,1) ) = []; 
    yIn( ~any(yIn,2), : ) = [];  
    yIn( :, ~any(yIn,1) ) = []; 
    xIn(xIn == 0) = NaN;
    yIn(yIn == 0) = NaN;  
    
    [rIn,cIn] = size(xIn);
    for i = cIn
        xSh = xIn(:,i);
        ySh = yIn(:,i);
        Y2 = [xSh', ySh']; % for implementing in ACO algorithm, the contour data from each defect is recorded and used as an input.
        [K,S, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare'); % ACO program. This is where the magic happens.
        if best_cost<0.4 % best_cost represents how close in match two shapes are. 
            plot(xSh,ySh,'Color','yellow'); % Plot all the identified defects.
            hold on
            drawnow           
            xdataI(1:length(xSh),i) = xSh; % Store coordinates of identified plots.
            ydataI(1:length(ySh),i) = ySh;

            xdataI( ~any(xdataI,2), : ) = [];  
            xdataI( :, ~any(xdataI,1) ) = []; 
            ydataI( ~any(ydataI,2), : ) = [];  
            ydataI( :, ~any(ydataI,1) ) = []; 
            xdataI(xdataI == 0) = NaN;
            ydataI(ydataI == 0) = NaN;              
        end
    end
end

hold off

prompt = 'Are all the defects in the image correctly identified? Y/N [Y]:';
shape1 = input(prompt,'s');

if strcmp(shape1,'Y')
   defCount = numel(findobj(gcf,'Type','line'));
   ContCoordsX = xdataI;
   ContCoordsY = ydataI;
   return
elseif strcmp(shape1,'N')
    prompt = 'Choose method for second round of identification: shape matching or height comparison. S/H [H]:';
    shape2 = input(prompt,'s');
    if strcmp(shape2,'S')
        close all
        figure; imshow(ImUniBg,[]);
        hold on
        for k = 1:length(idx)
            xdata = C(1,idx(k)+1:idx(k)+vtx(k));
            ydata = C(2,idx(k)+1:idx(k)+vtx(k));
            plot(xdata,ydata,'Color',[225/255;154/255;0/255]); % Plot all the contour data again.
            hold on
        end 
        plot(xdataI,ydataI,'Color','cyan'); % Plot defects identified in the last round.
        disp('The cyan lines indicate defects that have already been identified.');
        hold on
        disp('Please choose a second defect template.');
        rect = getrect;
        hold off
        
        close all
                
        x2 = [];
        y2 = [];
        
        for k = 1:length(idx)
            x2 = C(1,idx(k)+1:idx(k)+vtx(k)); % Again, cycle through all the contour data, since I don't want to have to store the data.
            y2 = C(2,idx(k)+1:idx(k)+vtx(k));
            if ((x2 > rect(1)) & (x2 < (rect(1)+rect(3)))) & ((y2 > rect(2)) & (y2 < (rect(2)+rect(4))))
                shapeH2 = C(1,idx(k));
                plot(x2,y2,'Color','blue')
                drawnow
                hold on
            end
        end 
        hold off
        disp('Please select which level you are interested in.');
        rect = getrect;
        
        x2 = [];
        y2 = [];
        xdata = [];
        ydata = [];
        
        figure; imshow(ImUniBg,[]);
        hold on
        for k = 1:length(idx)
            xdata = C(1,idx(k)+1:idx(k)+vtx(k));
            ydata = C(2,idx(k)+1:idx(k)+vtx(k));
            if ((xdata > rect(1)) & (xdata < (rect(1)+rect(3)))) & ((ydata > rect(2)) & (ydata < (rect(2)+rect(4))))
                x2 = xdata;
                y2 = ydata;
                shapeH2 = C(1,idx(k));
                plot(x2,y2,'Color','cyan') 
                break
            end
        end 
        
        hold off
        Y1 = [x2', y2'];
        pause(1)
        close all
        
        diffArea = AreaDifference(x2,y2,C,idx,vtx);
    
        figure; imshow(ImUniBg,[]);
        hold on
        
        for i = 1:length(diffArea)
            if ((diffArea(i)<250) && (vtx(i)>20)) && ((C(1,idx(i)) <= (shapeH2 + shapeH2/4)) && (C(1,idx(i)) >= (shapeH2 - shapeH2/4)))
                    xSh = C(1,idx(i)+1:idx(i)+vtx(i));
                    ySh = C(2,idx(i)+1:idx(i)+vtx(i)); 
                    
                     % if looping through a region already identified, skip 
                    Y2 = [xSh', ySh']; % for implementing in ACO algorithm, the contour data from each defect is recorded and used as an input.
                    [K,S, best_cost] = shape_matching(Y1,Y2, 'aco','shape_context','','chisquare'); % ACO program. This is where the magic happens.
                    if best_cost<0.4 % best_cost represents how close in match two shapes are. 
                        plot(xSh,ySh,'Color','yellow');
                        hold on
                        drawnow    
                       
                        xdataT(1:vtx(i),i) = xSh;
                        ydataT(1:vtx(i),i) = ySh;
            
                        xdataT( ~any(xdataT,2), : ) = [];  
                        xdataT( :, ~any(xdataT,1) ) = []; 
                        ydataT( ~any(ydataT,2), : ) = [];  
                        ydataT( :, ~any(ydataT,1) ) = []; 
                        xdataT(xdataT == 0) = NaN;
                        ydataT(ydataT== 0) = NaN;
                        
                    end
                end
            end
    end
end
hold off

xdata = [];
ydata = [];

[r1,c1] = size(xdataI);
[r2,c2] = size(xdataT);

if r1 > r2
    xdata = zeros(r1,c1+c2);
    ydata = zeros(r1,c1+c2);
elseif r1 < r2
    xdata = zeros(r2,c1+c2);
    ydata = zeros(r2,c1+c2);
end

for j = 1:c1
    xdata(1:r1,j) = xdataI(:,j);
    ydata(1:r1,j) = ydataI(:,j);
end

for k = 1:c2
    xdata(1:r2,k+c1) = xdataT(:,k);
    ydata(1:r2,k+c1) = ydataT(:,k);
end

close all

xdata( ~any(xdata,2), : ) = [];  
xdata( :, ~any(xdata,1) ) = []; 
ydata( ~any(ydata,2), : ) = [];  
ydata( :, ~any(ydata,1) ) = []; 
xdata(xdata == 0) = NaN;
ydata(ydata == 0) = NaN;

figure; imshow(ImUniBg,[]);
hold on

plot(xdata,ydata,'Color',[173/255;255/255;47/255]);
hold off

defCount = numel(findobj(gcf,'Type','line'))

ContCoordsX = xdata;
ContCoordsY = ydata;
end