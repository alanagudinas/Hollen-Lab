%SM4READER  Reads an .sm4 file into .mat format
%     SM4READER(fileID)
%
%SM4READER takes a file ID of an RHK .sm4 file, then reads and
%generates:
%   (1)outfile, a matlab structure containing the reading of (most of) the 
%   .sm4 data
%   (2)formatoutfile, a structure of arranged spatial (e.g. topography) and
%   spectral (e.g. I-V spectroscopy), and PLL (phase-locked loop) data.
%
%Note: the data included in the generated .mat files is not all possible
%measurement types on the RHK microscopes, nor is it a 100% reading of the 
%.sm4 file.  The reading is as thorough as we need but it may need extra
%header reading and/or .mat formatted output depending on the needs of the 
%user.
%
%Further information on SM4READER and the formatoutfile structure can be
%found at: 
%     http://unh2d.weebly.com/using-sm4-files-in-matlab.html
%     http://unh2d.weebly.com/sm4readerm-and-the-mat-file-format.html
%%


function [formatoutfile, outfile] = sm4reader(fileID)

    %Call the subfunction which reads the .sm4 file
    outfile = sm4read(fileID);
    
    %Call the subfunction which arranges the data into a new,
    %well-formatted structure
    [formatoutfile] = formatfilecontents(outfile,fileID);
    
end



%%


%----------------
%Generate outfile
%----------------

