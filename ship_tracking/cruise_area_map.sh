#!/bin/bash 
#RMS 2018
#Map of fieldwork location with ship location, seismometer locations and names plus details about the 
#next site on the cruise

#This should be called automatically from plot_ship_location.py 


if [ $# -eq 5 ]; then
	echo "Correct number of arguments given"
else 
	echo "Usage: ./cruise_area_map.sh station_name station_type station_distance speed heading"
	echo "Should be called by a wrapper"
	exit 1 
fi

next_station_name=$1
next_station_type=$2
next_station_distance=$3
speed=$4
heading=$5

gmt gmtset BASEMAP_TYPE_FANCY
gmt gmtset FONT_ANNOT_PRIMARY 12

#Subducted plate contours
alaskaslab=/Users/rmartinshort/Documents/Berkeley/Subduction_dynamics/Slab1.0_data/allslabs/alu_slab1.0_clip.grd
#Topography
GRD=/Users/rmartinshort/Documents/Berkeley/Alaska/maps/station_map/Alaska_gebco.nc
#High res bathy
hires_bathy=allSonne_1994_100m.nc
#Volcano locations 
volcanoes=/Users/rmartinshort/Documents/Berkeley/Alaska/maps/station_map/tectonics_quakes_map/Alaska_volcanoes.dat
#Tectonic plate bpundaries
birdplates=/Users/rmartinshort/Documents/Berkeley/Alaska/maps/station_map/bird_plates.xy
#Station locations
stations=/Users/rmartinshort/Documents/Berkeley/Alaska/OBS_cruise/maps/locations4gmt.dat
#color scheme 
CPT=/Users/rmartinshort/Documents/Berkeley/Useful_GMT_data/colormaps/mby.cpt
#accurate shiptrack
shiptrack=/Users/rmartinshort/Documents/Berkeley/Alaska/OBS_cruise/ship_data/shiptrack_full.dat


J=B-156/55/51/60/12i #map projection is Albers Conic Equal Area (see GMT docs)
R=-163/-148/52.5/58.5 #Cruise region

################
#Extract data we want to plot from the Sikuliaq track
awk -F',' '{print $3,$4}' SIKULIAQ_track.dat > tmp
tail -1 tmp > current_pos.dat
fullshiptrack=tmp
################

ps=Cruise_region.ps

#Make gradient file for lighting effects
gmt grdgradient $GRD -Nt1 -A0/270 -Ggrad_i.nc

#Make gradient file for lighting effects
#gmt grdgradient $hires_bathy -Nt1 -A0/270 -Ggrad_hi.nc

#Make the image, using the mby.cpt color scheme
gmt grdimage $GRD -Igrad_i.nc -C$CPT -R$R -J$J -K --PS_MEDIA=Custom_17ix14i > $ps

#plot the high resolution bathymetry on top
#gmt grdimage $hires_bathy -Igrad_hi.nc -C$CPT -R$R -J$J -K -O -Q >> $ps

#Run pscoast to generate the coastlines
gmt pscoast -Rd$R -J$J -BWSne -B2.0f2.0 -Dh -A500/1/1 -P -Lf-160.5/57.5/57.5/200.0+l"Distance [km]" -K -O -Wthinnest >> $ps

#Contour the alaska slab from the slab 1.0 model 
#gmt grdcontour $alaskaslab -J$J -R$R -Wthickest,blue -C20 -O -K >> $ps

#plot the plate margins 
gmt psxy $birdplates -Sf2.5/15p+t+l -J$J -Rd$R -Wthickest,purple -O -V -K >> $ps

#Plot all volcanoes
#gmt psxy $volcanoes -J$J -R$R -St0.4 -Gred -Wthinnest -O -K -V >> $ps
#plot events
#awk -F' ' '{print $1,$2,$3*0.2}' Events_since_cruise.dat > events.dat
#gmt psxy events.dat -J$J -R$R -O -Wthin,black -L -Sc -K -Gwhite -t40 >> $ps

#Plot the projected route between stations (from Spar's program)
#gmt psxy Projected_track.dat -J$J -Rg$R -O -Wthick,red -K >> $ps

#Plot all segment times 
#gmt pstext Segment_times.dat -J$J -Rg$R -D0/-0.4 -O -K >> $ps


#Plot the ship information
#gmt psxy $fullshiptrack -J$J -R$R -O -Wthin,green -K >> $ps
gmt psxy $shiptrack -J$J -R$R -O -Wthin,green -K -V >> $ps
gmt psxy current_pos.dat -J$J -R$R -O -Wthickest,blue -L -Sc0.3 -K -Gblue >> $ps

#Plot all station names
gmt pstext final_locations.csv -J$J -Rg$R -D0/-0.4 -Gwhite -O -K >> $ps

#Plot all stations
gmt psxy final_locations.csv -J$J -R$R -St0.5 -Gorange -Wthin,black -O -K -V >> $ps

#plot the coordinates of the next station in a different color
#gmt psxy next_station_coords.dat -J$J -R$R -O -Wthin,black -L -St0.5 -K -Gred >> $ps

#plot the coordinates of all visited stations in a different color
#gmt psxy Visited_stations.dat -J$J -R$R -O -Wthin,black -L -St0.5 -K -Ggreen >> $ps

gmt pstext -R$R -J$J -Gwhite -O -N -K -C0.5/0.5 -TO -Wthickest,black >> $ps << END
-162 59.2 16 0.0 0 TL Next station: $next_station_name ($next_station_type), Distance: $next_station_distance km, Speed: $speed km/h
END

#Make the legend
gmt pslegend -R$R -J$J -D-163/62/3i/0.3i -C0.1i/0.1i -L1.5 -O -K << EOF >> $ps
G -0.1i
H 15 Legend
D 0.2i 1p
N 1
V 0 1p
S 0.1i c0.4 0.5 blue thinnest,black 0.4i Sikuliaq location
S 0.1i t0.4 0.5 red thinnest,black 0.4i Next site
S 0.1i t0.4 0.5 green thinnest,black 0.4i Deployed site
S 0.1i t0.4 0.5 orange thinnest,black 0.4i Other site
S 0.1i s0.4 0.5 red thinnest,black 0.4i Seward location
V 0 1p
D 0.2i 1p
N 1
G 0.05i
EOF

#############Inset Alaska map#############
Jinset=B-151.5/50/54/71/6.5i #map projection is Albers Conic Equal Area (see GMT docs)
Rinset=-171/-132/50/71 #Whole of Alaska and Adjacent Canada 
gmt pscoast -R$Rinset -J$Jinset -B10g10 -BSWne -Di -A500/1/1 -Glightbrown -Wthinnest -Slightblue -X4.5i -Y10.0i -O -K >> $ps
gmt psxy domain.dat -J$Jinset -R$Rinset -O -Wthickest,red -L -K >> $ps

#Plot Seward location
gmt psxy seward_loc.dat -J$Jinset -R$Rinset -O -Wthickest,red -L -Ss0.4 -Gred -K >> $ps
gmt pstext seward_loc.dat -J$Jinset -R$Rinset -D1.0/0 -Gwhite -O -K >> $ps

#Plot the full ship track
gmt psxy $shiptrack -J$Jinset -R$Rinset -O -Wthin,blue -K >> $ps
#plot the current ship location
gmt psxy current_pos.dat -J$Jinset -R$Rinset -O -Wthickest,blue -L -Sc0.3 -Gblue >> $ps
#####################################

#Make the scale 
#gmt psscale -D2.3i/-0.4i/4.0i/0.2ih -E -C$CPT -Ba2000f2000g2000/:"Surface height [m]": -O >> $ps

#Post-processing stuff - make pdf
gmt ps2raster $ps -P -Tf

open Cruise_region.pdf