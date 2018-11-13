% Author: Alana Gudinas
% July 16, 2018
%
% [defCoordsX,defCoordsY,defStats,ImFlatSmooth] = STMDefectAnalysis( ImRaw, nmWidth )
%
% The purpose of this function is to organize the various image processing and
% analysis functions for user simplicity. It reads the file type of the
% input image, determines whether it is a .sm4 file or a .mat file, and passes
% the image data into the processing function (IMAGEPROCESS). It then takes
% the processed image and passes it into a function that reduces background
% noise (UNIFORMBACKGROUND), the output of which is passed into
% IDENTIFYDEFECTS, where the user may choose the method of defect
% identification. After the defects have been identified and the
% coordinates of them stored, the last step is to use statistical analysis
% to determine the average apparent height of each defect, as well as the
% maximum height and area. 
%
% "ImRaw" must be either a .sm4 file or a .mat file. The input must be a
% string containing the file name. nmWidth is the width of the image in
% nanometers. If the user is using a .sm4 file, providing the width of the 
% image is unnecessary. If the input is a .mat file, "nmWidth" must be provided.
%
% To convert an image file such as .png or .jpg into a .mat structure, you
% can use: save('ImageFileName.mat','WorkspaceVariable'). WorkspaceVariable
% must be the result of using MATLAB's "imread" function to read the image
% file. 
% The following is an example:
%--------------
% MyImage = imread('myImageFile.png');
% save('MyImage.mat','MyImage');
%--------------
% Now the .mat structure of the image will be saved in the current MATLAB
% folder, and may be inputed as a string into STMDEFECTANALYSIS.
%
% The outputs of this function are:
% 
% defCoordsX: a matrix containing the x-coordinates of the contour plots
% surrounding all identified defects.
% defCoordsY: same as above, but with y-coordinates. defCoordsX(:,1) and 
% defCoordsY(:,1) will plot the first contour.
% defCount: the number of identified defects in the image
% maxHeightVec: a vector of the maximum apparent brightness of each defect
% (the brightness data is taken over a line drawn vertically across the
% defect contour)
% meanHeightVec: a vector of the avearage apparent brightness of each
% defect
% areaVec: a vector of the area (to scale) of each defect, based on the
% contour plot


function [defCoordsX,defCoordsY,defStats,regionStats,ImFlatSmooth] = STMDefectAnalysis( ImRaw, nmWidth )

% check if user has necessary toolbox
hasIPT = license('test', 'image_toolbox');  
if ~hasIPT % image processing toolbox not installed
	message = sprintf('Sorry, but you do not seem to have the Image Processing Toolbox.\nDo you want to try to continue anyway?');
	reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No')
		return;
	end
end

[filepath,name,ext] = fileparts(ImRaw); % reads the file

% create .txt file containing all the operations on the image from start to
% end

global metaDataFile

metaDataFile = name + "MetaData.txt";
edit(metaDataFile);

fileID = fopen(metaDataFile,'a+');
formatSpec = '%s\n';
t = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
fprintf(fileID,formatSpec,t);
    
if strcmp(ext,'.sm4') 
    ImID = fopen(ImRaw); % open if an .sm4 file
    [FormatImRawFile, ImRawFile] = sm4reader(ImID); % use Jason's function to read the image and output a .mat structure
    ImSM4 = FormatImRawFile;
    fprintf(fileID,formatSpec,'Image file opened');
    ImData = ImSM4.Spatial.TopoData{1}; % ImData is the topographical data of the raw image.
    figure;imshow(ImData,[]); title('Raw Image Data');
    % Process the image using Jason's tools:
    [ImFlatSmooth,ImLineFlat,ImZ] = ImageProcess(ImData);
elseif strcmp(ext,'.mat')
    ImRaw = load(ImRaw);
    ImData = ImRaw.Spatial.TopoData{1};
    fprintf(fileID,formatSpec,'Image file opened');
    figure;imshow(ImData,[]); title('Raw Image Data');
    [ImFlatSmooth,ImLineFlat,ImZ] = ImageProcess(ImData);
elseif strcmp(ext,'.png')
    ImRaw = imread(ImRaw);
    save('ImRaw.mat','ImRaw');
    ImData = load(ImRaw); % create new variable
    ImData = cell2mat(struct2cell(ImData)); % convert to a matrix 
    fprintf(fileID,formatSpec,'Image file opened');
    figure;imshow(ImData,[]); title('Raw Image Data');
    [ImFlatSmooth,ImLineFlat,ImZ] = ImageProcess(ImData);
end

if nargin == 1
    imWidth = ImSM4.Spatial.width;
    nmWidth = imWidth*(1e9); % Data is in meters, multiply by 1e9 to convert to nm.
elseif nargin == 0
    error('Not enough input arguments, image file name is required');
end
pause(2);
close all

% Generate an image with a more uniform background, decreasing noise for
% further analysis:
[ImUniBgFinal, ImUniBgInit, meanPix1, meanPix2] = UniformBackground(ImFlatSmooth);

figure; imshow(ImFlatSmooth,[]); title('Processed Image');

figure; imshowpair(ImUniBgInit,ImUniBgFinal,'montage'); title('(Left) Image after one uniformity iteration, (Right) Image after two iterations');  % Compare first and second iterations of UNIFORMBACKGROUND.

% Allow user to select first or second iteration of UNIFORMBACKGROUND.
% Different images may require more noise reduction, while for others one
% iteration is enough.

prompt = {'Which image would you like to include for analysis? Please enter "1" to select the first image, and "2" to select the second. Enter "3" to analyze the processed image.'};
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
elseif strcmp(ImUniAns,'3');
    ImUniBg = ImFlatSmooth;
    meanPix = mean(ImFlatSmooth(:));
end

bgSpec = 'Chosen iteration of uniform background: %s\n';
fprintf(fileID,bgSpec,ImUniAns);

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
    methodId = 'Shape';
end

mtSpec = 'Method of defect identification: %s\n';
fprintf(fileID,mtSpec,methodId);

% Identify defects directs variables to either SHAPEDATA or FILTERDATA. 

[ defCoordsX, defCoordsY, defCount] = IdentifyDefects(methodId,ImUniBg,ImLineFlat,ImFlatSmooth,meanPix);

mstring = 'The number of defects identified in the image is: %d !';
mstr = sprintf(mstring,defCount);
mhooray = msgbox(mstr,'Defect Count');
waitfor(mhooray);

% Next step is statistical analysis.

[defStats,regionStats] = DefectStats(defCoordsX,defCoordsY,ImLineFlat,ImFlatSmooth,ImUniBg,nmWidth,ImZ);

fprintf(fileID,formatSpec,'Complete');
end
    
    

