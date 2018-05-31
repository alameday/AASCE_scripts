#!/bin/bash 
#RMS 2018
#Basic map of the AASCE Alaska cruise route

gmt gmtset BASEMAP_TYPE_FANCY
gmt gmtset FONT_ANNOT_PRIMARY 14

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
#accurate shiptrack
shiptrack=/Users/rmartinshort/Documents/Berkeley/Alaska/OBS_cruise/ship_data/shiptrack_full.dat

J=B-156/55.75/53.5/58/15i #map projection is Albers Conic Equal Area (see GMT docs)
R=-163/-149/53.5/58 #Cruise region 

###############
#Extract data we want to plot from the Sikuliaq track
awk -F',' '{print $3,$4}' SIKULIAQ_track.dat > tmp
tail -1 tmp > current_pos.dat
fullshiptrack=tmp
################

ps=basic_map.ps

#Make gradient file for lighting effects
gmt grdgradient $GRD -Nt1 -A0/270 -Ggrad_i.nc

#Run pscoast to generate the coastlines
gmt pscoast -Rd$R -J$J -BWSne -B1.0f1.0 -Dh -A100/1/1 -Slightblue -Glightgray -P -Lf-160.5/57.5/57.5/200.0+l"Distance [km]" -K -Wthinnest --PS_MEDIA=Custom_17ix10i > $ps

#plot the transparent topography 
gmt grdimage $GRD -Igrad_i.nc -C255,255 -t60 -R$R -J$J -K -O >> $ps 

#Contour the alaska slab from the slab 1.0 model 
#gmt grdcontour $alaskaslab -J$J -R$R -Wthickest,blue -C20 -O -K >> $ps

#plot the plate margins 
gmt psxy $birdplates -Sf2.5/15p+t+l -J$J -Rd$R -Wthickest,purple -O -V -K >> $ps

#Plot the route between stations
gmt psxy $shiptrack -J$J -R$R -O -Wthin,red -K -V >> $ps

#Plot all station names
gmt pstext final_locations.csv -J$J -Rg$R -D0/-0.4 -Gwhite -O -K >> $ps

#Plot all stations
gmt psxy final_locations.csv -J$J -R$R -St0.5 -Gblack -Wthin,black -O -V >> $ps

#Plot the ship information
#gmt psxy $fullshiptrack -J$J -R$R -O -Wthin,blue -L -K >> $ps
#gmt psxy current_pos.dat -J$J -R$R -O -Wthickest,blue -L -Sc0.3 -K -Gblue >> $ps

#Post-processing stuff - make pdf
gmt ps2raster $ps -P -Tf

open basic_map.pdf


