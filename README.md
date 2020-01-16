
DIST: Defect Identification and Statistics Toolbox
-
## Program Description and User Guide

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

There are two methods of identifying defects in DIST: filtering contours based on a set of parameters or via shape matching to a reference contour. 

### Contours

The basis of defect identification in DIST is isolating contour plots in the image that surround defects. After the image is processed with the GUI, contour plots are automatically generated. Since the purpose of the image processing is to increase background uniformity and isolate bright and dark extrema, the contour plots should enclose potential defects in the image. Then, contours surrounding defects are isolated with parameters defined by user inputs. 

Typically, a region of interest will have more than one contour, since the pixels in an image artifact are rarely uniform. To organize groups of concentric contours that are all plotted on the same region of interest (a bright or dark extrema in the image), the contours are sorted into a cell. Each cell contains an array of all the concentric contours in a cluster. The cell has two rows: the top containing the x-coordinates, and the bottom containing the y-coordinates. The "nested cell" is returned by the function "NestedContours". 

The nested cell is created so that users are able to choose (through filtering or shape matching) the specific contour plot that best describes a defect in the image.

### Filtering Contours

Contour filtering is a simple way to isolate the contours that exactly encircle a defect in the image. The contours may be filtered using three parameters: area, number of vertices, and brightness.

- Area: the contour area is computed from MATLAB's "bwarea" function, after the contour is used to create a binary image with MATLAB's "poly2mask" function. The actual filter is based on the difference in area between a target contour and the rest of the contours in the image. 

Area difference parameter recommendations: 

- Vertices: each generated contour is defined by a certain number of points, indicating vertices in the contour, which is a closed shape. This parameter is used most often to filter out contours that poorly resolve a region of interest, i.e. contours with few enough vertices that the shape is jagged and blocky. The vertices paremeter is defined as the minimum number of vertices in a contour, so that contours with less vertices are filtered out. 

- Brightness: oftentimes all of the defects of interest an image have a similar brightness. The brightness parameter is used to filter out contours that enclose an area with a brightness different than the target. For example, in an image with both bright defects and slightly darker artifacts (due to noise etc.), any region with a brightness outside a user-defined range will be filtered out. 


### Shape Matching 

DIST uses Oliver Van Kaick's alogrithm for contour correspondence using ant colony optimization (ACO). This function is useful for images with defects that have a distinctive shape, or when a user is interested in only identifying defects with a specific shape. 

Because a large volume of contour plots in the image will make the shape-matching process slow, the user has the option to filter the contours first, as described above. 

To begin the process, the user is prompted to choose a template defect. The template contour is then compared to every contour in the image, generating a best-cost value for each comparison. The best matching contour from each contour nest (described in "Contours") is selected as a postive defect identfication. DIST generates a histogram with the number of defects grouped by best cost parameter, with a lower value corresponding to a better match. The user can then filter the results based which defects are a closest match in shape. 

## Defect Statistics 
 
Statistics are automatically computed after the defect identification process. The computed statistics are listed below: 

- Line profile: pixel brightness values calculated from a line cross section across each defect contour
- Apparent height: vectors of mean and max/min pixel value for each defect contour (computed from line profile), scaled to nm 
- X/Y coordinates: coordinates of the location of each defect contour

Statistics computed using MATLAB's "regionprops": 

- Area: area of each defect
- Major/minor axis length
- Centroid: location of centroid of each contour
- Orientation: angle orientation of each contour with respect to a horizontal axis (computed from elipse)

