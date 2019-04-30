% Author: Alana Gudinas

% This is the umbrella function for DIST: Defect Identification and
% Statistics Toolbox.
% This steps through the processing and sets outputs. 
% Note: if inputting a .mat file, it must be formatted in the same way as
% the program: sm4reader.

function [ImageNew,ImZdata,defStats,regionStats,xCoords,yCoords] = DIST( ImRaw, nmWidth )

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
    
if strcmp(ext,'.sm4') 
    ImID = fopen(ImRaw); % open if an .sm4 file
    [FormatImRawFile, ImRawFile] = sm4reader(ImID); % use Jason's function to read the image and output a .mat structure
    ImSM4 = FormatImRawFile;
    fprintf(fileID,formatSpec,'Image file opened');
    ImData = ImSM4.Spatial.TopoData{1}; % ImData is the topographical data of the raw image.
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata] = FilteringGUI(ImData);
elseif strcmp(ext,'.mat')
    ImR = load(ImRaw);
    ImData = ImR.Spatial.TopoData{1};
    fprintf(fileID,formatSpec,'Image file opened');
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata] = FilteringGUI(ImData);
elseif strcmp(ext,'.png')
    ImRaw = imread(ImRaw);
    save('ImRaw.mat','ImRaw');
    ImData = load('ImRaw.mat'); % create new variable
    ImData = cell2mat(struct2cell(ImData)); % convert to a matrix
    fprintf(fileID,formatSpec,'Image file opened');
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata] = FilteringGUI(ImData)
elseif strcmp(ext,'.asc')
    ImData = load(ImRaw);
    fprintf(fileID,formatSpec,'Image file opened');
    %figure;imshow(ImData,[]); title('Raw Image Data');
    [~,~,~,~,ImageNew,ImZdata] = FilteringGUI(ImData)
end

if nargin == 1 % have to fix this
    imWidth = ImSM4.Spatial.width;
    nmWidth = imWidth*(1e9); % Data is in meters, multiply by 1e9 to convert to nm.
elseif nargin == 0
    error('Not enough input arguments, image file name is required');
end

image_mean = mean2(ImageNew);
image_std = std2(ImageNew);
image_min = image_mean - 5*image_std;
image_max = image_mean + 5*image_std;

figure;imshow(ImageNew,[image_min image_max]); title('Reduced Background Image','FontSize',15)

meanPix = mean2(ImZdata);

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

% Identify defects directs variables to either SHAPEDATA or FILTERDATA. 

[ defCoordsX, defCoordsY, defCount] = IdentifyDefects(methodId,ImageNew,ImZdata,meanPix);
[defStats,regionStats,xCoords,yCoords] = DefectStats(defCoordsX,defCoordsY,ImageNew,ImZdata,nmWidth);

