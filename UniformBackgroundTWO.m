% Author: Alana Gudinas
% July 6, 2018
%
%

function [ ImUniBg, ImDataProc, ImLineFlat, ImZdata ] = UniformBackgroundTWO(ImData)

global metaDataFile
fileID = fopen(metaDataFile,'a+'); % open txt file
formatSpec = '%s\n';

[r,c,d] = size(ImData);

if d > 1 % need a 2D array for processing
    ImData = rgb2gray(ImData);
    ImData = im2double(ImData);
end

global output_graph

Im_data = ImData;

% Line-by-line flattening of the image:

for n=1:length(Im_data(:,1)) %assumes square?
%create an array of x-data 
    x = 1:length(Im_data(n,:)); 
   % extract the y data from row n 
   y = Im_data(n,:); 
   %fit this data with a linear fit:
   p = polyfit(x,y,1); 
   linecorrect = x.*p(1)+p(2); 
   Im_data_flat_lin(n,:)=Im_data(n,:)-linecorrect; 
end

fprintf(fileID,formatSpec,'Image data line-by-line flattened');
ImLineFlat = Im_data_flat_lin; 

figure;imshow(ImLineFlat,[])

ImData = ImLineFlat;
ImVec = ImData(:); % Unroll image into a vector for analysis. 

% Define some variables:
meanPix = mean(ImVec);

% Create a vector of the difference in brightness between each pixel and
% its neighbor along the image vector:

pixDiff = [];
nd = length(ImVec);

for i = 1:nd-1
    pixDiff(i) = abs(ImVec(i+1) - ImVec(i)); % subtract the brightness of one pixel from its linear neighbor
end

avgDiff = mean(pixDiff);
ImVecSort = sort(ImVec);

bmod = mod(nd,2);

if bmod ~= 0 
    nde = (nd+1)/2;
else
    nde = nd/2;
end

pix1 = ImVecSort(1:nde); % this is the mean pixel brightness of the first half (the lower half) of the image vector.
pix2 = ImVecSort(nde:end); % mean pixel of the "brighter" half.

% mpix1 = mean(pix1);
% mpix2 = mean(pix2);

mpix1 = mean(pix1); %BETTER DEFINE THESE PLS
mpix2 = min(ImVec);

global ImDataFilt
ImDataUpdate = ImData;
ImDataFilt = ImData;
UB.low = 0;
UB.high = 0;
UB.strel = 0;
UB.gauss = 0;

