function [ defCoordsX, defCoordsY] = ShapeData(ImUniBg,ImLineFlat,ImFlatSmooth,meanPix)

[rU,cU] = size(ImUniBg);

[NestedContoursCell, xdataC, ydataC] = NestedContours(ImUniBg,meanPix);

figure; imshow(ImUniBg,[]);
hold on
plot(xdataC,ydataC,'Color','yellow');
hold off

strhelp = 'You have the option to filter the contour data (the yellow lines in the figure) before you use shape matching to identify defects. There are two filters you may apply: an area filter and a vertex filter.';
h1 = helpdlg(strhelp,'Optional Filtering');
waitfor(h1);

promptfilt = 'Would you like to include contour data filters before executing shape matching? (Yes/No)';
titleBox = 'Filter Option';
dims = [1 75];
definput = {'Yes'};
optionfilt = inputdlg(promptfilt,titleBox,dims,definput);
optionfilt = optionfilt{1};

if strcmp(optionfilt,'No')
    [defCoordsX, defCoordsY] = NestedShapeMatching(ImUniBg, NestedContoursCell, xdataC, ydataC);
elseif strcmp(optionfilt,'Yes')
    strhelp2 = 'The area filter is defined by the difference in area between your target defect and the other contour lines in the image. For larger defects, an area filter that is < 100 is restrictive. 250 is a good starting point. For smaller defects, start with a value of 150. The vertex filter is specified by the number of points in each contour plot. You may specify a maximum or minimum amount of vertices a contour line can have. A good minimum is 20 vertices.';
    h2 = helpdlg(strhelp2,'Filter Guidelines');
    waitfor(h2);
    strhelp3 = 'Start with the recommended area and vertex filters. The filter results will be plotted, and you may choose a better-suited filter afterwards.';
    h3 = helpdlg(strhelp3,'Filter Guidelines');
    waitfor(h3);
    
    promptselect = {'Enter an area difference filter:','Enter a vertex filter:'};
    titleBox = 'Filter Specification';
    definput = {'250','30'};
    dim = [1 60];
    ansSelect = inputdlg(promptselect,titleBox,dim,definput);
    
    areaFilt = ansSelect{1};
    vtxFilt = ansSelect{2};
    
    areaFilt = str2num(areaFilt);
    vtxFilt = str2num(vtxFilt);
    
    figure; imshow(ImLineFlat,[]);
    
    strhelp5 = 'Draw a rectangle around your the defect you are interested in comparing others to. The results of the comparison via your chosen filters will be plotted.';
    h5 = helpdlg(strhelp5,'Template Selection');
    waitfor(h5);
    
    rectSh = getrect;
    
    coNest = NestedContoursCell;
    [rN,cN] = size(coNest);
    xCoord = [];
    yCoord = [];
    
    for j = 1:cN 
        [~,ct] = size(coNest{1,j});
        for i = 1:ct
            xCoord = coNest{1,j}(:,i);
            yCoord = coNest{2,j}(:,i);
            xCoord(isnan(xCoord)) = [];
            yCoord(isnan(yCoord)) = [];
            if ~isempty(xCoord)
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
    
    shapehelp2 = 'Of the cluster of contour lines, select the shape of the defect you are interested. Be sure to completely enclose the shape of interest with the rectangle. The largest line completely inside the rectangle will be chosen as the template defect.';
    h2 = helpdlg(shapehelp2,'Template Selection');
    waitfor(h2);
    
    rect = getrect;

    close all
    
    xCoord = [];
    yCoord = [];
    xi = [];
    yi = [];
    k = 1;
    
    figure; imshow(ImUniBg,[]);
    hold on
    for j = 1:cN 
        [~,ct] = size(coNest{1,j});
        for i = 1:ct
            xCoord = coNest{1,j}(:,i);
            yCoord = coNest{2,j}(:,i);
            xCoord(isnan(xCoord)) = [];
            yCoord(isnan(yCoord)) = [];
            if ((xCoord > rect(1)) & (xCoord < (rect(1)+rect(3)))) & ((yCoord > rect(2)) & (yCoord < (rect(2)+rect(4))))
                xRef(:,k) = coNest{1,j}(:,i);
                yRef(:,k) = coNest{2,j}(:,i);
                k = k + 1;
            end
        end
    end
    [maxvec] = max(xRef);
    [maxval,idxval] = max(maxvec);
    xi = xRef(:,idxval);
    yi = yRef(:,idxval);
    xi(isnan(xi)) = [];
    yi(isnan(yi)) = [];
    plot(xi,yi,'Color','cyan');
 
    FilteredNest = NestedContoursCell;
    
    ImBWRef = poly2mask(xi,yi,rU,cU);
    s = regionprops(ImBWRef,'Centroid'); % Find coordinates of center of defect.
    centRef = cat(1, s.Centroid);
    xCent = centRef(:,1);
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
                if ((xCoord(1) == xCoord(end)) && (yCoord(1) == yCoord(end))) 
                    if length(xCoord) <= vtxFilt
                        FilteredNest{1,j}(:,i) = NaN(rt,1);
                        FilteredNest{2,j}(:,i) = NaN(rt,1);
                    elseif length(xCoord) > vtxFilt
                        ImBWComp = poly2mask(xCoord,yCoord,rU,cU);
                        sdata = regionprops(ImBWComp,'Centroid');
                        centroid = cat(1, sdata.Centroid);
                        xComp = centroid(1);
                        yComp = centroid(2);
                        diffX = xComp - xCent;
                        diffY = yComp - yCent;
                        xChange = xi + diffX;
                        yChange = yi + diffY;
                        Im_binC = poly2mask(xChange,yChange,512,512);
                        ImDiff = imsubtract(Im_binC,ImBWComp); 
                        diffArea = bwarea(ImDiff);
                        if diffArea > areaFilt
                            FilteredNest{1,j}(:,i) = NaN(rt,1);
                            FilteredNest{2,j}(:,i) = NaN(rt,1);
                        end
                    end
                end
            end
        end
    end
    
    diffAreaVec = AreaDifference(xi,yi,xdataC,ydataC);
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
            xFilt(:,k) = xdataC(:,i);
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
            plot(xCoord,yCoord,'Color','magenta');
            drawnow
            hold on
        end
    end
    [defCoordsX, defCoordsY] = NestedShapeMatching(ImUniBg, FilteredNest, xFilt, yFilt);
