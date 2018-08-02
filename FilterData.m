% Author: Alana Gudinas
% July 23, 2018


function [ defCoordsX, defCoordsY] = FilterData(ImUniBg,ImLineFlat,ImFlatSmooth,meanPix)

[NestedContoursCell, xdataC, ydataC, heightVec, Method] = NestedContours(ImUniBg,meanPix);

coNest = NestedContoursCell;

figure; imshow(ImUniBg,[]);
hold on
plot(xdataC,ydataC,'Color',[173/255;255/255;47/255]) % Plot all the contour lines in the image.
hold off
xFilt2 = [];

hf1 = 'The contour lines in the image have been plotted in green. You have the option to choose to filter the data to improve defect identification. The available filters are: area difference, apparent brightness, and number of vertices in the countour plot.';
helpf1 = helpdlg(hf1,'Filter');
waitfor(helpf1);

hf2 = 'The area filter is defined by the difference in area between your target defect and the other contour lines in the image. For larger defects, an area filter that is < 100 is restrictive. 250 is a good starting point. For smaller defects, start with a value of 150. The vertex filter is specified by the number of points in each contour plot. You may specify a maximum or minimum amount of vertices a contour line can have. A good minimum is 20 vertices.';
helpf2 = helpdlg(hf2,'Filter Guidelines');
waitfor(helpf2);

hf3 = 'The apparent brightness filter sorts defects by their "height", or intensity, data. You may choose to only plot defects whose height is the same as the target defect, or specify a range of brightnesses you are interested in.';
helpf3 = helpdlg(hf3,'Filter Guidelines');
waitfor(helpf3);

hf4 = 'Start with the recommended area and vertex filters. The filter results will be plotted, and you may choose a better-suited filter afterwards.';
helpf4 = helpdlg(hf4,'Filter Guidelines');
waitfor(helpf4);

promptselect = {'Enter an area difference filter:','Enter a vertex filter:'};
titleBox = 'Filter Specification';
definput = {'250','30'};
dim = [1 60];
ansSelect = inputdlg(promptselect,titleBox,dim,definput);

areaFilt = ansSelect{1};
vtxFilt = ansSelect{2};

areaFilt = str2num(areaFilt);
vtxFilt = str2num(vtxFilt);

hf5 = 'Draw a rectangle around your the defect you are interested in comparing others to. The results of the comparison via your chosen filters will be plotted.';
helpf5 = helpdlg(hf5,'Template Selection');
waitfor(helpf5);
    
rect = getrect; % Prompt user to use rectangle selection to choose a region with a defect of interest.

close all

nx = length(xdataC(1,:));
Method
if strcmp(Method,'Bright')
    idxN = [1:1:nx];
elseif strcmp(Method,'Dark')
    idxN = [nx:-1:1];
end

for k = idxN
    xint = xdataC(:,k);
    yint = ydataC(:,k);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = []; 
    if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xint;
        yi = yint;
        plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
        drawnow
        hold on
    end
end
hold off

shapehelp2 = 'Of the cluster of contour lines, select the shape of the defect you are interested. Be sure to completely enclose the shape of interest with the rectangle. The largest line completely inside the rectangle will be chosen as the template defect.';
h2 = helpdlg(shapehelp2,'Template Selection');
waitfor(h2);

rect = getrect; % Prompt user to make another selection.

close all

figure; imshow(ImUniBg,[]);
hold on

for k = 1:idxN
    xint = xdataC(:,k);
    yint = ydataC(:,k);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = [];
    if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
        xi = xint;
        yi = yint; 
        refH = heightVec(k); % height of reference defect 
        plot(xi,yi,'Color','cyan') % Plot template on image so user can see their selection. 
        break
    end
end
hold off

meanheight = mean(heightVec);
meanInt = meanheight/4;
meanInt = num2str(meanInt);
refHstr = num2str(refH);

hf6 = ['Your target defect is plotted in cyan. The apparent brightness has a value of: ',refHstr,'. In the next window that opens, please specify the range of brightnesses you are interested in.'];
helpf6 = helpdlg(hf6,'Brightness Info');
waitfor(helpf6);

