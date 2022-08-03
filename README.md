# SNODAS
Scripts for obtaining and processing NOHRSC SNODAS data files.

This repository holds several scripts (Matlab / bash) that are useful for obtaining and processing SNODAS data sets.

* animate_average_snodas_grids.m - this Matlab script will create a movie of the average SNODAS grids (climatologies for each day of the year). It is presently set up to make movie of the 'mean' files, but can easily be changed to do min or max. You can make plots of hs or swe.

* compare_snodas_coco.m - this script will compare SNODAS values to CocoRaHs values. Right now this only works for hs values, not SWE. Note that you have to have previously run the 'extract_snodas_at_cocorahs_points.m' file. That file does the hard work of extracting SNODAS data at desired points and times. This current script just makes the plot.

* compare_snodas_snowcourse.m - this script will compare SNODAS values to snowcourse values. It does this for both hs and swe values. Note that you have to have previously run the 'extract_snodas_at_snowcourses.m' file. That file does the hard work of extracting SNODAS data at desired points and times. This current script just makes the plot.

* compute_snodas_climatologies.m - this Matlab script will take 1036 (depth) or 1034 (swe) files from SNODAS and compute statistics for each day of the year. The period of record is 15 years. Min, max, and mean files are output.

* convert_snodas_hs_to_geo.sh - this is a bash script. It essentially takes a SNODAS hs file (binary format) and it [converts](https://nsidc.org/data/user-resources/help-center/how-do-i-convert-snodas-binary-files-geotiff-or-netcdf) it to a cloud optimized geotiff. It then uploads the file to my google cloud storage, for the purposes of display at www.mountainsnow.org. 

* convert_snodas_to_geo.sh - this is a bash script. It essentially takes a SNODAS swe file (binary format) and it [converts](https://nsidc.org/data/user-resources/help-center/how-do-i-convert-snodas-binary-files-geotiff-or-netcdf) it to a cloud optimized geotiff. It then uploads the file to my google cloud storage, for the purposes of display at www.mountainsnow.org. 

* cso_vs_snodas.m - this script will read in a csv file of CSO observations and then extract SNODAS data (hs) at those locations and times. 

* extract_snodas_at_cocorahs_points.m - this script will take a csv file of cocorahs data and will pull SNODAS values at those locations and times. The results are then saved in a .mat file for use by other scripts.

* extract_snodas_at_snowcourses - this script will take a csv file of snowcourse data data and will pull SNODAS values at those locations and times. The results are then saved in a .mat file for use by other scripts.

* get_proc_snodas.sh - this bash script is based off of [one](https://github.com/eaburakowski/NOHRSC_SNODAS) by Liz Burakowski. It will obtain SNODAS data, reformat a bit, delete unwanted stuff, etc.

* plot_anomaly.m - basically, this script will compute the gridded anomaly of hs or swe. In other words, the difference between a requested day/year and the long term average for that day.

* plot_average_snodas_grids.m - this Matlab script will create a folder of images of the grids produced by compute_snodas_climatologies.m. It is presently set up to plot the 'mean' files, but can easily be changed to do min or max. User can set region of interest and control the colorbar limits.

* snodas_daily_update.sh - this bash script gets TODAY's SNODAS stuff so that it can be uploaded to google cloud storage for the purposes of display at www.mountainsnow.org. It is run daily by my cron jobs.

* snowstats.m - this is a neat script. It requires as input the location (lat/lon) and day/month/year of a snow depth measurement. It also requires the snow depth. It then digs into the SNODAS climatology and creates a nice plot comparing this measurement to min/max/average values.

* snowstats_batch.m - I don't believe this script functions. Consider removing...


