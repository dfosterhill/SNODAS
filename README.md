# SNODAS
Scripts for obtaining and processing NOHRSC SNODAS data files.

This repository holds several scripts (Matlab / bash) that are useful for obtaining and processing SNODAS data sets.

* averagesnodas.m - this Matlab script will take 1036 (depth) or 1034 (swe) files from SNODAS and compute statistics for each day of the year. The period of record is 15 years. Min, max, and mean files are output.

* animate_average_snodas_grids.m - this Matlab script will create a movie of the grids produced by averagesnodas.m. It is presently set up to make movie of the 'mean' files, but can easily be changed to do min or max.

* plot_average_snodas_grids.m - this Matlab script will create a folder of images of the grids produced by averagesnodas.m. It is presently set up to plot the 'mean' files, but can easily be changed to do min or max. User can set region of interest and control the colorbar limits.
