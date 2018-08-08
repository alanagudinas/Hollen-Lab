% Author: Alana Gudinas
% June 2018
%
% [ ImFlatSmooth, ImLineFlat ] = ImageProcess( Im_struct )
%
% This program uses Jason Moscatello's image processing techniques
% to prepare STM images for further analysis.
% 
% The input must be a matlab data structure. A STM image in the form of a
% .sm4 file can be converted to a .mat structure with Jason's sm4tomatlab.m
% program. 
%
% The output is the processed image topography data for use in image
% analysis. 
%
%------------------------------------------------------------------------------------%

function [ImFlatSmooth,ImLineFlat] = ImageProcess(Im_struct)

Im_data = Im_struct.Spatial.TopoData{1}; % Define variable for topological data of the image. 

% Line-by-line flattening of the image:

for n=1:length(Im_data(1,:)) 
%create an array of x-data 
    x = 1:length(Im_data(:,n)); 
    x = transpose(x); % needed for x and y to have same dimesion directions 

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

ImLineFlat = Im_data_flat_quad; % Not for analysis, but for apparent height analysis and visualization.

ImLineFlat = Im_Flatten_XY2(Im_data);


% Deal with background in the image
% use the strel command here to use a disk of 15 pixels to find out how the 
% background varies.  we can use this since the background should be flat. 
% as per
% https://www.mathworks.com/help/images/image-enhancement-and-analysis.html.
% (Jason's notes)

background = imopen(Im_data_flat_quad,strel('disk',15)); 
Im_flat_bg = Im_data_flat_quad - background; 

% normalize the data for better display 

normIm_flat = (Im_data_flat_quad - min(min(Im_data_flat_quad))) / (max(max(Im_data_flat_quad)) - min(min(Im_data_flat_quad))); 
normIm_flat_bg = (Im_flat_bg - min(min(Im_flat_bg))) / (max(max(Im_flat_bg)) - min(min(Im_flat_bg))); 

% getting normalized vectors and some statistics in order to plot better 

meanIm_flat_bg = mean2(normIm_flat_bg);
stdIm_flat_bg = std2(normIm_flat_bg); 
low = meanIm_flat_bg - stdIm_flat_bg; 
high = meanIm_flat_bg + stdIm_flat_bg; 

% imadjust allows me to adjust the contrast on the imshowpair plotting 

ImflatA = imadjust(normIm_flat, [.001 .3],[]); 

ImflatbgA = imadjust(normIm_flat_bg, [low high],[]); 

figure; imshowpair(ImflatA,ImflatbgA, 'montage'); title('Line Flatten to Background Correction'); 

% wow, get rid of line noise!!

% filter strongly along the direction of the lines to get a background you 
% can subtract 

ImlineB = imgaussfilt(Im_flat_bg,[1 50]);  
Ic = Im_flat_bg - ImlineB; 
Icn = (Ic - min(min(Ic))) / (max(max(Ic)) - min(min(Ic))); 
Imean = mean2(Icn); 
Istd = std2(Icn); 

%figure;imshow(Icn, [(Imean - 5*Istd) (Imean + 5*Istd)]); title('Line Corrected')

ImDataLineCorSmooth = imgaussfilt(Icn,2); 

figure; imshow(ImDataLineCorSmooth, [(Imean - 5*Istd) (Imean + 5*Istd)]); title('Line Corrected and Smoothed'); 
 
ImFlatSmooth = ImDataLineCorSmooth; % Final processed image.

end
