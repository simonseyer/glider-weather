from eccodes import *
from glob import glob
import pygrib
import sys
from pymongo import MongoClient
from multiprocessing import Pool
from collections import namedtuple

path = "{}/icon-eu_europe_regular-lat-lon_model-level_*_*_{}_T.grib2"
altitude_path = "{}/icon-eu_europe_regular-lat-lon_time-invariant_*_{}_HHL.grib2"
batch_size = 100000
levels = range(35, 61)

GribEntry = namedtuple('GribEntry', 'latitude longitude values')

def grib_generator(paths):
	files = [open(path, 'rb') for path in paths]
	gids = [codes_grib_new_from_file(file) for file in files]
	iterators = [codes_grib_iterator_new(gid, 0) for gid in gids]

	while True:
		results = [codes_grib_iterator_next(iterator) for iterator in iterators]
		if not results[0]:
			break

		latitude = results[0][0]
		longitude = results[0][1]
		values = [result[2] for result in results]

		yield GribEntry(latitude, longitude, values)

	[codes_grib_iterator_delete(iterator) for iterator in iterators]
	[codes_release(gid) for gid in gids]
	[file.close() for file in files]

def process(level, base_path):
	paths = glob(path.format(base_path, level))
	generator = grib_generator(paths)
	altitude_paths = glob(altitude_path.format(base_path, level))
	altitude_generator = grib_generator(altitude_paths)

	metadata = [pygrib.index(path,'name')(name='Temperature')[0] for path in paths]
	analysis_date = metadata[0].analDate
	forecast_dates = [entry.validDate for entry in metadata]

	database = MongoClient("mongodb://127.0.0.1:27017").weather.temperatures
	count = 0
	documents = []

	print(f"Level {level}: start processing")

	for (temperature_entry, altitude_entry) in zip(generator, altitude_generator):
		temperatures = [value - 273.15 for value in temperature_entry.values]

		documents.append({
			'location': {
				'type': 'Point',
				'coordinates': [temperature_entry.longitude, temperature_entry.latitude]
			},
			'analysis_date': analysis_date,
			'altitude': altitude_entry.values[0],
			'temperatures': [{
				'forecast_date': data[0], 
				'temperature': data[1]
			} for data in zip(forecast_dates, temperatures)]
		})

		count += 1
		if len(documents) % batch_size == 0:
			database.insert_many(documents)
			documents = []
			print(f"Level {level}: inserted {count} entries")

	database.insert_many(documents)
	print(f"Level {level}: finished processing {count} entries")

def run():
	base_path = sys.argv[1]
	process_pool = Pool(processes=8)

	for level in levels:
		process_pool.apply_async(process, args=(level, base_path))

	process_pool.close()
	process_pool.join()

if __name__ == '__main__':
    run()
