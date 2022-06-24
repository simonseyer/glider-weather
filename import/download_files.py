from datetime import datetime, timedelta
import math
import urllib.request
import pathlib
import bz2
import sys
from multiprocessing import Pool

levels = range(35, 61)
forecast_offsets = range(0, 31)
base_path = sys.argv[1]

def getMostRecentModelTimestamp(waitTimeMinutes=180, modelIntervalHours=3):
    # model data becomes available approx 1.5 hours (90minutes) after a model run
    # cosmo-d2 model and icon-eu run every 3 hours
    now = datetime.utcnow() - timedelta(minutes=waitTimeMinutes)
    latestAvailableUTCRun = int(math.floor(now.hour/modelIntervalHours) * modelIntervalHours)
    modelTimestamp = datetime( now.year, now.month, now.day, latestAvailableUTCRun)
    return modelTimestamp

temperature_url_pattern = "https://opendata.dwd.de/weather/nwp/icon-eu/grib/{modelrun:02}/t/icon-eu_europe_regular-lat-lon_model-level_{timestamp:%Y%m%d}{modelrun:02}_{offset:03}_{level}_T.grib2.bz2"
height_url_pattern = "https://opendata.dwd.de/weather/nwp/icon-eu/grib/{modelrun:02}/hhl/icon-eu_europe_regular-lat-lon_time-invariant_{timestamp:%Y%m%d}{modelrun:02}_{level}_HHL.grib2.bz2"

timestamp=getMostRecentModelTimestamp()

def download_and_extract(url):
	file_name = pathlib.Path(url).stem
	file_path = base_path + "/" + file_name

	print(f"{url} -> {file_path}")

	resource = urllib.request.urlopen(url)
	compressed_data = resource.read()

	binary_data = bz2.decompress(compressed_data)

	with open(file_path, 'wb') as outfile:
		outfile.write(binary_data)

urls = []

for level in levels:
	urls.append(height_url_pattern.format(
		modelrun=timestamp.hour,
		timestamp=timestamp,
		level=level
	))

	for forecast_offset in forecast_offsets:
		urls.append(temperature_url_pattern.format(
			modelrun=timestamp.hour,
			timestamp=timestamp,
			level=level,
			offset=forecast_offset 
		))

def processJobs():
	process_pool = Pool(processes=16)
	process_pool.map(download_and_extract, urls)

if __name__ == '__main__':
    processJobs()