brightselect = {'Please specify the low end of the brightness range. Type "0" if you are only interested in defects at the exact same height of the target defect. A recommended low end value is the reference height subtracted by the mean height divided by 4. Enter the quantity to be subtracted from the reference height:','Please specify the high end of the brightness range. Type "0" if you are only interested in the height of the reference defect. A recommended high end is the reference height added to one fourth of the mean height. Enter the quantity to be added to the reference height:' };
titleBox = 'Brightness Filter Specification';
definput = {num2str(meanInt),num2str(meanInt)};
dim = [1 75];
brightans = inputdlg(brightselect,titleBox,dim,definput);
brightLow = brightans{1};
brightHigh = brightans{2};
brightLow = str2num(brightLow);
brightHigh = str2num(brightHigh);

diffArea = AreaDifference(xi,yi,xdataC,ydataC);

xint = [];
yint = [];
xFilt = [];
yFilt = [];
k = 1;

for i = 1:length(xdataC(1,:))
    xfd = xdataC(:,i);
    xfd(isnan(xfd)) = [];
    num = length(xfd);
    vtx(i) = num;
end

xB = xdataC;
yB = ydataC;
hV = heightVec;

for i = 1:length(xdataC(1,:))
    xint = xdataC(:,i);
    yint = ydataC(:,i);
    xint(isnan(xint)) = [];
    yint(isnan(yint)) = [];
    if (diffArea(i) < areaFilt) & (vtx(i) > vtxFilt) & (((refH - brightLow) <= heightVec(i)) & (heightVec(i) <= (refH + brightHigh)))
        xFilt(:,k) = xdataC(:,i);
        yFilt(:,k) = ydataC(:,i);
        xB(:,i) = NaN(length(xB(:,i)),1);
        yB(:,i) = NaN(length(xB(:,i)),1);
        hV(i) = NaN;
        k = k + 1;
    end
end

[rFilt,cFilt] = size(xFilt);

figure; imshow(ImFlatSmooth,[]); % may want to compare with original image here?
hold on
plot(xFilt,yFilt,'Color','yellow')
hold off

hf6 = 'The filtered defects are plotted in yellow.';
helpf6 = helpdlg(hf6,'Results');
waitfor(helpf6);

figure; imshow(ImLineFlat,[]);

ps = 'Have all the defects been correctly identified? (Y/N)';
titleBox = 'Accuracy Inquiry';
dims = [1 60];
definput = {'N'};
psout = inputdlg(ps,titleBox,dims,definput);
psout = psout{1};

