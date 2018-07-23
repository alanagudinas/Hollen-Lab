function [ C, hdata, idx, vtx, xdata, ydata] = ContourData(ImUniBg,Method)
    

% should I include optional filters at this level? would be easier to
% include them here as a parameter..

[xImdat,yImdat] = size(ImUniBg);

xImdat = [1:1:xImdat];
yImdat = [1:1:yImdat];

meanP = mean(ImUniBg(:));

imageb = imshow(ImUniBg,[]);
h = gca; %returns the handle to the current axes for the current figure (imageb).
h.Visible = 'On';
set(imageb,'AlphaData',0.8); % increase transparency so contour lines are visible.
hold on

[C,hdata] = imcontour(xImdat,yImdat,ImUniBg,10,'LineColor','cyan'); % create contour lines at ten different heights of the image
hdata.LineWidth = 1.25;
hold off
close

idx = []; % Empty variable for the vector containing index values for C. 
vtx = []; % Empty variable for the vector containing the number of vertices for each contour.
idx2 = [];
vtx2 = [];
xi = 0;
yi = 0; 

levels = multithresh(ImUniBg,5); % Segment the image to filter out some non-extrema.
% The following isn't necessary but cleans up the contour plot a little. 

for i = 1:length(C(1,:))
    if (C(1,i)<=levels(2)) % If the contour line has a height below a certain value, consider it a dark extrema and record the indices and vertices.
        idx = [idx,i];
        vtx = [vtx, C(2,i)];
    end
end
for i = 1:length(C(1,:))
    if (C(1,i)>levels(2)) && (C(1,i)<=levels(4)) % If the contour line falls between the brightest range, record the data.
        idx2 = [idx2,i];
        vtx2 = [vtx2, C(2,i)];
    end
end

idx = [idx idx2]; % Indices representing the start of a contour plot of an extremum.
vtx = [vtx vtx2]; % Vector of number of vertices in each plot.

xdata = zeros(500,length(idx));
ydata = zeros(500,length(idx));

if strcmp(Method,'Bright')
    for i = 1:length(idx)
        if (C(1,idx(i)) > meanP)
            xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
        end
    end
elseif strcmp(Method,'Dark')
    for i = 1:length(idx)
        if (C(1,idx(i)) < meanP)
            xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
        end
    end
elseif strcmp(Method,'None')
    for i = 1:length(idx)
        xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
        ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
    end
end

xdata( ~any(xdata,2), : ) = [];  
xdata( :, ~any(xdata,1) ) = []; 
ydata( ~any(ydata,2), : ) = [];  
ydata( :, ~any(ydata,1) ) = []; 
xdata(xdata == 0) = NaN;
ydata(ydata == 0) = NaN;  

end