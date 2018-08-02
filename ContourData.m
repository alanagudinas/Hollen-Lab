function [ C, hdata, idx, vtx, xdata, ydata, heightVec] = ContourData(ImUniBg,Method,meanPix)
    

% should I include optional filters at this level? would be easier to
% include them here as a parameter..

[r,c] = size(ImUniBg);

xImdat = [1:1:c];
yImdat = [1:1:r];

% meanP = mean(ImUniBg(:)); % no longer viable. need input from ImUniBg

imageb = imshow(ImUniBg,[]);
h = gca; %returns the handle to the current axes for the current figure (imageb).
h.Visible = 'On';
set(imageb,'AlphaData',0.8); % increase transparency so contour lines are visible.
hold on

[C,hdata] = imcontour(xImdat,yImdat,ImUniBg,10,'LineColor','cyan'); % create contour lines at ten different heights of the image
hdata.LineWidth = 1.25;
hold off
close

[ri,ci] = size(C);
idx = 1; 
vtx = C(2,1); 
k = 1;

while idx < ci
    idx(k+1) = idx(k) + vtx(k) + 1;
    if idx(k+1) >= ci
        idx = idx(1:k);
        vtx = vtx(1:k);
        break
    end
    vtx(k+1) = C(2,idx(k+1));
    k = k + 1;
end

xdata = zeros(500,length(idx));
ydata = zeros(500,length(idx));

heightVec = [];

if strcmp(Method,'Bright')
    for i = 1:length(idx)
        if (C(1,idx(i)) > meanPix)
            xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
            heightVec = [heightVec, C(1,idx(i))];
        end
    end
elseif strcmp(Method,'Dark')
    for i = 1:length(idx)
        if (C(1,idx(i)) < meanPix)
            xdata(1:vtx(i),i) = C(1,idx(i)+1:idx(i)+vtx(i));
            ydata(1:vtx(i),i) = C(2,idx(i)+1:idx(i)+vtx(i));
            heightVec = [heightVec, C(1,idx(i))];
        end
    end
end

xdata( ~any(xdata,2), : ) = [];  
xdata( :, ~any(xdata,1) ) = []; 
ydata( ~any(ydata,2), : ) = [];  
ydata( :, ~any(ydata,1) ) = []; 
xdata(xdata == 0) = NaN;
ydata(ydata == 0) = NaN;  

end