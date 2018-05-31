#!/bin/bash 
#RMS 2018
#Basic map of all events since 1970 in the cruise region. Will use to try to understand clustering

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
#Earthquakes
events=Events_since_1970.dat

J=B-156/55.75/53.5/58/15i #map projection is Albers Conic Equal Area (see GMT docs)
R=-163/-149/53.5/58 #Cruise region 

###############
#Extract data we want to plot from the Sikuliaq track
awk -F',' '{print $3,$4}' SIKULIAQ_track.dat > tmp
tail -1 tmp > current_pos.dat
fullshiptrack=tmp
################
#Extract the earthquake data to plot
awk -F' ' '{print $1,$2,$3/1000}' $events > tmp_events

ps=earthquake_map.ps

#Make gradient file for lighting effects
gmt grdgradient $GRD -Nt1 -A0/270 -Ggrad_i.nc

#Run pscoast to generate the coastlines
gmt pscoast -Rd$R -J$J -BWSne -B1.0f1.0 -Dh -A100/1/1 -Wthin -Slightblue -Glightgray -P -Lf-160.5/57.5/57.5/200.0+l"Distance [km]" -K -Wthinnest --PS_MEDIA=Custom_17ix15i > $ps

#plot the transparent topography 
gmt grdimage $GRD -Igrad_i.nc -C255,255 -t50 -R$R -J$J -K -O >> $ps 

#Contour the alaska slab from the slab 1.0 model 
gmt grdcontour $alaskaslab -J$J -R$R -Wthickest,blue -C20 -O -K >> $ps

#Plot all events
gmt psxy tmp_events -J$J -Rg$R -Sc0.2 -Wthinnest -t80 -Cneis.cpt -O -K >> $ps

#plot the plate margins 
gmt psxy $birdplates -Sf2.5/15p+t+l -J$J -Rd$R -Wthickest,purple -O -V -K >> $ps

#Plot the projected route between stations (from Spar's program)
#gmt psxy Projected_track.dat -J$J -Rg$R -O -Wthick,red  -K >> $ps

#Plot all station names
#gmt pstext $stations -J$J -Rg$R -D0/-0.4 -O -K >> $ps

#Plot all stations
gmt psxy $stations -J$J -R$R -St0.5 -Gorange -Wthin,black -O -V -K >> $ps

#Make the legend
gmt pslegend -R$R -J$J -D-156/59.3/3i/0.3i -C0.1i/0.1i -L1.5 -O << EOF >> $ps
G -0.1i
H 15 Legend
D 0.2i 1p
N 1
V 0 1p
S 0.1i c0.3 0.5 red thinnest,black 0.4i 0-20km
S 0.1i c0.3 0.5 orange thinnest,black 0.4i 20-50km
S 0.1i c0.3 0.5 yellow thinnest,black 0.4i 50-100km
S 0.1i c0.3 0.5 green thinnest,black 0.4i 100-150km
S 0.1i c0.3 0.5 blue thinnest,black 0.4i 150-200km
V 0 1p
D 0.2i 1p
N 1
G 0.05i
EOF

#Plot the ship information
#gmt psxy $fullshiptrack -J$J -R$R -O -Wthin,blue -L -K >> $ps
#gmt psxy current_pos.dat -J$J -R$R -O -Wthickest,blue -L -Sc0.3 -K -Gblue >> $ps

#Post-processing stuff - make pdf
gmt ps2raster $ps -P -Tf

open earthquake_map.pdf


