% Author: Alana Gudinas
% July 2018
%
% [ defCoordsX, defCoordsY] = ShapeData(ImUniBg,ImLineFlat,ImFlatSmooth,meanPix)
% 
% The purpose of this function is to identify all the defects in an STM
% image using a shape-matching algorithm.
%
% The inputs to the function are similar to other functions in this
% toolbox: (ImUniBig) the uniform background image from UNIFORM BACKGROUND,
% (ImLineFlat) the line-flattened image, (ImFlatSmooth) the processed
% image, and (meanPix) an output from UNIFORM BACKGROUND.
%
% The function outputs the coordinates of the identified defects in the
% image.
%
% In the future I may create separate functions for the loops that delete
% and add contours to the image.
%
% This function allows the user to decide at various moments whether to
% manually add or delete defect contours from the image.

function [ defCoordsX, defCoordsY] = ShapeData(ImUniBg,ImLineFlat,ImFlatSmooth,meanPix)

global help_dlg
global metaDataFile

fileID = fopen(metaDataFile,'a+'); % open txt file
formatSpec = '%s\n';

[rU,cU] = size(ImUniBg);
addDatX = [];
addDatY = [];

[NestedContoursCell, xdataC, ydataC] = NestedContours(ImUniBg,meanPix); % generate cell array of contour groups 

fprintf(fileID,formatSpec,'Contour data generated');

figure; imshow(ImLineFlat,[]);

figure; imshow(ImFlatSmooth,[])
hold on
[~,cN] = size(NestedContoursCell);
for i = 1:cN
    [~,ct] = size(NestedContoursCell{1,i});
    for j = 1:ct
        plot(NestedContoursCell{1,i}(:,j),NestedContoursCell{2,i}(:,j),'Color','cyan')
        hold on
    end
end

if help_dlg
    strhelp = 'You have the option to filter the contour data (the yellow lines in the figure) before you use shape matching to identify defects. There are two filters you may apply: an area filter and a vertex filter.';
    h1 = helpdlg(strhelp,'Optional Filtering');
    waitfor(h1);
end

promptfilt = 'Would you like to include contour data filters before executing shape matching? (Yes/No)';
titleBox = 'Filter Option';
dims = [1 75];
definput = {'Yes'};
optionfilt = inputdlg(promptfilt,titleBox,dims,definput);
optionfilt = optionfilt{1};

if strcmp(optionfilt,'No')
    [defCoordsX, defCoordsY,bestvec] = NestedShapeMatching(ImUniBg, NestedContoursCell, xdataC, ydataC);
    fprintf(fileID,formatSpec,'Shape matching completed');
