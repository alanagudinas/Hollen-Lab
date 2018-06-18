% [ idx, vtx, C ] = GetContourData( Im_struct )
%
% The purpose of this function is to create a contour plot based on the
% topography data of an STM image. Based on user-defined brightness
% thresholds, the program plots lines around prominent defects in an image.
% 
% The input is a MATLAB data structure. The outputs are the contour data
% "C", a vector of the indices "idx" in "C" marking the start of x and y
% data corresponding to the coordinates of a defect. "Vtx" is a vector
% containing the number of vertices in each contour plot around a defect. 
%
% The outputs are used in another program, ShapeMatching.

function [idx, vtx, C] = GetContourData(Im_struct)

% Start by procesing the image:

ImFlatSmooth = ImageProcess(Im_struct);

% Change the transparency of the image to allow overlay of contour lines,
% purely for visualization purposes.

imageb = imshow(ImFlatSmooth,[]);
h = gca; %returns the handle to the current axes for the current figure (imageb).
h.Visible = 'On';
set(imageb,'AlphaData',0.8);
hold on

xImdat = [1:1:512];
yImdat = [1:1:512]; % To set size of contour plot axes.

[C,hdata] = imcontour(xImdat,yImdat,ImFlatSmooth,15); % Overlay contour plot with 15 levels.
% This level is set for every image. In the future, may alter this on an
% image-by-image basis.

hdata.LineWidth = 1.25; % Make the contour lines slightly thicker, for visualization.
hold off

% C is sorted in a strange way. In the very first column, the height of the
% level and number of vertices in the level line is defined. The following
% values are the x and y data for that specific level. If the (x,y) is the
% same after # of vert as it was at the start, the loop is closed. 
% 
% Start by generating list of level values (for comparison):

LevelList = hdata.LevelList;

% I want to determine the range of brightness values a defect lies within on an
% image. To do so, I wrote a separate program below:

[thresh1,thresh2] = BrightnessThresholds(ImFlatSmooth);

idx = []; % Set some empty variables.
vtx = [];
idx2 = [];
vtx2 = [];
xdata = [];
ydata = [];

if ~iscell(thresh1) % If thresh1 and thresh2 are scalars, defects only lie in one brightness range.
    for i = 1:length(C(1,:))
        if (C(1,i)>=thresh1) & (C(1,i)<=thresh2) % Loop through C. If a height value lies between thresh1 and 2, store the inde value.
            idx = [idx,i];
            vtx = [vtx, C(2,i)];
        end
    end
else
    for i = 1:length(C(1,:)) % If thresh1 and thresh2 are vectors, there are two ranges.
        if ((C(1,i)>=thresh1(1)) && (C(1,i)<=thresh1(2)))
            idx = [idx,i];
            vtx = [vtx, C(2,i)];
        end
    end
    for j = 1:length(C(1,:))
        if ((C(1,j)>=thresh2(1)) && (C(1,j)<=thresh2(2)))
            idx2 = [idx2,j];
            vtx2 = [vtx2, C(2,j)];
        end
    end
    idx = [idx idx2]; % Store all the indices marking the start of a plot of a defect.
    vtx = [vtx vtx2]; % Store all the vertex values for plotting purposes.
end

figure; imshow(ImFlatSmooth,[])
hold on

for k = 1:length(idx)
    if vtx(k)<=20
        continue
    else
    xdata = C(1,idx(k)+1:idx(k)+vtx(k)); % xdata ranges from the index that marks the start of a level within the brightness range.
    ydata = C(2,idx(k)+1:idx(k)+vtx(k)); % Store all the points from idx to idx + vtx. 
    plot(xdata,ydata,'Color',[173/255;255/255;47/255])
    hold on
    drawnow
    end
end

numlines = numel(findobj(gcf,'Type','line')) % After contour lines have been plotted, count the numer of plots, which correpsond to number of defects.
hold off

end
