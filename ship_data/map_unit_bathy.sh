#!/bin/bash
#Produce map of a small region of the mutibeam bathymetry

fname=$1
minlon=$2
maxlon=$3
minlat=$4
maxlat=$5
oname=$6

echo $oname

gmt gmtset BASEMAP_TYPE_FANCY
gmt gmtset FONT_ANNOT_PRIMARY 12

#Subducted plate contours
alaskaslab=/Users/rmartinshort/Documents/Berkeley/Subduction_dynamics/Slab1.0_data/allslabs/alu_slab1.0_clip.grd
#Topography
GRD=/Users/rmartinshort/Documents/Berkeley/Alaska/maps/station_map/Alaska_gebco.nc
#Volcano locations 
volcanoes=/Users/rmartinshort/Documents/Berkeley/Alaska/maps/station_map/tectonics_quakes_map/Alaska_volcanoes.dat
#Tectonic plate bpundaries
birdplates=/Users/rmartinshort/Documents/Berkeley/Alaska/maps/station_map/bird_plates.xy
#Station locations
stations=/Users/rmartinshort/Documents/Berkeley/Alaska/OBS_cruise/maps/locations4gmt.dat
#color scheme 
CPT=/Users/rmartinshort/Documents/Berkeley/Useful_GMT_data/colormaps/mby.cpt
#previous bathy
prevbathy=/Users/rmartinshort/Documents/Berkeley/Alaska/OBS_cruise/maps/allSonne_1994_100m.nc

#Blend the high resolution bathymetry with lower resolution bathymetry to reduce artifacts
#gmt grdsample -R$R -I0.0005 $fname -Gbathy.grd
gmt grdsample -R$R -I0.0003 $GRD -Glow_res.grd
gmt grdblend $fname low_res.grd -R$R -I0.0003 -Gbathy.grd
#gmt grd2xyz bathyblended.grd > tmp.xyz
#gmt surface tmp.xyz -R$R -I0.0005 -T1 -Gsmoothed_blended.grd

gmt grd2cpt bathy.grd -Crainbow -E500 > bathycpt.cpt
CPT=bathycpt.cpt

ps=$oname

J=M5i 
R=$minlon/$maxlon/$minlat/$maxlat  #bathy file bounds

#high res bathy
bathy=$fname
bathy=bathy.grd

#Make gradient file for lighting effects
gmt grdgradient $bathy -Nt1 -A0/270 -Ggrad_h.nc
#gmt grdgradient $GRD -Nt1 -A0/270 -Ggrad_i.nc

gmt pscoast -Rd$R -J$J -BWSne -B0.05f0.05g0.05 -Df -A100/1/1 -K -Wthinnest -Slightblue -Glightgray --PS_MEDIA=Custom_15ix8i > $ps

#plot transparent bathy from global grid
#gmt grdimage $GRD -Igrad_i.nc -C255,255 -t30 -R$R -J$J -K -O >> $ps

#Contour the bathymetry 
gmt grdcontour $GRD -J$J -R$R -Wthin -C50 -A50 -O -K >> $ps

#Make the bathymetry
gmt grdimage $bathy -Igrad_h.nc -C$CPT -R$R -J$J -K -O -Q >> $ps

#Contour the bathymetry 
gmt grdcontour $bathy -J$J -R$R -Wthin -C50 -A50 -O -K >> $ps

#Plot all stations
gmt psxy $stations -J$J -R$R -St0.5 -Gorange -Wthin,black -O -K -V >> $ps
#Plot all station names
gmt pstext $stations -J$J -Rg$R -D0/-0.4 -O -K >> $ps

#Make the scale 
gmt psscale -D0i/0i/3.5i/0.2ih -X2.5i -Y12.8i -E -C$CPT -Ba300f300g300/:"Surface height [m]": -O >> $ps

#Post-processing stuff - make pdf
gmt ps2raster $ps -P -Tf

#open bathy.pdf

#------------------------------------------------------------------------------------------------
#Make the previous bathy map
#------------------------------------------------------------------------------------------------

# ps=prevbathy_map.ps

# gmt grdgradient $prevbathy -Nt1 -A0/270 -Ggrad_h.nc

# #Make the image, using the mby.cpt color scheme
# gmt grdimage $prevbathy -Igrad_h.nc -C$CPT -R$R -J$J -K -Q --PS_MEDIA=Custom_20ix13i > $ps

# #Run pscoast to generate the coastlines
# gmt pscoast -Rd$R -J$J -BWSne -B0.05f0.05 -Df -A100/1/1 -P -O -K -Wthinnest -Glightgray >> $ps

# #Plot all stations
# gmt psxy $stations -J$J -R$R -St0.1 -Gorange -Wthin,black -O -K -V >> $ps

# #Make the scale 
# gmt psscale -D0i/0i/2.0i/0.2ih -X1.5i -Y13i -E -C$CPT -Ba5f5g5/:"Surface height [m]": -O >> $ps

# #Post-processing stuff - make pdf
# gmt ps2raster $ps -P -Tf

# open prevbathy_map.pdf




