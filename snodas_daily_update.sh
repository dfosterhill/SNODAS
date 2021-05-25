#! /bin/bash
# script to be run daily (cron job) to obtain the latest SNODAS grids. Note that the 
# snodas grids seem to come online at 7 am each day. So, I will set the cron job to run
# this at noon each day, and grab that day's files
# david hill, oregon state university, dfh@oregonstate.edu, 17 jun 2020

#establish home directory for where my snodas archive is already at
homedir="/nfs/attic/dfh/data/snodas/snodas_download"
echo "$homedir"
#create folder for temp download
tempdir="$homedir/dailyupdate"
echo "$tempdir"
mkdir -p $tempdir
cd $tempdir

#get today's date info
day=$(date '+%d')
month=$(date '+%b')
monthnum=$(date '+%m')
year=$(date '+%Y')

#build up filename to get (Hs)
filename="SNODAS_$year$monthnum$day.tar"

#get file
wget -N ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/masked/$year/"${monthnum}_${month}"/$filename

#untar
tar -xvf $filename
#clean up by removing .tar file
rm $filename
#unzip
gunzip -f *.gz

#create destination folders for 1034 (SWE) and 1036 (HS) files.
mkdir -p "../$year/${monthnum}_${month}/Hs"
mkdir -p "../$year/${monthnum}_${month}/SWE"

#move 1034 files to SWE folder and 1036 files to Hs 
#folder...the rest will be deleted. Easy to change this to keep additional
#variables of interest (1025SlL00, 1025SlL01, 1038, 1039, 1044, 1050)
FILES=*.*
for files in $FILES
do
	case $files in
		*1034*)
		mv $files "../$year/${monthnum}_${month}/SWE/."
		;;
		*1036*)
		mv $files "../$year/${monthnum}_${month}/Hs/."
		;;
	esac
done
#remove the other files
rm *.*
#remove the temporary directory
cd ..
rmdir $tempdir		


