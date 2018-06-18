function [thresh1,thresh2] = BrightnessThresholds(Im_proc)

% This function utilizes MATLAB's "multithresh" to determine distinct brightness
% levels in an image. The input must be a processed image for best results.
% Intended use is with "GetContourData".
%
% I am writing this to require less user input in "GetContourData." Here, I
% am hoping to create something that will determine the best thresholds on
% an image-by-image basis.
%
% The most useful thing would be to have something that determines the best
% number of levels, which largely depends on image quality and processing. 
% It may not be possible to standardize which levels to use when plotting
% defects, different images will require a different number of levels in
% "multithresh."
% 
% As a preliminary step, I am saying that there are three scenarios for
% defect brightness in an image: 1) the defects are bright, 2) the defects
% are dark, and 3) the defects are a mix. 
%
% The outputs are the brightness values that the defects will lie between.

method = 0;
thresh1 = [];
thresh2 = [];

ImData = Im_proc;

ImRescale = mat2gray(ImData); % Rescale image to have pixel values 
% that range from 0 to 1 to standardize pixel range of every image.

thresh = multithresh(ImRescale,2);
segIm = imquantize(ImRescale,thresh); % Segment the image into three levels. 

segImVec = segIm(:); % Unroll the array into a vector.

mspix = mean(segImVec) % Determine the mean pixel value from the segmented image.

% The image is characterized from the value of mspix. By testing several
% different images, I determined preliminary mspix ranges. 

if (mspix<=1.85) && (mspix>=1.5) % defects are light 
    method = 1;
elseif (mspix>1.85)&&(mspix<=2.0) % defects are dark
    method = 0;
elseif (mspix<1.5)&&(mspix>=1.0) % defects are light but overall image is dark
    method = 2;
elseif (mspix>2.0)&&(mspix<=3.0) % defects are a mix
    method = 3;
end


if method == 1
    levels = multithresh(ImData,5);
    thresh1 = levels(3);
    thresh2 = levels(4);
elseif method == 0
    levels = multithresh(ImData,6);
    thresh1 = levels(1);
    thresh2 = levels(2);
elseif method == 2
    levels = multithresh(ImData,5);
    thresh1 = levels(2);
    thresh2 = levels(4);
elseif method == 3
    levels = multithresh(ImData,10);
    thresh1 = [levels(1);levels(2)];
    thresh2 = [levels(9);levels(10)];  % Need to reduce number of contour lines in mixed images?
end

% The threshold values aren't entirely accurate, right now it works best
% with "light defect" images. Moving forward I want to develop a more
% adaptive method. 

end



