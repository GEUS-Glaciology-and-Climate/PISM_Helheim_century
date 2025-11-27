#!/bin/bash

# Created by Signe Hillerup Larsen in 2022
# This script generates a PISM readable netcdf file.
# It requires Bedmachine data and netcdf files from pism-stable/examples (if files are not there, run preprocess.sh in the example files => Manual tweeking is likely necessary.
# At present it loads in a mask for Helheim - this is probably not necessary for a lot of applications

# Setting the working file (the file to be created)
PROJ_LIB=/usr/share/proj
WORKING=pism_files/pism_greenland_1km_v3.nc


# Removing earlier versions of this file in order to start from scratch
rm $WORKING


# Setting the directory where to find the bedmachine folder
DATADIR=data


# Setting the dorectory where to find pism examples
PISM_EXAMPLEDIR=/home/shl@geus.dk/programs/pism-stable/examples

# Defining the grid resolution at the higest resolution expected to run 
xres=1000
yres=1000
xmin=-593725
ymin=-3331123
xmax=855521
ymax=-815550

# Interpolating Bedmaching data onto the grid defined above
DATA=$DATADIR/Morlighem_2022/BedMachineGreenland-v5.nc
variab=thickness
shortname=thk
gdalwarp -of netCDF -r near -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncks -O -v Band1 tmp.nc $WORKING
ncap2 -s 'thk=float(Band1)' $WORKING $WORKING -O
ncap2 -s 'where(thk<0) thk=0' $WORKING $WORKING -O
ncatted -a standard_name,$shortname,d,, $WORKING # remove it
ncatted -O -a units,$shortname,o,c,"m" $WORKING
ncatted -O -a long_name,$shortname,o,c,"Ice sheet thickness" $WORKING
rm tmp.nc

variab=bed
shortname=topg
gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r near -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncks -A -v Band1 tmp.nc $WORKING
ncap2 -s 'topg=float(Band1)' $WORKING $WORKING -O
ncatted -a standard_name,$shortname,d,, $WORKING # remove it
ncatted -O -a units,$shortname,o,c,"m" $WORKING
ncatted -O -a long_name,$shortname,o,c,"Bedrock topography" $WORKING
rm tmp.nc

variab=surface
shortname=usurf
gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r near -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncks -A -v Band1 tmp.nc $WORKING
ncap2 -s 'usurf=float(Band1)' $WORKING $WORKING -O
ncatted -a standard_name,$shortname,d,, $WORKING # remove it
ncatted -O -a units,$shortname,o,c,"m" $WORKING
ncatted -O -a long_name,$shortname,o,c,"Ice surface elevation" $WORKING
rm tmp.nc




# Interpolating the ground heatflux from a PISM example 
DATA=$PISM_EXAMPLEDIR/jako/gr1km.nc #geothermal_heat_greenland.nc #
variab=bheatflx #Band1 #
shortname=bheatflx
gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r bilinear -srcnodata none -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncap2 -s 'Band1=double(Band1);' $WORKING $WORKING -O
ncks -A -v Band1 tmp.nc $WORKING 
ncap2 -s 'bheatflx=float(Band1)' $WORKING $WORKING -O
#ncrename -v Band1,$shortname $WORKING
ncatted -a standard_name,$shortname,d,, $WORKING # remove it
ncatted -O -a units,$shortname,o,c,"mW/m²" $WORKING
ncatted -O -a long_name,$shortname,o,c,"Basal Heat Flux" $WORKING
rm tmp.nc


# Interpolating climate from SeaRise (PISM example)
DATA=$PISM_EXAMPLEDIR/std-greenland/Greenland_5km_v1.1.nc

variab=presprcp
shortname=precipitation
gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r bilinear -dstnodata none -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncks -A -v Band1 tmp.nc $WORKING
ncap2 -O -s "precipitation=Band1*1000.0" $WORKING $WORKING
ncatted -a standard_name,$shortname,d,, $WORKING # remove it
ncatted -O -a units,$shortname,o,c,"kg m-2 year-1" $WORKING
ncatted -O -a long_name,$shortname,c,c,"mean annual precipitation rate" $WORKING
rm tmp.nc

variab=airtemp2m
shortname=ice_surface_temp
gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r bilinear -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncks -A -v Band1 tmp.nc $WORKING
ncrename -O -v Band1,$shortname $WORKING
ncatted -O -a units,$shortname,o,c,"Celsius" $WORKING
ncatted -O -a long_name,$shortname,c,c,"2 m air temp used as surface temp" $WORKING
rm tmp.nc

variab=smb
shortname=climatic_mass_balance
gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r bilinear -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:$variab tmp.nc -overwrite
ncks -A -v Band1 tmp.nc $WORKING
ncap2 -O -s "climatic_mass_balance=1000.0*Band1" $WORKING $WORKING
ncap2 -O -s "where(thk <= 0.0){climatic_mass_balance=-1000.0;}" $WORKING $WORKING
ncatted -O -a standard_name,$shortname,m,c,"land_ice_surface_specific_mass_balance_flux" $WORKING
ncatted -O -a units,$shortname,m,c,"kg m-2 year-1" $WORKING
rm tmp.nc


# Add the Helheim mask
DATA=helhmask_refined_v3.nc

gdalwarp -of netCDF -t_srs "+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs" -r bilinear -te $xmin $ymin $xmax $ymax -tr $xres $yres NETCDF:${DATA}:Band1 tmp.nc -overwrite
ncks -A -v Band1 tmp.nc $WORKING 
ncap2 -O -s 'ftt_mask=int(Band1)' $WORKING $WORKING 
#ncap2 -s 'where(thk<0) thk=0' $WORKING $WORKING -O
#ncatted -a standard_name,$shortname,d,, $WORKING # remove it
#ncatted -O -a units,$shortname,o,c,"m" $WORKING
ncatted -O -a long_name,$ftt_mask,o,c,"Drainage basin area for regional modeling" $WORKING
rm tmp.nc


# Clean up unwanted variables
# de-clutter by only keeping vars we want

ncks -O -v bheatflx,topg,thk,precipitation,ice_surface_temp,climatic_mass_balance,ftt_mask,usurf $WORKING $WORKING
ncatted -O -a projection,global,c,c,"+proj=stere +lat_0=90 +lat_ts=70 +lon_0=-45 +k=1 +x_0=0 +y_0=0 +datum=WGS84 +units=m +no_defs " $WORKING



# Make the file readable for PISM (calculates lat and long and I think this requires PROJ)
nc2cdo.py $WORKING


# Filling out climate values at edges because PISM v2.0.4 does not like no data in climate files
chmod 755 fill_climate_values.py
python fill_climate_values.py pism_greenland_1km_v3

#rm *tmp*
