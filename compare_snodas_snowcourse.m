%created by david hill June 2019
%this script will open up the saved .mat file that contains snow course and
%snodas data. It will then do some analysis.

clear all
close all
clc

%set path to .mat file
snowcoursepath='/Volumes/dfh-1/data/snowcourse';
%file name
filename='snowcourse_snodas_data.mat';

%set path to folder for output graphics
outputdir='/Volumes/dfh-1/Hill/snodas_data_processing/graphics/snodas_vs_other';
if ~exist(outputdir)
    mkdir(outputdir)
end

%load the data
load(fullfile(snowcoursepath,filename));

%first. I will eliminate all rows where snodas is NAN this is due
%to sites being out of snodas domain. 

I=find(isnan(snowcourse_snodas_data.data(:,9))==1);
length(I)
id(I,:)=[]; snowcourse_snodas_data.data(I,:)=[];

%next. eliminate rows where the snodas depth or swe is zero. I am
%doing this to be consistent with the snowcourse data base. In the processing
%of that database, we kept only non-zero values.
J=find(snowcourse_snodas_data.data(:,9)==0 | snowcourse_snodas_data.data(:,10)==0);
length(J)
snowcourse_snodas_data.data(J,:)=[];
id(J,:)=[];

%pick off various columns.
y=snowcourse_snodas_data.data(:,1);
m=snowcourse_snodas_data.data(:,2);
d=snowcourse_snodas_data.data(:,3);
doy=snowcourse_snodas_data.data(:,4);
lat=snowcourse_snodas_data.data(:,5);
lon=snowcourse_snodas_data.data(:,6);
snowcourse_swe=snowcourse_snodas_data.data(:,7);
snowcourse_h=snowcourse_snodas_data.data(:,8);
snodas_swe=snowcourse_snodas_data.data(:,9);
snodas_h=snowcourse_snodas_data.data(:,10);

%treating snowcourse as ground truth, compute overall bias and RMSE
bias_swe=nanmean(snodas_swe-snowcourse_swe)
rmse_swe=sqrt(nanmean((snodas_swe-snowcourse_swe).^2))

bias_h=nanmean(snodas_h-snowcourse_h)
rmse_h=sqrt(nanmean((snodas_h-snowcourse_h).^2))

%make plots
figure(1);
set(gcf,'PaperPosition',[1,1,3,2]);
binscatter(snowcourse_h,snodas_h);
xlabel('Snow Course Hs (mm)');ylabel('SNODAS Hs (mm)')
axis([0 7000 0 7000])
axis square
grid on
box on
colorbar off

fnameout=fullfile(outputdir,'snowcourse_snodas_depth.png');
print(gcf,'-dpng','-r300',fnameout);

figure(2);
set(gcf,'PaperPosition',[1,1,5,4]);
binscatter(snowcourse_swe,snodas_swe);
xlabel('Snow Course SWE (mm)');ylabel('SNODAS SWE (mm)')
axis([0 3000 0 3000])
grid on
box on

fnameout=fullfile(outputdir,'snowcourse_snodas_swe.png');
print(gcf,'-dpng','-r300',fnameout);

%next, let us investigate errors by individual snotel station location.
IDlist=unique(id);

for k=1:length(IDlist)
    k
    I=find(strcmp(id,IDlist(k)));
    station_lon(k)=lon(I(1));
    station_lat(k)=lat(I(1));
    station_bias_h(k)=nanmean(snodas_h(I)-snowcourse_h(I));
    station_bias_swe(k)=nanmean(snodas_swe(I)-snowcourse_swe(I));
    station_rmse_h(k)=sqrt(nanmean((snodas_h(I)-snowcourse_h(I)).^2));
    station_rmse_swe(k)=sqrt(nanmean((snodas_swe(I)-snowcourse_swe(I)).^2));
    
   if mod(k,1000)==0
     disp(num2str(k))
   end

end

%make some figs
figure(3)
set(gcf,'PaperPosition',[1 1 7.5 3])
subplot(1,2,1)
ax = worldmap([30 50],[-130 -100]);
setm(gca,'MLineLocation',[-150 -120 -90]);
setm(gca,'MLabelLocation',[-150 -120 -90]);
load coastlines
geoshow(ax, coastlat, coastlon,...
'DisplayType', 'polygon', 'FaceColor', [1 1 1])
states = shaperead('usastatelo', 'UseGeoCoords', true);
geoshow(ax, states, 'DisplayType', 'polygon','FaceColor',[1 1 1])
scatterm(station_lat,station_lon,10,station_bias_h,'filled')
colormap(brewermap([],'RdBu'))
colorbar
caxis([-500 500])
title('h bias (mm)')

