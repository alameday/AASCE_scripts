#!/usr/bin/env python
#RMS 2018
#Takes .xyz files from bathymetry program and converts to .netCDF

import pandas as pd
import utm
import numpy as np
import os
import glob

def utm2latlon(eastings,northings,zone_number=5,zone_letter='U'):

	'''Convert arrays of easting and northings to lat lon'''

	lons = np.zeros(len(eastings))
	lats = np.zeros(len(northings))
	i = 0 

	for (e,n) in zip(eastings,northings):
	    
	    (lat,lon) = utm.to_latlon(e,n,zone_number,zone_letter,strict=False)
	    lons[i] = lon
	    lats[i] = lat
	    i += 1 
	    
	return lats,lons

def grd2concat(concat_file,grd_file):

	print("Working on file %s" %grd_file)

	os.system('gmt grd2xyz %s >> %s' %(grd_file,concat_file))


def main():

	basename = "/Users/rmartinshort/Documents/Berkeley/Alaska/OBS_cruise/bathymetry/"
	os.chdir(basename)

	fnames = glob.glob('*out0.xyz')
	pfiles = []

	#Create a file that will keep track of the bathymetry xyz files that have already
	#been converted to .grd. May need to delete this if we want to rerun

	if not os.path.exists('Already_processed.dat'):
		processed_files = open('Already_processed.dat','w')
	else:
		processed_files = open('Already_processed.dat','r')
		already_processed = processed_files.readlines()
		processed_files.close()
		for element in already_processed:
			pfiles.append(element.strip())

	globalminlats = []
	globalminlons = []
	globalmaxlats = []
	globalmaxlons = []

	print(pfiles)

	processed_files = open('Already_processed.dat','w')

	for XYZfile in fnames:

			if XYZfile not in pfiles:

				print("-----------------------------------")
				print("Processing file %s" %XYZfile)
				print("-----------------------------------")

				ofname = XYZfile[:-4]+'.grd'
				bathy_test = pd.read_csv(XYZfile,sep=' ',names=['easting','northing','depth'])
				eastings = bathy_test['easting'].values
				northings = bathy_test['northing'].values
				lats, lons = utm2latlon(eastings,northings,zone_number=6,zone_letter='U')
				bathy_test['latitude'] = lats
				bathy_test['longitude'] = lons
				bathy_test[['longitude','latitude','depth']].to_csv('Bathymetry_lonlat.dat',
				                                        index=False,header=False)
				minlon=min(lons)
				maxlon=max(lons)
				minlat=min(lats)
				maxlat=max(lats)

				globalmaxlats.append(maxlat)
				globalmaxlons.append(maxlon)
				globalminlats.append(minlat)
				globalminlons.append(minlon)

				os.system('gmt xyz2grd Bathymetry_lonlat.dat -G%s -I0.0001 -R%s/%s/%s/%s' 
					%(ofname,minlon,maxlon,minlat,maxlat))

				processed_files.write('%s\n' %XYZfile)


	processed_files.close()

	#open the file that keeps track of the global min and max coordinates found. Rewrite if needed so that we can use 
	#this information to plot the bathymetry on a map.

	if (len(globalmaxlats) > 1): 

		if os.path.exists('min_max_lon_lat.dat'):
			maxminlonlat = open('min_max_lon_lat.dat','r')
			lines = maxminlonlat.readlines()
			coords = lines[0].split(',')
			min_lon = float(coords[0])
			max_lon = float(coords[1])
			min_lat = float(coords[2])
			max_lat = float(coords[3])

			if min(globalminlons) < min_lon:
				min_lon = min(globalmaxlons)
			elif min(globalminlats) < min_lat:
				min_lat = min(globalmaxlats)
			elif max(globalmaxlons) > max_lon:
				max_lon = max(globalmaxlons)
			elif max(globalmaxlats) > max_lat:
				max_lat = max(globalminlats)

		maxminlonlat = open('min_max_lon_lat.dat','w')
		maxminlonlat.write('%s,%s,%s,%s' %(min(globalminlons),max(globalmaxlons),min(globalminlats),max(globalminlats)))

	grdfiles = glob.glob('*out0.grd')
	concat_file_name = 'all_bathy.xyz'
	os.system('gmt grd2xyz %s > %s' %(grdfiles[0],concat_file_name))

	for grdfile in grdfiles[1:]:
		grd2concat(concat_file_name,grdfile)


if __name__ == '__main__':
	main()









