%this file will read in CSO data (conus only) and it will then compare the
%data to the SNODAS data at those locations / times. It will then prepare
%some figures and make some plots

%david hill
%july 2020
%dfh@oregonstate.edu

clear all
close all
fclose all

%location of cso data file. NOTE: the data is downloaded from CSO website
%as geojson file. I use the following web site:
% https://www.convertcsv.com/geojson-to-csv.htm to convert to csv. It is
%critical to use this converter. Other converters will have things show up
%in differnt columns, with this converter, the csv columns are: 
%lat, lon, altitude, geometry, ID, author, depth (cm), source (e.g. mtn hub), timestamp,
%elevation, _ms (I don't know what this last one is). A sample time stamp
%is: 2020-03-05T06:16:38.790Z. It would be good to change this matlab file
%to instead work directly with geojson file and avoid this additional step.
csopath='/Volumes/dfh-1/data/CSO_OBS';
filename='cso_2017-2019.csv';
fname2=fullfile(csopath,filename);

opts = detectImportOptions(fname2,'NumHeaderLines',1);
T=readtable(fname2,'ReadVariableNames',true,'Delimiter',',');

id=T{:,5};
name=T{:,6};
cso_h=T{:,7};
timestamp=T{:,9};
lon=T{:,2};
lat=T{:,1};
z=T{:,10};

%pick off days
tmp=char(T{:,9});
tmp2=tmp(:,9:10);
d=str2num(tmp2);

%pick off years
tmp=char(T{:,9});
tmp2=tmp(:,1:4);
y=str2num(tmp2);

%pick off months
tmp=char(T{:,9});
tmp2=tmp(:,6:7);
m=str2num(tmp2);

%Next, we need to turn our year / month / day information into a 'day of
%water year' (DOY)
doy=datenum(y,m,d)-datenum(y,9,30); %OCT 1 will have a DOY of 1
doy(doy<0)=doy(doy<0)+365; %make all values positive, in range of 1 --> 365       

%we want to preallocate output.
%datacompare will have the following columns:
% year  month  day  DOY  lat  lon  cso_mtnhub_h snodas_h
datacompare=1.1*ones(length(id),8,'double');

%set up snodas stuff...
%set directory locations...(you need to change this depending on where your
%snodas stuff is at...
snodashome='/Volumes/dfh-1/data/snodas/snodas_download'; %root dir for snodas (local)
%snodashome='/nfs/attic/dfh/Hill/snodas'; %root (on lassen)
    
monthfolders={'01_Jan' '02_Feb' '03_Mar' '04_Apr' '05_May' ...
    '06_Jun' '07_Jul' '08_Aug' '09_Sep' '10_Oct' '11_Nov' '12_Dec'};

%establish grid size (masked files). You should not have to change this.
    ncol=6935;
    nrows=3351;
    cellsize=0.008333333333333;  %grid resolution in deg
    ULlat=52.871249516804028; %center of upper left cell (lat)
    ULlon=-124.729583333331703; %center of upper left cell (lon)
    R=georasterref('RasterSize',[nrows,ncol],'ColumnsStartFrom','north', ...
    'RowsStartFrom','west','LatitudeLimits',[ULlat-(nrows)*cellsize ULlat], ...
    'LongitudeLimits',[ULlon ULlon+(ncol)*cellsize]);

%let us now loop over the cso datapoints
for k=1:length(doy)
k
    %lets find the indices of the requested location in our matrix.
    [K,J]=geographicToIntrinsic(R,lat(k),lon(k));
    K=round(K);J=round(J);
    %figure out how much data to skip...
    numbertoskip=(J-1)*ncol+K-1;

    %We need to build up the name of the snodas file that we are going to open.
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

    %establish full file name...
    depthfname=['/' num2str(y(k)) '/' monthfolders{m(k)} '/Hs/us_ssmv1' '1036' ...
        'tS__T0001TTNATS' num2str(y(k)) M D '05HP001.dat'];
    depthfname2=fullfile(snodashome,depthfname);
 
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
    
    datacompare(k,:)=[y(k) m(k) d(k) doy(k) lat(k) lon(k) cso_h(k) snodas_h];
    
    if mod(k,10)==0
        disp([num2str(k/length(doy)*100) '% done'])
    end
    
end

%make plots
figure(1);
set(gcf,'PaperPosition',[1,1,3,2]);
I=find(datacompare(:,7)<1000);
binscatter(datacompare(I,7)*10,datacompare(I,8),40);
colorbar off
xlabel('CSO Hs (mm)');ylabel('SNODAS Hs (mm)')
axis([0 5000 0 5000])
axis square
grid on
box on
print -dpng -r300 cso_snodas_depth.png

bias_snodas_mh=datacompare(I,8)-datacompare(I,7)*10;
BIAS_sd=nanmean(bias_snodas_mh)

figure(2)
set(gcf,'PaperPosition',[1,1,3,2]);
range=-2000:1000;
[f,xi]=ksdensity(bias_snodas_mh,range);
plot(xi,f,'k');
ylabel('Probability'); xlabel('Hs error (mm)');
title('CSO')
grid on
box on
print -dpng -r300 cso_snodas_depth_bias.png





