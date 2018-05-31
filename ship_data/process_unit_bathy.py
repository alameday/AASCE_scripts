#!/usr/bin/env python
#RMS 2018
#Grid and plot just one bathy file

import pandas as pd
import utm
import numpy as np
import os
import sys

def utm2latlon(eastings,northings,zone_number=5,zone_letter='U'):

	'''Convert arrays of easting and northings to lat lon'''

	lons = np.zeros(len(eastings))
	lats = np.zeros(len(northings))
	i = 0 

	for (e,n) in zip(eastings,northings):

		if i%100000 == 0:
			print("Processed %i lat/lons" %i)
	    
		(lat,lon) = utm.to_latlon(e,n,zone_number,zone_letter,strict=False)
		lons[i] = lon
		lats[i] = lat
		i += 1 
	    
	return lats,lons

def main():

	try:
		XYZfile = sys.argv[1]
	except:
		print("Useage: ./process_unit_bathy.py [fname]")
		sys.exit(1)

	if not os.path.exists(XYZfile):
		print("Given file %s not present" %infile)
		sys.exit(1)

	ofname = XYZfile[:-4]+'.grd'

	if not os.path.exists(ofname):

		print("Processing %s -> %s" %(XYZfile,ofname))
		bathy_test = pd.read_csv(XYZfile,sep=' ',names=['easting','northing','depth'])
		eastings = bathy_test['easting'].values
		northings = bathy_test['northing'].values
		lats, lons = utm2latlon(eastings,northings,zone_number=6,zone_letter='U')
		bathy_test['latitude'] = lats
		bathy_test['longitude'] = lons
		bathy_test[['longitude','latitude','depth']].to_csv('Bathymetry_lonlat.dat',
					                                        index=False,header=False)
		minlon=min(lons)-0.01
		maxlon=max(lons)+0.01
		minlat=min(lats)-0.01
		maxlat=max(lats)+0.01

		print("Gridding")

		os.system('gmt xyz2grd Bathymetry_lonlat.dat -G%s -I0.0003 -R%s/%s/%s/%s' 
			%(ofname,minlon,maxlon,minlat,maxlat))

	else:
		os.system('gmt grdinfo %s > tmp_info.dat' %ofname)

		infile=open('tmp_info.dat','r')
		lines = infile.readlines()
		grdcommand=lines[1].split()[-1].split('/')
		minlon=float(grdcommand[0].replace('-R',''))-0.01
		maxlon=float(grdcommand[1])+0.01
		minlat=float(grdcommand[2])-0.01
		maxlat=float(grdcommand[3])+0.01


	#plot the bathymetry
	print("Mapping %s" %(ofname))
	oname='%s.ps' %ofname 
 
	os.system('./map_unit_bathy.sh %s %s %s %s %s %s'  %(ofname,minlon,maxlon,minlat,maxlat,oname))

if __name__ == '__main__':

	main()