elseif strcmp(optionfilt,'Yes')
    if help_dlg
        strhelp2 = 'The area filter is defined by the difference in area between your target defect and the other contour lines in the image. For larger defects, an area filter that is < 100 is restrictive. 250 is a good starting point. For smaller defects, start with a value of 150. The vertex filter is specified by the number of points in each contour plot. You may specify a maximum or minimum amount of vertices a contour line can have. A good minimum is 20 vertices.';
        h2 = helpdlg(strhelp2,'Filter Guidelines');
        waitfor(h2);
        strhelp3 = 'Start with the recommended area and vertex filters. The filter results will be plotted, and you may choose a better-suited filter afterwards.';
        h3 = helpdlg(strhelp3,'Filter Guidelines');
        waitfor(h3);
    end
    
    promptselect = {'Enter an area difference filter:','Enter a vertex filter:'};
    titleBox = 'Filter Specification';
    definput = {'250','30'};
    dim = [1 60];
    ansSelect = inputdlg(promptselect,titleBox,dim,definput);
    
    areaFilt = ansSelect{1};
    vtxFilt = ansSelect{2};
    
    areaFilt = str2num(areaFilt); % convert answer to a number
    vtxFilt = str2num(vtxFilt);
    
    if help_dlg
        strhelp5 = 'Draw a rectangle around your the defect you are interested in comparing others to. The results of the comparison via your chosen filters will be plotted.';
        h5 = helpdlg(strhelp5,'Template Selection');
        waitfor(h5);
    end
    
    coNest = NestedContoursCell; % easier to type 
    [rN,cN] = size(coNest);
    xCoord = [];
    yCoord = [];
    rectSh = getrect; % allows user to select rectangle region on current figure 
    close all

    for j = 1:cN 
        [~,ct] = size(coNest{1,j});
        for i = 1:ct
            xCoord = coNest{1,j}(:,i); % temporary variable
            yCoord = coNest{2,j}(:,i);
            xCoord(isnan(xCoord)) = []; % get rid of NaN values, doesn't work with getrect
            yCoord(isnan(yCoord)) = [];
            if ~isempty(xCoord) % skip empty vectors
                if ((xCoord > rectSh(1)) & (xCoord < (rectSh(1)+rectSh(3)))) & ((yCoord > rectSh(2)) & (yCoord < (rectSh(2)+rectSh(4))))
                    xi = xCoord;
                    yi = yCoord;
                    plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
                    drawnow
                    hold on
                end
            end
        end
    end
    hold off
    
    if help_dlg
        shapehelp2 = 'Of the cluster of contour lines, click within the area enclosed by your contour of interest.';
        h2 = helpdlg(shapehelp2,'Template Selection');
        waitfor(h2);
    end
    
    
    % rect = getrect; % select another region for final template selection, since multiple contours will often be displayed
    
    [x,y] = ginput(1);
    xCoord = []; % just to be safe, reset variables
    yCoord = [];
    xi = [];
    yi = [];
    k = 1; % for indexing 
    
    figure; imshow(ImUniBg,[]);
    hold on
    % the following is for finding the exact contour plot that lies within
    % the user's selected rectangle. It will automatically pick the plot
    % with the largest area within the rectangle.
    for j = 1:cN 
        [~,ct] = size(coNest{1,j});
        for i = 1:ct
            xCoord = coNest{1,j}(:,i);
            yCoord = coNest{2,j}(:,i);
            xCoord(isnan(xCoord)) = [];
            yCoord(isnan(yCoord)) = [];
            if ((x < max(xCoord)) & (x > min(xCoord))) & ((y < max(yCoord)) & (y > min(yCoord)))
                xRef(:,k) = coNest{1,j}(:,i);
                yRef(:,k) = coNest{2,j}(:,i);
                k = k + 1;
            end
        end
    end
    [maxvec] = max(xRef); % find the greatest x value in the matrix
    [maxval,idxval] = max(maxvec); % find the index
    xi = xRef(:,idxval); % find the largest plot 
    yi = yRef(:,idxval);
    xi(isnan(xi)) = [];
    yi(isnan(yi)) = [];
    plot(xi,yi,'Color','cyan');

    FilteredNest = NestedContoursCell; % set new variable that will be filtered according to previous specs
    
    ImBWRef = poly2mask(xi,yi,rU,cU); % create binary image from target coordinates
    s = regionprops(ImBWRef,'Centroid'); % Find coordinates of center of defect.
    centRef = cat(1, s.Centroid);
    xCent = centRef(:,1); % centroid coordinates of reference defect
    yCent = centRef(:,2);
    
    % loop through and filter contour data
    for j = 1:cN 
        [rt,ct] = size(coNest{1,j});
        for i = 1:ct
            xCoord = coNest{1,j}(:,i);
            yCoord = coNest{2,j}(:,i);
            xCoord(isnan(xCoord)) = [];
            yCoord(isnan(yCoord)) = [];
            if ~isempty(xCoord)
                if ((xCoord(1) == xCoord(end)) && (yCoord(1) == yCoord(end))) % only store closed loops
                    if length(xCoord) <= vtxFilt
                        FilteredNest{1,j}(:,i) = NaN(rt,1); % if the contour is below vertex filter, insert NaNs
                        FilteredNest{2,j}(:,i) = NaN(rt,1);
                        continue
                    elseif length(xCoord) > vtxFilt % otherwise...calculate the difference in area of each contour against the reference
                        ImBWComp = poly2mask(xCoord,yCoord,rU,cU); % binary image of contour 
                        sdata = regionprops(ImBWComp,'Centroid');
                        centroid = cat(1, sdata.Centroid);
                        xComp = centroid(1); % centroid coordinates of defect
                        yComp = centroid(2);
                        diffX = xComp - xCent; % find difference between reference coordinates and currently indexed coordinates
                        diffY = yComp - yCent;
                        xChange = xi + diffX; % add difference to target defect to overlay the shape with the defect currently being tested
                        yChange = yi + diffY;
                        Im_binC = poly2mask(xChange,yChange,cU,rU); % make a new binary image
                        ImDiff = imsubtract(Im_binC,ImBWComp); % subtract the white area of the reference with the current defect
                        diffArea = bwarea(ImDiff); % area difference vector
                        if diffArea > areaFilt
                            FilteredNest{1,j}(:,i) = NaN(rt,1); % if contour exceeds filter, put in NaNs
                            FilteredNest{2,j}(:,i) = NaN(rt,1);
                        end
                    end
                else
                    FilteredNest{1,j}(:,i) = NaN(rt,1); % if the contour is below vertex filter, insert NaNs
                    FilteredNest{2,j}(:,i) = NaN(rt,1);
                end
            end
        end
    end
    
    formatFilt = 'Area filter: %d, vertex filter: %d\n';
    fprintf(fileID,formatFilt,[areaFilt; vtxFilt]);
    
    diffAreaVec = AreaDifference(xi,yi,xdataC,ydataC,cU,rU); % repeat the process with the non-cell array data for comparison
    xint = [];
    yint = [];
    xFilt = [];
    yFilt = [];
    k = 1;
    
    for i = 1:length(xdataC(1,:))
        xfd = xdataC(:,i);
        xfd(isnan(xfd)) = [];
        num = length(xfd);
        vtxVec(i) = num;
    end
    xB = xdataC;
    yB = ydataC;
    for i = 1:length(xdataC(1,:))
        xint = xdataC(:,i);
        yint = ydataC(:,i);
        xint(isnan(xint)) = [];
        yint(isnan(yint)) = [];
        if ((diffAreaVec(i)<areaFilt) && (vtxVec(i)>vtxFilt))
            xFilt(:,k) = xdataC(:,i); % xFilt is just the filtered contour data matrix
            yFilt(:,k) = ydataC(:,i);
            k = k + 1;
        end
    end
    xCoord = [];
    yCoord = [];
    close all
    figure; imshow(ImFlatSmooth,[]); title('Plots remaining after filters were applied');
    hold on
    [rNest,cNest] = size(FilteredNest);
    for i = 1:cNest
        [rt,ct] = size(NestedContoursCell{1,i});
        for j = 1:ct
            xCoord = FilteredNest{1,i}(:,j);
            yCoord = FilteredNest{2,i}(:,j);
            plot(xCoord,yCoord,'Color','magenta'); % plot the contours after being filtered
            drawnow
            hold on
        end
    end
    [defCoordsX, defCoordsY,bestvec] = NestedShapeMatching(ImUniBg, FilteredNest, xFilt, yFilt); % shove coordinates into shape matching program
    fprintf(fileID,formatSpec,'Shape matching completed');
