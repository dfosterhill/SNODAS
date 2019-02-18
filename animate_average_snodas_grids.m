%dfhill - dfh@oregonstate.edu
%February 2019

%this script will animate a sequence of 365 plots of mean daily snow
%(either Hs or SWE). The grids that are to be used for the plots
%are the 'averaged' (over the 15 year period of record) grids created by 
%the averagesnodas.m script. The generated animation is for a domain
%specified by the user (lat / lon limits). I have included several options
%but please add your own. All of the input files must be in a single folder
%(see below).

%note, my code uses brewermap.m, available at the link below. If you don't
%want to use that, make up your own colomap.
%https://www.mathworks.com/matlabcentral/fileexchange/
%45208-colorbrewer-attractive-and-distinctive-colormaps

clear all
close all
fclose('all')

%uncomment variable of interest (you have to have these grids already!).
param='1036'; %Hs
%param='1034'; %swe

%set directory locations
gridshome='/Volumes/dfh/Hill/snodas/dailyclim'; %root dir for grids
%gridshome='/nfs/attic/dfh/Hill/snodas/dailyclim'; %root (on lassen)
outputdir='/Volumes/dfh/Hill/snodas/graphics';    %root dir for output
%outputdir='/nfs/attic/dfh/Hill/snodas/graphics'; %root (on lasses)

if ~exist(outputdir)
    mkdir(outputdir)
end

%Deal with constructing the lat/lon grid information. This is from the .Hdr
%files of the masked SNODAS data
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

days=[274:365 1:273];
%begin the main loop over days. We will first do day 274-365 (Oct1-Dec31).
%we then do Jan1-Sep30

%load state boundaries (in the mapping toolbox in Matlab)
states = shaperead('usastatelo', 'UseGeoCoords', true);

%open up video object. Give it a sensible name!
writerObj=VideoWriter('west_mont.avi');
writerObj.FrameRate=15; %this seems to make an animation of a good length
writerObj.Quality=90;
open(writerObj);

for j=1:365
    j
    [y m d]=datevec(datenum(2003,1,days(j))); %returns month and day numbers 
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
    
    %establish full filename...
    fname=[M D param 'mean.dat'];
    fname2=fullfile(gridshome,fname);
    %open file
    fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
    
    %read in the data. 16 bit signed integers as per SNODAS doc.
    data=fread(fid,[ncol,nrows],'integer*2');
    data(data==-9999)=NaN;  %set missing data cells to NaN
    data(data==0)=NaN;  %set zero values to NaN
    data=data/1000; %convert to meters
    fclose(fid);
    
    figure(1)
    set(gcf,'PaperPosition',[1 1 6 4]);
    %uncomment the bounding box of interest, or make your own!
    %ax=worldmap([25 53],[-127 -66]); continential USA
    %ax=worldmap([41.5 46.5],[-125 -116]); %oregon
    %ax=worldmap([45.5 49.25],[-125 -116.5]); %washington
    %ax=worldmap([42.5 45.5],[-73 -70.5]); %new hampshire
    %ax=worldmap([36.75 42.25],[-114.5 -108.5]); %utah
    %ax=worldmap([40 42],[-112 -110]); %SLC area
    ax=worldmap([44.25 49.25],[-116 -109]); %western montana
    
    geoshow(ax, states, 'DisplayType', 'polygon','FaceColor','none','HandleVisibility','off')
    hold on
    geoshow(data',R,'DisplayType','surface')
    map=brewermap(10,'GnBu'); %need to have brewermap. If you don't, then you can 
                              %use a stock matlab colormap instead
    colormap(map);
    h=colorbar('northoutside'); caxis([0 2]); set(get(h,'title'),'string','Hs (m)')
    title([months{m} ' ' D]);
    box on
    frame=getframe(gcf);
    writeVideo(writerObj,frame); 
    close(1);   %key; otherwise, it bogs down.
end

close(writerObj);



