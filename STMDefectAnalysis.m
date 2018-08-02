% Author: Alana Gudinas
% July 16, 2018
%
% This is the umbrella function that uses all of the subfunctions for
% analysis and processing. Should be user-friendly and require minimal
% knowledge of matlab. Will include a bit of a user guide, default values,
% and information about the analysis.
% ImRaw_SM4 is the raw sm4 file, must be a string of the file name. 

function [defCount] = STMDefectAnalysis( ImRaw_SM4 )

ImID = fopen(ImRaw_SM4);

[FormatImRawFile, ImRawFile] = sm4reader(ImID);

ImSM4 = FormatImRawFile;
ImData = ImSM4.Spatial.TopoData{1}; % ImData is the topographical data of the raw image.
figure;imshow(ImData,[]); title('Raw Image Data');

% Process the image using Jason's tools:
ImFlatSmooth = ImageProcess(ImSM4);
ImLineFlat = Im_Flatten_X(ImSM4);

pause(2);
close all

% Generate an image with a more uniform background, decreasing noise for
% further analysis:
[ImUniBgFinal, ImUniBgInit, meanPix1, meanPix2] = UniformBackground(ImFlatSmooth);
figure; imshow(ImFlatSmooth,[]); title('Processed Image');

figure; imshowpair(ImUniBgInit,ImUniBgFinal,'montage'); title('(Left) Image after one uniformity iteration, (Right) Image after two iterations');  % Compare first and second iterations of UNIFORMBACKGROUND.

prompt = {'Which image would you like to include for analysis? Please enter "1" to select the first image, and "2" to select the second.'};
titleBox = 'Uniform background image selection';
dims = [1 60];
definput = {'2'};
ImUniAns = inputdlg(prompt,titleBox,dims,definput);
ImUniAns = ImUniAns{1};
ImUniBg = [];

if strcmp(ImUniAns,'1')
    ImUniBg = ImUniBgInit;
    meanPix = meanPix1;
elseif strcmp(ImUniAns,'2')
    ImUniBg = ImUniBgFinal;
    meanPix = meanPix2;
end

close all

figure; imshowpair(ImLineFlat,ImUniBg,'montage'); title('Line Flattened Image; Uniform Background Image','FontSize',15);

str = 'Which method would you like to use for initial defect Identification? Type "F" for filtering by various parameters (area, pixel intensity, vertices), or "S" to perform shape matching on a reference shape.';

promptB = {str};
titleBox = 'Defect Identification Method';
dims = [1 60];
definput = {'S'};
methAns = inputdlg(promptB,titleBox,dims,definput);
methAns = methAns{1};

if strcmp(methAns,'F')
    methodId = 'Filters';
elseif strcmp(methAns,'S')
    methodId = 'Shape'
end

[ defCoordsX, defCoordsY, defCount] = IdentifyDefects(methodId,ImUniBg,ImLineFlat,ImFlatSmooth,meanPix);

mstring = 'The number of defects identified in the image is: %d !';
mstr = sprintf(mstring,defCount);
mhooray = msgbox(mstr,'Defect Count');
waitfor(mhooray);

% now onto analysis

imWidth = ImSM4.Spatial.width;
nmWidth = imWidth*(1e9); % Data is in meters, multiply by 1e9 to convert to nm.

[maxHeightVec,meanHeightVec,areaVec] = DefectStats(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,nmWidth);


end
    
    