end

figure; imshow(ImFlatSmooth,[]); title('Results of the first round of identification via shape matching'); 
hold on
plot(defCoordsX,defCoordsY,'Color','cyan');
hold off

prompt1 = 'Are all the defects in the image correctly identified? (Yes/No)';
titleBox = 'Accuray Inquiry';
dims = [1 75];
definput = {'Yes'};
option1 = inputdlg(prompt1,titleBox,dims,definput);
option1 = option1{1};

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
            helpdel = 'When prompted by the command line. type "1" to begin defect deletion. When you are satisfied, type "0" in the command line';
            hdel = helpdlg(helpdel,'Defect Deletion');
            waitfor(hdel);
            xCoordDel = defCoordsX;
            yCoordDel = defCoordsY;
            pd = 'Type "0" when finished removing defects. Type "1" to begin. [0]:';
            anspd = input(pd);
            while anspd ~= 0
                rectld = getrect;
                for j = 1:length(defCoordsX(1,:))
                    xbn = defCoordsX(:,j);
                    ybn = defCoordsY(:,j);
                    xbn(isnan(xbn)) = [];
                    ybn(isnan(ybn)) = [];
                    if ((xbn > rectld(1)) & (xbn < (rectld(1)+rectld(3)))) & ((ybn > rectld(2)) & (ybn < (rectld(2)+rectld(4)))) % Test each plot to see if it falls within rectangle.
                        xCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        yCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        close all
                        figure; imshow(ImUniBg,[]);
                        hold on
                        plot(xCoordDel,yCoordDel,'Color','yellow')
                        hold off
                    end
                end
                pd = 'Type "0" when finished removing defects. [0]:';
                anspd = input(pd);
            end 
            prompt4 = 'Are there defects that should be added? (Yes/No)';
            titleBox = 'Defect Addition';
            dims = [1 60];
            definput = {'No'};
            option4 = inputdlg(prompt4,titleBox,dims,definput);
            option4 = option4{1};
            if strcmp(option4,'Yes')
                close all
                figure; imshow(ImUniBg,[])
                helpadd = 'Draw a rectangle around a region containing an unidentified defect.';
                ha = helpdlg(helpadd,'Crop Image');
                waitfor(ha);
                rectAdd = getrect;
    
                [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd);
                defCoordsX = [];
                defCoordsY = [];
                [r1,c1] = size(defAddX);
                [r2,c2] = size(xCoordDel);
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
                for k = 1:c2
                    defCoordsX(1:r2,k+c1) = xCoordDel(:,k);
                    defCoordsY(1:r2,k+c1) = yCoordDel(:,k);
                end
                defCoordsX( ~any(defCoordsX,2), : ) = [];  
                defCoordsX( :, ~any(defCoordsX,1) ) = []; 
                defCoordsY( ~any(defCoordsY,2), : ) = [];  
                defCoordsY( :, ~any(defCoordsY,1) ) = []; 
                defCoordsX(defCoordsX == 0) = NaN;
                defCoordsY(defCoordsY == 0) = NaN;  
                
            elseif strcmp(option4,'No')
                defCoordsX = xCoordDel;
                defCoordsY = yCoordDel;
            end
        end
    elseif strcmp(option2,'Yes')
        xR = [];
        yR = [];
        helpadd = 'Draw a rectangle around a region containing an unidentified defect.';
        ha = helpdlg(helpadd,'Crop Image');
        waitfor(ha);
        rectAdd = getrect;
        
        [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd);
        xInt = defCoordsX;
        yInt = defCoordsY;
        defCoordsX = [];
        defCoordsY = [];
        [r1,c1] = size(defAddX);
        [r2,c2] = size(xInt);
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

        for k = 1:c2
            defCoordsX(1:r2,k+c1) = xInt(:,k);
            defCoordsY(1:r2,k+c1) = yInt(:,k);
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
        
        prompt3 = 'Are there defects that should be removed? (Yes/No)';
        titleBox = 'Defect Removal';
        dims = [1 60];
        definput = {'Yes'};
        option3 = inputdlg(prompt3,titleBox,dims,definput);
        option3 = option3{1};
        if strcmp(option3,'No')
            disp('Done!');
        elseif strcmp(option3,'Yes')
            helpdel = 'When prompted by the command line. type "1" to begin defect deletion. When you are satisfied, type "0" in the command line';
            hdel = helpdlg(helpdel,'Defect Deletion');
            waitfor(hdel);
            xCoordDel = defCoordsX;
            yCoordDel = defCoordsY;
            pd = 'Type "0" when finished removing defects. Type "1" to begin. [0]:';
            anspd = input(pd);
            while anspd ~= 0
                rectld = getrect;
                for j = 1:length(defCoordsX(1,:))
                    xbn = defCoordsX(:,j);
                    ybn = defCoordsY(:,j);
                    xbn(isnan(xbn)) = [];
                    ybn(isnan(ybn)) = [];
                    if ((xbn > rectld(1)) & (xbn < (rectld(1)+rectld(3)))) & ((ybn > rectld(2)) & (ybn < (rectld(2)+rectld(4)))) % Test each plot to see if it falls within rectangle.
                        xCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        yCoordDel(:,j) = NaN(length(xCoordDel(:,1)),1);
                        close all
                        figure; imshow(ImUniBg,[]);
                        hold on
                        plot(xCoordDel,yCoordDel,'Color','yellow')
                        hold off
                    end
                end
                pd = 'Type "0" when finished removing defects. [0]:';
                anspd = input(pd);
            end 
            hold off
            defCoordsX = xCoordDel;
            defCoordsY = yCoordDel;
        end
    end
