%dfhill - dfh@oregonstate.edu
%Feb 2019

%This script will compute 15-year averages for the daily masked Hs or SWE as
%output by SNODAS. In the end, for each day of the year, three grids will
%be created. One for min depth, one for mean depth, and one for max depth.
%The averaging is done over water year, not calendar year. Feb 29 is simply
%ignored.

%Data assumed to be in folder structure like:
%snodas
%   2003
%       01_Jan
%            Hs
%            SWE
%       02_Feb
%       etc.
%   2004
%       01_Jan
%       etc

%In each folder, you should have the SWE (1034) and Hs (1036) files from
%SNODAS. They must be untarred and unzipped. So, for each file, you will
%have two files; a .dat (data) and a .Hdr (header). Period of Record should
%be Oct 2003 --> Sep 2018. 15 full water years

%NOTE: the SNODAS dataset is missing data for the following dates:
% 2004-02-25, 2004-08-31, 2004-09-27, 2005-06-25, 2005-08-01, 2005-08-02
% 2006-08-26, 2006-08-27, 2006-09-08, 2006-09-30, 2006-10-01, 2007-02-14
% 2007-03-26, 2008-03-13, 2008-06-13, 2008-06-18, 2009-08-20, 2012-12-20

clear all
close all
fclose('all')

%uncomment variable of interest.
param='1036'; %Hs
%param='1034'; %Swe

%set directory locations...
snodashome='/Volumes/dfh-1/data/snodas/snodas_download'; %root dir for snodas (local)
%snodashome='/nfs/attic/dfh/Hill/snodas'; %root (on lassen)

outfiledir='/Volumes/dfh-1/data/snodas/dailyclim'; %dir for output (local)
%outfiledir='/nfs/attic/dfh/Hill/snodas/dailyclim'; %output (lassen)

if ~exist(outfiledir)
    mkdir(outfiledir);
end

monthfolders={'01_Jan' '02_Feb' '03_Mar' '04_Apr' '05_May' ...
    '06_Jun' '07_Jul' '08_Aug' '09_Sep' '10_Oct' '11_Nov' '12_Dec'};

%establish grid size (masked files)
ncol=6935;
nrows=3351;

%compute datenumbers of missing dates
year=[2003 2004 2004 2004 2005 2005 2005 2006 2006 2006 2006 2006 ...
    2007 2007 2008 2008 2008 2009 2012];
month=[10 2 8 9 6 8 8 8 8 9 9 10 2 3 3 6 6 8 12];
day=[30 25 31 27 25 1 2 26 27 8 30 1 14 26 13 13 18 20 20];
missingdates=datenum(year,month,day);

%Begin the main loop over days 1-->365. 1 = Jan 1. 365 = Dec 31. 
for j=293:365 
    
    disp(['processing calendar day ' num2str(j)])
    
    %initialize arrays
    datamean=zeros(ncol,nrows);  %mean grid
    datacount=zeros(ncol,nrows); %count of bad (-9999) points at each grid cell
       
    if j>=274   %this catches Oct, Nov, Dec days. I wish to do averaging over
                %water years, not calendar years...
        startyear=2003;
        endyear=2018;
    else
        startyear=2004;
        endyear=2019;
    end
    
    %begin the loop over the 16 years in the POR
    for k=startyear:endyear
        disp(['processing year ' num2str(k)])
        
        [y m d]=datevec(datenum(2003,1,j)); %returns month and day numbers 
        %for the calendar day j. The 2003 doesn't really matter...
        %just pick any non-leap year.

        %check to see if this is one of the missing days. If it is not,
        %proceed to load the data. If it is, just skip this year.
        thisdate=datenum(k,m,d);
        if ~ismember(thisdate,missingdates)
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
                fname=['/' num2str(k) '/' monthfolders{m} '/Hs' ...
                    '/us_ssmv1' param 'tS__T0001TTNATS' num2str(k) M D '05HP001.dat'];
            else
                fname=['/' num2str(k) '/' monthfolders{m} '/SWE' ...
                    '/us_ssmv1' param 'tS__T0001TTNATS' num2str(k) M D '05HP001.dat'];
            end
            fname2=fullfile(snodashome,fname);
            %open file
            fid=fopen(fname2,'r','ieee-be'); %last item is machineformat (key!)
            %read in the data. 16 bit signed integers as per SNODAS doc.
            datatemp=fread(fid,[ncol,nrows],'integer*2');
            I=find(datatemp==-9999);    %index location of missing points
            J=find(datatemp~=-9999);    %index location of valid points
            datacount=datacount+double(datatemp~=-9999); %increment for valid points
            datatemp(I)=NaN;    %set missing points to NaN to not affect min/max

            if k==startyear
                datamin=datatemp;
                datamax=datatemp;
            else
                datamin=min(datamin,datatemp);
                datamax=max(datamax,datatemp);
            end

            datatemp(I)=0;      %set missing points to 0 to not affect sum
            datamean=datamean+datatemp; %running sum
            fclose(fid);
        end
        
    end
    %compute the mean
    datamean=datamean./datacount;
    datamean(datacount==0)=-9999;   %locations with no valid data
    datamin(isnan(datamin))=-9999;
    datamax(isnan(datamax))=-9999;
    
    %establish full filename for outputfiles...
    %write out three files; min, max, and mean.
    %naming format is mmdd param type .dat (type is min, max, or mean)
    fnameout=['/' M D param 'min.dat'];
    fnameout2=fullfile(outfiledir,fnameout);
    
    fid=fopen(fnameout2,'w','ieee-be');
    fwrite(fid,datamin,'integer*2');
    fclose(fid);
    
    fnameout=['/' M D param 'max.dat'];
    fnameout2=fullfile(outfiledir,fnameout);
    
    fid=fopen(fnameout2,'w','ieee-be');
    fwrite(fid,datamax,'integer*2');
    fclose(fid);
    
    fnameout=['/' M D param 'mean.dat'];
    fnameout2=fullfile(outfiledir,fnameout);
    
    fid=fopen(fnameout2,'w','ieee-be');
    fwrite(fid,datamean,'integer*2');
    fclose(fid);
    
end
    

