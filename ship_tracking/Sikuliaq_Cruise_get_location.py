#!/usr/bin/env python
#RMS 2018

#Loop to access the location, speed and heading of the RV SIKULIAQ and write to a file

import time
import datetime
import pandas as pd
import obspy as op 
import requests
import os


def main():

	start_time = datetime.datetime.today()
	set_time = 1000000
	timer = 0
	sleep_time = 600 
	trackfilename = "SIKULIAQ_track.dat"

	trackfile = open(trackfilename,'a')
	trackfile.write('Started: %s\n' %start_time)
	trackfile.close()

	while timer < set_time:

		print("Requesting location")
		trackfile = open(trackfilename,'a')

		response = requests.get("https://web.sikuliaq.alaska.edu/track/?REFRESH=60")
		page = response.content
		table = pd.read_html(page)[0]

		try:
			lat = float(table[1][1].split(' ')[2])
			lon = -float(table[1][2].split(' ')[1])
		except:
			lon = 'NaN'
			lat = 'NaN'
			continue

		record_time = table[0][1].split(':')
		update_time = table[0][2].split(':')

		try:

			Rtime = op.UTCDateTime('-'.join([record_time[1].split("@")[0].strip(),
                                record_time[1].split("@")[1].strip(),
                                record_time[2],record_time[3].split(' ')[0]]))
			Utime = op.UTCDateTime('-'.join([update_time[1].split("@")[0].strip(),
                                update_time[1].split("@")[1].strip(),
                                update_time[2],update_time[3].split(' ')[0]]))

			if abs(Rtime-Utime) > 600:

				print("Regular shiptrack site hasn't updated for > 10 mins. Trying alternative")

				base_url="http://data.sikuliaq.alaska.edu/archive/SKQ201811S/lds/raw/pco2_ldeo_merge/"
				response = requests.get(base_url)
				page = response.content
				table = pd.read_html(page)[0]
				fname = table.loc[len(table)-1][1]
				response = requests.get(base_url+fname)
				page = str(response.content)
				sdata = page.split('\n')[-2]


				latval = sdata.split(',')[11].strip().split()[0]
				lonval = sdata.split(',')[12].strip().split()[0]

				lat = float(latval[:2]) + float(latval[2:])/60
				lon = -1*(float(lonval[:3]) + float(lonval[3:])/60)
				speed = float(sdata.split(',')[-6])*1.852 #conversion from knots to km/h
				heading = np.nan

		except:
			Rtime = 'NaN'
			Utime = 'NaN'
			continue

		try:
			heading = float(table[3][1].split()[2])
			speed = float(table[4][2].split()[0])
		except:
			heading = 'NaN'
			speed = 'NaN'
			continue

		trackfile.write('%s,%s,%s,%s,%s,%s\n' %(Rtime,Utime,lon,lat,heading,speed))
		trackfile.close()


		time.sleep(sleep_time)
		timer += sleep_time


if __name__ == '__main__':

	main()