h=subplot(1,2,2);
range=-500:500;
[f,xi]=ksdensity(station_bias_h,range);
plot(xi,f,'k');
ylabel('Probability'); title('h bias (mm)')
set(h,'position',[0.5703 0.2100 0.3347 0.6150])
grid on
fnameout=fullfile(outputdir,'snowcourse_station_bias_h_map.png');
print(gcf,'-dpng','-r300',fnameout);


%
figure(10)
set(gcf,'PaperPosition',[1 1 3 2])
range=-500:500;
[f,xi]=ksdensity(station_bias_h,range);
plot(xi,f,'k');
ylabel('Probability'); xlabel('Hs error (mm)')
grid on
fnameout=fullfile(outputdir,'snowcourse_station_bias_h_dist_v2.png');
title('Snow Course')
print(gcf,'-dpng','-r300',fnameout);
%

figure(4)
set(gcf,'PaperPosition',[1 1 7.5 3])
subplot(1,2,1)
ax = worldmap([30 50],[-130 -100]);
setm(gca,'MLineLocation',[-150 -120 -90]);
setm(gca,'MLabelLocation',[-150 -120 -90]);
load coastlines
geoshow(ax, coastlat, coastlon,...
'DisplayType', 'polygon', 'FaceColor', [1 1 1])
states = shaperead('usastatelo', 'UseGeoCoords', true);
geoshow(ax, states, 'DisplayType', 'polygon','FaceColor',[1 1 1])
scatterm(station_lat,station_lon,10,station_bias_swe,'filled')
colormap(brewermap([],'RdBu'))
colorbar
caxis([-100 100])
title('SWE bias (mm)')

h=subplot(1,2,2);
range=-100:100;
[f,xi]=ksdensity(station_bias_swe,range);
plot(xi,f,'k');
ylabel('Probability'); title('SWE bias (mm)')
set(h,'position',[0.5703 0.2100 0.3347 0.6150])
grid on
fnameout=fullfile(outputdir,'snowcourse_station_bias_swe_map.png');
print(gcf,'-dpng','-r300',fnameout);

figure(5)
set(gcf,'PaperPosition',[1 1 7.5 3])
subplot(1,2,1)
ax = worldmap([30 50],[-130 -100]);
setm(gca,'MLineLocation',[-150 -120 -90]);
setm(gca,'MLabelLocation',[-150 -120 -90]);
load coastlines
geoshow(ax, coastlat, coastlon,...
'DisplayType', 'polygon', 'FaceColor', [1 1 1])
states = shaperead('usastatelo', 'UseGeoCoords', true);
geoshow(ax, states, 'DisplayType', 'polygon','FaceColor',[1 1 1])
scatterm(station_lat,station_lon,10,station_rmse_h,'filled')
colormap(brewermap([],'YlGnBu'))
colorbar
caxis([0 800])
title('h RMSE (mm)')

h=subplot(1,2,2);
range=0:1000;
[f,xi]=ksdensity(station_rmse_h,range);
plot(xi,f,'k');
ylabel('Probability'); title('h RMSE (mm)')
set(h,'position',[0.5703 0.2100 0.3347 0.6150])
grid on
fnameout=fullfile(outputdir,'snowcourse_station_rmse_h_map.png');
print(gcf,'-dpng','-r300',fnameout);

figure(6)
set(gcf,'PaperPosition',[1 1 7.5 3])
subplot(1,2,1)
ax = worldmap([30 50],[-130 -100]);
setm(gca,'MLineLocation',[-150 -120 -90]);
setm(gca,'MLabelLocation',[-150 -120 -90]);
load coastlines
geoshow(ax, coastlat, coastlon,...
'DisplayType', 'polygon', 'FaceColor', [1 1 1])
states = shaperead('usastatelo', 'UseGeoCoords', true);
geoshow(ax, states, 'DisplayType', 'polygon','FaceColor',[1 1 1])
scatterm(station_lat,station_lon,10,station_rmse_swe,'filled')
colormap(brewermap([],'YlGnBu'))
colorbar
caxis([0 500])
title('SWE RMSE (mm)')

h=subplot(1,2,2);
range=0:500;
[f,xi]=ksdensity(station_rmse_swe,range);
plot(xi,f,'k');
ylabel('Probability'); title('SWE RMSE (mm)')
set(h,'position',[0.5703 0.2100 0.3347 0.6150])
grid on
fnameout=fullfile(outputdir,'snowcourse_station_rmse_swe_map.png');
print(gcf,'-dpng','-r300',fnameout);
    
