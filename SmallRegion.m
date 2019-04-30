% Author: Alana Gudinas
% July 24, 2018
%
% [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectData)
%
% This function is used in both SHAPEDATA and FILTERDATA to analyze a
% region of an image where a defect was not properly identified in the
% former functions. A user may manually select a contour line from a plot
% or perform shape matching to find the best match to a template defect.
%
% The inputs are: (ImLineFlat) the line-flattened original image, (ImFlatSmooth) 
% the processed image, (ImUniBg) the uniform background image, and (rectData) the 
% coordinates of a rectangular region of the original image. The outputs are
% the x and y coordinates of the identified defects, after a change of
% coordinates to plot them in the correct region on the original image.

% NOTE: no longer a processing option. 

function [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectData)

global help_dlg
global metaDataFile

fileID = fopen(metaDataFile,'a+'); % open txt file
formatSpec = '%s\n';
    
ImSectBg = imcrop(ImUniBg,rectData); % crop image w/ coordinates of rectData

image_mean = mean2(ImSectBg);
image_std = std2(ImSectBg);
image_min = image_mean - 5*image_std;
image_max = image_mean + 5*image_std;

figure; imshow(ImSectBg,[image_min image_max]); title('Cropped Uniform Background Image')

if help_dlg
    hs = 'The cropped image region is displayed';
    helps1 = helpdlg(hs,'Cropped Image');
    waitfor(helps1);
end

ImSect = ImSectBg;

meanPix = mean(ImSect(:));

[r,c] = size(ImSect);
xImdat = [1:1:c];
yImdat = [1:1:r];

imagesect = imshow(ImSect,[image_min image_max]);
h = gca; 
h.Visible = 'On';
set(imagesect,'AlphaData',0.8); 
hold on

imcontour(xImdat,yImdat,ImSect,10,'LineColor','cyan'); % create contour lines at ten different heights of the image
hdata.LineWidth = 1.25;
hold off

[ NestedContoursCell, xdataC, ydataC ] = NestedContours(ImSect,meanPix); % create cell array of contour groups

if help_dlg
    small1 = 'You may choose to manually select contours or perform shape-matching on a reference shape to identify the defects in the cropped image.';
    sm1 = helpdlg(small1,'Identify Defects');
    waitfor(sm1);
end

ps1 = 'Would you like to manually select contours or perform shape matching? Type "M" for manual selection, or "S" for shape matching. M/S';
dims = [ 1 75 ];
definput = {'M'};
titleBox = 'Contour Selection';
smallans = inputdlg(ps1,titleBox,dims,definput);
smallans = smallans{1};

if strcmp(smallans,'S')
    if help_dlg
        hs2 = 'Shape matching will now begin. You will be prompted to select a reference shape.';
        helps2 = helpdlg(hs2,'Shape Matching');
        waitfor(helps2);
    end

    [defCoordsX, defCoordsY] = NestedShapeMatching(ImSect, NestedContoursCell, xdataC, ydataC);

    figure; imshow(ImSect,[]); title('Shape Matching Results');
    hold on
    plot(defCoordsX,defCoordsY,'Color','yellow');

    if help_dlg
        hs3 = 'Please select the defect shape that should be identified.';
        helps3 = helpdlg(hs3,'Final Selection');
        waitfor(helps3);
    end
    defAddX = [];
    defAddY = [];
    rect = getrect; % of plotted contours, choose what should be identified as a defect

    for i = 1:length(defCoordsX(1,:))
        xA = defCoordsX(:,i);
        yA = defCoordsY(:,i);
        xA(isnan(xA)) = [];
        yA(isnan(yA)) = [];
        if ((xA > rect(1)) & (xA < (rect(1)+rect(3)))) & ((yA > rect(2)) & (yA < (rect(2)+rect(4))))
            defAddX(:,i) = defCoordsX(:,i);
            defAddY(:,i) = defCoordsY(:,i);
        end
    end
    
    if isempty(defAddX)
        stri = 'Please select a region containing an entire contour plot!';
        hels = helpdlg(stri,'Last Try');
        waitfor(hels);
        rect = getrect; % of plotted contours, choose what should be identified as a defect
        for i = 1:length(defCoordsX(1,:))
            xA = defCoordsX(:,i);
            yA = defCoordsY(:,i);
            xA(isnan(xA)) = [];
            yA(isnan(yA)) = [];
            if ((xA > rect(1)) & (xA < (rect(1)+rect(3)))) & ((yA > rect(2)) & (yA < (rect(2)+rect(4))))
                defAddX(:,i) = defCoordsX(:,i);
                defAddY(:,i) = defCoordsY(:,i);
            end
        end
        defAddX = defAddX + rectData(1); % change of coordinates to plot contour on original image
        defAddY = defAddY + rectData(2);
    end
    
    defAddX = defAddX + rectData(1); % change of coordinates to plot contour on original image
    defAddY = defAddY + rectData(2);
    
elseif strcmp(smallans,'M')
    figure; imshow(ImSect,[]);
    hold on
    plot(xdataC,ydataC,'Color','yellow');
    hold off
    if help_dlg
        hs3 = 'Please select the group of contours you are interested in.';
        helps3 = helpdlg(hs3,'Contour Selection');
        waitfor(helps3);
    end
    rect = getrect; % select region of the cropped image containing defects
    for i = 1:length(xdataC(1,:))
        xA = xdataC(:,i);
        yA = ydataC(:,i);
        xA(isnan(xA)) = [];
        yA(isnan(yA)) = [];
        if ((xA > rect(1)) & (xA < (rect(1)+rect(3)))) & ((yA > rect(2)) & (yA < (rect(2)+rect(4))))
            plot(xA,yA,'Color','blue');
            drawnow
            hold on 
        end
    end
    areaVec = [];
    if help_dlg
        shapehelp2 = 'Of the cluster of contour lines, decide which plot you want to add. With the mouse, click within the space of that line, making sure that where you click is enclosed by the loop of interest.';
        h2 = helpdlg(shapehelp2,'Defect Selection');
        waitfor(h2);
    end
    [x,y] = ginput(1); % manually select contour of interest
    xi = [];
    yi = [];
    for k = 1:length(xdataC(1,:))
        xint = xdataC(:,k);
        yint = ydataC(:,k);
        xint(isnan(xint)) = [];
        yint(isnan(yint)) = []; 
        if ((x < max(xint)) & (x > min(xint))) & ((y < max(yint)) & (y > min(yint)))
            xi = [xi, xdataC(:,k)]; % vector of all the contours enclosed by ginput coords
            yi = [yi, ydataC(:,k)];
        end          
    end
    for i = 1:length(xi(1,:))
        xint = xi(:,i);
        yint = yi(:,i);
        xint(isnan(xint)) = [];
        yint(isnan(yint)) = []; 
        Im_binR = poly2mask(xint,yint,512,512);
        areaVec(i) = bwarea(Im_binR); % find area of each contour
    end
    figure; imshow(ImSect,[]); title('Defect Selection');
    hold on

    [~,idm] = min(areaVec); % minimum area is the defect of interest
    xtarg = xi(:,idm);
    ytarg = yi(:,idm);
    
    defAddX = xtarg + rectData(1);
    defAddY = ytarg + rectData(2);
    
    plot(xtarg,ytarg,'Color','cyan');
    hold off
end
close all
end