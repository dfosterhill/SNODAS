%created by david hill June 2019
%this script will open up the .mat file saved by the extract_snodas_at_cocorahs_points
%script. That .mat file contains SWE and h both from cocorahs, and also 
%snodas. This script will then just do some basic analysis and make some
%plots. 

clear all
close all

%set path to coco data
cocopath='/Volumes/dfh-1/data/cocorahs';
%file name
filename='coco_snodas_data.mat';

%set path to folder for output graphics
outputdir='/Volumes/dfh-1/Hill/snodas_data_processing/graphics/snodas_vs_other';
if ~exist(outputdir)
    mkdir(outputdir)
end

%load the data
load(fullfile(cocopath,filename));

%we are going to be ONLY working with depth values. Don't care about swe.

%first. I will eliminate all rows where snodas is NAN this is due
%to sites being out of snodas domain. 

I=find(isnan(cocorahs_snodas_data.data(:,10))==1);
length(I)
id(I,:)=[]; cocorahs_snodas_data.data(I,:)=[];

%next. eliminate rows where the snodas depth is zero. I am
%doing this to be consistent with the coco data base. In the processing
%of that database, we kept only non-zero values.
J=find(cocorahs_snodas_data.data(:,10)==0);
length(J)
cocorahs_snodas_data.data(J,:)=[];
id(J,:)=[];

%pick off various columns.
y=cocorahs_snodas_data.data(:,1);
m=cocorahs_snodas_data.data(:,2);
d=cocorahs_snodas_data.data(:,3);
doy=cocorahs_snodas_data.data(:,4);
lat=cocorahs_snodas_data.data(:,5);
lon=cocorahs_snodas_data.data(:,6);
coco_swe=cocorahs_snodas_data.data(:,7);
coco_h=cocorahs_snodas_data.data(:,8);
snodas_swe=cocorahs_snodas_data.data(:,9);
snodas_h=cocorahs_snodas_data.data(:,10);

%treating coco as ground truth, compute overall bias and RMSE
bias_h=nanmean(snodas_h-coco_h)
rmse_h=sqrt(nanmean((snodas_h-coco_h).^2))

%make plots
figure(1);
set(gcf,'PaperPosition',[1,1,3,2]);
binscatter(coco_h,snodas_h);
colorbar off
xlabel('CoCoRaHS Hs (mm)');ylabel('SNODAS Hs (mm)')
axis([0 3000 0 3000])
axis square
grid on
box on

fnameout=fullfile(outputdir,'coco_snodas_depth.png');
print(gcf,'-dpng','-r300',fnameout);

%next, let us investigate errors by individual coco station location.
IDlist=unique(id);

for k=1:length(IDlist)
    k;
    I=find(strcmp(id,IDlist(k)));
    station_lon(k)=lon(I(1));
    station_lat(k)=lat(I(1));
    station_bias_h(k)=nanmean(snodas_h(I)-coco_h(I));
    station_rmse_h(k)=sqrt(nanmean((snodas_h(I)-coco_h(I)).^2));

   if mod(k,1000)==0
       disp(num2str(k))
   end
    
end

%make some figs
figure(3)
set(gcf,'PaperPosition',[1 1 5 4])
ax = worldmap([30 50],[-130 -70]);
setm(gca,'MLineLocation',[-120 -100 -80]);
setm(gca,'MLabelLocation',[-120 -100 -80]);
load coastlines
geoshow(ax, coastlat, coastlon,...
'DisplayType', 'polygon', 'FaceColor', [1 1 1])
states = shaperead('usastatelo', 'UseGeoCoords', true);
geoshow(ax, states, 'DisplayType', 'polygon','FaceColor',[1 1 1])
scatterm(station_lat,station_lon,2,station_bias_h,'filled')
colormap(brewermap([],'RdBu'))
colorbar
caxis([-200 200])
title('h bias (mm)')
fnameout=fullfile(outputdir,'coco_station_bias_h_map.png');
print(gcf,'-dpng','-r300',fnameout);

figure(4)
set(gcf,'PaperPosition',[1 1 3 2])
range=-200:200;
[f,xi]=ksdensity(station_bias_h,range);
plot(xi,f,'k');
ylabel('Probability'); xlabel('Hs error (mm)')
grid on
fnameout=fullfile(outputdir,'coco_station_bias_h_dist.png');
title('CoCoRaHS')
print(gcf,'-dpng','-r300',fnameout);

figure(5)
set(gcf,'PaperPosition',[1 1 5 4])
ax = worldmap([30 50],[-130 -70]);
setm(gca,'MLineLocation',[-120 -100 -80]);
setm(gca,'MLabelLocation',[-120 -100 -80]);
load coastlines
geoshow(ax, coastlat, coastlon,...
'DisplayType', 'polygon', 'FaceColor', [1 1 1])
states = shaperead('usastatelo', 'UseGeoCoords', true);
geoshow(ax, states, 'DisplayType', 'polygon','FaceColor',[1 1 1])
scatterm(station_lat,station_lon,2,station_rmse_h,'filled')
colormap(brewermap([],'YlGnBu'))
colorbar
caxis([0 400])
title('h RMSE (mm)')
fnameout=fullfile(outputdir,'coco_station_rmse_h_map.png');
print(gcf,'-dpng','-r300',fnameout);

figure(6)
set(gcf,'PaperPosition',[1 1 5 4])
range=0:500;
[f,xi]=ksdensity(station_rmse_h,range);
plot(xi,f,'k');
ylabel('Probability'); title('h RMSE (mm)')
grid on
fnameout=fullfile(outputdir,'coco_station_rmse_h_dist.png');
print(gcf,'-dpng','-r300',fnameout);



    
