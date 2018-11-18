% Author: Alana Gudinas
% June 2018
%
% [ ImFlatSmooth, ImLineFlat ] = ImageProcess( ImData )
%
% This program uses Jason Moscatello's image processing techniques
% to prepare STM images for further analysis.
% 
% The input must be an image data array. If the data has dimensions m x n x
% z, where z > 1, the program will automatically use ImData(:,:,1).
%
% The outputs are:
% ImFlatSmooth: the final processed image
% ImLineFlat: the line-by-line flattened image

function [ImFlatSmooth,ImLineFlat,ImZdata] = ImageProcess(ImData)

global metaDataFile
fileID = fopen(metaDataFile,'a+'); % open txt file
formatSpec = '%s\n';

[r,c,d] = size(ImData);

if d > 1 % need a 2D array for processing
    %ImData = ImData(:,:,1);
    ImData = rgb2gray(ImData);
    ImData = im2double(ImData);
    %ImData = mat2gray(ImData);
end

global output_graph

Im_data = ImData;

% Line-by-line flattening of the image:
 
for n=1:length(Im_data(1,:)) 
%create an array of x-data 
    x = 1:length(Im_data(:,n)); 
    x = transpose(x); % needed for x and y to have same dimension directions 

   % extract the y data from row n 

   y = Im_data(:,n); 

   %fit this data with a linear fit:
   
   p = polyfit(x,y,1); 

   linecorrect = x.*p(1)+p(2); 

   Im_data_flat_lin(:,n)=Im_data(:,n)-linecorrect; 

end

% For comparison purposes, line flatten with quadratic fit:
for n=1:length(Im_data(1,:)) 

   %fit data with a quadratic
   
   p2 = polyfit(x,y,2);
   linecorrect2 = (x.^2).*p2(1) + x.*p2(2) + p2(3); 
   Im_data_flat_quad(:,n)=Im_data(:,n)-linecorrect2; % Im_data_flat_quad is now the flattened image. 
   
end

fprintf(fileID,formatSpec,'Image data line-by-line flattened');
ImLineFlat = Im_data_flat_quad; % Not for analysis, but for apparent height analysis and visualization.

% ImLineFlat = Im_Flatten_XY2(Im_data); need to alter

figure;imshow(ImLineFlat,[])

% Deal with background in the image
% use the strel command here to use a disk of 15 pixels to find out how the 
% background varies.  we can use this since the background should be flat. 
% as per
% https://www.mathworks.com/help/images/image-enhancement-and-analysis.html.
% (Jason's notes)

background = imopen(Im_data_flat_quad,strel('disk',15)); 
Im_flat_bg = Im_data_flat_quad - background; 

fprintf(fileID,formatSpec,'Background corrected');

% normalize the data for better display 

normIm_flat = (Im_data_flat_quad - min(min(Im_data_flat_quad))) / (max(max(Im_data_flat_quad)) - min(min(Im_data_flat_quad))); 
normIm_flat_bg = (Im_flat_bg - min(min(Im_flat_bg))) / (max(max(Im_flat_bg)) - min(min(Im_flat_bg))); 

fprintf(fileID,formatSpec,'Image data normalized');
% getting normalized vectors and some statistics in order to plot better 

meanIm_flat_bg = mean2(normIm_flat_bg);
stdIm_flat_bg = std2(normIm_flat_bg); 
low = meanIm_flat_bg - stdIm_flat_bg; 
high = meanIm_flat_bg + stdIm_flat_bg; 

% ask Jason about this?
if low < 0
    low = 0;
end
% imadjust allows me to adjust the contrast on the imshowpair plotting 

ImflatA = imadjust(normIm_flat, [.001 .3],[]); 

fprintf(fileID,formatSpec,'Contrast adjusted');

ImflatbgA = imadjust(normIm_flat_bg, [low high],[]); 

if output_graph
    figure; imshowpair(ImflatA,ImflatbgA, 'montage'); title('Line Flatten to Background Correction'); 
end
% get rid of line noise

% filter strongly along the direction of the lines to get a background you 
% can subtract 

ImlineB = imgaussfilt(Im_flat_bg,[1 50]);  
Ic = Im_flat_bg - ImlineB; 
Icn = (Ic - min(min(Ic))) / (max(max(Ic)) - min(min(Ic))); 
Imean = mean2(Icn);
Istd = std2(Icn); 

fprintf(fileID,formatSpec,'Filtered along direction of lines');

%figure;imshow(Icn, [(Imean - 5*Istd) (Imean + 5*Istd)]); title('Line Corrected')

ImDataLineCorSmooth = imgaussfilt(Icn,2); 
fprintf(fileID,formatSpec,'Gaussian filter applied');

ImZdata = imgaussfilt(Ic,2); 

if output_graph
    figure; imshow(ImDataLineCorSmooth, [(Imean - 5*Istd) (Imean + 5*Istd)]); title('Line Corrected and Smoothed'); 
end

ImFlatSmooth = ImDataLineCorSmooth; % Final processed image.

end
