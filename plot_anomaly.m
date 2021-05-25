%dfhill - dfh@oregonstate.edu
%February 2019

%this script will make an anomaly plot for snow depth. Given a particular
%day / month / year, it will difference the grid with the previously
%computed climatology grid for that day! Presently, this is set only to
%work with the mean values.

clear all
close all
fclose('all')
clc

%uncomment variable of interest (you have to have these grids already!).
param='1036'; %Hs
%param='1034'; %swe

%specify domain
%uncomment the bounding box of interest, or make your own! Give name as
%well
%latlim=[25 53]; lonlim=[-127 -66]; domain='USA'; %USA
latlim=[41.5 46.5]; lonlim=[-125 -116]; domain='Oregon'; %oregon
%latlim=[45.5 49.25]; lonlim=[-125 -116.5]; %washington
%latlim=[42.5 45.5]; lonlim=[-73 -70.5]; %new hampshire
%latlim=[36.75 42.25]; lonlim=[-114.5 -108.5]; %utah
%latlim=[40 42]; lonlim=[-112 -110]; %SLC area
%latlim=[44.25 49.25]; lonlim=[-116 -109]; %western montana

%below is the day for which I'd like to compute the anomaly.
y=2019;
m=5;
d=3;

%set directory locations
%first, the directory where the previously computed climatoloty grids are
%(please see compute_snodas_climatologies.m)
gridshome='/Volumes/dfh-1/data/snodas/dailyclim'; %root dir for grids
%gridshome='/nfs/attic/dfh/Hill/snodas/dailyclim'; %root (on lassen)

%next, the location of the complete set of daily files
dailyhome='/Volumes/dfh-1/data/snodas/snodas_download'; %dir for daily data

%finally, where do you want the output to go?
outputdir='/Volumes/dfh-1/Hill/snodas_data_processing/graphics'; 
%outputdir='/nfs/attic/dfh/Hill/snodas/graphics';

if ~exist(outputdir)
    mkdir(outputdir)
end

%First, we have to check to see if the user picked a missing day.
%NOTE: the SNODAS dataset is missing data for the following dates:
% 2004-02-25, 2004-08-31, 2004-09-27, 2005-06-25, 2005-08-01, 2005-08-02
% 2006-08-26, 2006-08-27, 2006-09-08, 2006-09-30, 2006-10-01, 2007-02-14
% 2007-03-26, 2008-03-13, 2008-06-13, 2008-06-18, 2009-08-20, 2012-12-20

%compute datenumbers of missing dates
year=[2003 2004 2004 2004 2005 2005 2005 2006 2006 2006 2006 2006 ...
    2007 2007 2008 2008 2008 2009 2012];
month=[10 2 8 9 6 8 8 8 8 9 9 10 2 3 3 6 6 8 12];
day=[30 25 31 27 25 1 2 26 27 8 30 1 14 26 13 13 18 20 20];
missingdates=datenum(year,month,day);
userdata=datenum(y,m,d);

%Deal with constructing the lat/lon grid information
ncol=6935;  %columns
nrows=3351; %rows
cellsize=0.008333333333333;  %grid resolution in deg
ULlat=52.871249516804028; %center of upper left cell (lat)
ULlon=-124.729583333331703; %center of upper left cell (lon)

R=georasterref('RasterSize',[nrows,ncol],'ColumnsStartFrom','north', ...
    'RowsStartFrom','west','LatitudeLimits',[ULlat-(nrows)*cellsize ULlat], ...
    'LongitudeLimits',[ULlon ULlon+(ncol)*cellsize]);

months={'Jan' 'Feb' 'Mar' 'Apr' 'May' ...
    'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};

monthfolders={'01_Jan' '02_Feb' '03_Mar' '04_Apr' '05_May' ...
    '06_Jun' '07_Jul' '08_Aug' '09_Sep' '10_Oct' '11_Nov' '12_Dec'};

%read in state boundaries
states = shaperead('usastatelo', 'UseGeoCoords', true);

%lets pull in the grid for the day in question.
%build up bits of file name
if m<10                     
    M=['0' num2str(m)];
else
    M=num2str(m);
end

if d<10
    D=['0' num2str(d)];
else
    D=num2str(d);
end

%establish full filename...
if strcmp(param,'1036')
    fname=['/' num2str(y) '/' monthfolders{m} '/Hs/us_ssmv1' param ...
        'tS__T0001TTNATS' num2str(y) M D '05HP001.dat'];
else
    fname=['/' num2str(y) '/' monthfolders{m} '/SWE/us_ssmv1' param ...
        'tS__T0001TTNATS' num2str(y) M D '05HP001.dat'];
end
fname2=fullfile(dailyhome,fname);

%open file
fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
%read in the data. 16 bit signed integers as per SNODAS doc.
data=fread(fid,[ncol,nrows],'integer*2');
data(data==-9999)=NaN;  %set missing data cells to NaN
data(data==0)=NaN;  %set zero values to NaN
data=data/1000; %convert to meters
fclose(fid);

%lets pull in the climatological grid for that day of the year!
fname=['/' M D param 'mean.dat'];
fname2=fullfile(gridshome,fname);
%open file
fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
%read in the data. 16 bit signed integers as per SNODAS doc.
dataavg=fread(fid,[ncol,nrows],'integer*2');
dataavg(dataavg==-9999)=NaN;  %set missing data cells to NaN
dataavg(dataavg==0)=NaN;  %set zero values to NaN
dataavg=dataavg/1000; %convert to meters
fclose(fid);

figure(1)
set(gcf,'PaperPosition',[1 1 6 4]);
ax=worldmap(latlim,lonlim);

geoshow(ax, states, 'DisplayType', 'polygon','FaceColor','none','HandleVisibility','off')
hold on
geoshow(data'-dataavg',R,'DisplayType','surface')
map=brewermap(10,'RdBu');
colormap(map);

%note the caxis on next line. Adjust this as you desire (colorbar axis
%limits)
if strcmp(param,'1036')
    varname='Hs';
else
    varname='SWE';
end
h=colorbar('northoutside'); caxis([-1.5 1.5]); set(get(h,'title'),'string',['\Delta' varname ' (m)'])
title([months{m} ' ' D ' ' num2str(y)]);
box on

%prep output
%build up bits of output file name (001, 002, 003, etc...)
if j<10                     
    J=['00' num2str(j)];
elseif j>=10 & j<100
    J=['0' num2str(j)];
else
    J=num2str(j);
end
fnameout=fullfile(outputdir,[domain '_' M D num2str(y) 'anom_image.png']);
print(gcf,'-dpng','-r300',fnameout); %300 dpi png images






