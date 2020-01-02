% Author: Alana Gudinas
% 29 December 2019

% This is the umbrella function for DIST: Defect Identification and
% Statistics Toolbox. The subfunctions and processes in the program are 
% included here, as well as the message boxes that prompt the user to make
% analysis decisions.
%
% Note: if inputting a .mat file, it must be formatted in the same way as
% the program: sm4reader.
%
% Inputs
% 'ImRaw': character string containing file name of image. Accepted file
% formats are: .sm4, .mat, .asc, and .png.
% 'nmWidth': width of the image in nanometers. This parameter does not need
% to be specified if the image file is .sm4.
%
% Outputs
% 'ImageNew': Processed image following the GUI.
% 'ImZdata': Unscaled image data (for computing statistics).
% 'defStats': Matrix containing computed statistics. Includes a sorted 
% vector of the brightness extrema for each defect (Max/MinHeightVec), a 
% vector with the corresponding contour indices, and the same for the mean
% brightness of each defect.
% 'regionStats': Matrix containing statistics computed with MATLAB's
% "regionprops". Includes 'Centroid','Eccentricity','MajorAxisLength',
% 'MinorAxisLength','Orientation',and 'Area' of each defect contour.
% 'xCoords': A matrix containing the x-coordinates of the contour plots
% surrounding all identified defects.
% 'yCoords': same as above, but with y-coordinates. xCoords(:,1) and 
% yCoords(:,1) plots the first contour.
% 'NestedContoursCell': Cell structure with each entry containing a
% concentric contour plot in the image. 

% v 0.1.0

function [ImageNew,ImZdata,defStats,regionStats,xCoords,yCoords,NestedContoursCell] = DIST( ImRaw, nmWidth )

% Check if user has necessary toolbox:
hasIPT = license('test', 'image_toolbox');  
if ~hasIPT % image processing toolbox not installed
	message = sprintf('Sorry, but you do not seem to have the Image Processing Toolbox.\nDo you want to try to continue anyway?');
	reply = questdlg(message, 'Toolbox missing', 'Yes', 'No', 'Yes');
	if strcmpi(reply, 'No')
		return;
	end
end

[~,name,ext] = fileparts(ImRaw); % read the file

% create .txt file containing all operations on the image from start to end
global metaDataFile

metaDataFile = name + "MetaData.txt";
edit(metaDataFile);

fileID = fopen(metaDataFile,'a+');
formatSpec = '%s\n';
t = datetime('now','TimeZone','local','Format','d-MMM-y HH:mm:ss Z');
fprintf(fileID,formatSpec,t);
    
% below are specific configurations for each image file type
if strcmp(ext,'.sm4') 
    ImID = fopen(ImRaw); % open if an .sm4 file
    [FormatImRawFile, ImRawFile] = sm4reader(ImID); % use Jason Moscatello's function to read the image and output a .mat structure
    ImFile = FormatImRawFile;
    fprintf(fileID,formatSpec,'Image file opened');
    ImData = ImFile.Spatial.TopoData{1}; % ImData is the topographical data of the raw image.
    nmWidth = (1e9)*ImFile.Spatial.width;
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata,ImFlat] = FilteringGUI(ImData); % send image to GUI for user to process.
elseif strcmp(ext,'.mat')
    ImSM4 = load(ImRaw);
    if isstruct(ImSM4) % check if processed using 'sm4reader'
        ImData = ImSM4.Spatial.TopoData{1}; % note: this is for .sm4 files that have been processed with sm4reader
        imWidth = ImSM4.Spatial.width;
        nmWidth = imWidth*(1e9);
    else
        ImData = ImSM4; % if not, use image data. 'nmWidth' required.
    end
    fprintf(fileID,formatSpec,'Image file opened');
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata,ImFlat] = FilteringGUI(ImData);
elseif strcmp(ext,'.png')
    ImRaw = imread(ImRaw);
    save('ImRaw.mat','ImRaw'); % save as .mat file
    ImData = load('ImRaw.mat'); % create new variable
    ImData = cell2mat(struct2cell(ImData)); % convert to a matrix
    fprintf(fileID,formatSpec,'Image file opened');
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata,ImFlat] = FilteringGUI(ImData);
elseif strcmp(ext,'.asc')
    ImData = load(ImRaw);
    fprintf(fileID,formatSpec,'Image file opened');
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata,ImFlat] = FilteringGUI(ImData);
end

if (nargin == 1) & ~strcmp(ext,'.sm4')
    if exist('ImSM4','var')
        if ~isstruct(ImSM4)
            error('Not enough input arguments, image width is required');
        end
    end
elseif nargin == 0
    error('Not enough input arguments, image file name is required');
end

image_mean = mean2(ImageNew); % values computed for display purposes
image_std = std2(ImageNew);
image_min = image_mean - 5*image_std;
image_max = image_mean + 5*image_std;

% ImageNew is result of user processing in GUI.
figure;imshow(ImageNew,[image_min image_max]); title('Reduced Background Image','FontSize',15)

%meanPix = mean2(ImZdata);
meanPix = mean2(ImageNew);

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

waitfor(close)

mtSpec = 'Method of defect identification: %s\n';
fprintf(fileID,mtSpec,methodId);

% IDENTIFYDEFECTS directs variables to either SHAPEDATA or FILTERDATA. 

[defCoordsX, defCoordsY, defCount, NestedContoursCell] = IdentifyDefects(methodId,ImageNew,ImFlat,meanPix);
[defStats,regionStats,xCoords,yCoords] = DefectStats(defCoordsX,defCoordsY,ImageNew,ImZdata,ImFlat,nmWidth);