end

figure; imshow(ImLineFlat,[]); title('All identified defects');
hold on
plot(defCoordsX,defCoordsY,'Color',[173/255;255/255;47/255]);


quickadd = 'You may choose to add contour lines to the plot without analyzing specific image regions. If you would like to add contour lines around missing defects, type "Y". Y/N';
titleBox = 'Quick Add';
dims = [1 75];
definput = {'N'};
optquick = inputdlg(quickadd,titleBox,dims,definput);
optquick = optquick{1};

if strcmp(optquick,'N')
    figure; imshow(ImLineFlat,[]); title('All identified defects');
    hold on
    plot(defCoordsX,defCoordsY,'Color',[173/255;255/255;47/255]);
    hold off
elseif strcmp(optquick,'Y')
    figure; imshow(ImLineFlat,[]);
    hold on
    plot(defCoordsX,defCoordsY,'Color',[173/255;255/255;47/255]);
    quickhelp = 'Draw a rectangle around a region where you wish to plot a contour line. When prompted by the command line, type "1" to begin. Type "0" when you are finished.';
    qh = helpdlg(quickhelp,'Quick Add');
    waitfor(qh);
    pd = 'Type "0" when finished adding contour lines. Type "1" to begin. [0]:';
    anspd = input(pd);
    while anspd ~= 0
        quickR = getrect;
        [rN,cN] = size(coNest);
        for i = 1:cN
            [rt,ct] = size(coNest{1,i});
            for j = 1:ct
                xCoord = coNest{1,i}(:,j);
                yCoord = coNest{2,i}(:,j);
                xCoord(isnan(xCoord)) = [];
                yCoord(isnan(yCoord)) = [];
                if ((xCoord > quickR(1)) & (xCoord < (quickR(1)+quickR(3)))) & ((yCoord > quickR(2)) & (yCoord < (quickR(2)+quickR(4)))) % Test each plot to see if it falls within rectangle.
                    defCoordsX = [defCoordsX, coNest{1,i}(:,j)]
                    defCoordsY = [defCoordsY, coNest{2,i}(:,j)]
                    plot(xCoord,yCoord,'Color','blue');
                    drawnow
                    hold on
                end
            end
        end
        pd = 'Type "0" when finished adding plots. [0]:';
        anspd = input(pd);
    end 
    hold off
end

end