if strcmp(psout,'N')
    ps1 = 'Would you like to conduct a second round of defect identification? (Y/N)';
    titleBox = 'Second Round';
    definput = {'Y'};
    ps1out = inputdlg(ps1,titleBox,dims,definput);
    ps1out = ps1out{1};
    if strcmp(ps1out,'N')
        psa = 'Are there defects that should be removed? (Y/N)';
        titleBox = 'Defect Removal';
        dims = [1 60];
        definput = {'Y'};
        psouta = inputdlg(psa,titleBox,dims,definput);
        psouta = psouta{1};
        if strcmp(psouta,'N')
            psd = 'Are there defects that should be added? (Y/N)';
            titleBox = 'Defect Addition';
            dims = [1 60];
            definput = {'Y'};
            psoutd = inputdlg(psd,titleBox,dims,definput);
            psoutd = psoutd{1};
            if strcmp(psoutd,'Y')
                adds = 'Please select a region containg a defect that shold be re-analyzed.';
                helpadd = helpdlg(adds,'Defect Addition');
                waitfor(helpadd);
                rectAdd = getrect;
                [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd);
                defCoordsX = [];
                defCoordsY = [];
                [r1,c1] = size(defAddX);
                [r2,c2] = size(xFilt);
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
                    defCoordsX(1:r2,k+c1) = xFilt(:,k);
                    defCoordsY(1:r2,k+c1) = yFilt(:,k);
                end
                defCoordsX( ~any(defCoordsX,2), : ) = [];  
                defCoordsX( :, ~any(defCoordsX,1) ) = []; 
                defCoordsY( ~any(defCoordsY,2), : ) = [];  
                defCoordsY( :, ~any(defCoordsY,1) ) = []; 
                defCoordsX(defCoordsX == 0) = NaN;
                defCoordsY(defCoordsY == 0) = NaN;  
                
                figure; imshow(ImFlatSmooth,[]); title('Identified Defects');
                hold on
                plot(defCoordsX,defCoordsY,'Color','cyan');
                hold off
            elseif strcmp(psoutd,'N')
                m1 = msgbox('Then what is all the fuss about?!','Confused');
                waitfor(m1);
                defCoordsX = xFilt;
                defCoordsY = yFilt;
            end
        elseif strcmp(psouta,'Y')
            xld = xFilt;
            yld = yFilt;
            pd = 'Type "0" when finished removing defects. Type "1" to begin. [0]:';
            anspd = input(pd);
            while anspd ~= 0
                rectld = getrect;
                for j = 1:length(xFilt(1,:)) % needs to be resized
                    xbn = xFilt(:,j);
                    ybn = yFilt(:,j);
                    xbn(isnan(xbn)) = [];
                    ybn(isnan(ybn)) = [];
                    if ((xbn > rectld(1)) & (xbn < (rectld(1)+rectld(3)))) & ((ybn > rectld(2)) & (ybn < (rectld(2)+rectld(4)))) % Test each plot to see if it falls within rectangle.
                        xld(:,j) = NaN(length(xld(:,1)),1);
                        yld(:,j) = NaN(length(xld(:,1)),1);
                        close all
                        figure; imshow(ImUniBg,[]);
                        hold on
                        plot(xld,yld,'Color','yellow')
                        hold off
                    end
                end
                pd = 'Type "0" when finished removing defects. [0]:';
                anspd = input(pd);
            end  
            defCoordsX = xld;
            defCoordsY = yld;
        end            
    elseif strcmp(ps1out,'Y')
        close all
        figure;imshow(ImLineFlat,[]);
        figure; imshow(ImUniBg,[]); title('Unidentified Contour Lines','FontSize',15);
        hold on
        plot(xB,yB,'Color','green');
        hold off
        hs2 = 'Please draw a rectangle around a remaining defect of interest.';
        helpsec2 = helpdlg(hs2,'Template Selection');
        waitfor(helpsec2);
        xFilt2 = [];
        yFilt2 = [];
        rect = getrect; % Prompts user to pick a new defect that captures the missing defects in the image.
        for k = idxN
            xint = xB(:,k);
            yint = yB(:,k);
            xint(isnan(xint)) = [];
            yint(isnan(yint)) = []; 
            if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
                xi = xint;
                yi = yint;
                plot(xi,yi,'Color','blue'); % Plot all lines within rectangle.
                drawnow
                hold on
            end
        end
        hold off
        rect = getrect;
        refH2 = [];
        close all

        xint = [];
        yint = [];

        figure; imshow(ImUniBg,[]);
        hold on

        for k = idxN
            xint = xB(:,k);
            yint = yB(:,k);
            xint(isnan(xint)) = [];
            yint(isnan(yint)) = [];
            if ((xint > rect(1)) & (xint < (rect(1)+rect(3)))) & ((yint > rect(2)) & (yint < (rect(2)+rect(4)))) % Test each plot to see if it falls within rectangle.
                xi = xint;
                yi = yint; 
                plot(xi,yi,'Color','cyan') % Plot template on image so user can see their selection. 
                refH2 = hV(k); % height of reference defect 
                break
            end
        end
        refH2str = num2str(refH2);
        hf6 = ['Your target defect is plotted in cyan. The apparent brightness has a value of: ',refH2str,'. In the next window that opens, please specify the range of brightnesses you are interested in.'];
        helpf6 = helpdlg(hf6,'Brightness Info');
        waitfor(helpf6);
        
        promptselect = {'Enter an area difference filter:','Enter a vertex filter:'};
        titleBox = 'Filter Specification';
        definput = {'250','30'};
        dim = [1 60];
        ansSelect = inputdlg(promptselect,titleBox,dim,definput);
        areaFilt = ansSelect{1};
        vtxFilt = ansSelect{2};
        areaFilt = str2num(areaFilt);
        vtxFilt = str2num(vtxFilt);
        
        hv = hV;
        hv(isnan(hv)) = [];
        meanheight = mean(hv);
        meanInt = meanheight/4;
        meanInt = num2str(meanInt);
       
        brightselect = {'Please specify the low end of the brightness range. Type "0" if you are only interested in defects at the exact same height of the target defect. A recommended low end value is the reference height subtracted by the mean height divided by 4. Enter the quantity to be subtracted from the reference height:','Please specify the high end of the brightness range. Type "0" if you are only interested in the height of the reference defect. A recommended high end is the reference height added to one fourth of the mean height. Enter the quantity to be added to the reference height:' };
        titleBox = 'Brightness Filter Specification';
        definput = {num2str(meanInt),num2str(meanInt)};
        dim = [1 75];
        brightans = inputdlg(brightselect,titleBox,dim,definput);
        brightLow = brightans{1};
        brightHigh = brightans{2};
        brightLow = str2num(brightLow);
        brightHigh = str2num(brightHigh);

        hold off
        diffArea2 = AreaDifference(xi,yi,xB,yB);
        vtx2 = [];
        for i = 1:length(xB(1,:))
            xfd = xB(:,i);
            xfd(isnan(xfd)) = [];
            num = length(xfd);
            vtx2(i) = num;
        end
        xD = xB;
        yD = yB;
        k = 1;
        hT = hV;
        for i = 1:length(xB(1,:))
            xint = xB(:,i);
            yint = yB(:,i);
            xint(isnan(xint)) = [];
            yint(isnan(yint)) = [];
            if ((diffArea2(i)<areaFilt) && (vtx2(i)>vtxFilt)) && (((refH2 - brightLow) <= hV(i)) & (hV(i) <= (refH2 + brightHigh)))
                xFilt2(:,k) = xB(:,i);
                yFilt2(:,k) = yB(:,i);
                xD(:,i) = NaN(length(xD(:,1)),1);
                yD(:,i) = NaN(length(xD(:,1)),1);
                hT(i) = NaN;
                k = k + 1;
            end
        end
        close all

        figure; imshow(ImUniBg,[]); % may want to compare with original image here?
        hold on
        plot(xFilt2,yFilt2,'Color','yellow')
        hold off
    end
