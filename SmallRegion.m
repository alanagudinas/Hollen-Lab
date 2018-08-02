% Author: Alana Gudinas
% July 24, 2018

function [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectData)
    
[imR,imC] = size(ImUniBg);

ImSectBg = imcrop(ImUniBg,rectData);

[seR,seC] = size(ImSectBg);
% xscale = imC/seC;
% xscale = round(xscale,0);

% ImSectBg = imresize(ImSectBg,xscale);
figure; imshow(ImSectBg,[]); title('Cropped Uniform Background Image')

hs = 'The cropped image region is displayed';
helps1 = helpdlg(hs,'Cropped Image');
waitfor(helps1);

prompts = 'Would you like to see the less processed image region? Y/N';
titleBox = 'Image Choice';
dims = [1 75];
definput = {'N'};
opts = inputdlg(prompts,titleBox,dims,definput);
opts = opts{1};

if strcmp(opts,'Y')
    ImSectFl = imcrop(ImLineFlat,rectData);
    figure; imshow(ImSectFl,[]); title('Cropped Line-Flattened Image');
    ImSectSm = imcrop(ImFlatSmooth,rectData);
    figure; imshow(ImSectSm,[]); title('Smoothed and Flattened Image')
    imSectArray = {ImSectBg,ImSectSm,ImSectFl};
elseif strcmp(opts,'N')
    imSectArray = {ImSectBg};
end

% ImVec = ImSectBg;
% ImVec = ImVec + abs(min(min(ImVec)));
% ImVec = ImVec(:);
% 
% minlim = min(ImVec);
% maxlim = max(ImVec);

figure; montage(imSectArray,'Size', [1 length(imSectArray)]); title('Smaller Image Regions','FontSize',15);

% colorbar
% lim = caxis;
% caxis([minlim maxlim]);


str = 'Which image would you like to analyze for defect identification? Type "1" for uniform background, "2" for flattened and smoothed, and "3" for line flattened (if applicable).';
promptSect = {str};
titleBox = 'Image Region Selection';
dims = [1 60];
definput = {'1'};
ImSectAns = inputdlg(promptSect,titleBox,dims,definput);
ImSectAns = ImSectAns{1};

if strcmp(ImSectAns,'1')
    ImSect = ImSectBg;
elseif strcmp(ImSectAns,'2')
    ImSect = ImSectSm;
elseif strcmp(ImSectAns,'3')
    ImSect = ImSectFl;
end

meanPix = mean(ImSect(:));

[r,c] = size(ImSect);
xImdat = [1:1:c];
yImdat = [1:1:r];

imagesect = imshow(ImSect,[]);
h = gca; 
h.Visible = 'On';
set(imagesect,'AlphaData',0.8); 
hold on

[Csect,hsect] = imcontour(xImdat,yImdat,ImSect,10,'LineColor','cyan'); % create contour lines at ten different heights of the image
hdata.LineWidth = 1.25;
hold off

hs2 = 'Shape matching will now begin. You will be prompted to select a reference shape.';
helps2 = helpdlg(hs2,'Shape Matching');
waitfor(helps2);

[ NestedContoursCell, xdataC, ydataC ] = NestedContours(ImSect,meanPix);

[defCoordsX, defCoordsY] = NestedShapeMatching(ImSect, NestedContoursCell, xdataC, ydataC);

figure; imshow(ImSect,[]); title('Shape Matching Results');
hold on
plot(defCoordsX,defCoordsY,'Color','yellow');

hs3 = 'Please select the defect shape that should be identified.';
helps3 = helpdlg(hs3,'Final Selection');
waitfor(helps3);

rect = getrect;

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

defAddX = defAddX + rectData(1);
defAddY = defAddY + rectData(2);

pause(1)
close all
% Need to plot other data so user can see what has already been identified.
addloop = 'Would you like to re-analyze another region of the image and identify a defect? Y/N';
titleBox = 'Add More';
dims = [1 75];
definput = {'N'};
optadd = inputdlg(addloop,titleBox,dims,definput);
optadd = optadd{1};



end