%This subfunction reads the .sm4 file and saves it to the structure called
%outfile
function outfile = sm4read(fileID)
    
    %Read and record the file header under outfile.HeaderData
    %--------------------------------------------------------
    outfile.HeaderData.HeaderSize = fread(fileID,1,'uint16');
    outfile.HeaderData.Signature = fread(fileID,18,'uint16=>char');
    outfile.HeaderData.Signature = transpose(outfile.HeaderData.Signature); %changing the array of characters to a row instead of a column
    outfile.HeaderData.TotalPageCount = fread(fileID,1,'uint32'); %this is all four bytes because uint32 is 4 bytes
    outfile.HeaderData.ObjectListCount = fread(fileID,1,'uint32');
    outfile.HeaderData.ObjectFieldSize = fread(fileID,1,'uint32');
    outfile.HeaderData.Reserved = fread(fileID,2,'uint32');%the reserved 8 bytes

    
    
    %Here we define the Object Header list of codes.
    %-----------------------------------------------
    %Note: codes start from zero in reality, so these are all offset by 1.
    ObjectIDCode{1} = 'Undefined';
    ObjectIDCode{2} = 'Page Index Header';
    ObjectIDCode{3} = 'Page Index Array';
    ObjectIDCode{4} = 'Page Header';
    ObjectIDCode{5} = 'Page Data';
    ObjectIDCode{6} = 'Image Drift Header';
    ObjectIDCode{7} = 'Image Drift';
    ObjectIDCode{8} = 'Spec Drift Header';
    ObjectIDCode{9} = 'Spec Drift Data (with X,Y coordinates)';
    ObjectIDCode{10} = 'Color Info';
    ObjectIDCode{11} = 'String data';
    ObjectIDCode{12} = 'Tip Track Header';
    ObjectIDCode{13} = 'Tip Track Data';
    ObjectIDCode{14} = 'PRM';
    ObjectIDCode{15} = 'Thumbnail';
    ObjectIDCode{16} = 'PRM Header';
    ObjectIDCode{17} = 'Thumbnail Header';
    ObjectIDCode{18} = 'API Info';
    ObjectIDCode{19} = 'History Info';
    ObjectIDCode{20} = 'Piezo Sensitivity';
    ObjectIDCode{21} = 'Frequency Sweep Data';
    ObjectIDCode{22} = 'Scan Processor Info';
    ObjectIDCode{23} = 'PLL Info';
    ObjectIDCode{24} = 'CH1 Drive Info';
    ObjectIDCode{25} = 'CH2 Drive Info';
    ObjectIDCode{26} = 'Lockin0 Info';
    ObjectIDCode{27} = 'Lockin1 Info';
    ObjectIDCode{28} = 'ZPI Info';
    ObjectIDCode{29} = 'KPI Info';
    ObjectIDCode{30} = 'Aux PI Info';
    ObjectIDCode{31} = 'Low-pass Filter0 Info';
    ObjectIDCode{32} = 'Low-pass Filter1 Info';


    
    %Now that we know what the codes mean, we read the list of codes
    %---------------------------------------------------------------
    for i=1:outfile.HeaderData.ObjectListCount  %Iterating over the number of known objects from the file header
        outfile.ObjectList(i).ObjectID = fread(fileID,1,'uint32');
        outfile.ObjectList(i).ObjectName = ObjectIDCode{outfile.ObjectList(i).ObjectID + 1}; %+1 to account for the indices starting at 1, not 0
        outfile.ObjectList(i).Offset = fread(fileID,1,'uint32');%the offset of the object
        outfile.ObjectList(i).Size = fread(fileID,1,'uint32'); %the size of the object
    end


    
    %Read and record the Page Index Header
    %-------------------------------------
    outfile.PageIndexHeader.PageCount = fread(fileID,1,'uint32'); % the number of pages in the Page Index Array
    outfile.PageIndexHeader.ObjectListCount = fread(fileID,1,'uint32'); %the count of objects stored after the Page Index Header
                                                                        %currently there is just one: Page Index Array        
    outfile.PageIndexHeader.Reserved = fread(fileID, 2, 'uint32'); %two fields reserved for future use 

    

    %Read and record the Page Index Array
    %------------------------------------
    outfile.PageIndexHeader.ObjectID = fread(fileID,1,'uint32');   
    outfile.PageIndexHeader.Offset = fread(fileID,1,'uint32');     
    outfile.PageIndexHeader.Size = fread(fileID,1,'uint32'); 


    %Read the Page Index pages
    for j=1:outfile.PageIndexHeader.PageCount %this for reads the page index array for each page

        outfile.PageIndex(j).PageID = fread(fileID, 8, 'uint16'); %unique ID for each Page
        outfile.PageIndex(j).PageDataType = fread(fileID,1,'uint32'); %type of data stored with the page
        outfile.PageIndex(j).PageSourceType = fread(fileID,1,'uint32'); %a number describing the page type
        outfile.PageIndex(j).ObjectListCount = fread(fileID,1,'uint32'); %number of objects after each Page Index
        outfile.PageIndex(j).MinorVersion = fread(fileID,1,'uint32'); %stores the minor version of the file
            
            %Reads the objects for each page, currently 4
            for i=1: outfile.PageIndex(j).ObjectListCount 
                outfile.PageIndex(j).ObjectID(i) = fread(fileID,1,'uint32');  
                index = outfile.PageIndex(j).ObjectID(i) + 1;
                outfile.PageIndex(j).ObjectName{i} = ObjectIDCode{index};
                outfile.PageIndex(j).Offset(i) = fread(fileID,1,'uint32');
                outfile.PageIndex(j).Size(i) = fread(fileID,1,'uint32'); 
            end

    end

    
    
    %Read and record the Page Headers for each Page
    %----------------------------------------------
    for j = 1:outfile.PageIndexHeader.PageCount  %steps through the pages

        fseek(fileID,outfile.PageIndex(j).Offset(1) ,'bof'); %use the offsets
        %we read to earlier to find the beginning of the Page Header

        outfile.PageHeader(j).FieldSize = fread(fileID,1,'uint16');
        outfile.PageHeader(j).StringCount = fread(fileID,1,'uint16');
        outfile.PageHeader(j).PageType_DataSource = fread(fileID,1,'uint32');
        outfile.PageHeader(j).DataSubSource = fread(fileID,1,'uint32');
        outfile.PageHeader(j).LineType = fread(fileID,1,'uint32');
        outfile.PageHeader(j).XCorner = fread(fileID,1,'uint32');
        outfile.PageHeader(j).YCorner = fread(fileID,1,'uint32');
        outfile.PageHeader(j).Width = fread(fileID,1,'uint32');
        outfile.PageHeader(j).Height = fread(fileID,1,'uint32');
        outfile.PageHeader(j).ImageType = fread(fileID,1,'uint32');
        outfile.PageHeader(j).ScanDirection = fread(fileID,1,'uint32');
        outfile.PageHeader(j).GroupID = fread(fileID,1,'uint32');
        outfile.PageHeader(j).PageDataSize = fread(fileID,1,'uint32');
        outfile.PageHeader(j).MinZValue = fread(fileID,1,'int32');
        outfile.PageHeader(j).MaxZValue = fread(fileID,1,'int32');
        outfile.PageHeader(j).XScale = fread(fileID,1,'single');
        outfile.PageHeader(j).YScale = fread(fileID,1,'single');
        outfile.PageHeader(j).ZScale = fread(fileID,1,'single');
        outfile.PageHeader(j).XYScale = fread(fileID,1,'single');
        outfile.PageHeader(j).XOffset = fread(fileID,1,'single');
        outfile.PageHeader(j).YOffset = fread(fileID,1,'single');
        outfile.PageHeader(j).ZOffset = fread(fileID,1,'single');
        outfile.PageHeader(j).Period = fread(fileID,1,'single');
        outfile.PageHeader(j).Bias = fread(fileID,1,'single');
        outfile.PageHeader(j).Current = fread(fileID,1,'single');
        outfile.PageHeader(j).Angle = fread(fileID,1,'single');
        outfile.PageHeader(j).ColorInfoListCount = fread(fileID,1,'uint32');
        outfile.PageHeader(j).GridXSize = fread(fileID,1,'uint32');
        outfile.PageHeader(j).GridYSize = fread(fileID,1,'uint32');
        outfile.PageHeader(j).ObjectListCount = fread(fileID,1,'uint32');

       %Skip flags and reserved data
       fseek(fileID,1+3+60,0);

       %Read the Object List
       for i=1:outfile.PageHeader(j).ObjectListCount
        outfile.PageHeader(j).ObjectID(i) = fread(fileID,1,'uint32');
        outfile.PageHeader(j).Offset(i) = fread(fileID,1,'uint32');     % 4 bytes
        outfile.PageHeader(j).Size(i) = fread(fileID,1,'uint32');
       end

       
       
       %Read and record the Text Strings for each Page
       %----------------------------------------------
       %PageheaderObjectList
        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strLabel = fread(fileID,count,'uint16=>char');%string that goes on top of plot window, such as "current image"
        outfile.TextString(j).strLabel=transpose(outfile.TextString(j).strLabel);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strSystemText = fread(fileID,count,'uint16=>char');%a comment describing the data
        outfile.TextString(j).strSystemText=transpose(outfile.TextString(j).strSystemText);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strSessionText = fread(fileID,count,'uint16=>char');%general session comments
        outfile.TextString(j).strSessionText=transpose(outfile.TextString(j).strSessionText);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strUserText = fread(fileID,count,'uint16=>char');%user comments
        outfile.TextString(j).strUserText=transpose(outfile.TextString(j).strUserText);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strPath = fread(fileID,count,'uint16=>char');%Path
        outfile.TextString(j).strPath=transpose(outfile.TextString(j).strPath);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strDate = fread(fileID,count,'uint16=>char');%DAQ date
        outfile.TextString(j).strDate=transpose(outfile.TextString(j).strDate);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strTime = fread(fileID,count,'uint16=>char');%DAQ time
        outfile.TextString(j).strTime=transpose(outfile.TextString(j).strTime);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strXUnits = fread(fileID,count,'uint16=>char');%physical units of x axis
        outfile.TextString(j).strXUnits=transpose(outfile.TextString(j).strXUnits);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strYUnits = fread(fileID,count,'uint16=>char');%physical units of Y axis
        outfile.TextString(j).strYUnits=transpose(outfile.TextString(j).strYUnits);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strZUnits = fread(fileID,count,'uint16=>char');%physical units of Z axis
        outfile.TextString(j).strZUnits=transpose(outfile.TextString(j).strZUnits);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strXLabel = fread(fileID,count,'uint16=>char');
        outfile.TextString(j).strXLabel=transpose(outfile.TextString(j).strXLabel);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strYLabel = fread(fileID,count,'uint16=>char');
        outfile.TextString(j).strYLabel=transpose(outfile.TextString(j).strYLabel);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strStatusChannelText = fread(fileID,count,'uint16=>char');%status channel text
        outfile.TextString(j).strStatusChannelText=transpose(outfile.TextString(j).strStatusChannelText);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strCompletedLineCount = fread(fileID,count,'uint16=>char');%contains last saved line count for an image data page
        outfile.TextString(j).strCompletedLineCount=transpose(outfile.TextString(j).strCompletedLineCount);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strOverSamplingCount = fread(fileID,count,'uint16=>char');%Oversampling count for image data pages
        outfile.TextString(j).strOverSamplingCount=transpose(outfile.TextString(j).strOverSamplingCount);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strSlicedVoltage = fread(fileID,count,'uint16=>char');%voltage at which the sliced image is created from the spectra page.  empty if not a sliced image
        outfile.TextString(j).strSlicedVoltage=transpose(outfile.TextString(j).strSlicedVoltage);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strPLLProStatus = fread(fileID,count,'uint16=>char');%PLLPro status text: blank, master or user
        outfile.TextString(j).strPLLProStatus=transpose(outfile.TextString(j).strPLLProStatus);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strSetpointUnit = fread(fileID,count,'uint16=>char');%ZPI controller item's set-point unit
        outfile.TextString(j).strSetpointUnit=transpose(outfile.TextString(j).strSetpointUnit);

        count=fread(fileID,1,'uint16'); %tells how long the next string is
        outfile.TextString(j).strCHDriveValues = fread(fileID,count,'uint16=>char');%staores value of CH1 and CH2 if they are in hardware space
        outfile.TextString(j).strCHDriveValues=transpose(outfile.TextString(j).strCHDriveValues);
    end

  
    
    %Read and record the Scale Data
    %------------------------------
    %Read Data from Sequential Data Pages
    for j=1:outfile.PageIndexHeader.PageCount
        fseek(fileID,outfile.PageIndex(j).Offset(2),'bof');%the offset corresponding to the beginning of the data is the 2nd offset
        outfile.Data{j} = fread(fileID,outfile.PageIndex(j).Size(2)/4,'int32','l');
                % /4 is because the total data size has to be divided
                % by the numer of bytes that use each 'long' data
        outfile.ScaleData{j} = outfile.PageHeader(j).ZOffset+double(outfile.Data{j})*outfile.PageHeader(j).ZScale;        
        outfile.ScaleData{j} = reshape(outfile.ScaleData{j},outfile.PageHeader(j).Width,outfile.PageHeader(j).Height);
        outfile.ScaleData{j} = outfile.ScaleData{j};
    end   
