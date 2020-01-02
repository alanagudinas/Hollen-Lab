
DIST: Defect Identification and Statistics Toolbox
-
## User Guide

DIST is a MATLAB toolbox for identifying and analyzing atomic defects present in scanning probe microscopy (SPM) images. This toolbox was created with scanning tunneling microscope (STM) images in mind, but can be used with any image. 

This document is meant to provide a brief overview of the toolbox and how to use it to generate defect statistics. 

Before using this program, you must install Oliver Van Kaick's "Contour Correspondence via Ant Colony Optimization" MATLAB files. You can access it here: https://www.mathworks.com/matlabcentral/fileexchange/24094-contour-correspondence-via-ant-colony-optimization.

## Starting up

In order to use DIST, you should have the following MATLAB files installed: 

- DIST
- sm4reader
- FilteringGUI.fig
- FilteringGUI
- GlobalVar
- ShapeData
- FilterData
- FilterNest
- Identify Defects
- DefectStats
- ContourData
- NestedContours
- NestedShapeMatching
- SmallRegion
- AreaDifference

DIST requires an image file as an input. If using RHK-generated data in a .sm4 file format, you can convert the file to a .mat structure using Jason Moscatello's "sm4reader.m". This will create a structure with fields corresponding to different information encapsulated in the sm4 file. More information can be found at: https://unh2d.weebly.com/using-sm4-files-in-matlab.html.

DIST accepts the following file formats: 
- png
- mat
- sm4
- asc

The width of the original image in nanometers is required for generating statistics of identified defects. If the input file is .sm4, this is computed automatically. Otherwise, the width must be provided.

To run DIST, the ACO algorithm by Oliver Van Kaick (described above) must first be installed. From the "aco" folder, you should immediately run the function "set_global" by typing > set_global in the command line. Next, run GlobalVar to initialize global variables in DIST. For first-time users, it is recommended that you set the global variable "help_dlg" to "1" to trigger pop-up help boxes to guide you through the toolbox.

Type the following in MATLAB's command line to begin the program: 

[outputs] = DIST( fileName, imageWidth )

## Interactive Image Processing

Running DIST will first trigger a GUI with two image frames and four interactive sliders. The left image is the original, and the right is the processed image updated when the sliders are moved. There are four controls: 

- Strel disk radius: adjusts size of MATLAB strel object. https://www.mathworks.com/help/images/ref/strel.html
- Gaussian filter sigma: adjusts standard deviation of 2-D Gaussian smoothing kernel.https://www.mathworks.com/help/images/ref/imgaussfilt.html
- Lower bound parameter: sets the minimum pixel value in the image. Any pixels brighter than this value (and lower than the upper bound parameter) will be set to the mean pixel value in the image, which determines the background. 
- Upper bound parameter: sets the maximum. pixel value in the image. Any pixels darker than this value (and brighter than the lower bound parameter) will be set to the mean pixel value in the image, which determines the background.

The lower and upper bound parameters should be adjusted until the defects of interest are isolated from the background.

## Defect Identification

### Filtering Contours

### Shape Matching 

## Defect Statistics 
 


