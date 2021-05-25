%this script will read in a .csv file of snowcourse data. It will then go 
%into the snodas dataset and pull the values at all dates / locations of
%snowcourse points. Finally, it will save a new .mat file that contains
%the snowcourse and snodas data. There is a separate script
%that will then plot / analyze the data...I separate them since this
%initial operation is very slow.

%format of snowcourse file is this:
%Date,Station Id,Station Name,Latitude,Longitude,Elevation (ft),Snow Depth (cm) Start of Month Values,Snow Water Equivalent (mm) Start of Month Values
%Jan 1980,ABY,Abbey,39.95500,-120.53800,5650,58,140
%Feb 1980,ABY,Abbey,39.95500,-120.53800,5650,38,127
%etc...cycling through months and then stations.

%Dave Hill - Oregon State University
%created 2019.

clear all
close all
fclose all
clc

%%%%%%%%%%%%%%%%
%USER INPUT
%path to cocorahs csv file.
cocopath='/Volumes/dfh-1/data/snowcourse';
%name of file.
filename='snowcourse_jan80_dec18.csv';
fname2=fullfile(cocopath,filename);

%path to snodas data
snodashome='/Volumes/dfh-1/data/snodas/snodas_download'; %root dir for snodas (local)
%snodashome='/nfs/attic/dfh/Hill/snodas'; %root (on lassen)

%output file directory (where do you want to store the result). One option
%is to just put it in the same place as the raw cocorahs data. Up to you.
outputdir='/Volumes/dfh-1/data/snowcourse';

%%%%%%%%%%%%%%%%%

%read in the snowcourse file
opts = detectImportOptions(fname2,'NumHeaderLines',1364);
T=readtable(fname2,opts,'ReadVariableNames',true);

%delete rows with zero value for depth
T(T.Snow_Depth__cm__Start_of_Month_Values==0,:)=[];
%delete rows with zero value for swe
T(T.Snow_Water_Equivalent__mm__Start_of_Month_Values==0,:)=[];
%delete rows with nans for either swe or h
T(isnan(T.Snow_Water_Equivalent__mm__Start_of_Month_Values)==1,:)=[];
T(isnan(T.Snow_Depth__cm__Start_of_Month_Values)==1,:)=[];

dates=T{:,1};
id=T{:,2};
lon=T{:,5};
lat=T{:,4};
el=T{:,6}/3.281; %convert elevations from ft to m
snowcourse_h=T{:,7}*10; %put depths in mm
snowcourse_swe=T{:,8}; %swe is in mm.

%need to work with dates...
for j=1:length(snowcourse_swe)
    M=dates{j}(1:3);
    y(j,1)=str2num(dates{j}(5:8));
    if strcmp(M,'Jan')
        m(j,1)=1;
    elseif strcmp(M,'Feb')
        m(j,1)=2;
    elseif strcmp(M,'Mar')
        m(j,1)=3;
    elseif strcmp(M,'Apr')
        m(j,1)=4;        
    elseif strcmp(M,'May')
        m(j,1)=5;
    elseif strcmp(M,'Jun')
        m(j,1)=6;        
    elseif strcmp(M,'Jul')
        m(j,1)=7;        
    elseif strcmp(M,'Aug')
        m(j,1)=8;        
    elseif strcmp(M,'Sep')
        m(j,1)=9;        
    elseif strcmp(M,'Oct')
        m(j,1)=10;  
    elseif strcmp(M,'Nov')
        m(j,1)=11;
    else
        m(j,1)=12;
    end
end
d=double(ones(size(m)));

%Next, we need to turn our year / month / day information into a 'day of
%water year' (DOY)
doy=datenum(y,m,d)-datenum(y,9,30); %OCT 1 will have a DOY of 1
doy(doy<0)=doy(doy<0)+365; %make all values positive, in range of 1 --> 365       

%we want to preallocate output. To do this, find out how many datapoints
%lie in the period of record of snodas.
I=find(datenum(y,m,d)>=datenum(2003,10,1) & ...
    datenum(y,m,d)<=datenum(2018,9,30));

%datacompare will have the following columns:
% year  month  day  DOY  lat  lon  snowcourse_swe  snowcourse_h  snodas_swe  snodas_h
snowcourse_snodas_data.data=1.1*ones(length(I),10,'double');

%a bit of metadata
snowcourse_snodas_data.meta.description = 'columns: y m d doy lat lon snowcourse_swe snowcourse_h snodas_swe snodas_h';
snowcourse_snodas_data.meta.author = 'david hill; dfh@oregonstate.edu';
snowcourse_snodas_data.meta.creationdate = date;