end
    
figure; imshow(ImFlatSmooth,[]); title('Results of the first round of identification via shape matching'); 
hold on
plot(defCoordsX,defCoordsY,'Color','cyan');
hold off
figure; imshow(ImLineFlat,[]);
hold on
plot(defCoordsX,defCoordsY,'Color','yellow');
hold off

figure; histogram(bestvec); title('Best Cost Histogram');
prompt1 = 'Would you like to filter the results based on shape similarity? Y/N';
titleBox = 'Best Cost Filter';
dims = [1 75];
definput = {'N'};
optb = inputdlg(prompt1,titleBox,dims,definput);
optb = optb{1};

if strcmp(optb,'Y')
    [x,y] = ginput(1);
    for i = 1:length(bestvec)
        if bestvec(i) > x
            defCoordsX(:,i) = NaN;
            defCoordsY(:,i) = NaN;
            bestvec(i) = NaN;
        end
    end
end
close all

figure; imshow(ImLineFlat,[]);

figure; imshow(ImFlatSmooth,[]);
hold on
plot(defCoordsX,defCoordsY,'Color','cyan');
hold off

prompt1 = 'Are all the defects in the image correctly identified? (Yes/No)';
titleBox = 'Accuray Inquiry';
dims = [1 75];
definput = {'Yes'};
option1 = inputdlg(prompt1,titleBox,dims,definput);
option1 = option1{1};

