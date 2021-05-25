%this script will read in a .csv file from the cocorahs project. It will
%retain only the observations that fall within the time range of the SNODAS
%dataset (2003 - 2018 (or whatever)). It will then go into the snodas
%dataset and pull the values of Hs and SWE at all dates / locations of
%cocorahs points. Finally, it will save a new .mat file that contains
%cocorahs Hs and SWE and also snodas Hs and SWE. There is a separate script
%that will then plot / analyze the data...I separate them since this
%initial operation is very slow (millions of points).

%format of cocrahs file is this:
%StationNumber,StationName,Latitude,Longitude,ReportDate,ReportTime,TotalSnowDepth,TotalSnowSWE
%units for swe / h are in inches.

%Dave Hill - Oregon State University
%created 2019.

clear all
close all
fclose all

%%%%%%%%%%%%%%%%
%USER INPUT
%path to cocorahs csv file.
cocopath='/Volumes/dfh-1/data/cocorahs';
%name of file.
filename='CoCoRaHS_TotalSnowDepthAndSwe_1999-2018.csv';
fname2=fullfile(cocopath,filename);

%path to snodas data
snodashome='/Volumes/dfh-1/data/snodas/snodas_download'; %root dir for snodas (local)
%snodashome='/nfs/attic/dfh/Hill/snodas'; %root (on lassen)

%output file directory (where do you want to store the result). One option
%is to just put it in the same place as the raw cocorahs data. Up to you.
outputdir='/Volumes/dfh-1/data/cocorahs';

%%%%%%%%%%%%%%%%%

%read the cocorahs file in.
opts = detectImportOptions(fname2,'NumHeaderLines',0);
T=readtable(fname2,opts,'ReadVariableNames',true);

%delete rows with zero value for depth
T(T.TotalSnowDepth==0,:)=[];
%delete rows with -1 (trace) for depth
T(T.TotalSnowDepth==-1,:)=[];
%delete rows with -2 (N/A) for depth
T(T.TotalSnowDepth==-2,:)=[];

id=T{:,1};
lon=T{:,4};
lat=T{:,3};
dates=T{:,5};
coco_h=T{:,7}*25.4; %put in mm...
coco_swe=T{:,8};

%find date info
[y,m,d]=datevec(dates);

%let us eliminate data outside our range.
I=find(datenum(y,m,d)<datenum(2003,10,1) | datenum(y,m,d)>datenum(2018,9,30));
id(I,:)=[];
lon(I)=[]; lat(I)=[]; y(I)=[]; m(I)=[]; d(I)=[]; coco_h(I)=[]; coco_swe(I)=[];

%Next, we need to turn our year / month / day information into a 'day of
%water year' (DOY)
doy=datenum(y,m,d)-datenum(y,9,30); %OCT 1 will have a DOY of 1
doy(doy<0)=doy(doy<0)+365; %make all values positive, in range of 1 --> 365       

%we want to preallocate output.
%cocorahs_snodas_data will have the following columns:
% year  month  day  DOY  lat  lon  coco_swe  coco_h  snodas_swe  snodas_h
cocorahs_snodas_data.data=1.1*ones(length(id),10,'double');

%a bit of metadata
cocorahs_snodas_data.meta.description = 'columns: y m d doy lat lon coco_swe coco_h snodas_swe snodas_h';
cocorahs_snodas_data.meta.author = 'david hill; dfh@oregonstate.edu';
cocorahs_snodas_data.meta.creationdate = date;
    
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

%let us now loop over the cocorahs datapoints
for k=1:length(id)

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
        fclose all;%(fid);
    else
        %read in the data. 16 bit signed integers as per SNODAS doc.
        data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
        data(1)=[]; %toss this first value since not needed...the 'skip' option in 
                    %fread requires you read the first value, then we 'skip' to 
                    %the value we actually want.
        data(data==-9999)=NaN;  %set missing data cells to NaN
        fclose all;%(fid);   
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
    fclose all;%(fid);
    else
        %read in the data. 16 bit signed integers as per SNODAS doc.
        data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
        data(1)=[]; %toss this first value since not needed...the 'skip' option in 
                    %fread requires you read the first value, then we 'skip' to 
                    %the value we actually want.
        data(data==-9999)=NaN;  %set missing data cells to NaN
        fclose all;%(fid);   
        snodas_swe=data;
    end
    
    cocorahs_snodas_data.data(k,:)=[y(k) m(k) d(k) doy(k) lat(k) lon(k) ...
        coco_swe(k) coco_h(k) snodas_swe snodas_h];
    
    if mod(k,10000)==0
        disp([num2str(k/length(id)*100) '% done'])
    end
    
end

%Hmmm....turns out there are some weird points in the data. I think that
%there are a lot of coco data points with a depth of 99. That seems to be a
%'flag' value.

k=find(coco_h==99*25.4);
cocorahs_snodas_data.data(k,:)=[];
id(k,:)=[];

%finally, there are some other weird points with coco_h very large. I am
%going to delete those.

k=find(coco_h>100*25.4);
cocorahs_snodas_data.data(k,:)=[];
id(k,:)=[];

save([outputdir '/coco_snodas_data.mat'], 'cocorahs_snodas_data', 'id') 





