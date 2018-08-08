% Author: Alana Gudinas
% July 2018
% 
% function [ C, hdata, idx, vtx, xdata, ydata, heightVec] = ContourData(ImUniBg,Method,meanPix)
%
% The purpose of this function is to generate contour data based on the
% various brightness levels present in an STM image. Ideally, the input is
% a highly processed image with little noise. The suggested input is
% "ImUniBg", which is the output of UNIFORM BACKGROUND. 
% "Method" must be a string entry, either 'Bright' or 'Dark'. "Method"
% specifies if the user is interested in analyzing bright or dark defects
% in an image, as compared to the background brightness. "meanPix" is the
% mean pixel brightness of the image. 
%
% C and hdata are the outputs of MATLAB's "imcontour". "idx" and "vtx" are
% vectors specifying the index in C where a new contour line begins, and
% the number of points in that contour plot, respectively. "xdata" and
% "ydata" are matrices of the x and y coordinates of each contour plot.
% Each column represents a new line. Since every line has a different
% number of points, the matrix has a number of rows equal to the contour
% line with the most vertices. "heightVec" is a vector of the "heights", or
% brightness level, of each contour plot. The indices of heightVec match
% those of xdata and ydata.

function [ C, hdata, idx, vtx, xdata, ydata, heightVec] = ContourData(ImUniBg,Method,meanPix)

global hMethod 

% This determines which contour plots are stored in xdata and ydata.

if strcmp(Method,'Bright')
    hMethod = 1;
elseif strcmp(Method,'Dark')
    hMethod = 0;
end

[r,c] = size(ImUniBg);

xImdat = [1:1:c];
yImdat = [1:1:r];

% meanP = mean(ImUniBg(:)); % no longer viable. need input from ImUniBg

imageb = imshow(ImUniBg,[]);
h = gca;
h.Visible = 'On';
set(imageb,'AlphaData',0.8); % Makes the image slightly transparent so the contour lines can be seen superimposed on the image.
hold on

[C,hdata] = imcontour(xImdat,yImdat,ImUniBg,10,'LineColor','cyan'); % Create contour lines at ten different brightness levels in the image.
hdata.LineWidth = 1.25;
hold off
close

[ri,ci] = size(C);
idx = 1; 
vtx = C(2,1); 
k = 1;

% Generate idx and vtx. 
    % The data in C is organized so that the very first column contains the
    % brightness level of the first contour in the first row, and the
    % number of vertices of the first contour in the second row.
while idx < ci
    idx(k+1) = idx(k) + vtx(k) + 1; 
    if idx(k+1) >= ci
        idx = idx(1:k);
        vtx = vtx(1:k);
        break
    end
    vtx(k+1) = C(2,idx(k+1));
    k = k + 1;
end

xdata = zeros(700,length(idx));
ydata = zeros(700,length(idx));

heightVec = [];

% If user is only interested in bright defects, only store the contour
% lines with brightness levels greater than the average pixel brightness,
% and vice versa.

if hMethod == 1
    for i = 1:length(idx)
        if (C(1,idx(i)) > meanPix)
            xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
            heightVec = [heightVec, C(1,idx(i))];
        end
    end
elseif hMethod == 0
    for i = 1:length(idx)
        if (C(1,idx(i)) < meanPix)
            xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
            heightVec = [heightVec, C(1,idx(i))];
        end
    end
end

% Get rid of colums and rows that are all zeros, and make zero entries NaN.
xdata( ~any(xdata,2), : ) = [];  
xdata( :, ~any(xdata,1) ) = []; 
ydata( ~any(ydata,2), : ) = [];  
ydata( :, ~any(ydata,1) ) = []; 
xdata(xdata == 0) = NaN;
ydata(ydata == 0) = NaN;  

end