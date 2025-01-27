# MINIO_ALIAS and BUCKET_NAME are assumed to be environment variables

set dotenv-load

# list all the available commands
default:
  just --list

latest_key := `mcli --json ls ${MINIO_ALIAS}/tgwf-green-domains-live/ | jq -s '.[-1].key'`


# print the path to the latest daily green domains snapshot
print_latest_key:
    echo {{latest_key}}

# run the server. clearing and downloading the databases to serve via datasette
serve: daily_snapshot real_time_cloud_csvs real_time_cloud_db
	uv run datasette . -h 0.0.0.0

# run the datasette server with out clearing and downloading the latest snapshot
serve_no_snapshot:
	uv run datasette . -h 0.0.0.0

# run the tests
test:
	uv run pytest

# run the tests every time python code is changed
test_dev:
	# run pytest on every file to files matching .py
	find . -name '*.py' | entr pytest

# clear all the local databases and download the latest snapshots
all_dataset_dbs: daily_snapshot real_time_cloud_csvs real_time_cloud_db

# fetch  the latest real time cloud dataset snapshots from object storage
real_time_cloud_csvs:
	mcli cp ${MINIO_ALIAS}/${RTC_BUCKET_NAME}/realtimecloud/cloud_region_metadata.b890188.csv cloud_region_metadata.csv
	mcli cp ${MINIO_ALIAS}/${RTC_BUCKET_NAME}/realtimecloud/cloud_region_metadata_dev.aa905b1.csv cloud_region_metadata_dev.csv

# create a sqlite databse for the real time cloud dataset and importy the csvs
real_time_cloud_db:
	uv run sqlite-utils create-database cloud_regions.db
	uv run sqlite-utils insert cloud_regions.db cloud_regions_metadata ./cloud_region_metadata.csv --csv -d
	uv run sqlite-utils insert cloud_regions.db cloud_regions_metadata_dev ./cloud_region_metadata_dev.csv --csv -d


# download and uncompress the latest daily snapshot of the green domains dataset
daily_snapshot: downloaded_snapshot 
	gunzip ./daily_snapshot.db.gz

# download the latest daily green domains snapshot from object storage
downloaded_snapshot: cleared_snapshot
	echo "Downloading database snapshot from ${MINIO_ALIAS}/${BUCKET_NAME}/{{ latest_key }}"
	# copy the file to the local filesystem
	mcli cp ${MINIO_ALIAS}/${BUCKET_NAME}/{{ latest_key }} daily_snapshot.db.gz

# remove any local sqlite.db databases
cleared_snapshot:
	rm -rf ./*.db
	rm -rf ./*.csv

# deploy the latest version to production
release *options:
	uv run ansible-playbook ansible/deploy.yml -i ansible/inventories/prod.yml {{ options }}