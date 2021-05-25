%dfhill - dfh@oregonstate.edu
%February 2019

%This script (can be turned into a function if desired) will take a
%longitude and latitude value. It will then extract the min, max, and 
%mean snow depth (or swe) values at that location from the SNODAS dataset 
%for each day of the year. These are based on 15 years of SNODAS output. 

%It is assumed that you have already processed the SNODAS data files with
%my averagesnodas.m script (which creates min, max, and mean grids for each
%day of the year. All of these grids must be in the same folder (see
%below).

%NOTE: if you are doing Hs, and you have an observed HS, you can include
%this, and it will get plotted. 

clear all
close all
fclose('all')

% specify lon / lat (required)
lat=40.572096;
lon=-111.629968;

%specify (optonal) yr, mo, da of observation, and observed HS value (m) 
YR=2019;
MO=2;
DA=19;
HS=3; 

%uncomment variable of interest (you have to have these grids already!).
param='1036'; %Hs
%param='1034'; %swe

%set directory locations
gridshome='/Volumes/dfh-1/data/snodas/dailyclim'; %root dir for grids
%gridshome='/nfs/attic/dfh/Hill/snodas/dailyclim'; %root (on lassen)
outputdir='/Volumes/dfh-1/Hill/snodas_data_processing/graphics';    %root dir for output
%outputdir='/nfs/attic/dfh/Hill/snodas/graphics';

if ~exist(outputdir)
    mkdir(outputdir)
end

%Deal with constructing the lat/lon grid information
ncol=6935;  %columns
nrows=3351; %rows
cellsize=0.008333333333333;  %grid resolution in deg
ULlat=52.871249516804028; %center of upper left cell (lat)
ULlon=-124.729583333331703; %center of upper left cell (lon)

R=georasterref('RasterSize',[nrows,ncol],'ColumnsStartFrom','north', ...
    'RowsStartFrom','west','LatitudeLimits',[ULlat-(nrows)*cellsize ULlat], ...
    'LongitudeLimits',[ULlon ULlon+(ncol)*cellsize]);

%lets find the indices of the requested location in our matrix.
[I,J]=geographicToIntrinsic(R,lat,lon);
I=round(I);J=round(J);

%figure out how much data to skip...
numbertoskip=(J-1)*ncol+I-1;

months={'Jan' 'Feb' 'Mar' 'Apr' 'May' ...
    'Jun' 'Jul' 'Aug' 'Sep' 'Oct' 'Nov' 'Dec'};

days=[274:365 1:273];
%begin the main loop over days. We will first do day 274-365 (Oct1-Dec31).
%we then do Jan1-Sep30

for j=1:365 
    j
    [y m d]=datevec(datenum(2001,1,days(j))); %returns month and day numbers 
                                        %for the calendar day j.
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
    
    %do mean first
    %establish full filename...
    fname=[M D param 'mean.dat'];
    fname2=fullfile(gridshome,fname);
    %open file
    fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
    
    %read in the data. 16 bit signed integers as per SNODAS doc.
    data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
    data(1)=[]; %toss this first value since not needed...the 'skip' option in 
                %fread requires you read the first value, then we 'skip' to 
                %the value we actually want.
    data(data==-9999)=NaN;  %set missing data cells to NaN
    datamean(j)=data/1000; %convert to meters
    fclose(fid);
    
    %do min next
    %establish full filename...
    fname=[M D param 'min.dat'];
    fname2=fullfile(gridshome,fname);
    %open file
    fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
    
    %read in the data. 16 bit signed integers as per SNODAS doc.
    data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
    data(1)=[];
    data(data==-9999)=NaN;  %set missing data cells to NaN
    datamin(j)=data/1000; %convert to meters
    fclose(fid);
    
    %do max last
    %establish full filename...
    fname=[M D param 'max.dat'];
    fname2=fullfile(gridshome,fname);
    %open file
    fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
    
    %read in the data. 16 bit signed integers as per SNODAS doc.
    data=fread(fid,2,'integer*2',2*(numbertoskip-1),'ieee-be');
    data(1)=[];
    data(data==-9999)=NaN;  %set missing data cells to NaN
    datamax(j)=data/1000; %convert to meters
    fclose(fid);    
end

%set up figure
figure(1)
set(gcf,'PaperPosition',[1 1 5 4])
hold on

%deal with x axis stuff in date format. The absolute year (2001/2002) does
%not matter...but datenum requires one. We are making 'seasonal' plots
%(month on time axis), so the year is realy just a throwaway.
time=datenum([2001*ones(1,92) 2002*ones(1,273)],ones(size(days)),days);
fill([time fliplr(time)],[datamin fliplr(datamax)],'b')
grid on
alpha(0.1);
box on
plot(time,datamean,'b','LineWidth',2)
datetick('x','mmm')
ylabel('Snow Depth (m)','FontSize',10)
title(['Snow Depth at Lat = ' num2str(lat) ', Lon = ' num2str(lon)], ...
    'FontSize',10,'FontWeight','normal');

%let's add a marker at the snowdepth measurement. but only if HS is defined
%above.
if exist('HS')
    %create 'time' value for the measurement
    if MO<10
        T=datenum(2002,MO,DA);
    else
        T=datenum(2001,MO,DA);
    end
    plot([T T],[0 HS],'k','LineWidth',1,'HandleVisibility','off')
    plot(T,HS,'ko','MarkerSize',8,'LineWidth',1,'MarkerFaceColor','r')
end

%add legend
AX=legend('Mean');
AX.FontSize=10;

%write out figure.

fnameout=fullfile(outputdir,['lat' num2str(lat) 'lon' num2str(lon) 'stats.png']);
print(gcf,'-dpng','-r300',fnameout); %300 dpi png image



