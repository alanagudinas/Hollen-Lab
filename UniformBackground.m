% Author: Alana Gudinas
% July 6, 2018
%
% [ImUniBg, ImUniBgINIT, meanPix1, meanPix2] = UniformBackground(Im_proc)
% reduces the amount of noise in a STM image to make further analysis 
% simple by increasing background uniformity. The function makes some
% statistical computations on the pixels in the image, and determines a
% brightness range that can be considered the background of the image. If a
% pixel falls within that range, it is set to the mean pixel value of the
% image.
%
% Im_proc is a processed image, which can be created from a raw STM image
% using "ImageProcess."
% ImUniBg is the result of the second iteration, an image with a more 
% uniform background, where extrema are easier to distinguish, both 
% optically and computationally. ImUniBgINIT is the result of the first
% iteration. meanPix1 is the background pixel value from the first
% iteration, and meanPix2 is the background pixel value from the second
% iteration.
%
% Im_proc must be an image matrix.

function [ ImUniBg, ImUniBgINIT, meanPix1, meanPix2 ] = UniformBackground(Im_proc)

global metaDataFile
fileID = fopen(metaDataFile,'a+'); % open meta data .txt file
formatSpec = '%s\n';

ImData = Im_proc;

ImRescale = ImData; % Rescale image to have pixel values that range from 0 to 1. (Purely for simplicity)

ImReVec = ImRescale(:); % Unroll image into a vector for analysis. 

% Define some variables:

meanPixel = mean(ImReVec);
maxPix = max(ImReVec);

% Create a vector of the difference in brightness between each pixel and
% its neighbor along the image vector:

pixDiff = [];
nd = length(ImReVec);

for i = 1:nd-1
    pixDiff(i) = abs(ImReVec(i+1) - ImReVec(i)); % subtract the brightness of one pixel from its linear neighbor
end

maxDiff = max(pixDiff);
minDiff = min(pixDiff);
avgDiff = mean(pixDiff);
mostDiff = mode(pixDiff);

distVec = pixDiff;

ImTest = ImRescale;

% Some reasoning:
%
% Some images have way more contrast between defects and background than others.
% How can pixDiff be utilized here?
%   a. to determine the variation in brightness. An avgDiff that is close
%      (as compared to what?) to both maxDiff and minDiff means the contrast 
%      is very low. 
%   b. to create the background brightness range. Theoretically (though I
%      could be way off the mark) the most commonly occuring brightness
%      difference (mostDiff) should correspond to the fluctuations in the
%      background. 
%

ImReVecSort = sort(ImReVec);

bmod = mod(nd,2);

if bmod ~= 0 
    nde = (nd+1)/2;
else
    nde = nd/2;
end
pix1 = ImReVecSort(1:nde); % this is the mean pixel brightness of the first half (the lower half) of the image vector.
pix2 = ImReVecSort(nde:end); % mean pixel of the "brighter" half.

mpix1 = mean(pix1);
mpix2 = mean(pix2);

% Below is where I determine the actual brightness range the background
% falls under. The background in most STM images fluctates quite a bit due
% to noise. Therefore, a fairly wide range is needed to capture all of the
% background, but cannot be too wide as to include the extrema that may be
% defects. I reasoned that avgDiff, the average difference in brightness
% one pixel is to its vector neighbor, is an accurate measure of the pixel
% fluctations. 

for j = 1:numel(ImRescale)
    if ((mpix1 - avgDiff) <= ImRescale(j)) && (ImRescale(j) <= (mpix2 + avgDiff))
        ImTest(j) = meanPixel;
    end
end

meanPix1 = meanPixel;
ImUniBgINIT = ImTest;
fprintf(fileID,formatSpec,'New image generated with improved background uniformity');
% figure; imshowpair(ImData,ImTest,'montage') % very nice (so far)

% Now, from the new images with semi-uniform backgrounds, create defect
% threshold values and compare contour results. Two approaches:
%   1. Use image segmentation and expect better results than before
%      increasing uniformity.
%   2. Use above pixel-by-pixel strategy to identify defects.
%       - trouble will occur here in images where a dark extreme isn't a
%         defect.
% Decided to repeat above process first to improve uniformity results.
% Below, the "t" subscript at the end of every variable just marks that it
% is the second iteration.

ImTestVec = ImTest(:);
ImTestSort = sort(ImTestVec);

pixVec2 = ImTestSort;

if bmod ~= 0 
    nde = (nd+1)/2;
else
    nde = nd/2;
end

pix1_t = ImTestSort(1:nde);
pix2_t = ImTestSort(nde:end);

mpix_t = mean(ImTestVec);
mpix1_t = mean(pix1_t);
mpix2_t = mean(pix2_t);

meanPixel2 = mpix_t;

pixDiff_t = [];

for i = 1:nd-1
    pixDiff_t(i) = abs(ImTestVec(i+1) - ImTestVec(i));
end

avgDiff_t = mean(pixDiff_t(nde:end));
maxDt = max(pixDiff_t);
minDt = min(pixDiff_t);

distVec2 = pixDiff_t;

ImTest2 = ImTest;

for j = 1:numel(ImTest)
    if ((mpix1_t - avgDiff_t*10) <= ImTest(j)) && (ImTest(j) <= (mpix2_t + avgDiff_t*10))
        ImTest2(j) = mpix_t;
    end
end

ImUniBg = ImTest2;

fprintf(fileID,formatSpec,'New (2) image generated with improved background uniformity');
meanPix2 = mpix_t;

end