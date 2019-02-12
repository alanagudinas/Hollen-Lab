% Author: Alana Gudinas
% July 6, 2018
%
% Use this to test the slider function of UniformBackground.
% You can adjust the pixel range for the background as well as strel size.


function [ ImDataUpdate ] = UniformBackgroundTWO(Im_proc,Im_flat)

global metaDataFile
fileID = fopen(metaDataFile,'a+'); % open meta data .txt file
formatSpec = '%s\n';

ImData = Im_proc;
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

mpix1 = mean(pix1);
mpix2 = min(ImVec);

% The sliding scale should adjust the upper and lower limit of the range.
% Maybe just multiples of avgDiff?

ImDataUpdate = ImData;
UB.low = 0;
UB.high = 0;
UB.strel = 0;

    function UniBgSliders
        UB.fig = imshow(ImData,[]);
        UB.imdata = ImData;
        UB.sliderLow = uicontrol('Style', 'slider',...
        'Min',0,'Max',100,'Value',UB.low,...
        'Units', 'Normalized',...
        'Position', [0.3 0.05 0.4 0.2],...
        'SliderStep', [1/100 1/100],...
        'Callback', {@update_image,'low'});
    
        UB.sliderHigh = uicontrol('Style', 'slider',...
        'Min',0,'Max',100,'Value',UB.high,...
        'Units', 'Normalized',...
        'Position', [0.3 0.02 0.4 0.2],...
        'SliderStep', [1/100 1/100],...
        'Callback', {@update_image,'high'});
    
        UB.sliderStrel = uicontrol('Style', 'slider',...
        'Min',0,'Max',20,'Value',UB.strel,...
        'Units', 'Normalized',...
        'Position', [0.3 -0.01 0.4 0.2],...
        'SliderStep', [1/100 1/100],...
        'Callback', {@update_image,'strel'});
    global upper
    global lower
    %addlistener
        function update_image(hObject,callbackdata, param)
            UB.(param) = get(hObject, 'Value');
             if strcmp(param,'strel')
                Im_data_flat_lin = Im_flat;
                nm = UB.(param);
                nm = round(nm); 
                strelSize = nm;
                
                background = imopen(Im_data_flat_lin,strel('disk',strelSize)); 
                Im_flat_bg = Im_data_flat_lin - background; 
                fprintf(fileID,formatSpec,'Background corrected');

                %normalize the data for better display 

                normIm_flat = (Im_data_flat_lin - min(min(Im_data_flat_lin))) / (max(max(Im_data_flat_lin)) - min(min(Im_data_flat_lin))); 
                normIm_flat_bg = (Im_flat_bg - min(min(Im_flat_bg))) / (max(max(Im_flat_bg)) - min(min(Im_flat_bg))); 

                fprintf(fileID,formatSpec,'Image data normalized');
                % getting normalized vectors and some statistics in order to plot better 

                meanIm_flat_bg = mean2(normIm_flat_bg);
                stdIm_flat_bg = std2(normIm_flat_bg); 
                low = meanIm_flat_bg - stdIm_flat_bg; 
                high = meanIm_flat_bg + stdIm_flat_bg; 

                % ask Jason about this?
                if low < 0
                    low = 0;
                end
                % imadjust allows me to adjust the contrast on the imshowpair plotting 

                ImflatA = imadjust(normIm_flat, [.001 .3],[]); 

                fprintf(fileID,formatSpec,'Contrast adjusted');

                ImflatbgA = imadjust(normIm_flat_bg, [low high],[]);   

                ImlineB = imgaussfilt(Im_flat_bg,[1 50]);  
                Ic = Im_flat_bg - ImlineB; 
                Icn = (Ic - min(min(Ic))) / (max(max(Ic)) - min(min(Ic))); 
                Imean = mean2(Icn);
                Istd = std2(Icn); 

                fprintf(fileID,formatSpec,'Filtered along direction of lines');

                ImData = imgaussfilt(Icn,2); 
                set(UB.fig,'CData',ImData)
            elseif strcmp(param,'low')
               nm = UB.(param);
               nm = round(nm); 
               set(hObject, 'Value', nm);
               %ImDataUpdate = ImData;
                if nm == 0
                    ImDataUpdate = ImData;
                else
                    lower = mpix1 - nm * avgDiff;
                    for k = 1:numel(ImData)   
                        if (lower <= ImDataUpdate(k)) & (ImDataUpdate(k) <= (upper))
                            ImDataUpdate(k) = meanPix;
                        end
                    end
                end
                set(UB.fig,'CData',ImDataUpdate)
            elseif strcmp(param,'high')
                nm = UB.(param);
                nm = round(nm); 
                set(hObject, 'Value', nm);
                %ImDataUpdate = ImData;
                if nm == 0
                    ImDataUpdate = ImData;
                else
                    upper = mpix2 + nm * avgDiff;
                    for k = 1:numel(ImData)
                        if (lower <= ImDataUpdate(k)) & (ImDataUpdate(k) <= upper)
                            ImDataUpdate(k) = meanPix;
                        end
                    end
                end
                set(UB.fig,'CData',ImDataUpdate)
             end
          end
    end

UniBgSliders

fprintf(fileID,formatSpec,'New image generated with improved background uniformity');
%think i need to include a "done" button
end