elseif strcmp(psout,'Y')
    defCoordsX = xFilt;
    defCoordsY = yFilt;
end

if ~isempty(xFilt2)
    [r1,c1] = size(xFilt);
    [r2,c2] = size(xFilt2);

    if r1 > r2
        defX = zeros(r1,c1+c2);
        defY = zeros(r1,c1+c2);
    elseif r1 < r2
        defX = zeros(r2,c1+c2);
        defY = zeros(r2,c1+c2);
    end


    for j = 1:c1
        defX(1:r1,j) = xFilt(:,j);
        defY(1:r1,j) = yFilt(:,j);
    end

    for k = 1:c2
        defX(1:r2,k+c1) = xFilt2(:,k);
        defY(1:r2,k+c1) = yFilt2(:,k);
    end

    defX( ~any(defX,2), : ) = [];  
    defX( :, ~any(defX,1) ) = []; 
    defY( ~any(defY,2), : ) = [];  
    defY( :, ~any(defY,1) ) = []; 
    defX(defX == 0) = NaN;
    defY(defY == 0) = NaN;
    
    close all
    figure; imshow(ImLineFlat,[]);
    figure; imshow(ImUniBg,[]);
    hold on
    plot(defX,defY,'Color','cyan');
    plot(xFilt,yFilt,'Color','red');
    plot(xFilt2,yFilt2,'Color','yellow');
    hold off
    
    promptfilt2 = 'Are all the defects in the image correctly identified? Y/N';
    titleBox = 'Results of second round';
    dims = [1 60];
    definput = {'Y'};
    filt2 = inputdlg(promptfilt2,titleBox,dims,definput);
    filt2 = filt2{1};
    
    if strcmp(filt2,'Y')
        defCoordsX = defX;
        defCoordsY = defY;
    elseif strcmp(filt2,'N')
        psa = 'Are there defects that should be removed?';
        titleBox = 'Defect Removal';
        dims = [1 60];
        definput = {'Y'};
        psouta = inputdlg(psa,titleBox,dims,definput);
        psouta = psouta{1};
        if strcmp(psouta,'N')
            psd = 'Are there defects that should be added?';
            titleBox = 'Defect Addition';
            dims = [1 60];
            definput = {'Y'};
            psoutd = inputdlg(psd,titleBox,dims,definput);
            psoutd = psoutd{1};
            if strcmp(psoutd,'Y')
               adds = 'Please select a region containg a defect that shold be re-analyzed.';
               helpadd = helpdlg(adds,'Defect Addition');
               waitfor(helpadd);
               rectAdd = getrect;
               
                [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd);
                defCoordsX = [];
                defCoordsY = [];
                [r1,c1] = size(defAddX);
                [r2,c2] = size(defX);
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
                    defCoordsX(1:r2,k+c1) = defX(:,k);
                    defCoordsY(1:r2,k+c1) = defY(:,k);
                end
                defCoordsX( ~any(defCoordsX,2), : ) = [];  
                defCoordsX( :, ~any(defCoordsX,1) ) = []; 
                defCoordsY( ~any(defCoordsY,2), : ) = [];  
                defCoordsY( :, ~any(defCoordsY,1) ) = []; 
                defCoordsX(defCoordsX == 0) = NaN;
                defCoordsY(defCoordsY == 0) = NaN;  
            elseif strcmp(psoutd,'N')
                m1 = msgbox('Then what is all the fuss about?!','Confused');
                waitfor(m1);
            end
        elseif strcmp(psouta,'Y')
            figure;imshow(ImUniBg,[]);
            xld = defX;
            yld = defY;
            pd = 'Type "0" when finished removing defects. Type "1" to begin. [0]:';
            anspd = input(pd);
            while anspd ~= 0
                rectld = getrect;
                for j = 1:length(defX(1,:)) % needs to be resized
                    xbn = defX(:,j);
                    ybn = defY(:,j);
                    xbn(isnan(xbn)) = [];
                    ybn(isnan(ybn)) = [];
                    if ((xbn > rectld(1)) & (xbn < (rectld(1)+rectld(3)))) & ((ybn > rectld(2)) & (ybn < (rectld(2)+rectld(4)))) % Test each plot to see if it falls within rectangle.
                        close
                        xld(:,j) = NaN(length(xld(:,1)),1);
                        yld(:,j) = NaN(length(xld(:,1)),1);
                        figure; imshow(ImUniBg,[]);
                        hold on
                        plot(xld,yld,'Color','yellow')
                        hold off
                    end
                end
                pd = 'Type "0" when finished removing defects. [0]:';
                anspd = input(pd);
            end  
            promptadd = 'Are there any defects you wish to add? Y/N';
            titleBox = 'Defect Addition';
            definput = {'Y'};
            dims = [1 60];
            addans = inputdlg(promptadd,titleBox,dims,definput);
            addans = addans{1};
            if strcmp(addans,'N')
                defCoordsX = xld;
                defCoordsY = yld;
            elseif strcmp(addans,'Y')
               adds = 'Please select a region containg a defect that shold be re-analyzed.';
               helpadd = helpdlg(adds,'Defect Addition');
               waitfor(helpadd);
               rectAdd = getrect;
               
                [ defAddX, defAddY ] = SmallRegion(ImLineFlat,ImFlatSmooth,ImUniBg,rectAdd);
                defCoordsX = [];
                defCoordsY = [];
                [r1,c1] = size(defAddX);
                [r2,c2] = size(xld);
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
                    defCoordsX(1:r2,k+c1) = xld(:,k);
                    defCoordsY(1:r2,k+c1) = yld(:,k);
                end
                defCoordsX( ~any(defCoordsX,2), : ) = [];  
                defCoordsX( :, ~any(defCoordsX,1) ) = []; 
                defCoordsY( ~any(defCoordsY,2), : ) = [];  
                defCoordsY( :, ~any(defCoordsY,1) ) = []; 
                defCoordsX(defCoordsX == 0) = NaN;
                defCoordsY(defCoordsY == 0) = NaN;  
               
            end
        end
    end
end

close all

figure; imshow(ImFlatSmooth,[]); title('Identified Defects');
hold on
plot(defCoordsX,defCoordsY,'Color','cyan');
hold off

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
        for i = idxN
            xCoord = xdataC(:,i);
            yCoord = ydataC(:,i);
            xCoord(~isnan(xCoord)) = NaN;
            yCoord(~isnan(yCoord)) = NaN;
            if ~all(isnan(xCoord))
                if ((xCoord > quickR(1)) & (xCoord < (quickR(1)+quickR(3)))) & ((yCoord > quickR(2)) & (yCoord < (quickR(2)+quickR(4)))) % Test each plot to see if it falls within rectangle.
                    defCoordsX = [defCoordsX, xdataC(:,i)];
                    defCoordsY = [defCoordsY, xdataC(:,i)];
                    plot(xCoord,yCoord,'Color','blue');
                    drawnow
                    hold on
                    break
                end 
            end
        end
        pd = 'Type "0" when finished adding plots. [0]:';
        anspd = input(pd);
    end 
    hold off
end

end