%--------------------------------------------------------------------------%
% This begins the "choose your own adventure" part of the function. If the
% user is dissatisfied with the identified defects, they may opt to add,
% delete, or re-analyze regions in the image.
%--------------------------------------------------------------------------%

if strcmp(option1,'Yes')
    m1 = msgbox('Defects have been identified!','Success');
    waitfor(m1);
elseif strcmp(option1,'No')
    prompt2 = 'Are there missing defects? (Yes/No)';
    titleBox = 'Accuracy Inquiry';
    dims = [1 60];
    definput = {'Yes'};
    option2 = inputdlg(prompt2,titleBox,dims,definput);
    option2 = option2{1};
    if strcmp(option2,'No')
        prompt3 = 'Are there defects that should be removed? (Yes/No)';
        titleBox = 'Defect Removal';
        dims = [1 60];
        definput = {'Yes'};
        option3 = inputdlg(prompt3,titleBox,dims,definput);
        option3 = option3{1};
        if strcmp(option3,'No')
            m2 = msgbox('Then what is all the fuss about?!','Confused');
            waitfor(m2);
        elseif strcmp(option3,'Yes')
            if help_dlg
                helpdel = 'When prompted by the command line. type "1" to begin defect deletion. When you are satisfied, type "0" in the command line';
                hdel = helpdlg(helpdel,'Defect Deletion');
                waitfor(hdel);
            end
            xCoordDel = defCoordsX; % new variable for defects after deletion process
            yCoordDel = defCoordsY;
            numD = 0;
            pd = 'Type "0" when finished removing defects. Type "1" to begin. [0]:'; % input from command line
            anspd = input(pd);
            while anspd ~= 0
                [x,y] = ginput(1); % user draws rectangle on image of defects
                for j = 1:length(defCoordsX(1,:))
                    xbn = defCoordsX(:,j);
                    ybn = defCoordsY(:,j);
                    xbn(isnan(xbn)) = [];
                    ybn(isnan(ybn)) = [];
                    if ((x < max(xbn)) & (x > min(xbn))) & ((y < max(ybn)) & (y > min(ybn)))
                        xCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1); % if the coordinate is inside rectangle, we don't want it any more
                        yCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        close all
                        figure; imshow(ImUniBg,[]);
                        hold on
                        plot(xCoordDel,yCoordDel,'Color','yellow')
                        hold off
                        numD = numD + 1;
                    end
                end
                pd = 'Type "0" when finished removing defects. [0]:';
                anspd = input(pd); % repeat process until user types "0"
            end 
            xCoordDel( ~any(xCoordDel,2), : ) = [];  % get rid of columns and rows that are all NaN
            xCoordDel( :, ~any(xCoordDel,1) ) = []; 
            yCoordDel( ~any(yCoordDel,2), : ) = [];  
            yCoordDel( :, ~any(yCoordDel,1) ) = []; 
            xCoordDel(xCoordDel == 0) = NaN; % set zeros to NaN
            yCoordDel(yCoordDel == 0) = NaN; 
            
            delSpec = 'Number of contours deleted: %d\n';
            fprintf(fileID,delSpec,numD);
            
            prompt4 = 'Are there defects that should be added? (Yes/No)';
            titleBox = 'Defect Addition';
            dims = [1 60];
            definput = {'No'};
            option4 = inputdlg(prompt4,titleBox,dims,definput);
            option4 = option4{1};
            if strcmp(option4,'Yes')
                if help_dlg
                    adds = 'Please select a region containg a defect that shold be re-analyzed. When you are ready to begin, type 1 in the command line. When you have finished analyzing more regions, type 0. [0]:';
                    helpadd = helpdlg(adds,'Defect Addition');
                    waitfor(helpadd);
                end
                pd = 'Type "0" when finished adding defects. Type "1" to begin. [0]:';
                anspd = input(pd); % input from the command line 
                [r2,c2] = size(xCoordDel);
                defCoordsX = []; % final viariable
                defCoordsY = [];
                % don't know of a more generalized way to do this, but
                % alter the size of defAddX and Y if need be..
                defAddX = zeros(750,100); % since all the added contours will be different lengths, need to set empty matrix. Not the best way.
                defAddY = zeros(750,100); 
                addDatX = zeros(750,200); 
                addDatY = zeros(750,200); 
                k = 1;
                numA = 0;
                while anspd ~= 0 
                    rectAdd = getrect; % user selects region that needs further analysis
                    [ AddX, AddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd); % rectangle coordinates are inputted
                    [rx,cx] = size(AddX);
                    numA = numA + cx;
                    addDatX(1:rx,numA:numA+cx-1) = AddX;
                    addDatY(1:rx,numA:numA+cx-1) = AddY;
                    for i = 1:cx
                        defAddX(1:rx,k) = AddX(:,i); % add new defect coordinates to matrix
                        defAddY(1:rx,k) = AddY(:,i);
                        k = k + 1;
                    end
                    [r1,c1] = size(defAddX); 
                    if r1 > r2 % if defAddX is bigger than xCoordDel, make defCoords the size of defAdd
                        defCoordsX = zeros(r1,c1+c2);
                        defCoordsY = zeros(r1,c1+c2);
                    elseif r1 < r2 % vice versa
                        defCoordsX = zeros(r2,c1+c2);
                        defCoordsY = zeros(r2,c1+c2);
                    end
                    for j = 1:c1
                        defCoordsX(1:r1,j) = defAddX(:,j); % add matrix to matrix
                        defCoordsY(1:r1,j) = defAddY(:,j);
                    end

                    for k = 1:c2
                        defCoordsX(1:r2,k+c1) = xCoordDel(:,k); % add the previous data
                        defCoordsY(1:r2,k+c1) = yCoordDel(:,k);
                    end
                    defCoordsX( ~any(defCoordsX,2), : ) = [];  % get rid of nan columns and rows
                    defCoordsX( :, ~any(defCoordsX,1) ) = []; 
                    defCoordsY( ~any(defCoordsY,2), : ) = [];  
                    defCoordsY( :, ~any(defCoordsY,1) ) = []; 
                    defCoordsX(defCoordsX == 0) = NaN;
                    defCoordsY(defCoordsY == 0) = NaN;  

                    figure; imshow(ImFlatSmooth,[]);
                    hold on
                    plot(defCoordsX,defCoordsY,'Color','cyan');
                    pd = 'Type "0" when finished adding defects. [0]:';
                    anspd = input(pd); % repeat until user types "0"
                end
                
                addSpec = 'Number of defects added: %d\n';
                fprintf(fileID,addSpec,numA);
                
            elseif strcmp(option4,'No')
                defCoordsX = xCoordDel;
                defCoordsY = yCoordDel;
            end
        end
    elseif strcmp(option2,'Yes') % same as above, different branch of the tree
        if help_dlg
            adds = 'Please select a region containg a defect that shold be re-analyzed. When you are ready to begin, type 1 in the command line. When you have finished analyzing more regions, type 0. [0]:';
            helpadd = helpdlg(adds,'Defect Addition');
            waitfor(helpadd);
        end
        pd = 'Type "0" when finished adding defects. Type "1" to begin. [0]:';
        anspd = input(pd);
        xInt = defCoordsX;
        yInt = defCoordsY;
        [r2,c2] = size(xInt);
        defCoordsX = [];
        defCoordsY = [];
        defAddX = zeros(750,100);
        defAddY = zeros(750,100);
        addDatX = zeros(750,200); 
        addDatY = zeros(750,200); 
        k = 1;
        numA = 0;
        while anspd ~= 0 
            rectAdd = getrect;
            [ AddX, AddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd);
            [rx,cx] = size(AddX);
            numA = numA + cx;
            addDatX(1:rx,numA:numA+cx-1) = AddX;
            addDatY(1:rx,numA:numA+cx-1) = AddY;
            for i = 1:cx
                defAddX(1:rx,k) = AddX(:,i);
                defAddY(1:rx,k) = AddY(:,i);
                k = k + 1;
            end
            [r1,c1] = size(defAddX);
            if r1 > r2
                defCoordsX = zeros(r1,c1+c2);
                defCoordsY = zeros(r1,c1+c2);
            elseif r1 < r2
                defCoordsX = zeros(r2,c1+c2);
                defCoordsY = zeros(r2,c1+c2);
            end
            for j = 1:c1
                defCoordsX(1:r1,j) = defAddX(:,j);
                defCoordsY(1:r1,j) = defAddY(:,j);
            end

            for n = 1:c2
                defCoordsX(1:r2,n+c1) = xInt(:,n);
                defCoordsY(1:r2,n+c1) = yInt(:,n);
            end
            defCoordsX( ~any(defCoordsX,2), : ) = [];  
            defCoordsX( :, ~any(defCoordsX,1) ) = []; 
            defCoordsY( ~any(defCoordsY,2), : ) = [];  
            defCoordsY( :, ~any(defCoordsY,1) ) = []; 
            defCoordsX(defCoordsX == 0) = NaN;
            defCoordsY(defCoordsY == 0) = NaN;  
        
            figure; imshow(ImFlatSmooth,[]);
            hold on
            plot(defCoordsX,defCoordsY,'Color','cyan');
            pd = 'Type "0" when finished adding defects. [0]:';
            anspd = input(pd);
        end
        addSpec = 'Number of defects added: %d\n';
        fprintf(fileID,addSpec,numA);
        
        prompt3 = 'Are there defects that should be removed? (Yes/No)';
        titleBox = 'Defect Removal';
        dims = [1 60];
        definput = {'Yes'};
        option3 = inputdlg(prompt3,titleBox,dims,definput);
        option3 = option3{1};
        if strcmp(option3,'No')
            disp('Done!');
        elseif strcmp(option3,'Yes')
            if help_dlg
                helpdel = 'When prompted by the command line. type "1" to begin defect deletion. When you are satisfied, type "0" in the command line';
                hdel = helpdlg(helpdel,'Defect Deletion');
                waitfor(hdel);
            end
            xCoordDel = defCoordsX;
            yCoordDel = defCoordsY;
            xAddDel = addDatX;
            yAddDel = addDatY;
            pd = 'Type "0" when finished removing defects. Type "1" to begin. [0]:';
            anspd = input(pd);
            numD = 0;
            while anspd ~= 0
                [x,y] = ginput(1);
                for j = 1:length(defCoordsX(1,:))
                    xbn = defCoordsX(:,j);
                    ybn = defCoordsY(:,j);
                    xbn(isnan(xbn)) = [];
                    ybn(isnan(ybn)) = [];
                    if ((x < max(xbn)) & (x > min(xbn))) & ((y < max(ybn)) & (y > min(ybn)))
                        xCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        yCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        close all
                        figure; imshow(ImLineFlat,[]);
                        hold on
                        plot(xCoordDel,yCoordDel,'Color','yellow')
                        hold off
                        numD = numD + 1;
                    end
                end
                for i = 1:length(addDatX(1,:))
                    xan = addDatX(:,i);
                    yan = addDatY(:,i);                    
                    xan(isnan(xan)) = [];
                    yan(isnan(yan)) = [];
                    if ((x < max(xan)) & (x > min(xan))) & ((y < max(yan)) & (y > min(yan)))
                        xAddDel(:,j) = NaN(length(xAddDel(:,1)),1); % it needs to only take smallest area %%%%%%%%%
                        yAddDel(:,j) = NaN(length(yAddDel(:,1)),1);
                    end
                end
                pd = 'Type "0" when finished removing defects. [0]:';
                anspd = input(pd);
            end 
            delSpec = 'Number of defects deleted: %d\n';
            fprintf(fileID, delSpec, numD);
            hold off
            defCoordsX = xCoordDel;
            defCoordsY = yCoordDel;
            addDatX = xAddDel;
            addDatY = yAddDel;
        end
    end