end




%%


%----------------------
%Generate formatoutfile
%----------------------

%This subfunction uses the data read into outfile and uses it to generate a well-structured
%.mat file for use in data analysis and visualization.
%
%Your needs may vary, the fields chosed are the ones we have needed so far
%and/or identified as important.
function [formatoutfile] = formatfilecontents(outfile,fileID)

    %Initialize variables that track how many pages of each type there are
    topocount = 0;                  %Topography
    currentcount = 0;               %Spatial current
    liacurrentcount = 0;            %Spatial LIA current
    IV_Point_Speccount = 0;         %Spectral point current
    dIdV_Point_Speccount = 0;       %Spectral point LIA (dIdV) current
    IV_Line_Speccount = 0;          %Spectral line current
    dIdV_Line_Speccount = 0;        %Spectral line LIA (dIdV) current
    Spatialpagenumber = 0;          %Total number of spatial pages
    Pointspectrapagenumber = 0;     %Total number of point line pages
    Linespectrapagenumber = 0;      %Total number of line spectra pages
    Frequencyspectrapagenumber = 0; %Total number of frequency sweep pages
    SpatialPLLpagenumber = 0;       %Spatial pages
    PLLPageNumber = 0;              %PLL Page
    PLLTrue = 0;                    %Logical for if there is PLL data, start at 0 (false)
    
    %number of PLL and AFM pages
    PLLAmpcount = 0;                
    PLLPhasecount = 0;
    dFcount = 0;
    dFspeccount = 0;
    PLLDrivecount = 0;    
    PLLAmp_Speccount = 0;
    PLLPhase_Speccount = 0;
    PLLDrive_Speccount = 0;
    
    
    
    %----------
    %Data Types
    %----------
    for p = 1:outfile.PageIndexHeader.PageCount
        
        
        %Spatial Data
        %------------
        %Check to see if the page label is Topography
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'Topography');
        if argtestcompare == 1  
            topocount = topocount + 1;  %iterate number of topo pages
            
            %add TopoData to the Spatial field
            formatoutfile.Spatial.TopoData{topocount} = rot90(outfile.ScaleData{p},-1);  %using topolabel in the parenthesis uses its string value for the structure name instead of using 'topolabel'
            formatoutfile.Spatial.TopoUnit = outfile.TextString(p).strZUnits;
            Spatialpagenumber = p; %tracks the last spatial page; will be 
            %used to read the rest of the spatial data later
        end   
        
        %Check to see if the page is spatial Current data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'Current');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 2   
            currentcount = currentcount+1;
            formatoutfile.Spatial.CurrentData{currentcount} = rot90(outfile.ScaleData{p},-1);  
            formatoutfile.Spatial.CurrentUnit = outfile.TextString(p).strZUnits;
            Spatialpagenumber = p;
        end
        
        %Check to see if the page is spatial LIA current data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'LIA Current');
        if argtestcompare == 1  && outfile.PageHeader(p).PageType_DataSource == 2  %if the comparison returns a true, flattendebug is set to true
            liacurrentcount = liacurrentcount+1;
            formatoutfile.Spatial.LIACurrentData{liacurrentcount} = rot90(outfile.ScaleData{p},-1);  %using topolabel in the parenthesis uses its string value for the structure name instead of using 'topolabel'
            formatoutfile.Spatial.LIACurrentUnit = outfile.TextString(p).strZUnits;
            Spatialpagenumber = p;
        end
            
        %Check to see if the page is spatial PLL Amplitude data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'PLL Amplitude');
        if argtestcompare == 1  && outfile.PageHeader(p).PageType_DataSource == 3  %if the comparison returns a true, flattendebug is set to true
            PLLAmpcount = PLLAmpcount+1;
            formatoutfile.Spatial.PLLAmplitudeData{PLLAmpcount} = rot90(outfile.ScaleData{p},-1);  %using topolabel in the parenthesis uses its string value for the structure name instead of using 'topolabel'
            formatoutfile.Spatial.PLLAmplitudeUnit = outfile.TextString(p).strZUnits;
            SpatialPLLpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end
        
        
        %Check to see if the page is spatial PLL Phase data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'PLL Phase');
        if argtestcompare == 1  && outfile.PageHeader(p).PageType_DataSource == 3  %if the comparison returns a true, flattendebug is set to true
            PLLPhasecount = PLLPhasecount+1;
            formatoutfile.Spatial.PLLPhaseData{PLLPhasecount} = rot90(outfile.ScaleData{p},-1);  %using topolabel in the parenthesis uses its string value for the structure name instead of using 'topolabel'
            formatoutfile.Spatial.PLLPhaseUnit = outfile.TextString(p).strZUnits;
            SpatialPLLpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end
        
        
        %Check to see if the page is spatial dF.
        %if dF data is present, PLL must be on and we record ZPI data too
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'dF');
        if argtestcompare == 1  && outfile.PageHeader(p).PageType_DataSource == 3  %if the comparison returns a true, flattendebug is set to true
            dFcount = dFcount+1;
            formatoutfile.Spatial.dFData{dFcount} = rot90(outfile.ScaleData{p},-1);  %using topolabel in the parenthesis uses its string value for the structure name instead of using 'topolabel'
            formatoutfile.Spatial.dFUnit = outfile.TextString(p).strZUnits;
            SpatialPLLpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        
            %read the ZPI data, start by finding the offset
            for objectnumber = 1:outfile.PageHeader(p).ObjectListCount
                if outfile.PageHeader(p).ObjectID(objectnumber) == 27
                        outfile.ZPI.Offset = outfile.PageHeader(p).Offset(objectnumber);
                        outfile.ZPI.Size = outfile.PageHeader(p).Size(objectnumber);
                end
            end
            
            %Read and record the ZPI
            fseek(fileID,outfile.ZPI.Offset,'bof');
            formatoutfile.Spatial.dFsetpoint = fread(fileID,1,'double');
            formatoutfile.Spatial.dFsetpointUnit = 'Hz';
        
        
        end
        
        
        
        %Check to see if the page is spatial PLL Drive
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'PLL Drive');
        if argtestcompare == 1  && outfile.PageHeader(p).PageType_DataSource == 3  %if the comparison returns a true, flattendebug is set to true
            PLLDrivecount = PLLDrivecount+1;
            formatoutfile.Spatial.PLLDriveData{PLLDrivecount} = rot90(outfile.ScaleData{p},-1);  %using topolabel in the parenthesis uses its string value for the structure name instead of using 'topolabel'
            formatoutfile.Spatial.PLLDriveUnit = outfile.TextString(p).strZUnits;
            SpatialPLLpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end        
        
       
        
        %Point Spectral Data
        %-------------------
        %Check to see if the page is point spectra current data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'Current');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 38  
            IV_Point_Speccount = IV_Point_Speccount + 1;
            formatoutfile.Spectral.IV_Point_Data = outfile.ScaleData{p};
            formatoutfile.Spectral.IV_Point_DataUnit = 'A';
            spectralpagenumber = p;
            Pointspectrapagenumber = p;
        end
        
        %Check to see if the page is point spectra LIA current data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'LIA Current');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 38  
            dIdV_Point_Speccount = dIdV_Point_Speccount+1;
            formatoutfile.Spectral.dIdV_Point_Data = outfile.ScaleData{p};
            formatoutfile.Spectral.dIdV_Point_DataUnit = 'A';
            spectralpagenumber = p;
            Pointspectrapagenumber = p;
        end
        
        
        
        %Line Spectral Data
        %------------------
        %Check to see if the page is line spectra current data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'Current');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 16  
            IV_Line_Speccount = IV_Line_Speccount+1;
            formatoutfile.Spectral.IV_Line_Data = outfile.ScaleData{p};
            formatoutfile.Spectral.IV_Line_DataUnit = 'A';
            spectralpagenumber = p;
            Linespectrapagenumber = p;
        end
        
        %Check to see if the page is line spectra LIA current data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'LIA Current');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 16
            dIdV_Line_Speccount = dIdV_Line_Speccount+1; 
            formatoutfile.Spectral.dIdV_Line_Data = outfile.ScaleData{p};
            formatoutfile.Spectral.dIdV_Line_DataUnit = 'A';
            spectralpagenumber = p;
            Linespectrapagenumber = p;
        end
    
        
        
        %AFM spectra, frequency, V and Z
        %-------------------------------
        %Check to see if the page is PLL Amplitude spectral data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'PLL Amplitude');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 38
            PLLAmp_Speccount = PLLAmp_Speccount+1; 
            formatoutfile.Spectral.PLLAmpSpec = outfile.ScaleData{p};
            formatoutfile.Spectral.PLLAmpUnit = outfile.TextString(p).strZUnits;
            spectralpagenumber = p;
            Frequencyspectrapagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end
        
        
        
        %Check to see if the page is PLL Phase spectral data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'PLL Phase');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 38
            PLLPhase_Speccount = PLLPhase_Speccount+1; 
            formatoutfile.Spectral.PLLPhaseSpec = outfile.ScaleData{p};
            formatoutfile.Spectral.PLLPhaseUnit = outfile.TextString(p).strZUnits;
            spectralpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end
        
        
        
        %Check to see if the page is PLL Drive spectral data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'PLL Drive');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 38
            PLLDrive_Speccount = PLLDrive_Speccount+1; 
            formatoutfile.Spectral.PLLDriveSpec = outfile.ScaleData{p};
            formatoutfile.Spectral.PLLDriveUnit = outfile.TextString(p).strZUnits;
            spectralpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end
        
        
        %Check to see if the page is dF spectral data
        argtestcompare = strcmpi(outfile.TextString(p).strLabel,'dF');
        if argtestcompare == 1 && outfile.PageHeader(p).PageType_DataSource == 38
            dFspeccount = dFspeccount+1; 
            formatoutfile.Spectral.dFSpec = outfile.ScaleData{p};
            formatoutfile.Spectral.dFSpecUnit = outfile.TextString(p).strZUnits;
            spectralpagenumber = p;
            PLLPagenumber = p;
            PLLTrue = 1;
        end
        
    end
    
    
    
    
    %---------------
    %General headers
    %---------------
    
    %Check to see if there are any spatial pages.  If so, add the general
    %spatial information to formatoutfile.Spatial
    if topocount + currentcount + liacurrentcount + PLLAmpcount + PLLPhasecount + dFcount + PLLDrivecount > 0
        formatoutfile.Spatial.points = outfile.PageHeader(Spatialpagenumber).Width;
        formatoutfile.Spatial.lines = outfile.PageHeader(Spatialpagenumber).Height;
        formatoutfile.Spatial.width = abs(outfile.PageHeader(Spatialpagenumber).XScale * formatoutfile.Spatial.points);
        formatoutfile.Spatial.height = abs(outfile.PageHeader(Spatialpagenumber).YScale * formatoutfile.Spatial.lines);
        formatoutfile.Spatial.widthheightUnit = 'm';
        
        formatoutfile.Spatial.bias = outfile.PageHeader(Spatialpagenumber).Bias;
        formatoutfile.Spatial.biasUnit = 'V';
        
        formatoutfile.Spatial.current = outfile.PageHeader(Spatialpagenumber).Current;
        formatoutfile.Spatial.currentUnit = 'A';
        
        formatoutfile.Spatial.xoffset = outfile.PageHeader(Spatialpagenumber).XOffset;
        formatoutfile.Spatial.yoffset = outfile.PageHeader(Spatialpagenumber).YOffset;
        formatoutfile.Spatial.xyoffsetUnit = 'm';
        
        
        %If there is PLL data, then it is an AFM scan.
        %For the AFM scans, the bias and current fields means nothing, so
        %remove them
        if PLLTrue == 1
            formatoutfile.Spatial = rmfield(formatoutfile.Spatial,'current'); 
            formatoutfile.Spatial = rmfield(formatoutfile.Spatial,'bias');
            formatoutfile.Spatial = rmfield(formatoutfile.Spatial,'currentUnit'); 
            formatoutfile.Spatial = rmfield(formatoutfile.Spatial,'biasUnit');

        end
    
    end
     
    
    
    
    %XXXX
    %There are three types of spatial data: frequency, point (IV,V,Z), line
    %(IV).
    %XXXX
    
    
    
    %Check to see if there are any spectral pages.  If so, add the general
    %spectral information to formatoutfile.Spectral
    if IV_Point_Speccount + dIdV_Point_Speccount + IV_Line_Speccount + dIdV_Line_Speccount + PLLAmp_Speccount + PLLPhase_Speccount + PLLDrive_Speccount> 0
            formatoutfile.Spectral.points = outfile.PageHeader(spectralpagenumber).Width;
            formatoutfile.Spectral.scans = outfile.PageHeader(spectralpagenumber).Height;
            formatoutfile.Spectral.bias = outfile.PageHeader(spectralpagenumber).Bias;
            formatoutfile.Spectral.biasUnit = 'V';
            
            formatoutfile.Spectral.current = outfile.PageHeader(spectralpagenumber).Current;
            formatoutfile.Spectral.currentUnit = 'A';
            
            xpoints = outfile.PageHeader(p).Width;
            xscale = (1:xpoints)-1;
            formatoutfile.Spectral.xdata = (outfile.PageHeader(p).XOffset + outfile.PageHeader(p).XScale * xscale)';
            formatoutfile.Spectral.xdataUnit = outfile.TextString(p).strXUnits;
    end
    
    
    
    %Check to see if there are any Frequency spectra pages.  If so, add the general
    %spectral information to formatoutfile.Spectral 
    if Frequencyspectrapagenumber > 0
       xpoints = outfile.PageHeader(p).Width;
       xscale = (1:xpoints)-1;
       formatoutfile.Spectral.points = outfile.PageHeader(Frequencyspectrapagenumber).Width;
       formatoutfile.Spectral.scans = outfile.PageHeader(spectralpagenumber).Height;
       formatoutfile.Spectral.type = 'frequency';
    end 
    
    
    
    
    
    
    %If there are point spectra pages, add the specific point spectra
    %information to formatoutfile.Spectral
    if Pointspectrapagenumber > 0
        for objectnumber = 1:outfile.PageHeader(Pointspectrapagenumber).ObjectListCount
            if outfile.PageHeader(Pointspectrapagenumber).ObjectID(objectnumber) == 7
                    outfile.PageHeader(Pointspectrapagenumber).SpecDriftHeader.Offset = outfile.PageHeader(Pointspectrapagenumber).Offset(objectnumber);
                    outfile.PageHeader(Pointspectrapagenumber).SpecDriftHeader.Size = outfile.PageHeader(Pointspectrapagenumber).Size(objectnumber);
            end
        end

        for objectnumber = 1:outfile.PageHeader(Pointspectrapagenumber).ObjectListCount
            if outfile.PageHeader(Pointspectrapagenumber).ObjectID(objectnumber) == 8
                    outfile.PageHeader(Pointspectrapagenumber).SpecDriftData.Offset = outfile.PageHeader(Pointspectrapagenumber).Offset(objectnumber);
                    outfile.PageHeader(Pointspectrapagenumber).SpecDriftData.Size = outfile.PageHeader(Pointspectrapagenumber).Size(objectnumber);
            end
        end
            
            %read the Spec data for tip start time and position
            fseek(fileID,outfile.PageHeader(Pointspectrapagenumber).SpecDriftData.Offset,'bof');
            formatoutfile.Spectral.startTime = fread(fileID,1,'single');
            formatoutfile.Spectral.xCoord = fread(fileID,1,'single');
            formatoutfile.Spectral.yCoord = fread(fileID,1,'single');
            formatoutfile.Spectral.xyCoordUnit = 'm';
            formatoutfile.Spectral.dx = fread(fileID,1,'single');
            formatoutfile.Spectral.dy = fread(fileID,1,'single');
            formatoutfile.Spectral.xCumulative = fread(fileID,1,'single');
            formatoutfile.Spectral.yCumulative = fread(fileID,1,'single');
            formatoutfile.Spectral.type = 'Point';
   
    
            if Frequencyspectrapagenumber > 0
                   if formatoutfile.Spectral.xdataUnit == 'Hz'
                        formatoutfile.Spectral.type = 'Frequency';
                   end

                   if formatoutfile.Spectral.xdataUnit == 'V'
                        formatoutfile.Spectral.type = 'Vspec';
                   end

                   if formatoutfile.Spectral.xdataUnit == 'm'
                        formatoutfile.Spectral.type = 'Zspec';
                   end
            end
    end    
    
    
    %If there are point spectra pages, add the specific point spectra
    %information to formatoutfile.Spectral
    if Linespectrapagenumber > 0
    %need to find out which pages have the extra header data
        for objectnumber = 1:outfile.PageHeader(Linespectrapagenumber).ObjectListCount
            if outfile.PageHeader(Linespectrapagenumber).ObjectID(objectnumber) == 7
                    outfile.PageHeader(Linespectrapagenumber).SpecDriftHeader.Offset = outfile.PageHeader(Linespectrapagenumber).Offset(objectnumber);
                    outfile.PageHeader(Linespectrapagenumber).SpecDriftHeader.Size = outfile.PageHeader(Linespectrapagenumber).Size(objectnumber);
            end
        end

        for objectnumber = 1:outfile.PageHeader(Linespectrapagenumber).ObjectListCount
            if outfile.PageHeader(Linespectrapagenumber).ObjectID(objectnumber) == 8
                    outfile.PageHeader(Linespectrapagenumber).SpecDriftData.Offset = outfile.PageHeader(Linespectrapagenumber).Offset(objectnumber);
                    outfile.PageHeader(Linespectrapagenumber).SpecDriftData.Size = outfile.PageHeader(Linespectrapagenumber).Size(objectnumber);
            end
        end


        [~, numberofscans] = size(outfile.ScaleData{Linespectrapagenumber}); %determine number of scans in the data set
        formatoutfile.Spectral.xCoord = zeros(numberofscans,1);%initialize the arrays to hold the coordinates
        formatoutfile.Spectral.yCoord = zeros(numberofscans,1);
        formatoutfile.Spectral.xyCoordUnit = 'm';
        
        %read the Spec data for tip start time and position
        fseek(fileID,outfile.PageHeader(Linespectrapagenumber).SpecDriftData.Offset,'bof'); %go to the beginning of the header
        for k = 1:numberofscans %the header repeats a sequence of information, need to iterate over all points
            fseek(fileID,4,'cof'); %skip the StartTime
            formatoutfile.Spectral.xCoord(k) = fread(fileID,1,'single'); %Record x and y coordinates
            formatoutfile.Spectral.yCoord(k) = fread(fileID,1,'single');
            fseek(fileID,16,'cof'); %skip the dx dx xcumulative and ycumulative fields since we won't record them here
        end
           
        fseek(fileID,outfile.PageHeader(Linespectrapagenumber).SpecDriftData.Offset,'bof');
        formatoutfile.Spectral.startTime = fread(fileID,1,'single');
        fseek(fileID,8,'cof'); %skip the x and y coord
        formatoutfile.Spectral.dx = fread(fileID,1,'single');
        formatoutfile.Spectral.dy = fread(fileID,1,'single');
        formatoutfile.Spectral.xCumulative = fread(fileID,1,'single');
        formatoutfile.Spectral.yCumulative = fread(fileID,1,'single');
        formatoutfile.Spectral.type = 'Line';
           
    end
    
    
    
    
    
    
    %If there is PLL data present, create a PLL header and format to
    %contain the relevant information.
    if PLLTrue == 1 %our test for the presence of PLL data
    
        %need to find out which pages have the extra header data
        for objectnumber = 1:outfile.PageHeader(PLLPagenumber).ObjectListCount
            if outfile.PageHeader(PLLPagenumber).ObjectID(objectnumber) == 22
                    outfile.SpatialPLL.Offset = outfile.PageHeader(PLLPagenumber).Offset(objectnumber);
                    outfile.SpatialPLL.Size = outfile.PageHeader(PLLPagenumber).Size(objectnumber);
            end
        end
        
        fseek(fileID,outfile.SpatialPLL.Offset,'bof'); %go to the relevant offset
        fseek(fileID,8,'cof'); %skip the beginning, not useful information
        formatoutfile.PLL.DriveAmplitude = fread(fileID,1,'double'); %begin reading the data
        formatoutfile.PLL.DriveAmplitudeUnit = 'V';
        
        formatoutfile.PLL.DriveRefFrequency = fread(fileID,1,'double');
        formatoutfile.PLL.DriveRefFrequencyUnit = 'Hz';
        
        formatoutfile.PLL.LockinFrequencyOffset = fread(fileID,1,'double');
        formatoutfile.PLL.LockinFrequencyOffsetUnit = 'Hz';
        
        formatoutfile.PLL.LockinHarmonicFactor = fread(fileID,1,'double');
            
        formatoutfile.PLL.LockinPhaseOffset = fread(fileID,1,'double');
        formatoutfile.PLL.LockinPhaseUnit = 'deg';
        
        formatoutfile.PLL.PIGain = fread(fileID,1,'double');
        formatoutfile.PLL.PIGainUnit = 'Hz/deg';
        
        formatoutfile.PLL.PIntCutOffFreq = fread(fileID,1,'double');
        formatoutfile.PLL.PIntCutOffFreqUnit = 'Hz';
        
        formatoutfile.PLL.LowerBound = fread(fileID,1,'double');
        formatoutfile.PLL.UpperBound = fread(fileID,1,'double');
        formatoutfile.PLL.PIOutputUnit = 'Hz';
        
        formatoutfile.PLL.DissPIGain = fread(fileID,1,'double');
        formatoutfile.PLL.DissPIGainUnit = 'V/V';
        
        formatoutfile.PLL.DissIntCutOffFreq = fread(fileID,1,'double');
        formatoutfile.PLL.DissIntCutOffFreqUnit = 'Hz';
        
        formatoutfile.PLL.DissLowerBound = fread(fileID,1,'double');
        formatoutfile.PLL.DissUpperBound = fread(fileID,1,'double');
        formatoutfile.PLL.DissPIOutputUnit = 'V';
        
    end
    
    
    
    
    %What if there is no formatoutfile?
    %----------------------------------
    
    %Makes the formatoutfile a non-structure.  This is used with
    %sm4tomatlab to prevent an error and prevent saving if there are no
    %data pages
    if Spatialpagenumber + Pointspectrapagenumber + Linespectrapagenumber + Frequencyspectrapagenumber == 0
        formatoutfile='None';
    end
    
end