global upper
global lower

    function [ImUniBg] = UniBgSliders
        UB.fig = imshow(ImData,[]); title('Image Processing', 'FontSize',15);
        fig = gcf;
        fig.Position = [500 500 600 650]; 
        fig.WindowStyle = 'modal';
        fig.Name = 'Image Processing';
        fig.Color = [223;234;249]./256;
        UB.imdata = ImData;
        
        UB.sliderLow = uicontrol('Style', 'slider',...
        'Min',0,'Max',100,'Value',UB.low,...
        'Units', 'Normalized',...
        'Position', [0.3 -0.12 0.4 0.2],...
        'SliderStep', [1/100 1/100],...;
        'Callback', {@update_image,'low'},'String','Lower Bound Adjustment','HorizontalAlignment','left');
        
        UB.sliderHigh = uicontrol('Style', 'slider',...
        'Min',0,'Max',100,'Value',UB.high,...
        'Units', 'Normalized',...
        'Position', [0.3 -0.15 0.4 0.2],...
        'SliderStep', [1/100 1/100],...
        'Callback', {@update_image,'high'});
      
        UB.sliderStrel = uicontrol('Style', 'slider',...
        'Min',0,'Max',20,'Value',UB.strel,...
        'Units', 'Normalized',...
        'Position', [0.3 -0.06 0.4 0.2],...
        'SliderStep', [1/100 1/100],...
        'Callback', {@update_image,'strel'});
        
        UB.sliderGauss = uicontrol('Style', 'slider',...
        'Min',0,'Max',5,'Value',UB.gauss,...
        'Units', 'Normalized',...
        'Position', [0.3 -0.09 0.4 0.2],...
        'SliderStep', [1/20 1/20],...
        'Callback', {@update_image,'gauss'});
    
        dB = uicontrol;
        dB.String = 'Finished';
        dB.Callback = {@update_image,'done'};
        dB.FontSize = 20;
        dB.Position(3) = 90;
        dB.Position(4) = 50;
         % create new text object that updates when callback values updates
         
        function update_image(hObject,callbackdata, param)
            UB.(param) = get(hObject, 'Value');
             if strcmp(param,'strel')
                nm = UB.(param);
                nm = round(nm); 
                strelSize = nm;
                
                background = imopen(Im_data_flat_lin,strel('disk',strelSize)); 
                Im_flat_bg = Im_data_flat_lin - background; 
                
                % Normalize data for better display
                normIm_flat = (Im_data_flat_lin - min(min(Im_data_flat_lin))) / (max(max(Im_data_flat_lin)) - min(min(Im_data_flat_lin))); 
                normIm_flat_bg = (Im_flat_bg - min(min(Im_flat_bg))) / (max(max(Im_flat_bg)) - min(min(Im_flat_bg)));
                
                % getting normalized vectors and some statistics in order to plot better 
                meanIm_flat_bg = mean2(normIm_flat_bg);
                stdIm_flat_bg = std2(normIm_flat_bg); 
                low = meanIm_flat_bg - stdIm_flat_bg; 
                high = meanIm_flat_bg + stdIm_flat_bg; 
                
                if low < 0
                    low = 0;
                end
                
                ImflatA = imadjust(normIm_flat, [.001 .3],[]); 
                ImflatbgA = imadjust(normIm_flat_bg, [low high],[]);   

                ImlineB = imgaussfilt(Im_flat_bg,[1 50]);  
                Ic = Im_flat_bg - ImlineB; 
                Icn = (Ic - min(min(Ic))) / (max(max(Ic)) - min(min(Ic))); 

                Imean = mean2(Icn);
                Istd = std2(Icn); 
                ImZdata = imgaussfilt(Ic,2); 
                
                ImData = Icn;
                set(UB.fig,'CData',ImData)
                imshow(ImData)
                return
            elseif strcmp(param,'gauss')
                nm = UB.(param);
                ImDataFilt = imgaussfilt(ImData,nm); 
                set(UB.fig,'CData',ImDataFilt)

            elseif strcmp(param,'low')
               nm = UB.(param);
               nm = round(nm); 
               set(hObject, 'Value', nm);
               ImDataUpdate = ImDataFilt;
%                 if nm == 0
%                     ImDataUpdate = ImData;
                    lower = mpix1 - nm * avgDiff;
                    for k = 1:numel(ImData)   
                        if (lower <= ImDataUpdate(k)) & (ImDataUpdate(k) <= (upper))
                            ImDataUpdate(k) = meanPix;
                        end
                    end

                set(UB.fig,'CData',ImDataUpdate)

            elseif strcmp(param,'high')
                nm = UB.(param);
                nm = round(nm); 
                set(hObject, 'Value', nm);
                ImDataUpdate = ImDataFilt;
                if nm == 0
                    ImDataUpdate = ImDataFilt;
                else
                    upper = mpix2 + nm * avgDiff;
                    for k = 1:numel(ImData)
                        if (lower <= ImDataUpdate(k)) & (ImDataUpdate(k) <= upper)
                            ImDataUpdate(k) = meanPix;
                        end
                    end
                end
                set(UB.fig,'CData',ImDataUpdate)
                
             elseif strcmp(param,'done')
                close
                return
             end
        end
end

UniBgSliders

dB.Value = 0;
waitfor(dB,'Value');
ImUniBg = ImDataUpdate;

fprintf(fileID,formatSpec,'New image generated with improved background uniformity');

end