end

figure; imshow(ImLineFlat,[]); title('All identified defects');
hold on
plot(defCoordsX,defCoordsY,'Color',[173/255;255/255;47/255]);

%--------------------------------------------------------------------------%
% The last step allows the user to quickly add contour plots to the image
% without any analysis.
%--------------------------------------------------------------------------%

quickadd = 'You may choose to add contour lines to the plot without analyzing specific image regions. If you would like to add contour lines around missing defects, type "Y". Y/N';
titleBox = 'Quick Add';
dims = [1 75];
definput = {'N'};
optquick = inputdlg(quickadd,titleBox,dims,definput);
optquick = optquick{1};

% this only works if xdataC is now somehow the same size as defCoordsX
if strcmp(optquick,'N')
    figure; imshow(ImLineFlat,[]); title('All identified defects');
    hold on
    plot(defCoordsX,defCoordsY,'Color',[173/255;255/255;47/255]);
    hold off
elseif strcmp(optquick,'Y')
    addX = [];
    addY = [];
    figure; imshow(ImLineFlat,[]);
    hold on
    plot(xdataC,ydataC,'Color','magenta');
    plot(defCoordsX,defCoordsY,'Color',[173/255;255/255;47/255]);
    [r1,c1] = size(defCoordsX);
    [r2,c2] = size(xdataC);
    if r1 > r2
        xdataC(r2+1:r1,:) = NaN;
        ydataC(r2+1:r1,:) = NaN;
    elseif r2 > r1
        defCoordsX(r1+1:r2,:) = NaN;
        defCoordsY(r1+1:r2,:) = NaN;
    end     
    if help_dlg
        quickhelp = 'Draw a rectangle around a region where you wish to plot a contour line. When prompted by the command line, type "1" to begin. Type "0" when you are finished.';
        qh = helpdlg(quickhelp,'Quick Add');
        waitfor(qh);
    end
    pd = 'Type "0" when finished adding contour lines. Type "1" to begin. [0]:';
    anspd = input(pd);
    numA = 0;
    [rA,cA] = size(addDatX);
    while anspd ~= 0 % same type of loop as deleting and adding
        quickR = getrect; % select contour 
        for i = 1:c2
            xCoord = xdataC(:,i);
            yCoord = ydataC(:,i);
            xCoord(isnan(xCoord)) = [];
            yCoord(isnan(yCoord)) = [];
            if ((xCoord > quickR(1)) & (xCoord < (quickR(1)+quickR(3)))) & ((yCoord > quickR(2)) & (yCoord < (quickR(2)+quickR(4)))) % Test each plot to see if it falls within rectangle.
                addX = [addX, xdataC(:,i)];
                addY = [addY, ydataC(:,i)];
            end
        end
        if ~isempty(addX)
            [maxvec] = max(addX);
            [maxval,idxval] = max(maxvec);
            xi = addX(:,idxval); % add the largest contour within the rectangle
            yi = addY(:,idxval);
            defCoordsX = [defCoordsX, xi];
            defCoordsY = [defCoordsY, yi];
            rx = length(xi);
            cx = 1;
            plot(xi,yi,'Color','cyan');
            drawnow
            hold on
            numA = numA + 1;
            addDatX(1:rx,cA+numA) = xi;
            addDatY(1:rx,cA+numA) = yi;
        end
        pd = 'Type "0" when finished adding plots. [0]:';
        anspd = input(pd);
    end 
    addSpec = 'Number of contours added: %d\n';
    fprintf(fileID,addSpec,numA);
    hold off  
end

if ~isempty(addDatX)
    addDatX( ~any(addDatX,2), : ) = [];  
    addDatX( :, ~any(addDatX,1) ) = []; 
    addDatY( ~any(addDatY,2), : ) = [];  
    addDatY( :, ~any(addDatY,1) ) = []; 
    addDatX(addDatX == 0) = NaN;
    addDatY(addDatY == 0) = NaN;  
end

defCoordsX( ~any(defCoordsX,2), : ) = [];  
defCoordsX( :, ~any(defCoordsX,1) ) = []; 
defCoordsY( ~any(defCoordsY,2), : ) = [];  
defCoordsY( :, ~any(defCoordsY,1) ) = []; 
defCoordsX(defCoordsX == 0) = NaN;
defCoordsY(defCoordsY == 0) = NaN;  

close all
figure; imshow(ImFlatSmooth,[]);
hold on
plot(defCoordsX,defCoordsY,'Color','cyan')
plot(addDatX,addDatY,'Color','magenta');
hold off

% Done!

end