%let's delete data outside that window.
J=find(datenum(y,m,d)<datenum(2003,10,1) | ...
    datenum(y,m,d)>datenum(2018,9,30));

y(J)=[]; d(J)=[]; m(J)=[]; lon(J)=[]; lat(J)=[]; doy(J)=[];
snowcourse_h(J)=[]; snowcourse_swe(J)=[];
id(J,:)=[];

%work on snodas stuff...
monthfolders={'01_Jan' '02_Feb' '03_Mar' '04_Apr' '05_May' ...
    '06_Jun' '07_Jul' '08_Aug' '09_Sep' '10_Oct' '11_Nov' '12_Dec'};

%establish grid size (masked files)
    ncol=6935;
    nrows=3351;
    cellsize=0.008333333333333;  %grid resolution in deg
    ULlat=52.871249516804028; %center of upper left cell (lat)
    ULlon=-124.729583333331703; %center of upper left cell (lon)
    R=georasterref('RasterSize',[nrows,ncol],'ColumnsStartFrom','north', ...
    'RowsStartFrom','west','LatitudeLimits',[ULlat-(nrows)*cellsize ULlat], ...
    'LongitudeLimits',[ULlon ULlon+(ncol)*cellsize]);

%let us now loop over the snow course datapoints
for k=1:length(I)

    %lets find the indices of the requested location in our matrix.
    [K,J]=geographicToIntrinsic(R,lat(k),lon(k));
    K=round(K);J=round(J);
    %figure out how much data to skip...
    numbertoskip=(J-1)*ncol+K-1;

    %We need to build up the name of the file that we are going to open.
    if m(k)<10
        M=['0' num2str(m(k))];
    else
        M=num2str(m(k));
    end
    if d(k)<10
        D=['0' num2str(d(k))];
    else
        D=num2str(d(k));
    end    

    %establish full fill name...
    depthfname=['/' num2str(y(k)) '/' monthfolders{m(k)} '/Hs/us_ssmv1' '1036' ...
        'tS__T0001TTNATS' num2str(y(k)) M D '05HP001.dat'];
    swefname=['/' num2str(y(k)) '/' monthfolders{m(k)} '/SWE/us_ssmv1' '1034' ...
        'tS__T0001TTNATS' num2str(y(k)) M D '05HP001.dat'];
    depthfname2=fullfile(snodashome,depthfname);
    swefname2=fullfile(snodashome,swefname);
 
    %do depth first
    %open file
    fid=fopen(depthfname2,'r','ieee-be'); %last item is machineformat (key!)
    if fid ==-1
        snodas_h=NaN; % file may not have been found if it was a missing day
    elseif K<R.XIntrinsicLimits(1) | K>R.XIntrinsicLimits(2) | ...
            J<R.YIntrinsicLimits(1) | J>R.YIntrinsicLimits(2)
        snodas_h=NaN; %if lat / lon out of bounds
        fclose(fid);
    else
        %read in the data. 16 bit signed integers as per SNODAS doc.
        data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
        data(1)=[]; %toss this first value since not needed...the 'skip' option in 
                    %fread requires you read the first value, then we 'skip' to 
                    %the value we actually want.
        data(data==-9999)=NaN;  %set missing data cells to NaN
        fclose(fid);   
        snodas_h=data;
    end
    
    %do swe next
    %open file
    fid=fopen(swefname2,'r','ieee-be'); %last item is machineformat (key!)
    if fid==-1
        snodas_swe=NaN; %since file was missing
    elseif K<R.XIntrinsicLimits(1) | K>R.XIntrinsicLimits(2) | ...
        J<R.YIntrinsicLimits(1) | J>R.YIntrinsicLimits(2)
    snodas_swe=NaN; 
    fclose(fid);
    else
        %read in the data. 16 bit signed integers as per SNODAS doc.
        data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
        data(1)=[]; %toss this first value since not needed...the 'skip' option in 
                    %fread requires you read the first value, then we 'skip' to 
                    %the value we actually want.
        data(data==-9999)=NaN;  %set missing data cells to NaN
        fclose(fid);   
        snodas_swe=data;
    end
    
    snowcourse_snodas_data.data(k,:)=[y(k) m(k) d(k) doy(k) lat(k) ...
        lon(k) snowcourse_swe(k) snowcourse_h(k) snodas_swe snodas_h];
    
    if mod(k,100)==0
        disp([num2str(k/length(I)*100) '% done'])
    end
    
end

save([outputdir '/snowcourse_snodas_data.mat'], 'snowcourse_snodas_data', 'id') 


