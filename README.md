# Hollen-Lab

DIST: Defect Identification and Statistics Toolbox
-
User Guide:
-
Before using this program, you should make sure to have Oliver Van Kaick's "Contour Correspondence via Ant Colony Optimization" file installed. You can access it here: https://www.mathworks.com/matlabcentral/fileexchange/24094-contour-correspondence-via-ant-colony-optimization.

From the "aco" folder, you should immediately run the function "set_global."

After installing the folder, your starting point should be either a .sm4 file or .mat structure. If you have an image file (.png or .jpg) that has not been converted to a .mat file, you can run the following: 

MyImage = imread('myImageFile.png');
save('MyImage.mat','MyImage');

'MyImage.mat' is your new starting point. If you are not starting with a .sm4 file, you will need to provide the width of the image in nanometers. 

To use the toolbox, start by running "GlobalVar." Set the global variable "output_graph" to "1" if you want graphical outputs and figures containing the processed images. Set the global variable "help_dlg" to "1" if you would like pop-up help boxes to guide you through the toolbox.

After running "GlobalVar", run the program from MATLAB's command line by typing:

[defCoordsX,defCoordsY,defCount,maxHeightVec,meanHeightVec,areaVec,ImFlatSmooth] = STMDefectAnalysis( ImRaw, nmWidth )

where ImRaw is either the .sm4 or .mat file. You don't need an argument for "nmWidth" if you're starting with a .sm4 file.

"DefCoordsX/Y" are the coordinates of the identified defects in your input image. "DefCount" is the number of defects. "max/meanHeightVec" are vectors containing the maximum and average apparent heights, respectively, of all the defects. "AreaVec" is a vector containing the area of all the defects. "ImFlatSmooth" is the processed image. 

"STMDefectAnalysis" will walk you through the toolbox. After the image is processed, a figure will appear with two images side by side, which are the outputs of "UniformBackground." You will be asked to choose an image to use in analysis. If both images have eliminated too many details from the processed image, type "3" to use "ImFlatSmooth" instead, the output of "ImageProcess." The prompt will ask: 'Which image would you like to include for analysis? Please enter "1" to select the first image, and "2" to select the second. Enter "3" to analyze the processed image.'

Next, you will be asked to type "S" or "F" for defect identification, and "B" or "D" for the brightness level of the defects you're interested in. Entering "S" will allow you to identify defects via shape-matching with a template defect, and entering "F" will allow you to identify defects via filters.

In both "ShapeData" and "FilterData", you will be prompted to specify filters for the contour data. After entering the filter values, a figure will appear with contour plots on it. Use your mouse to select a rectangle surrounding a contour plot of interest.

"STMDefectAnalysis" additionally opens a text file when you run it. The file will be your input file name, plus "MetaData.txt". This text file stays open throughout the whole process and records the various operations performed on the image. While the toolbox is running, you may choose to add your own notes to the file. Remember to save it at the end, and if you are going to re-do the analysis on an image, erase the old data in the text file before running the toolbox again.
