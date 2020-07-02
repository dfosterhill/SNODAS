#! /bin/bash
# scripts to download, unpackage, and clean up snodas data. 

# david hill, oregon state university, dfh@oregonstate.edu, 17 jun 2020

# Note: I seem to have lost my original bash scripts for this, so I have reconstructed 
# my work by adapting scripts from Liz Burakowski (thanks, Liz!), and adjusting to my
# needs. 

#Other notes: while the SNODAS files have many variables, I am simply keeping Hs and SWE 
# and ditching the others. This script will clean things up and move files into sensibly 
# organized folders. 

#Also: you can change this to download the unmasked files if you want (shorter period 
# of record).

# Also note: there are some missing files, as indicated below, so when you generate other
# scripts to loop over them and perform operations, you'll have to plan for these missing
# ones.

#MISSING MASKED FILES
#---------------------

#The following dates are missing ALL data (YYYY-MM-DD):

#2004-02-25
#2004-08-31
#2004-09-27
#2005-06-25
#2005-08-01
#2005-08-02
#2006-08-26
#2006-08-27
#2006-09-08
#2006-09-30
#2006-10-01
#2007-02-14
#2007-03-26
#2008-03-13
#2008-06-13
#2008-06-18
#2009-08-20
#2012-12-20

#The following dates are missing individual files:

#2003-10-30 is missing one file:

#us_ssmv11034tS__T0001TTNATS2003103005HP001

# create folder for download 
mkdir -p snodas_download
cd snodas_download

#loop over years and months to download files. USER CAN SET MONTHS AND YEARS
for months in "09_Sep" "10_Oct" "11_Nov" "12_Dec" "01_Jan" "02_Feb" "03_Mar" "04_Apr" "05_Mar" "06_Jun" "07_Jul" "08_Aug" 

	do
	for years in {2003..2020}
    	do
	  		#next line pulls all days for the given month / year
	  		wget -N ftp://sidads.colorado.edu/DATASETS/NOAA/G02158/masked/$years/"$months"/*.tar
	  		
	  		# (1) untar and unzip
	  		for file in *.tar;
	  		do
	  			tar -xvf $file
	  			gunzip -f *.gz
	  		done
	  	#clean up by deleting .tar files
	  	rm *.tar
	  	
	  	# let's move files into a folder structure of years / months. While there are
	  	# many variables, we will keep only SWE and Hs
	  	
	  	mkdir -p $years/"$months"/SWE
	  	mkdir -p $years/"$months"/Hs
	  	
	  	# let's loop over files to move 1034 files to Hs folder and 1036 files to SWE 
	  	# folder...the rest will be deleted. Easy to change this to keep additional
	  	# variables of interest (1025SlL00, 1025SlL01, 1038, 1039, 1044, 1050)
	  	
	  	FILES=*.*
	  	for files in $FILES
	  	do
	  		case $files in
	  			*1034*)
	  			mv $files $years/"$months"/Hs/.
	  			;;
	  			*1036*)
	  			mv $files $years/"$months"/SWE/.
	  			;;
	  		esac
	  	done
	  	#remove the other files
	  	rm *.*		
    	done
    done
